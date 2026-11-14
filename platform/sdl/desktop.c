/* The Cirera desktop app's files (platform/sdl/main.c, --console or PINYOL_APP): where its menu and games are, the
 * games it comes with copied where they can be played and saved, and a game's .zip dropped on the window installed.
 *   menu:   <app>/menu              (the console's menu, firmware/cirera: a pinyol game)
 *   games:  <user data>/games/<id>  (macOS: ~/Library/Application Support/pinyol/Cirera, Windows: %APPDATA%\pinyol\Cirera)
 * The games that come with the app (<app>/games) are copied there, so their saves live beside them, and copied again
 * by a newer app (its games/.stamp changed). */
#include "desktop.h"

#include <SDL.h>
#include <dirent.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "compat.h"
#include "hal.h"
#include "puff.h"

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif

static bool is_dir(const char *p) {
    struct stat st;
    return !stat(p, &st) && S_ISDIR(st.st_mode);
}

static bool is_file(const char *p) {
    struct stat st;
    return !stat(p, &st) && S_ISREG(st.st_mode);
}

static bool is_link(const char *p) { /* a link, or on Windows any reparse point: never followed */
#ifdef _WIN32
    DWORD a = GetFileAttributesA(p);
    return a != INVALID_FILE_ATTRIBUTES && (a & FILE_ATTRIBUTE_REPARSE_POINT);
#else
    struct stat st;
    return !lstat(p, &st) && S_ISLNK(st.st_mode);
#endif
}

/* Only folders and files under dir: a link unpacked from a zip could point anywhere on the computer */
static bool plain(const char *dir) {
    DIR *d = opendir(dir);
    if (!d) return false;
    struct dirent *e;
    bool ok = true;
    while (ok && (e = readdir(d))) {
        if (!strcmp(e->d_name, ".") || !strcmp(e->d_name, "..")) continue;
        char c[1024];
        snprintf(c, sizeof c, "%s/%s", dir, e->d_name);
        ok = !is_link(c) && (is_file(c) || (is_dir(c) && plain(c)));
    }
    closedir(d);
    return ok;
}

static bool copy_file(const char *from, const char *to) {
    if (is_link(to) || is_dir(to)) return false;
    FILE *a = fopen(from, "rb"), *b = a ? fopen(to, "wb") : NULL;
    char buf[65536];
    size_t n;
    bool ok = a && b;
    while (ok && (n = fread(buf, 1, sizeof buf, a)) > 0) ok = fwrite(buf, 1, n, b) == n;
    if (a) fclose(a);
    if (b && fclose(b)) ok = false;
    return ok;
}

static bool same_file(const char *a, const char *b) {
    FILE *x = fopen(a, "rb"), *y = x ? fopen(b, "rb") : NULL;
    bool same = x && y;
    while (same) {
        int c = fgetc(x);
        same = c == fgetc(y);
        if (c == EOF) break;
    }
    if (x) fclose(x);
    if (y) fclose(y);
    return same;
}

static bool copy_tree(const char *from, const char *to, bool hidden) {
    DIR *d = opendir(from);
    if (!d) return false;
    if (is_link(to) || (mkdir(to, 0755) && (!is_dir(to) || is_link(to)))) return closedir(d), false;
    struct dirent *e;
    bool ok = true;
    while (ok && (e = readdir(d))) {
        if (!strcmp(e->d_name, ".") || !strcmp(e->d_name, "..") || (!hidden && e->d_name[0] == '.')) continue;
        char a[1024], b[1024];
        snprintf(a, sizeof a, "%s/%s", from, e->d_name);
        snprintf(b, sizeof b, "%s/%s", to, e->d_name);
        ok = !is_link(a) && (is_dir(a) ? copy_tree(a, b, hidden) : copy_file(a, b));
    }
    closedir(d);
    return ok;
}

