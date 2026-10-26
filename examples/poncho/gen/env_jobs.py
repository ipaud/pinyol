"""What was asked of the image model to make the playroom: the walls, giant toys, shelf toys, foreground, tiles, enemies, items, logo and cover. Every sheet is ONE row of objects (or frames)
on a flat grey ground, ONLY the objects; every job has one reference (raw/env_ref.png for the places, raw/poncho_props_a.png for the toys, Poncho's own pictures for the logo).

    python3 gen/env_run.py --plan | python3 gen/env_run.py [--only TEXT] [--redo FILE]       then   python3 gen/env_make.py   and   python3 gen/env_build.py"""
from __future__ import annotations

import gpt_jobs as J

WIDE = "@@2304x768"
TALL = "@@1536x1024"
STYLE = ("16-bit SNES / Mega Drive era pixel art, hand-pixelled with hard square pixels and no anti-aliasing, a dark brown outline, cel shading with 3 tones per material, saturated cheerful colours, "
         "a cheerful 1990s Japanese platformer look, rich in small details. Exactly the style of the reference image.")
FLAT = "Plain flat uniform mid-grey background (no checkerboard, no gradient), no ground line, no cast shadow, no text, no labels, no numbers."
STRICT = (" STRICT: clean readable shapes; flat solid colours with hard pixel edges; no dithering, no noise, no gradients, no blur; every object complete and uncut; "
          "wide empty grey gaps between the objects so none touches another.")
ROW = "All of them in ONE horizontal row, left to right in the order listed, evenly spaced, each drawn at the same pixel size, standing on the same invisible baseline. "
ENV = "raw/env_ref.png"
PROPS = "raw/poncho_props_a.png"

# name -> (prompt, reference, size)
JOBS: dict = {}

JOBS["env_ref"] = ("A side-scrolling 16-bit platformer scene with NO characters: the inside of a GIANT toy playroom as a three-year-old sees it. A wooden parquet floor along the bottom with a lit top edge, "
                   "a wall with cream star wallpaper, a big window with open red curtains and a sunny landscape of green hills, a tall bookcase full of colourful toys and books, a giant teddy bear, "
                   "a cardboard rocket, stacked colourful alphabet blocks, a long red crayon on the floor, a red toy car. " + STYLE + " Fill the whole picture, no grey border.",
                   "raw/poncho_style_a.png", "@@1920x1280")

# ------------------------------------------------------------------------------------------------------------ the far wall (two panels, joined later)
WALL = ("Fill the WHOLE picture edge to edge (no grey, no border, no floor, no furniture in front). The wallpaper is warm cream with vertical soft-peach stripes and small yellow stars; a wooden skirting "
        "board is NOT drawn. The left 12% and the right 12% of the picture are only plain wallpaper with no objects at all, so the picture joins its neighbour. ")
JOBS["wall_a"] = ("A very wide flat side-on view of ONE playroom wall: " + WALL + "In the middle a big window with a white frame and mullions, open red curtains tied back at both sides with golden cords, a curtain rod, "
                  "and through the glass a sunny landscape: blue sky, white fluffy clouds, a big yellow sun, rolling green hills and a tiny red barn. " + STYLE, ENV, WIDE)
JOBS["wall_b"] = ("A very wide flat side-on view of ONE playroom wall: " + WALL + "Along the top a string of colourful paper bunting triangles. In the middle a row of framed children's drawings "
                  "(a house with a sun, a smiling cat, a rocket, a rainbow), a round wall clock, a height-measuring chart on the wall with marks, a small round mirror. " + STYLE, ENV, WIDE)

# ------------------------------------------------------------------------------------------------------------ giant toys behind the floor line
JOBS["giant_a"] = ("A SPRITE SHEET of 6 GIANT toys as seen by a toddler, each standing on a baseline and complete: (1) a big sitting teddy bear with a red bow tie, (2) a tall cardboard ROCKET with painted "
                   "portholes, red fins and a drawn flame, (3) a tower of four stacked toy alphabet blocks in different colours, (4) a big striped beach ball resting on the floor, "
                   "(5) a toy castle made of wooden blocks with flags, (6) a wooden rocking horse. " + ROW + STYLE + " " + FLAT + STRICT, ENV, WIDE)
JOBS["giant_b"] = ("A SPRITE SHEET of 6 GIANT toys as seen by a toddler, each standing on a baseline and complete: (1) a big yellow rubber duck, (2) a green toy dinosaur plush, (3) a pyramid of coloured "
                   "stacking rings on a post, (4) a big toy drum with two sticks, (5) a toy train engine with a smoking chimney, (6) a big sitting plush bunny with long ears. "
                   + ROW + STYLE + " " + FLAT + STRICT, ENV, WIDE)

