/* What is done to the world's picture after the layers are drawn and before it is shown (post.c): a shock wave (a ring
 * that bends what it passes over: an explosion, a bass drop) and heat haze (rows swaying: a desert, a fire, a
 * portal). Set by a game's _draw for that frame; in the picture's own pixels (240 x 160). */
#pragma once
#include <stdbool.h>
#include <stdint.h>

#include "bp.h"

void post_shock(float x, float y, float r, float width, float amp); /* a ring of radius r, `width` wide, bending by up to amp pixels (4 a frame at most) */
void post_haze(int y0, int y1, float amp, float phase, float period); /* rows y0..y1 moved sideways by amp * sin(y / period + phase) */
void post_zone(int x0, int y0, int x1, int y1, bool water, float amp, float phase, float period); /* a rectangle that sways (heat) or wobbles (water) */
/* The same on the whole screen (480 x 320: pictures, text and shapes, as img() draws them), for games that draw no world. The panel is
 * drawn in strips of whole columns, so here each column moves up and down (heat: by amp * sin(x / period + phase); water: that and a
 * ripple of half of it); post_screen draws it on a window of the screen. Set by _draw for that frame. */
void post_screen_zone(int x0, int y0, int x1, int y1, bool water, float amp, float phase, float period);
void post_screen(surface *s);
void post_screen_reset(void); /* a new _draw */
void post_crt(bool on, float scan, float persist); /* the tube, until turned off: `scan` (0..1) dims every second row of the screen, `persist` (0..0.95) keeps that much of the world's last frame */
int post_scan(void); /* what the scanlines leave of a pixel's brightness, 0..256 (256: no scanlines) */
float post_time(void);
bool post_any(void);
void post_apply(uint16_t *world, int w, int h); /* on the picture, then forgotten for the next frame */
void post_reset(void);
void post_free(void); /* a game ended: the copy let go */