static void rm_tree(const char *p) {
    DIR *d = opendir(p);
    if (d) {
        struct dirent *e;
        while ((e = readdir(d))) {
            if (!strcmp(e->d_name, ".") || !strcmp(e->d_name, "..")) continue;
            char c[1024];
            snprintf(c, sizeof c, "%s/%s", p, e->d_name);
            if (is_dir(c) && !is_link(c)) rm_tree(c);
            else if (remove(c)) rmdir(c); /* (a link to a folder, on Windows: the link goes, not what it points to) */
        }
        closedir(d);
    }
    rmdir(p);
}

bool desktop_paths(char *menu, char *games, size_t n) {
    char *base = SDL_GetBasePath(), *pref = SDL_GetPrefPath("pinyol", "Cirera"); /* (both end in a separator) */
    bool ok = base && pref;
    if (ok) {
        snprintf(menu, n, "%smenu", base); /* (not "cirera": beside a binary "Cirera" it would clash where case does not count) */
        snprintf(games, n, "%sgames", pref);
        mkdir(games, 0755);
        char bundled[1024], stamp[1100], mine[1100];
        snprintf(bundled, sizeof bundled, "%sgames", base);
        snprintf(stamp, sizeof stamp, "%s/.stamp", bundled); /* tools/make_app.py's: what the app's games are */
        snprintf(mine, sizeof mine, "%s/.stamp", games);
        DIR *d = same_file(stamp, mine) ? NULL : opendir(bundled);
        struct dirent *e;
        bool copied = d != NULL;
        while (d && (e = readdir(d))) { /* over the player's copy, if there is one: its saves stay */
            char from[1024], to[1024];
            snprintf(from, sizeof from, "%s/%s", bundled, e->d_name);
            snprintf(to, sizeof to, "%s/%s", games, e->d_name);
            if (e->d_name[0] == '.' || !is_dir(from)) continue;
            if (!copy_tree(from, to, false)) hal_log("app: could not copy %s", e->d_name), copied = false;
        }
        if (d) closedir(d);
        if (copied) copy_file(stamp, mine);
        ok = is_dir(menu) && is_dir(games);
    }
    SDL_free(base);
    SDL_free(pref);
    return ok;
}

#define ZIP_MAX_FILES 4000
#define ZIP_MAX_BYTES (96u << 20)
#define ZIP_MAX_ARCHIVE (128u << 20)

typedef struct {
    const uint8_t *name;
    char path_name[1024];
    uint16_t name_n, flags, method, host;
    uint32_t crc, csize, usize, local, attrs;
} zip_entry;

static uint16_t zip_u16(const uint8_t *p) { return (uint16_t)p[0] | (uint16_t)p[1] << 8; }
static uint32_t zip_u32(const uint8_t *p) {
    return (uint32_t)p[0] | (uint32_t)p[1] << 8 | (uint32_t)p[2] << 16 | (uint32_t)p[3] << 24;
}
static uint32_t zip_crc32(const uint8_t *p, size_t n) {
    uint32_t c = 0xffffffffu;
    while (n--) {
        c ^= *p++;
        for (int k = 0; k < 8; k++) c = (c >> 1) ^ (0xedb88320u & (0u - (c & 1)));
    }
    return ~c;
}

