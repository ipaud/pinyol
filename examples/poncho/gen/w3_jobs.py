"""WORLD 3, the chalk park: what was asked of the image model (14 calls). Same rules as gen/w2_jobs.py. The first picture (c_far) is also the style reference of the places."""
from __future__ import annotations

import env_jobs as E  # noqa

STYLE0, FLAT, STRICT, ROW, WIDE = E.STYLE, E.FLAT, E.STRICT, E.ROW, E.WIDE
STYLE = (STYLE0 + " The look of this world: a park pavement of dark blue-grey asphalt covered in bright CHALK drawings (white, yellow, pink, sky blue, orange, green chalk with a soft powdery texture "
         "done with hard pixels), high contrast, the grown-up park objects (swings, slide, bench) in saturated colours with dark outlines.")
FAR = "raw/c_far.png"
CRE = "raw/w1_creatures_ref.png"
PROPS = "raw/poncho_props_a.png"
MARKET = "raw/market_ref.png"
LIVE = "friendly-mischievous: big round cartoon eyes with a cheeky smile, never scary"
FR = "Facing RIGHT. "

JOBS: dict = {}
JOBS["c_far"] = ("A very wide flat view of a sunny city park seen from a child's height: fill the WHOLE picture edge to edge (no grey, no border). The top 45% a bright sky in three flat blue bands with simple white clouds; "
                 "behind, rows of round green park trees in two tones, a long black iron railing fence with spear tips, a distant playground roof and a clock tower; at the very bottom a low grey stone wall. "
                 "The left 12% and the right 12% are only plain sky, tree tops and railing so the picture joins its neighbour. " + STYLE, MARKET, E.WIDE)

JOBS["c_mid_a"] = ("A SPRITE SHEET of 5 park objects seen from the front, each complete and standing on a baseline: (1) a red metal swing set with two swings on chains and a wooden seat each, (2) a tall blue "
                   "playground slide with a ladder and a yellow slide, (3) a green wooden park bench with metal legs and a curled armrest, (4) a big leafy round park tree with a brown trunk, "
                   "(5) a stone drinking fountain with a small silver spout. " + ROW + STYLE + " " + FLAT + STRICT, FAR, WIDE)
JOBS["c_mid_b"] = ("A SPRITE SHEET of 6 park things, each complete and standing on a baseline: (1) a black iron park lamp post with a round glowing lamp, (2) a square wooden sandbox with sand and a small red bucket and spade, "
                   "(3) a seesaw with two coloured seats on a triangular middle, (4) a GIANT CHALK DRAWING of a smiling yellow sun with rays on a dark asphalt square, (5) a GIANT CHALK DRAWING of a house with a red "
                   "roof, a door and windows and a smoke curl on a dark asphalt square, (6) a GIANT CHALK DRAWING of a rainbow arch with two clouds on a dark asphalt square. " + ROW + STYLE + " " + FLAT + STRICT, FAR, WIDE)
JOBS["c_fore"] = ("A SPRITE SHEET of 6 things seen very close, big and bold, each complete: (1) an open cardboard box of coloured chalk sticks, (2) a red and white football ball, (3) a pink hula hoop leaning, "
                  "(4) a small kick-scooter wheel and deck lying down, (5) a green water bottle, (6) a pile of fallen autumn leaves. " + ROW + STYLE + " " + FLAT + STRICT, FAR, WIDE)

JOBS["c_floor"] = ("ONE wide slab of a park PAVEMENT seen from the side, filling the WHOLE picture edge to edge (no grey): the top 33% is the lit top surface of dark blue-grey asphalt with fine speckles, a few cracks, and "
                   "bright chalk marks lying on it (a yellow hopscotch square, a pink spiral, a white arrow); a clear light kerb edge along the very top with a thin dark outline; below it the front face: a concrete kerb "
                   "of grey-blue slabs with seams and a little grass at the bottom. The left and right edges are plain so the slab repeats. " + STYLE, FAR, WIDE)
JOBS["c_tiles_a"] = ("A SPRITE SHEET of 5 square tiles, each a perfect square seen straight on and filling its square: (1) a wooden box painted with a chalk white circle on yellow, (2) a box with a chalk white star on pink, "
                     "(3) a box with a chalk white heart on blue, (4) a box with a chalk white sun on orange, (5) a plain empty chalk-dust grey wooden box. All stackable, with dark outlines and corner nails. "
                     + ROW + STYLE + " " + FLAT + STRICT, FAR, WIDE)