# ------------------------------------------------------------------------------------------------------------ small toys that stand on the bookcase's boards
JOBS["shelf_a"] = ("A SPRITE SHEET of 10 small things that stand on a bookshelf, each complete: (1) three upright picture books of different colours, (2) a low stack of four lying books, "
                   "(3) a small sitting teddy bear, (4) a wooden toy train engine, (5) three alphabet blocks stacked in a pyramid, (6) a small beach ball, (7) a spinning top, (8) a tin toy robot, "
                   "(9) a small rubber duck, (10) a little toy drum. " + ROW + STYLE + " " + FLAT + STRICT, ENV, WIDE)
JOBS["shelf_b"] = ("A SPRITE SHEET of 10 small things that stand on a bookshelf, each complete: (1) a row of five thin upright books, (2) a small rocking horse, (3) a piggy bank, (4) a small toy castle tower, "
                   "(5) a stuffed bunny sitting, (6) a jack-in-the-box with a spring clown, (7) a paper boat, (8) a small potted plant, (9) a little xylophone, (10) a small globe on a stand. "
                   + ROW + STYLE + " " + FLAT + STRICT, ENV, WIDE)

# ------------------------------------------------------------------------------------------------------------ the foreground, in front of everything
JOBS["fore"] = ("A SPRITE SHEET of 6 toys seen very close, big and bold, each complete: (1) a long red wax crayon lying tilted with a paper wrapper and a sharp tip, (2) a long green crayon lying tilted, "
                "(3) a long blue crayon lying tilted, (4) a stack of two toy blocks (blue and yellow), (5) a yellow bouncy ball with a white shine, (6) a few scattered coloured building bricks. "
                + ROW + STYLE + " " + FLAT + STRICT, ENV, WIDE)

# ------------------------------------------------------------------------------------------------------------ tiles
JOBS["floor"] = ("ONE wide slab of a wooden parquet playroom floor seen from the side, filling the WHOLE picture edge to edge (no grey): the top 22% is the lit surface edge of the floor with warm light-orange "
                 "planks and a thin dark outline along the very top, below it the front face of the floor in medium and dark brown planks with horizontal plank seams, a few nail heads and wood grain; "
                 "the left and right edges are plain wood so the slab repeats. " + STYLE, ENV, WIDE)
JOBS["blocks"] = ("A SPRITE SHEET of 5 square toy tiles, each a perfect square seen straight on and filling its square: (1) a red alphabet block with a white circle, (2) a blue block with a white triangle, "
                  "(3) a green block with a white square, (4) a yellow block with a white star, (5) an orange wooden toy-box crate with metal corners and X braces. "
                  + ROW + STYLE + " " + FLAT + STRICT, ENV, WIDE)
JOBS["ramp"] = ("A SPRITE SHEET of 3 objects: (1) a long wooden toy RAMP seen from the side, a wedge twice as wide as tall, rising to the right, light-orange wood with a lit top edge and dark underside, "
                "(2) a wide wooden SHELF PLANK seen from the front, four times as wide as tall, light top edge, two small dark brackets, (3) a small wooden wedge. "
                + ROW + STYLE + " " + FLAT + STRICT, ENV, WIDE)

# ------------------------------------------------------------------------------------------------------------ enemies (facing right, one row, same scale, standing on one baseline)
FR = "Facing RIGHT. "
JOBS["car"] = ("A SPRITE SHEET of 10 frames of a cute red TOY CAR enemy with big round angry-cheerful cartoon eyes on its windscreen, chrome bumper, yellow headlights, black tyres with white hubcaps. "
               "Frames 1 to 8 an eight-frame DRIVE loop: the wheels clearly turning (the hubcap spokes rotate a little each frame) and the body bouncing up and down by one pixel. Frame 9 HURT: squashed flat, "
               "eyes as spirals. Frame 10 DEFEATED: flipped upside down on its roof with the wheels in the air. " + FR + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)
JOBS["robot"] = ("A SPRITE SHEET of 10 frames of a tin WIND-UP ROBOT enemy: a boxy teal body, a square grey head with a red antenna, big yellow round eyes, red cheeks, a golden key turning on its back, "
                 "stiff chunky arms and feet. A ten-frame WALK cycle, stiff and bouncy, one foot then the other, the key turning. " + FR + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)
JOBS["robot_hit"] = ("A SPRITE SHEET of 6 frames of the SAME tin wind-up robot of the reference: frames 1 to 2 WINDING UP before a dash (leaning back, the golden key spinning, a white spark ring over its head is NOT "
                     "drawn), frames 3 to 4 STOMPED (squashed flat with eyes as spirals, the key flying off), frames 5 to 6 DEFEATED (lying on its back with the legs wiggling in the air). " + FR + ROW
                     + STYLE + " " + FLAT + STRICT, "raw/robot.png", "@@1920x640")