static bool zip_name_decode(const uint8_t *s, size_t n, bool utf8, char *out, size_t cap) {
    static const uint16_t cp437[128] = {
        0x00c7,0x00fc,0x00e9,0x00e2,0x00e4,0x00e0,0x00e5,0x00e7,0x00ea,0x00eb,0x00e8,0x00ef,0x00ee,0x00ec,0x00c4,0x00c5,
        0x00c9,0x00e6,0x00c6,0x00f4,0x00f6,0x00f2,0x00fb,0x00f9,0x00ff,0x00d6,0x00dc,0x00a2,0x00a3,0x00a5,0x20a7,0x0192,
        0x00e1,0x00ed,0x00f3,0x00fa,0x00f1,0x00d1,0x00aa,0x00ba,0x00bf,0x2310,0x00ac,0x00bd,0x00bc,0x00a1,0x00ab,0x00bb,
        0x2591,0x2592,0x2593,0x2502,0x2524,0x2561,0x2562,0x2556,0x2555,0x2563,0x2551,0x2557,0x255d,0x255c,0x255b,0x2510,
        0x2514,0x2534,0x252c,0x251c,0x2500,0x253c,0x255e,0x255f,0x255a,0x2554,0x2569,0x2566,0x2560,0x2550,0x256c,0x2567,
        0x2568,0x2564,0x2565,0x2559,0x2558,0x2552,0x2553,0x256b,0x256a,0x2518,0x250c,0x2588,0x2584,0x258c,0x2590,0x2580,
        0x03b1,0x00df,0x0393,0x03c0,0x03a3,0x03c3,0x00b5,0x03c4,0x03a6,0x0398,0x03a9,0x03b4,0x221e,0x03c6,0x03b5,0x2229,
        0x2261,0x00b1,0x2265,0x2264,0x2320,0x2321,0x00f7,0x2248,0x00b0,0x2219,0x00b7,0x221a,0x207f,0x00b2,0x25a0,0x00a0
    };
    size_t at = 0;
    if (utf8) {
        if (n >= cap) return false;
        memcpy(out, s, n);
        out[n] = 0;
        return true;
    }
    for (size_t i = 0; i < n; i++) {
        uint32_t c = s[i] < 0x80 ? s[i] : cp437[s[i] - 0x80];
        size_t need = c < 0x80 ? 1 : c < 0x800 ? 2 : 3;
        if (need >= cap - at) return false;
        if (need == 1) out[at++] = (char)c;
        else if (need == 2) out[at++] = (char)(0xc0 | (c >> 6)), out[at++] = (char)(0x80 | (c & 0x3f));
        else out[at++] = (char)(0xe0 | (c >> 12)), out[at++] = (char)(0x80 | ((c >> 6) & 0x3f)),
             out[at++] = (char)(0x80 | (c & 0x3f));
    }
    out[at] = 0;
    return true;
}

static uint8_t *zip_read(const char *path, size_t *n) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    uint8_t *data = NULL;
    long len = fseek(f, 0, SEEK_END) ? -1 : ftell(f);
    if (len > 0 && (unsigned long)len <= ZIP_MAX_ARCHIVE && !fseek(f, 0, SEEK_SET) && (data = malloc((size_t)len)) &&
        fread(data, 1, (size_t)len, f) != (size_t)len)
        free(data), data = NULL;
    fclose(f);
    *n = data ? (size_t)len : 0;
    return data;
}

static bool zip_device_name(const uint8_t *s, size_t n) {
    size_t stem = 0;
    while (stem < n && s[stem] != '.') stem++;
    while (stem && s[stem - 1] == ' ') stem--;
    static const char *const names[] = {"CON", "PRN", "AUX", "NUL", "CONIN$", "CONOUT$"};
    for (size_t i = 0; i < sizeof names / sizeof *names; i++) {
        size_t len = strlen(names[i]);
        if (stem == len && !SDL_strncasecmp((const char *)s, names[i], len)) return true;
    }
    bool port = stem >= 4 &&
                (!SDL_strncasecmp((const char *)s, "COM", 3) || !SDL_strncasecmp((const char *)s, "LPT", 3));
    if (!port) return false;
    if (stem == 4) return s[3] >= '1' && s[3] <= '9';
    return stem == 5 && s[3] == 0xc2 && (s[4] == 0xb9 || s[4] == 0xb2 || s[4] == 0xb3);
}

