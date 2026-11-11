/* First person: a map of walls seen from inside it, a column at a time, as Wolfenstein 3D drew it (docs/lua.md
 * "First person"), onto a canvas the game then shows: twice as big, as a window, turned, anywhere.
 *
 *   local dist, wall = raycast("VIEW", {map = rows, x = 3.5, y = 2.5, angle = 90, fov = 66, fog = 10,
 *                                       walls = {["#"] = "TEX_STONE", D = "TEX_DOOR", W = 0x806040},
 *                                       ceiling = 0x303040, floor = 0x505050,
 *                                       sprites = {{x = 5.5, y = 4.5, picture = "GUARD", frame = 0, scale = 1}}})
 *
 * map: the rows, one character a square (space or "." open). A wall's character is in walls: a picture (its frame 0
 * wraps across each square of wall) or a colour. x, y in squares; angle in degrees, 0 east and 90 south; fov in
 * degrees. Walls and floor darken with distance (fog: squares to black, or to fog_colour = 0xRRGGBB: a mist, a smoke, the
 * glow of a candle; 0, none) and the walls facing north or south
 * are a little darker, so corners show. Sprites stand on the floor centred on their point, as tall as a wall at the
 * same distance times scale, hidden by the walls in front. Returns the distance to the wall in the middle of the view
 * (in squares, along the view) and that wall's character.
 *
 * doors = {{x = 7, y = 3, open = 0.4}, ...}: the wall square (x, y) (from 0, as the map's columns and rows) is a door, as
 * Wolfenstein 3D's: a thin wall across the middle of its square, slid aside by open (0 shut, 1 gone), drawn with the
 * picture of its character. It runs from wall to wall: across the square east to west when the squares west and east
 * of it are walls, north to south otherwise. jamb = picture or colour: the sides of a door's square (the frame it
 * slides into), where a ray inside that square meets the wall beside it.
 *
 * A downloaded game's map and numbers are checked: rows and columns are bounded, a ray stops after RAY_STEPS
 * squares, positions are made finite. */
#include <stdlib.h>

#include "gfx_px.h"
#include "lua_api.h"

#define MAX_ROWS 256
#define MAX_COLS 256
#define MAX_SPRITES 64
#define MAX_DOORS 64
#define RAY_STEPS 128
#define MAX_W 480
#define MAX_H 320 /* a view taller is drawn to this height */
#define BAND 16
#define DEG 0.017453292f /* radians a degree */

typedef struct {
    const asset *pic; /* or NULL: a colour */
    uint16_t colour;
} wall_look;

typedef struct {
    int h, y0, k, u;
    const wall_look *look;
} column;

typedef struct {
    int x, y;
    float open;  /* 0 shut .. 1 gone */
    bool across; /* runs east to west, at y + 0.5 (walls west and east of it); else north to south, at x + 0.5 */
} door;

typedef struct {
    float x, y, d, scale;
    asset *pic;
    int frame;
} sprite;

static inline uint16_t shaded(uint16_t c, int k) { /* c times k/256, in 32 steps: the channels spread over 32 bits,
                                                     * one multiply */
    uint32_t x = ((c | (uint32_t)c << 16) & 0x07E0F81Fu) * (uint32_t)((k + 4) >> 3) >> 5 & 0x07E0F81Fu;
    uint16_t v = (uint16_t)(x | x >> 16);
    return v == CANVAS_KEY ? v ^ 1 : v; /* the key colour is see-through on a canvas */
}

static uint32_t fog_spread; /* the fog's colour, its channels spread over 32 bits (0: black, as before) */

static inline uint16_t fogged(uint16_t c, int k) { /* c with 256 - k of the fog's colour, in 32 steps */
    if (!fog_spread) return shaded(c, k);
    const uint32_t m = (uint32_t)((k + 4) >> 3) > 32 ? 32 : (uint32_t)((k + 4) >> 3);
    uint32_t x = (((c | (uint32_t)c << 16) & 0x07E0F81Fu) * m + fog_spread * (32 - m)) >> 5 & 0x07E0F81Fu;
    uint16_t v = (uint16_t)(x | x >> 16);
    return v == CANVAS_KEY ? v ^ 1 : v;
}

static int fog_k(float d, float fog) { /* 256 near, 0 at fog squares */
    if (fog <= 0) return 256;
    float f = 1.0f - d / fog;
    return f <= 0 ? 0 : f >= 1 ? 256 : (int)(f * 256);
}

