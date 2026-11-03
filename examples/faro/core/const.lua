-- the numbers of the game, in one place (screen pixels: every picture is drawn at 480x320)
local C = {}
C.W, C.H = 480, 320
C.GRAV, C.JUMP, C.MAXFALL, C.CUT = 0.35, -6.6, 7, 0.45 -- a jump rises 62 px; let go early and it is cut
C.WALK, C.WALK_LIFT, C.ACC = 2.0, 1.0, 0.5
C.HW, C.HH = 10, 80                -- Estel's box: half its width, its height (her feet are its bottom middle)
C.LANT_R, C.LIFT_R = 56, 104       -- the lantern's light low and held high
C.OIL_MAX, C.OIL_MIN = 240, 50     -- ticks of light held high; below the second it must fill again
C.CALM_T = 300                     -- an ánima touched by the high light follows her this long
C.TOUCH = 24                       -- an ánima this near chills her
C.WARMTH, C.MATCHES = 4, 3
C.INVULN = 100
C.FIRE_T = 60                      -- ticks of the lantern held high to take fire or to light a wick
return C