static bool zip_name_ok(const uint8_t *s, size_t n) {
    if (!n || s[0] == '/' || s[0] == '\\' || memchr(s, 0, n)) return false;
    size_t start = 0, depth = 0;
    for (size_t i = 0; i <= n; i++) {
        if (i < n && s[i] != '/') {
            if (s[i] == '\\' || s[i] == ':' || s[i] == '<' || s[i] == '>' || s[i] == '"' ||
                s[i] == '|' || s[i] == '?' || s[i] == '*') return false;
            continue;
        }
        size_t len = i - start;
        if (!len && i != n) return false;
        if (len) {
            if (++depth > 64 || (s[i - 1] == '.' || s[i - 1] == ' ') ||
                (len == 1 && s[start] == '.') || (len == 2 && s[start] == '.' && s[start + 1] == '.') ||
                zip_device_name(s + start, len)) return false;
        }
        start = i + 1;
    }
    return true;
}

static bool zip_entry_at(const uint8_t *z, size_t cd_end, size_t *at, zip_entry *e) {
    size_t p = *at;
    if (p > cd_end || cd_end - p < 46 || zip_u32(z + p) != 0x02014b50) return false;
    e->host = zip_u16(z + p + 4) >> 8;
    e->flags = zip_u16(z + p + 8), e->method = zip_u16(z + p + 10);
    e->crc = zip_u32(z + p + 16), e->csize = zip_u32(z + p + 20), e->usize = zip_u32(z + p + 24);
    e->name_n = zip_u16(z + p + 28);
    uint16_t extra_n = zip_u16(z + p + 30), comment_n = zip_u16(z + p + 32);
    e->attrs = zip_u32(z + p + 38), e->local = zip_u32(z + p + 42);
    uint64_t next = (uint64_t)p + 46 + e->name_n + extra_n + comment_n;
    if (next > cd_end || e->csize == 0xffffffff || e->usize == 0xffffffff || e->local == 0xffffffff ||
        (e->flags & (1 | 0x40 | 0x2000)) || (e->method != 0 && e->method != 8)) return false;
    e->name = z + p + 46;
    if (memchr(e->name, 0, e->name_n) ||
        !zip_name_decode(e->name, e->name_n, (e->flags & 0x800) != 0, e->path_name, sizeof e->path_name) ||
        !zip_name_ok((const uint8_t *)e->path_name, strlen(e->path_name))) return false;
    size_t x = p + 46 + e->name_n, xend = x + extra_n;
    while (x < xend) {
        if (xend - x < 4) return false;
        uint16_t id = zip_u16(z + x), size = zip_u16(z + x + 2);
        if ((size_t)size > xend - x - 4 || id == 1) return false; /* ZIP64 is unsupported */
        x += 4 + size;
    }
    *at = (size_t)next;
    return true;
}

static bool zip_dirs(const char *root, const char *path) {
    char part[2048];
    size_t root_n = strlen(root), path_n = strlen(path);
    if (path_n < root_n || path_n >= sizeof part || memcmp(root, path, root_n) ||
        (path_n > root_n && path[root_n] != '/') || !is_dir(root) || is_link(root)) return false;
    if (path_n == root_n) return true;
    for (const char *s = path + root_n + 1; *s; s++) if (*s == '/') {
        size_t n = (size_t)(s - path);
        memcpy(part, path, n);
        part[n] = 0;
        if (mkdir(part, 0755) && (!is_dir(part) || is_link(part))) return false;
    }
    return mkdir(path, 0755) == 0 || (is_dir(path) && !is_link(path));
}