JOBS["c_tiles_b"] = ("A SPRITE SHEET of 6 objects: (1) a long straight MIDDLE section of a conveyor belt seen from the side, as tall as a square tile: a dark rubber belt with a regular repeating row of white chalk "
                     "arrows pointing right, plain and repeating, under it a short steel band; (2) its LEFT END with a roller; (3) its RIGHT END with a roller; (4) a long SOLID FILLED wooden ramp wedge twice as wide as tall "
                     "rising to the right, pale planks, no truss, no holes; (5) a long HOPSCOTCH plank four times as wide as tall: a flat board painted with numbered-less chalk squares in yellow, pink and blue; "
                     "(6) a SKATEBOARD seen from the side with orange wheels and a chalk-star deck, three times as wide as tall. " + ROW + STYLE + " " + FLAT + STRICT, FAR, WIDE)
JOBS["c_pad"] = ("A SPRITE SHEET of 3 frames of a small bouncy TRAMPOLINE pad seen from the front: a blue frame on short legs with a taut black bouncing mat: frame 1 taut slightly curved up, frame 2 pressed down in the "
                 "middle, frame 3 fully squashed down flat between the legs; same width and legs in all three. " + ROW + STYLE + " " + FLAT + STRICT, FAR, "@@1920x640")

JOBS["c_pigeon"] = ("A SPRITE SHEET of 10 frames of a plump grey PIGEON enemy with a green-purple neck, orange feet and big round cartoon eyes with a cheeky grin, " + LIVE + ": frames 1 to 8 an eight-frame WALK cycle, head bobbing "
                    "forward and back, feet stepping; frame 9 HURT (ruffled feathers, spiral eyes), frame 10 DEFEATED (flat on its back with feet up and X eyes). " + FR + ROW + STYLE + " " + FLAT + STRICT, CRE, WIDE)
JOBS["c_ball"] = ("A SPRITE SHEET of 10 frames of a bouncy striped beach BALL enemy with red, yellow and blue panels and a cheeky cartoon face, " + LIVE + ": frames 1 to 8 a bounce cycle: round on the ground, squashed wide at "
                  "impact, stretching tall as it pushes off, stretched tall rising, round at the top, round falling, stretched falling, squashing again; frame 9 HURT (flat pancake, spiral eyes); frame 10 DEFEATED "
                  "(deflated floppy, X eyes). " + ROW + STYLE + " " + FLAT + STRICT, CRE, WIDE)
JOBS["c_snail"] = ("A SPRITE SHEET of 13 frames of a cute SNAIL enemy with a big spiral purple-and-pink shell, a soft orange body, two eye stalks with cartoon eyes and a cheeky grin, " + LIVE + ": frames 1 to 8 an eight-frame "
                   "SLIDE cycle (the body stretching and contracting along the ground, the eye stalks swaying); frames 9 to 11 HIDE: the head and body pulling into the shell in three steps until only the shell with a "
                   "tiny dark opening shows; frames 12 to 13 DEFEATED (the shell tipped on its side, the body flopping out with X eyes). " + FR + ROW + STYLE + " " + FLAT + STRICT, CRE, WIDE)
JOBS["c_kite"] = ("A SPRITE SHEET of 10 frames of a living diamond-shaped KITE enemy: red and yellow quarters, a cheeky cartoon face in the middle, a long tail of paper bows on a curly string, " + LIVE + ": frames 1 to 8 an eight-frame "
                  "FLY cycle (the kite swaying and tilting, the tail wiggling in a different curve each frame); frames 9 to 10 DEFEATED (crumpled and tilted with X eyes, the tail limp). " + FR + ROW + STYLE + " " + FLAT + STRICT, CRE, WIDE)

JOBS["c_coin"] = ("A SPRITE SHEET of 8 frames of a big golden COIN with a white chalk-style star embossed in its middle, SPINNING: front view, narrowing, edge-on, narrowing the other way, back view in the same order, a small "
                  "glint travelling across, centred in each cell. " + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)
JOBS["c_pack"] = ("A SPRITE SHEET of 4 things, each complete: (1) an ice-cream cone with three scoops (pink, white, blue) and a cherry, (2) a lemon ice lolly on a stick, "
                  "(3) a tall goal flag: a white pole with a golden ball on top and a small stone base, and a big yellow triangular pennant with a white chalk smiley sun, waving frame A, "
                  "(4) the same flag with the pennant in a different wave. " + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)