static int read_map(lua_State *L, int t, const char **rows, int *lens) {
    lua_getfield(L, t, "map");
    if (!lua_istable(L, -1)) luaL_error(L, "raycast: map must be a table of rows (strings)");
    int n = (int)lua_rawlen(L, -1);
    if (n > MAX_ROWS) n = MAX_ROWS;
    for (int i = 0; i < n; i++) {
        lua_rawgeti(L, -1, i + 1);
        size_t len = 0;
        rows[i] = lua_tolstring(L, -1, &len); /* the map table keeps it alive while raycast runs */
        lens[i] = rows[i] ? (int)(len > MAX_COLS ? MAX_COLS : len) : 0;
        lua_pop(L, 1);
    }
    lua_pop(L, 1); /* (the map table stays referenced by the options table) */
    return n;
}

static void read_walls(lua_State *L, int t, wall_look *looks, bool *is_wall) {
    lua_getfield(L, t, "walls");
    if (!lua_istable(L, -1)) luaL_error(L, "raycast: walls must be a table {character = picture or colour}");
    lua_pushnil(L);
    while (lua_next(L, -2)) {
        size_t klen = 0;
        const char *k = lua_type(L, -2) == LUA_TSTRING ? lua_tolstring(L, -2, &klen) : NULL;
        if (k && klen == 1 && (unsigned char)k[0] < 128) {
            unsigned c = (unsigned char)k[0];
            is_wall[c] = true;
            if (lua_type(L, -1) == LUA_TSTRING) {
                const char *id = lua_tostring(L, -1);
                asset *a = safe_name(id) ? gfx_asset(id) : NULL;
                looks[c].pic = a && !a->missing && gfx_pixels(a) ? a : NULL;
                looks[c].colour = 0x8410;
            } else {
                looks[c].pic = NULL;
                looks[c].colour = to565(luaL_checkinteger(L, -1));
            }
        }
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
}

static int read_sprites(lua_State *L, int t, sprite *sp, float px, float py) {
    lua_getfield(L, t, "sprites");
    int n = 0;
    if (lua_istable(L, -1)) {
        int len = (int)lua_rawlen(L, -1);
        for (int i = 1; i <= len && n < MAX_SPRITES; i++) {
            lua_rawgeti(L, -1, i);
            if (lua_istable(L, -1)) {
                int s = lua_gettop(L);
                const char *id = opt_str(L, s, "picture");
                asset *a = id && safe_name(id) ? gfx_asset(id) : NULL;
                if (a && !a->missing && gfx_pixels(a)) {
                    sprite *q = &sp[n++];
                    q->x = opt_float(L, s, "x", 0, -NUM_MAX, NUM_MAX), q->y = opt_float(L, s, "y", 0, -NUM_MAX, NUM_MAX);
                    q->scale = opt_float(L, s, "scale", 1, 0.05f, 8);
                    q->frame = (int)opt_int(L, s, "frame", 0);
                    q->frame = q->frame < 0 || q->frame >= a->frames ? 0 : q->frame;
                    q->pic = a;
                    q->d = (q->x - px) * (q->x - px) + (q->y - py) * (q->y - py);
                }
            }
            lua_pop(L, 1);
        }
    }
    lua_pop(L, 1);
    for (int i = 1; i < n; i++) /* the farthest first */
        for (int j = i; j > 0 && sp[j - 1].d < sp[j].d; j--) {
            sprite tmp = sp[j];
            sp[j] = sp[j - 1], sp[j - 1] = tmp;
        }
    return n;
}

static bool wall_at(const char *const *rows, const int *lens, int nrows, const bool *is_wall, int x, int y) {
    if (y < 0 || y >= nrows || x < 0 || x >= lens[y]) return true; /* off the map: a wall, as the rays take it */
    unsigned ch = (unsigned char)rows[y][x];
    return ch < 128 && is_wall[ch];
}

static int read_doors(lua_State *L, int t, door *dr, const char *const *rows, const int *lens, int nrows, const bool *is_wall) {
    lua_getfield(L, t, "doors");
    int n = 0;
    if (lua_istable(L, -1)) {
        int len = (int)lua_rawlen(L, -1);
        for (int i = 1; i <= len && n < MAX_DOORS; i++) {
            lua_rawgeti(L, -1, i);
            if (lua_istable(L, -1)) {
                int s = lua_gettop(L);
                door *d = &dr[n];
                d->x = (int)opt_int(L, s, "x", -1), d->y = (int)opt_int(L, s, "y", -1);
                d->open = opt_float(L, s, "open", 0, 0, 1);
                if (d->y >= 0 && d->y < nrows && d->x >= 0 && d->x < lens[d->y]) {
                    d->across = wall_at(rows, lens, nrows, is_wall, d->x - 1, d->y) && wall_at(rows, lens, nrows, is_wall, d->x + 1, d->y);
                    n++;
                }
            }
            lua_pop(L, 1);
        }
    }
    lua_pop(L, 1);
    return n;
}

static const door *door_at(const door *dr, int n, int x, int y) {
    for (int i = 0; i < n; i++)
        if (dr[i].x == x && dr[i].y == y) return &dr[i];
    return NULL;
}

typedef struct { int xl, w, ytop, h, k; const asset *t; const uint16_t *px; int frame; float depth; } view_sprite;
typedef struct {
    asset *cv; /* NULL: straight onto the screen, in the strips */
    const column *cols;
    const view_sprite *sv;
    const float *zbuf;
    const uint16_t *floor_c;
    int W, H, nsv, shift; /* shift: a view's pixel is 1 << shift of the screen's across and down */
    uint16_t ceil_s;
} view_job;
static view_job on_screen;

/* One band of a view, bw columns from bx, into band (BAND columns a row, in fast memory): its walls, then its sprites */
static void view_band(const view_job *j, int bx, int bw, uint16_t *band) {
    const column *cols = j->cols;
    const view_sprite *sv = j->sv;
    const float *zbuf = j->zbuf;
    const uint16_t *floor_c = j->floor_c, ceil_s = j->ceil_s;
    const int H = j->H, nsv = j->nsv;
    for (int i = 0; i < bw; i++) {
        const column *q = &cols[bx + i];
        int a = q->y0 < 0 ? 0 : q->y0, b = q->y0 + q->h > H ? H : q->y0 + q->h;
        const int ce = a < H / 2 ? a : H / 2; /* (a wall seen from far can end before the middle: the ceiling goes on to it) */
        uint16_t *p = band + i;
        for (int y = 0; y < ce; y++, p += BAND) *p = ceil_s;
        for (int y = ce; y < a; y++, p += BAND) *p = floor_c[y];
        p = band + i + b * BAND;
        for (int y = b; y < H; y++, p += BAND) *p = y < H / 2 ? ceil_s : floor_c[y];
        if (q->look && q->look->pic) {
            const asset *t = q->look->pic;
            const uint16_t *col = t->pixels + q->u;
            int32_t step = (int32_t)((int64_t)t->h * 65536 / (q->h ? q->h : 1)), v = (a - q->y0) * step;
            int last = -1; /* a wall up close: one texel over many pixels, its fog worked out once */
            uint16_t c = 0;
            p = band + i + a * BAND;
            for (int y = a; y < b; y++, v += step, p += BAND) {
                int vv = v >> 16;
                if (vv != last) last = vv, c = fogged(col[(vv < t->h ? vv : t->h - 1) * t->w], q->k);
                *p = c;
            }
        } else {
            uint16_t c = fogged(q->look ? q->look->colour : 0x8410, q->k);
            for (int y = a; y < b; y++) band[y * BAND + i] = c;
        }
    }
    for (int i = 0; i < nsv; i++) { /* the sprites' columns in this band, hidden where a wall is nearer */
        const asset *t = sv[i].t;
        int x0 = sv[i].xl > bx ? sv[i].xl : bx, x1 = sv[i].xl + sv[i].w < bx + bw ? sv[i].xl + sv[i].w : bx + bw;
        for (int x = x0; x < x1; x++) {
            if (sv[i].depth >= zbuf[x]) continue;
            int u = (x - sv[i].xl) * t->w / sv[i].w;
            for (int y = sv[i].ytop < 0 ? 0 : sv[i].ytop; y < sv[i].ytop + sv[i].h && y < H; y++) {
                int v = (y - sv[i].ytop) * t->h / sv[i].h;
                if (gfx_opaque(t, sv[i].frame, u, v)) band[y * BAND + x - bx] = fogged(sv[i].px[v * t->w + u], sv[i].k);
            }
        }
    }
}

static uint16_t bands[2][MAX_H * BAND];

/* Onto a canvas: a band at a time, copied a row at a time: the canvas (in PSRAM on the console) written in runs instead
 * of a pixel per row, which made a whole view cost twice as much. Every other band on each core. */
static void view_bands(int part, void *ctx) {
    const view_job *j = ctx;
    uint16_t *out = j->cv->pixels;
    for (int bx = part * BAND; bx < j->W; bx += 2 * BAND) {
        const int bw = j->W - bx < BAND ? j->W - bx : BAND;
        view_band(j, bx, bw, bands[part]);
        for (int y = 0; y < j->H; y++) memcpy(out + y * j->cv->w + bx, bands[part] + y * BAND, (size_t)bw * sizeof *bands[part]);
    }
}

/* Onto the screen: what this window of it shows, straight into it. A view on a canvas goes through the slow memory twice
 * a frame, written and read again, and that was most of its cost (lua_draw.c calls this as it draws the list). */
void ray_draw(surface *s, int x0, int y0) {
    const view_job *j = &on_screen;
    const int sh = j->shift, x1 = x0 + (j->W << sh), y1 = y0 + (j->H << sh);
    const int xa = s->x0 > x0 ? s->x0 : x0, xb = s->x0 + s->w < x1 ? s->x0 + s->w : x1;
    const int ya = s->y0 > y0 ? s->y0 : y0, yb = s->y0 + s->h < y1 ? s->y0 + s->h : y1;
    if (ya >= yb) return;
    uint16_t *band = bands[s->part];
    const int xs = step_x(s), ys = step_y(s);
    for (int x = xa; x < xb;) {
        const int bx = (x - x0) >> sh, bw = j->W - bx < BAND ? j->W - bx : BAND;
        view_band(j, bx, bw, band);
        const int xe = x0 + ((bx + bw) << sh) < xb ? x0 + ((bx + bw) << sh) : xb;
        while (x < xe) {
            const uint16_t *col = band + ((x - x0) >> sh) - bx + ((ya - y0) >> sh) * BAND;
            uint16_t *d = at(s, x, ya);
            if (sh && !(((x - x0) | (ya - y0) | (yb - y0)) & 1) && x + 1 < xe) { /* whole pixels of the view: one read, four writes (130000 pixels a frame) */
                for (int y = ya; y < yb; y += 2, col += BAND, d += 2 * ys) {
                    const uint16_t v = stored(s, *col);
                    d[0] = v, d[ys] = v, d[xs] = v, d[xs + ys] = v;
                }
                x += 2;
                continue;
            }
            for (int y = ya; y < yb; y++, d += ys) *d = stored(s, col[(((y - y0) >> sh) - ((ya - y0) >> sh)) * BAND]);
            x++;
        }
    }
}

static int l_raycast(lua_State *L) {
    asset *cv = NULL;
    int W, H, sx = 0, sy = 0, shift = 0;
    if (draw_ray_listed()) return luaL_error(L, "raycast: one view on the screen a frame, and nothing else cast after it");
    if (lua_istable(L, 1)) { /* a place on the screen */
        sx = opt_int(L, 1, "x", 0), sy = opt_int(L, 1, "y", 0);
        W = opt_int(L, 1, "w", 240), H = opt_int(L, 1, "h", 136);
        const int scale = opt_int(L, 1, "scale", 1);
        if (W < 1 || H < 1 || W > MAX_W || H > MAX_H || (scale != 1 && scale != 2)) return luaL_error(L, "raycast: w 1..480, h 1..320, scale 1 or 2");
        shift = scale - 1;
    } else {
        const char *id = luaL_checkstring(L, 1);
        cv = safe_name(id) ? gfx_asset_opt(id) : NULL;
        if (!cv || !cv->canvas) return luaL_error(L, "raycast \"%s\": not a canvas (make one with canvas())", id);
        W = cv->w > MAX_W ? MAX_W : cv->w, H = cv->h > MAX_H ? MAX_H : cv->h;
    }
    luaL_checktype(L, 2, LUA_TTABLE);
    static const char *rows[MAX_ROWS];
    static int lens[MAX_ROWS];
    static wall_look looks[128];
    static bool is_wall[128];
    static sprite sp[MAX_SPRITES];
    static float zbuf[MAX_W];
    static door doors[MAX_DOORS];
    static wall_look jamb;
    memset(is_wall, 0, sizeof is_wall);
    int nrows = read_map(L, 2, rows, lens);
    read_walls(L, 2, looks, is_wall);
    int ndoors = read_doors(L, 2, doors, rows, lens, nrows, is_wall);
    bool has_jamb = false;
    lua_getfield(L, 2, "jamb");
    if (lua_type(L, -1) == LUA_TSTRING) {
        const char *jid = lua_tostring(L, -1);
        asset *a = safe_name(jid) ? gfx_asset(jid) : NULL;
        jamb.pic = a && !a->missing && gfx_pixels(a) ? a : NULL, jamb.colour = 0x8410, has_jamb = true;
    } else if (lua_isinteger(L, -1)) {
        jamb.pic = NULL, jamb.colour = to565(lua_tointeger(L, -1)), has_jamb = true;
    }
    lua_pop(L, 1);
    float px = opt_float(L, 2, "x", 1.5f, -MAX_COLS, 2 * MAX_COLS), py = opt_float(L, 2, "y", 1.5f, -MAX_ROWS, 2 * MAX_ROWS);
    float ang = opt_float(L, 2, "angle", 0, -NUM_MAX, NUM_MAX) * DEG;
    float fov = opt_float(L, 2, "fov", 66, 20, 150) * DEG;
    float fog = opt_float(L, 2, "fog", 0, 0, 1000);
    lua_getfield(L, 2, "fog_colour");
    if (lua_isinteger(L, -1)) {
        const uint16_t f = to565(lua_tointeger(L, -1));
        fog_spread = (f | (uint32_t)f << 16) & 0x07E0F81Fu;
    } else fog_spread = 0;
    lua_pop(L, 1);
    lua_Integer ceil_rgb = opt_int(L, 2, "ceiling", 0x303040), floor_rgb = opt_int(L, 2, "floor", 0x505050);
    uint16_t ceil_c = to565(ceil_rgb), floor_c0 = to565(floor_rgb);
    int nsp = read_sprites(L, 2, sp, px, py);

    float dx = cosf(ang), dy = sinf(ang), k = tanf(fov / 2);
    float plx = -dy * k, ply = dx * k; /* the camera plane, across the view */
    static column cols[MAX_W];
    static uint16_t floor_c[MAX_H];
    float centre_d = 0;
    char centre_c = 0;
    for (int x = 0; x < W; x++) { /* each column's wall: how far, which face, which square of which texture */
        float cam = 2.0f * (float)x / (float)W - 1.0f;
        float rx = dx + plx * cam, ry = dy + ply * cam;
        int mx = (int)floorf(px), my = (int)floorf(py);
        float ddx = rx == 0 ? 1e30f : fabsf(1.0f / rx), ddy = ry == 0 ? 1e30f : fabsf(1.0f / ry);
        int sx = rx < 0 ? -1 : 1, sy = ry < 0 ? -1 : 1;
        float tx = rx < 0 ? (px - (float)mx) * ddx : ((float)mx + 1.0f - px) * ddx;
        float ty = ry < 0 ? (py - (float)my) * ddy : ((float)my + 1.0f - py) * ddy;
        int side = 0;
        unsigned c = 0;
        float d = -1, door_w = 0; /* d >= 0: a door was met, that far, door_w along it */
        const door *in_door = NULL; /* the door whose square the ray is crossing */
        bool at_jamb = false;
        for (int step = 0; step < RAY_STEPS; step++) { /* square to square until a wall */
            if (tx < ty) tx += ddx, mx += sx, side = 0;
            else ty += ddy, my += sy, side = 1;
            if (my < 0 || my >= nrows || mx < 0 || mx >= lens[my]) { c = '#'; break; } /* off the map: a wall */
            unsigned ch = (unsigned char)rows[my][mx];
            if (ch < 128 && is_wall[ch]) {
                const door *dr = ndoors ? door_at(doors, ndoors, mx, my) : NULL;
                if (!dr) { /* a wall; beside a door, seen from inside the door's square: its jamb */
                    at_jamb = in_door && has_jamb && side == (in_door->across ? 0 : 1);
                    c = ch;
                    break;
                }
                in_door = dr;
                if (dr->open >= 1) continue;
                float e = side == 0 ? tx - ddx : ty - ddy, out_d = tx < ty ? tx : ty, t;
                if (dr->across) t = ry == 0 ? -1 : ((float)my + 0.5f - py) / ry, door_w = px + t * rx - (float)mx;
                else t = rx == 0 ? -1 : ((float)mx + 0.5f - px) / rx, door_w = py + t * ry - (float)my;
                if (t >= e && t <= out_d && door_w >= dr->open && door_w <= 1) { /* the door's own wall, where it has not slid away */
                    d = t, side = dr->across ? 1 : 0, c = ch;
                    break;
                }
                continue; /* through the gap: on to the next square */
            }
            in_door = NULL;
        }
        bool hit_door = d >= 0;
        if (!hit_door) d = side == 0 ? tx - ddx : ty - ddy;
        if (d < 0.01f) d = 0.01f;
        zbuf[x] = d;
        if (x == W / 2) centre_d = d, centre_c = (char)c;
        column *q = &cols[x];
        q->h = (int)((float)H / d), q->y0 = H / 2 - q->h / 2;
        q->k = fog_k(d, fog) * (side ? 3 : 4) / 4;
        q->look = at_jamb ? &jamb : c < 128 && is_wall[c] ? &looks[c] : NULL;
        q->u = 0;
        if (q->look && q->look->pic) {
            const asset *t = q->look->pic;
            float wx;
            if (hit_door) wx = door_w - in_door->open; /* the door's edge moves with it */
            else wx = side == 0 ? py + d * ry : px + d * rx, wx -= floorf(wx);
            int u = (int)(wx * (float)t->w);
            if (!hit_door && ((side == 0 && rx > 0) || (side == 1 && ry < 0))) u = t->w - 1 - u; /* not mirrored, from either side */
            q->u = u < 0 ? 0 : u >= t->w ? t->w - 1 : u;
        }
    }
    uint16_t ceil_s = shaded(ceil_c, 256);
    for (int y = H / 2; y < H; y++) floor_c[y] = fogged(floor_c0, fog_k((float)H / (2.0f * (float)y - (float)H + 1.0f), fog));
    float inv = 1.0f / (plx * dy - dx * ply);
    static view_sprite sv[MAX_SPRITES];
    int nsv = 0;
    for (int i = 0; i < nsp; i++) { /* the sprites on the view: where and how big (farthest first, as sorted) */
        const sprite *q = &sp[i];
        const asset *t = q->pic;
        float rx = q->x - px, ry = q->y - py;
        float ax = inv * (dy * rx - dx * ry), depth = inv * (-ply * rx + plx * ry);
        if (depth <= 0.05f) continue;
        int h = (int)((float)H / depth * q->scale), w = h * t->w / (t->h ? t->h : 1);
        if (h <= 0 || w <= 0 || h > 8 * H) continue;
        int cx = (int)((float)W / 2 * (1.0f + ax / depth));
        sv[nsv].xl = cx - w / 2, sv[nsv].w = w, sv[nsv].h = h, sv[nsv].ytop = H / 2 + (int)((float)H / depth / 2) - h;
        sv[nsv].k = fog_k(depth, fog), sv[nsv].t = t, sv[nsv].frame = q->frame, sv[nsv].depth = depth;
        sv[nsv].px = t->pixels + (size_t)q->frame * t->w * t->h;
        nsv++;
    }
    const view_job job = {cv, cols, sv, zbuf, floor_c, W, H, nsv, shift, ceil_s};
    if (cv) {
        hal_parallel(view_bands, (void *)&job);
        if (!cv->full) memset(cv->mask, 0xFF, (size_t)((cv->w + 7) / 8) * cv->h); /* the view covers its canvas */
        cv->full = true;
        cv->gen++;
        draw_canvas_written(W * H);
    } else {
        on_screen = job;
        draw_ray(L, sx, sy, W << shift, H << shift);
    }
    lua_pushnumber(L, centre_d);
    char s[2] = {centre_c, 0};
    lua_pushstring(L, s);
    return 2;
}

/* Voxel Space (Comanche, 1992): a landscape from a height map and a colour map, a column at a time, nearest first
 * so what stands nearer hides what lies behind (a y-buffer per column). Onto a canvas, as raycast draws.
 *
 *   voxels("VIEW", {height = "HILLS", colour = "HILLS_C", x = 100, y = 100, angle = 0, z = 80, horizon = 60,
 *                   distance = 300, fov = 90, scale = 120, sky = 0x9ED6F0, fog = 200})
 *   (sky = {0x203060, 0xF0A070}: from the top's colour down to the horizon's, a dawn)
 *
 * height: a picture or canvas whose brightness is the ground's height (0..255); colour: one the same size (or any:
 * both wrap); x, y the camera on the map, angle in degrees (0 east, 90 south), z its height, horizon the screen row
 * of the far horizon, distance how far it looks (in map pixels), scale how tall the hills are drawn, fog the
 * distance from which the ground fades to the sky's colour (0: none). Columns run until the view is filled. */
/* The height map as bytes, kept from one frame to the next while the same picture (and the same canvas generation)
 * is asked for: the brightness of each pixel once, not once a sample. In slow memory. */
static uint8_t *hmap;
static int16_t *ray_ybuf;
static int hmap_w, hmap_h;
static const asset *hmap_src;
static uint32_t hmap_gen;

static bool height_map(const asset *a) {
    if (hmap && hmap_src == a && hmap_gen == a->gen && hmap_w == a->w && hmap_h == a->h) return true;
    uint8_t *m = hal_realloc_slow(hmap, (size_t)a->w * a->h);
    if (!m) return false;
    hmap = m, hmap_w = a->w, hmap_h = a->h, hmap_src = a, hmap_gen = a->gen;
    for (int i = 0; i < a->w * a->h; i++) {
        const uint16_t c = a->pixels[i];
        hmap[i] = (uint8_t)(((c >> 11) * 702 + ((c >> 5) & 63) * 345 + (c & 31) * 702) >> 8); /* (R + G + B) / 3 of the 8-bit channels */
    }
    return true;
}

void ray_free(void) { /* the player ends: the voxel renderer's buffers let go */
    free(hmap), hmap = NULL, hmap_src = NULL, hmap_w = hmap_h = 0;
    free(ray_ybuf), ray_ybuf = NULL;
}

static int l_voxels(lua_State *L) {
    const char *id = luaL_checkstring(L, 1);
    asset *cv = safe_name(id) ? gfx_asset_opt(id) : NULL;
    if (!cv || !cv->canvas) return luaL_error(L, "voxels \"%s\": not a canvas (make one with canvas())", id);
    luaL_checktype(L, 2, LUA_TTABLE);
    const char *hid = opt_str(L, 2, "height"), *cid = opt_str(L, 2, "colour");
    if (!cid) cid = opt_str(L, 2, "color");
    const asset *hm = hid && safe_name(hid) ? gfx_asset_opt(hid) : NULL;
    const asset *cm = cid && safe_name(cid) ? gfx_asset_opt(cid) : hm;
    if (!hm || hm->w < 1 || hm->h < 1 || !hm->pixels) return luaL_error(L, "voxels: height needs a canvas or a plain (not packed) picture");
    if (!cm || cm->w < 1 || cm->h < 1 || !cm->pixels) return luaL_error(L, "voxels: colour needs a picture or canvas with colours");
    if (!height_map(hm)) return luaL_error(L, "voxels: out of memory");
    const int W = cv->w > MAX_W ? MAX_W : cv->w, H = cv->h > MAX_H ? MAX_H : cv->h;
    const float px = opt_float(L, 2, "x", 0, -1e6f, 1e6f), py = opt_float(L, 2, "y", 0, -1e6f, 1e6f);
    const float ang = opt_float(L, 2, "angle", 0, -NUM_MAX, NUM_MAX) * DEG, fov = opt_float(L, 2, "fov", 90, 10, 170) * DEG;
    const float cz = opt_float(L, 2, "z", 80, -1e4f, 1e4f), scale = opt_float(L, 2, "scale", 120, 1, 1e4f);
    const float horizon = opt_float(L, 2, "horizon", (float)H / 2, -1e4f, 1e4f), dist = opt_float(L, 2, "distance", 300, 2, 4000);
    const float fog = opt_float(L, 2, "fog", 0, 0, 1e5f);
    int top = -1, bottom = 0x9ED6F0; /* sky = colour, or {top, horizon}: a gradient down to the horizon */
    lua_getfield(L, 2, "sky");
    if (lua_istable(L, -1)) {
        lua_rawgeti(L, -1, 1), top = (int)(luaL_checkinteger(L, -1) & 0xFFFFFF), lua_pop(L, 1);
        lua_rawgeti(L, -1, 2), bottom = (int)(luaL_checkinteger(L, -1) & 0xFFFFFF), lua_pop(L, 1);
    } else if (!lua_isnil(L, -1)) bottom = (int)(luaL_checkinteger(L, -1) & 0xFFFFFF);
    lua_pop(L, 1);
    uint16_t sky = to565(bottom); /* (the fog fades to the horizon's colour) */
    if (sky == CANVAS_KEY) sky ^= 1; /* (the key colour is see-through on a canvas) */
    uint16_t *out = cv->pixels;
    if (top < 0) for (int i = 0; i < W * H; i++) out[i] = sky;
    else {
        const int rows = horizon < 1 ? 1 : horizon > H ? H : (int)horizon;
        for (int y = 0; y < H; y++) {
            const int t = y >= rows ? 256 : y * 256 / rows; /* 0 at the top, 256 at the horizon and below */
            int c = 0;
            for (int sh = 0; sh <= 16; sh += 8)
                c |= ((((top >> sh) & 255) * (256 - t) + ((bottom >> sh) & 255) * t) >> 8) << sh;
            uint16_t v = to565(c);
            if (v == CANVAS_KEY) v ^= 1;
            for (int x = 0; x < W; x++) out[y * W + x] = v;
        }
    }
    int16_t *ybuf = ray_ybuf; /* the lowest row still open in each column (slow memory: the console's internal RAM is counted) */
    if (!ybuf && !(ybuf = ray_ybuf = hal_realloc_slow(NULL, MAX_W * sizeof *ybuf))) return luaL_error(L, "voxels: out of memory");
    for (int x = 0; x < W; x++) ybuf[x] = (int16_t)H;
    /* the maps are read with a mask when their sides are powers of two (the usual), a modulo otherwise */
    const int hw = hmap_w, hh = hmap_h, cw = cm->w, ch = cm->h;
    const bool hpow = !(hw & (hw - 1)) && !(hh & (hh - 1)), cpow = !(cw & (cw - 1)) && !(ch & (ch - 1));
    const uint16_t *cpx = cm->pixels;
    const float k = tanf(fov / 2), dxv = cosf(ang), dyv = sinf(ang), plx = -dyv * k, ply = dxv * k;
    const int sr = sky >> 11, sg = (sky >> 5) & 63, sb = sky & 31;
    const float BIG = 1048576.0f; /* added before the cast: the coordinates positive, a multiple of every power of two below it */
    /* z outwards in steps that grow 1 % each, the same for every column (the rays fan from the camera) */
    for (float z = 1, dz = 1; z < dist; z += dz, dz *= 1.01f) {
        const float zs = scale / z, base = cz * zs + horizon;
        const int f = fog > 0 ? (z >= fog ? 16 : (int)(z / fog * 10)) : 0; /* 16ths of the sky's colour mixed in */
        const float rx = dxv * z, ry = dyv * z, sx = plx * z, sy_ = ply * z; /* this ring: the middle, and its span across */
        for (int x = 0; x < W; x++) {
            const int16_t open = ybuf[x];
            if (open <= 0) continue;
            const float cam = 2.0f * (float)x / (float)W - 1.0f;
            const float mx = px + rx + sx * cam, my = py + ry + sy_ * cam;
            int ix = (int)(mx + BIG), iy = (int)(my + BIG);
            int hx, hy;
            if (hpow) hx = ix & (hw - 1), hy = iy & (hh - 1);
            else hx = ix % hw, hy = iy % hh;
            const int h = hmap[hy * hw + hx];
            int sy = (int)(base - (float)h * zs);
            if (sy < 0) sy = 0;
            if (sy >= open) continue;
            int cx, cy;
            if (cpow) cx = ix & (cw - 1), cy = iy & (ch - 1);
            else cx = ix % cw, cy = iy % ch;
            uint16_t c = cpx[cy * cw + cx];
            if (f > 0) { /* towards the sky's colour */
                const int r = c >> 11, g = (c >> 5) & 63, b = c & 31;
                c = (uint16_t)(((r * (16 - f) + sr * f) >> 4) << 11 | ((g * (16 - f) + sg * f) >> 4) << 5 | ((b * (16 - f) + sb * f) >> 4));
            }
            if (c == CANVAS_KEY) c ^= 1;
            uint16_t *col = out + sy * W + x;
            for (int y = sy; y < open; y++, col += W) *col = c;
            ybuf[x] = (int16_t)sy;
        }
    }
    memset(cv->mask, 0xFF, (size_t)((cv->w + 7) / 8) * cv->h); /* the view covers its canvas */
    cv->full = true;
    cv->gen++;
    draw_canvas_written(W * H);
    return 0;
}

void ray_register(lua_State *L) {
    lua_register(L, "raycast", l_raycast);
    lua_register(L, "voxels", l_voxels);
}