static bool zip_extract(const uint8_t *z, size_t n, size_t cd_off, const zip_entry *e,
                        const char *dir, size_t *total) {
    unsigned kind = e->host == 3 ? (e->attrs >> 16) & 0170000 : 0;
    if (kind && kind != 0100000 && kind != 0040000) return false; /* no links or special files */
    size_t path_name_n = strlen(e->path_name);
    bool folder = e->path_name[path_name_n - 1] == '/' || kind == 0040000 || (e->attrs & 0x10);
    char path[1024];
    size_t name_n = path_name_n - (e->path_name[path_name_n - 1] == '/');
    if (snprintf(path, sizeof path, "%s/%.*s", dir, (int)name_n, e->path_name) >= (int)sizeof path) return false;
    if (folder) {
        if (e->usize || e->csize) return false;
        return zip_dirs(dir, path);
    }
    if (e->usize > ZIP_MAX_BYTES - *total) return false;
    size_t p = e->local;
    if (p > n || n - p < 30 || zip_u32(z + p) != 0x04034b50) return false;
    uint16_t flags = zip_u16(z + p + 6), method = zip_u16(z + p + 8);
    uint16_t local_name_n = zip_u16(z + p + 26), local_extra_n = zip_u16(z + p + 28);
    if (flags != e->flags || method != e->method || local_name_n != e->name_n ||
        p + 30u + local_name_n + local_extra_n > n ||
        memcmp(z + p + 30, e->name, e->name_n) ||
        (!(flags & 8) && (zip_u32(z + p + 14) != e->crc || zip_u32(z + p + 18) != e->csize ||
                          zip_u32(z + p + 22) != e->usize))) return false;
    p += 30 + local_name_n + local_extra_n;
    if (p > cd_off || e->csize > cd_off - p || e->usize > ZIP_MAX_BYTES - *total) return false;
    uint8_t *out = malloc(e->usize ? e->usize : 1);
    if (!out) return false;
    unsigned long out_n = e->usize, in_n = e->csize;
    bool ok = e->method == 0 ? (e->csize == e->usize && (memcpy(out, z + p, e->usize), true))
              : puff(out, &out_n, z + p, &in_n) == 0 && out_n == e->usize && in_n == e->csize;
    ok = ok && zip_crc32(out, e->usize) == e->crc;
    if (ok) {
        char parent[sizeof path];
        snprintf(parent, sizeof parent, "%s", path);
        char *slash = strrchr(parent, '/');
        if (!slash) ok = false;
        else {
            *slash = 0;
            ok = zip_dirs(dir, parent) && !is_link(path) && !is_dir(path);
        }
    }
    FILE *f = ok ? fopen(path, "wb") : NULL;
    if (ok) ok = f && fwrite(out, 1, e->usize, f) == e->usize;
    if (f && fclose(f)) ok = false;
    free(out);
    if (ok) *total += e->usize;
    return ok;
}

static bool zip_unpack(const char *zip, const char *dir) {
    size_t n = 0;
    uint8_t *z = zip_read(zip, &n);
    if (!z) return false;
    bool ok = false;
    size_t stop = n > 65557 ? n - 65557 : 0, eocd = n;
    if (n >= 22) for (size_t i = n - 22 + 1; i-- > stop;)
        if (zip_u32(z + i) == 0x06054b50 && i + 22 + zip_u16(z + i + 20) == n) { eocd = i; break; }
    if (eocd == n) goto done;
    uint8_t *e = z + eocd;
    uint16_t disk = zip_u16(e + 4), cd_disk = zip_u16(e + 6), disk_n = zip_u16(e + 8), count = zip_u16(e + 10);
    uint32_t cd_size = zip_u32(e + 12), cd_off = zip_u32(e + 16);
    if (disk || cd_disk || disk_n != count || count == 0xffff || count > ZIP_MAX_FILES || cd_size == 0xffffffff ||
        cd_off == 0xffffffff || (uint64_t)cd_off + cd_size != eocd) goto done;
    size_t cd_end = (size_t)cd_off + cd_size, at = cd_off, total = 0;
    for (uint16_t i = 0; i < count; i++) {
        zip_entry entry;
        if (!zip_entry_at(z, cd_end, &at, &entry) || !zip_extract(z, n, cd_off, &entry, dir, &total)) goto done;
    }
    ok = at == cd_end;
done:
    free(z);
    return ok;
}