JOBS["ball"] = ("A SPRITE SHEET of 10 frames of a cute blue rubber BOUNCING BALL enemy with yellow stars and a happy cartoon face, big eyes: frames 1 to 8 a bounce cycle: round on the ground, squashed wide at "
                "impact, stretching tall as it pushes off, stretched tall rising, round at the top of the bounce, round falling, stretched falling, squashing again; frame 9 HURT: flat pancake with spiral eyes; "
                "frame 10 DEFEATED: a deflated floppy ball. Every frame touches the same baseline when on the ground. " + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)
JOBS["plane"] = ("A SPRITE SHEET of 10 frames of a cute white folded PAPER PLANE enemy with big cartoon eyes and a tiny angry smile, blue ruled-paper lines: frames 1 to 8 an eight-frame FLAP and GLIDE loop (the wings "
                 "folding up and down, the nose pitching a little up and down), frame 9 HURT (crumpled, spiral eyes), frame 10 DEFEATED (a crumpled paper ball). " + FR + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)

# ------------------------------------------------------------------------------------------------------------ items
JOBS["coin"] = ("A SPRITE SHEET of 8 frames of a big golden COIN with a star embossed in its middle, SPINNING: front view, narrowing, edge-on, narrowing the other way, back view in the same order, a small glint "
                "travelling across, centred in each cell. " + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)
JOBS["pickups"] = ("A SPRITE SHEET of 11 pickups and icons, each complete: (1) a pink strawberry ICE CREAM cone with a cherry, (2) a red coiled SPRING trampoline fully extended, (3) the same spring half "
                   "compressed, (4) the same spring flat, (5) a blue-and-orange kick SCOOTER seen from the side, (6) a bright red heart with a white shine, (7) an empty dark purple heart, (8) a golden "
                   "musical note, (9) a pink musical note pair, (10) a small gold star, (11) a white sparkle. " + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)
JOBS["keyboard"] = ("A SPRITE SHEET of 6 frames of Poncho's friend, a cute TOY KEYBOARD (blue plastic with white and black keys, four coloured buttons) that has a happy cartoon face with big eyes and rosy cheeks "
                    "above the keys: frames 1 to 2 IDLE (eyes open, a small blink in frame 2), frames 3 to 6 PLAYING (eyes closed in joy, a wide smile, the body bouncing, keys pressed down in different places "
                    "in each frame, tiny golden notes drawn above it). " + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)
JOBS["flag"] = ("A SPRITE SHEET of 6 frames of an end-of-level GOAL FLAG on a white pole with a golden ball on top and a small wooden base: a red cloth with a golden star waving in a six-frame loop, the cloth rippling "
                "in a different phase in each frame. " + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)

# ------------------------------------------------------------------------------------------------------------ logo and cover
LOGO = ("The title LOGO of a game, 'PONCHO' as huge chunky 16-bit bubble letters in sunny yellow-orange with a thick dark purple outline and a white shine, each letter slightly tilted and bouncing, with a "
        "small curly-haired toddler's cream cap sitting on the P, and under it in smaller playful blue letters 'and the Crazy Scooter' with an orange-wheeled kick scooter drawn at the end. "
        "Only the logo, centred, on a plain flat grey ground, no other scene. " + STYLE)
JOBS["logo_a"] = (LOGO, "raw/poncho_style_a.png", "@@1536x1024")
JOBS["logo_b"] = (LOGO.replace("each letter slightly tilted and bouncing", "the letters in a curved arch with stars and sparkles around them, a rainbow swoosh under the word"), "raw/poncho_style_a.png", "@@1536x1024")
COVER = ("Key art for a platformer, 3:2 wide: Poncho, the same curly-haired toddler with the cream cap, zebra t-shirt and yellow shorts of the reference, riding his blue-and-orange kick scooter at speed to the "
         "right with a huge happy open-mouthed grin, in the giant toy playroom: wooden floor, a window with red curtains and sunny hills, a giant teddy bear and a cardboard rocket behind, "
         "colourful alphabet blocks, a red toy car, a few gold coins in the air. Dynamic, cheerful, rich in detail. Fill the whole picture. " + STYLE)
JOBS["cover_a"] = (COVER, "raw/poncho_scooter_ref.png", "@@1536x1024")
JOBS["cover_b"] = (COVER.replace("riding his blue-and-orange kick scooter at speed to the right", "jumping off a wooden ramp on his blue-and-orange kick scooter high in the air, arms wide"), "raw/poncho_scooter_ref.png", "@@1536x1024")
