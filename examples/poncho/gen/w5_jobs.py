"""POLISH round: what was asked of the image model (10 calls): world-3 extras (hopscotch, puddle, seesaw, rainbow ramp, pigeon peck), the melon foe, the banana peel, a strong bounce pad, world-4 extras
(black key, pressed key, bigger lights, 4-frame flag, stun burst) and the costumes' jump / fall frames. Same rules as gen/w3_jobs.py."""
from __future__ import annotations

import w3_jobs as W3
import w4_jobs as W4
import env_jobs as E

FLAT, STRICT, ROW, WIDE = E.FLAT, E.STRICT, E.ROW, E.WIDE
FR = "Facing RIGHT. "
JOBS: dict = {}
S3, S4 = W3.STYLE, W4.STYLE

JOBS["x3_a"] = ("A SPRITE SHEET of 8 objects: (1) a long HOPSCOTCH board seen from the side, four times as wide as tall: a flat dark asphalt slab with a thin light edge whose top face is painted with a row of bright "
                "white-outlined chalk squares containing the chalk digits 1, 2, 3 in yellow, pink and blue; (2) the SAME hopscotch board but CRACKED: a jagged black crack across it, one chunk tilted and loose, the digits "
                "partly broken; (3) a SOLID wooden RAMP wedge twice as wide as tall rising to the right whose slanted face is painted with chalk rainbow arcs in red, orange, yellow, green and blue; (4) a flat puddle of "
                "blue water on the ground seen from the side, calm, with a sky reflection and a white shine; (5) the same puddle with one small ripple ring; (6) the same puddle with two wide ripple rings and tiny droplets; "
                "(7) a SEESAW seen from the side: a long plank with a coloured seat at each end on a triangular pivot, the LEFT end touching the ground and the right end high; (8) the same seesaw with the RIGHT end "
                "touching the ground and the left end high. " + ROW + S3 + " " + FLAT + STRICT, "raw/c_far.png", WIDE)
JOBS["x3_peck"] = ("A SPRITE SHEET of 4 frames of the SAME plump grey pigeon enemy of the reference PECKING at the ground: frame 1 standing with the head up, frame 2 leaning forward with the beak nearly down, frame 3 the beak touching the "
                   "ground with the tail up, frame 4 coming back up. " + FR + ROW + S3 + " " + FLAT + STRICT, "raw/c_pigeon.png", "@@1536x512")
MEL = ("a cute small green striped WATERMELON enemy with big round cartoon eyes, a cheeky grin, rosy cheeks, a little green stem on top and tiny feet and arms, friendly-mischievous never scary")
JOBS["x2_melon_a"] = ("A SPRITE SHEET of 10 frames of " + MEL + ": frames 1 to 8 an eight-frame WALK cycle, bouncy, one foot then the other; frame 9 HURT (spiral eyes, a crack on the rind); frame 10 DEFEATED (split open "
                      "into two halves showing red flesh and seeds, X eyes, lying on the ground). " + FR + ROW + E.STYLE + " " + FLAT + STRICT, "raw/apple_a.png", WIDE)
JOBS["x2_melon_b"] = ("A SPRITE SHEET of 10 objects: (1) to (6) six frames of the SAME green striped watermelon enemy of the reference (the one with big eyes) as a tight ROLLING BALL, the stripes and the face at a "
                      "different rotation in each of the six frames; (7) a flat yellow BANANA PEEL lying on the ground, curled, shiny, seen from the side, wide and low; (8) the same peel with a little shine "
                      "sparkle; (9) a bouncy AWNING pad: a stretched awning of HOT PINK and white stripes between two small posts, with a big bright YELLOW arrow with a dark outline pointing up painted on it, "
                      "taut slightly curved up; (10) the same pad pressed flat down in the middle. " + ROW + E.STYLE + " " + FLAT + STRICT, "raw/apple_a.png", WIDE)
JOBS["x4_a"] = ("A SPRITE SHEET of 7 objects: (1) a square tile seen straight on showing the lit top of a giant piano key area: cream-white white key with a glossy BLACK piano key block standing up on it, pink shine, dark outline, "
                "(2) a square tile of a white piano key PRESSED DOWN: sunk lower with a darker shade and a glowing cyan light on its edge, (3) a long hanging string of FIVE big round warm yellow stage lights on a black cable "
                "in a curve with soft glows, wide and short, (4) to (7) four frames of a goal flag: a white pole with a golden treble clef on top and a small black speaker base, and a big magenta triangular pennant with "
                "a white eighth note, the pennant waving in FOUR clearly different curves (flat, rippling up, rippling down, twisting). " + ROW + S4 + " " + FLAT + STRICT, "raw/k_far.png", WIDE)
JOBS["x4_burst"] = ("A SPRITE SHEET of 4 frames of a colourful BURST effect for a stunned boss, each centred: frame 1 a small bright star flash with four tiny stars and notes starting to fly out, frame 2 a ring of "
                    "about eight stars and music notes in pink, cyan, yellow and white flying outward, frame 3 a wider ring with the stars bigger and fewer, frame 4 a faint wide ring of tiny sparkles and two notes. "
                    "Only the effect, nothing else in the picture. " + ROW + S4 + " " + FLAT + STRICT, "raw/k_far.png", "@@2048x512")
JP = ("A SPRITE SHEET of 3 frames of the SAME boy of the reference in the SAME outfit, same size and same proportions, for a platformer jump: frame 1 JUMP UP: rising, both arms stretched upward, legs trailing "
      "below, a happy open mouth; frame 2 JUMP PEAK: at the top, knees tucked up, arms out to the sides, a joyful face; frame 3 FALL: falling, legs reaching down, arms up and out, hair and clothes lifting. ")
for _x in ("dino", "barretina", "boots", "futbol"):
    JOBS[f"x5_j_{_x}"] = (JP + FR + ROW + E.STYLE + " " + FLAT + STRICT, f"raw/jref_{_x}.png", "@@1536x512")