/* The game in a .zip (game.json at its top, or in one folder as tools/pack_game.py makes it) installed as
 * <games>/<its folder's name, or the zip's>, kept to letters, digits, _ and -. Existing games update through a staged
 * copy and directory rename; saves and files omitted by the update stay. */
bool desktop_install(const char *zip, const char *games, char *name, size_t name_max) {
    char tmp[1024], json[1100], src[1100] = "", id[41] = "";
    snprintf(tmp, sizeof tmp, "%s/.instalando", games);
    if (is_link(tmp)) { if (remove(tmp) && rmdir(tmp)) return false; }
    else rm_tree(tmp);
    if (mkdir(tmp, 0700)) return false;
    if (!zip_unpack(zip, tmp) || !plain(tmp)) return rm_tree(tmp), false;
    snprintf(json, sizeof json, "%s/game.json", tmp);
    const char *slash = strrchr(zip, '/'), *back = strrchr(zip, '\\');
    const char *base = back && (!slash || back > slash) ? back + 1 : slash ? slash + 1 : zip;
    if (is_file(json)) { /* game.json at the top: the zip's name */
        snprintf(id, sizeof id, "%s", base);
        char *dot = strrchr(id, '.');
        if (dot && !strcmp(dot, ".zip")) *dot = 0;
        snprintf(src, sizeof src, "%s", tmp);
    } else { /* in one folder */
        DIR *d = opendir(tmp);
        struct dirent *e;
        while (d && (e = readdir(d))) {
            snprintf(json, sizeof json, "%s/%s/game.json", tmp, e->d_name);
            if (e->d_name[0] != '.' && is_file(json)) {
                snprintf(id, sizeof id, "%s", e->d_name);
                snprintf(src, sizeof src, "%s/%s", tmp, e->d_name);
                break;
            }
        }
        if (d) closedir(d);
    }
    for (char *c = id; *c; c++) /* a folder name that is safe anywhere: no dots, slashes, spaces */
        if (!((*c >= 'a' && *c <= 'z') || (*c >= 'A' && *c <= 'Z') || (*c >= '0' && *c <= '9') || *c == '_' || *c == '-'))
            *c = '_';
    snprintf(name, name_max, "%s", id);
    bool ok = *src && *id && SDL_strcasecmp(id, CONSOLE_MENU_ID) != 0;
    if (ok) {
        char to[1024], stage_root[1024], stage[1100], backup[1100], saves[1200];
        snprintf(to, sizeof to, "%s/%s", games, id);
        snprintf(stage_root, sizeof stage_root, "%s/.actualizando", games);
        snprintf(stage, sizeof stage, "%s/%s", stage_root, id);
        snprintf(backup, sizeof backup, "%s/.respaldo-%s", games, id);
        if (is_link(to) || is_link(stage_root) || is_link(backup)) ok = false;
        else {
            /* Recover a prior interrupted swap before starting another one. */
            if (is_dir(backup)) {
                if (is_dir(to)) rm_tree(backup);
                else ok = rename(backup, to) == 0;
            }
            if (ok) {
                rm_tree(stage_root);
                ok = mkdir(stage_root, 0700) == 0;
            }
            if (ok && is_dir(to)) ok = copy_tree(to, stage, true);
            if (ok && !is_dir(to)) ok = mkdir(stage, 0700) == 0;
            if (ok) {
                snprintf(saves, sizeof saves, "%s/saves", src); /* (src/game.c's save folder) */
                rm_tree(saves);
                ok = copy_tree(src, stage, false);
            }
            if (ok && is_dir(to)) {
                ok = rename(to, backup) == 0;
                if (ok && rename(stage, to)) {
                    ok = false;
                    if (rename(backup, to)) hal_log("app: could not restore %s after update failure", id);
                } else if (ok) rm_tree(backup);
            } else if (ok) ok = rename(stage, to) == 0;
            rm_tree(stage_root);
        }
    }
    rm_tree(tmp);
    return ok;
}
