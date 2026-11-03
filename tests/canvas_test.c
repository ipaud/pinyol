/* A canvas with no see-through pixel is copied without its mask (asset.full): the same pixels as with it, on a plain buffer and
 * on the console's turned strips both ways round and both byte orders; and one see-through pixel drawn on it brings the mask back. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "bp.h"

static int failures, checks;
#define CHECK(c)                                                                  \
    do {                                                                          \
        checks++;                                                                 \
        if (!(c)) failures++, fprintf(stderr, "%s:%d: CHECK(%s)\n", __FILE__, __LINE__, #c); \
    } while (0)

enum { FW = 96, FH = 64, CW = 61, CH = 40, BG = 0x5A5A }; /* (61: a row's last mask byte is part full) */

static void draw(uint16_t *out, const asset *a, bool turned, bool flip, bool swap) {
    for (int i = 0; i < FW * FH; i++) out[i] = BG;
    if (!turned) {
        surface s = {.px = out, .w = FW, .h = FH};
        gfx_blit_flip(&s, a, 0, 13, 9, false, NULL, -1);
        return;
    }
    for (int r0 = 0; r0 < FW; r0 += 32) { /* the strips, as the console draws them */
        surface s = gfx_turned(out + (size_t)r0 * FH, r0, 32, FW, FH, flip, swap);
        gfx_blit_flip(&s, a, 0, 13, 9, false, NULL, -1);
    }
}

/* what the canvas should show: every pixel but (hx, hy), the hole (-1: none) */
static int wrong(const uint16_t *out, const asset *a, bool turned, bool flip, bool swap, int hx, int hy) {
    static uint16_t ref[FW * FH];
    for (int i = 0; i < FW * FH; i++) ref[i] = BG;
    for (int y = 0; y < CH; y++)
        for (int x = 0; x < CW; x++)
            if (x != hx || y != hy) ref[(9 + y) * FW + 13 + x] = a->pixels[y * CW + x];
    static uint16_t want[FW * FH];
    if (!turned) memcpy(want, ref, sizeof want);
    else
        for (int r0 = 0; r0 < FW; r0 += 32) { /* the reference turned the same way: each pixel set through the surface */
            surface t = gfx_turned(want + (size_t)r0 * FH, r0, 32, FW, FH, flip, swap);
            for (int y = 0; y < FH; y++)
                for (int x = 0; x < FW; x++) {
                    surface one = t;
                    gfx_fill(&one, x, y, 1, 1, ref[y * FW + x]);
                }
        }
    int n = 0;
    for (int i = 0; i < FW * FH; i++) n += out[i] != want[i];
    return n;
}

int main(void) {
    asset *a = NULL;
    CHECK(gfx_canvas("GLASS", CW, CH, NULL, &a) == NULL && a);
    CHECK(!a->full); /* new: all see-through */
    for (int i = 0; i < CW * CH; i++) a->pixels[i] = (uint16_t)(0x1234 + i * 7) == CANVAS_KEY ? 1 : (uint16_t)(0x1234 + i * 7);
    gfx_canvas_mask(a, 0, 0, CW, CH);
    CHECK(a->full);
    static uint16_t out[FW * FH];
    for (int turned = 0; turned < 2; turned++)
        for (int flip = 0; flip < 2; flip++)
            for (int swap = 0; swap < 2; swap++) {
                draw(out, a, turned, flip, swap);
                CHECK(wrong(out, a, turned, flip, swap, -1, -1) == 0);
            }
    a->pixels[17 * CW + 60] = CANVAS_KEY; /* one hole, in a row's last, part-full mask byte */
    gfx_canvas_mask(a, 60, 17, 1, 1);
    CHECK(!a->full);
    for (int turned = 0; turned < 2; turned++)
        for (int flip = 0; flip < 2; flip++)
            for (int swap = 0; swap < 2; swap++) {
                draw(out, a, turned, flip, swap);
                CHECK(wrong(out, a, turned, flip, swap, 60, 17) == 0);
            }
    a->pixels[17 * CW + 60] = 0x0F0F;
    gfx_canvas_mask(a, 60, 17, 1, 1);
    CHECK(a->full);
    /* a mask worked out eight pixels a byte: the same as one at a time, with a box that starts and ends inside bytes */
    for (int i = 0; i < CW * CH; i++) a->pixels[i] = (i * 2654435761u) % 7 == 0 ? CANVAS_KEY : (uint16_t)(i | 1);
    gfx_canvas_mask(a, 3, 2, CW - 5, CH - 4);
    int bad = 0;
    for (int y = 2; y < CH - 2; y++)
        for (int x = 3; x < CW - 2; x++) bad += !gfx_opaque(a, 0, x, y) != (a->pixels[y * CW + x] == CANVAS_KEY);
    CHECK(bad == 0 && !a->full);
    printf("canvas_test: %d checks, %d failed\n", checks, failures);
    return failures != 0;
}
