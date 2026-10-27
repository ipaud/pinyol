"""WORLD 4, the keyboard stage, and the final boss BOSS_SILENCIO: what was asked of the image model. Same rules as gen/w3_jobs.py. k_far is also the style reference of the places."""
from __future__ import annotations

import env_jobs as E  # noqa

STYLE0, FLAT, STRICT, ROW, WIDE = E.STYLE, E.FLAT, E.STRICT, E.ROW, E.WIDE
BIG = "@@3072x1024"
STYLE = (STYLE0 + " The look of this world: the inside of a giant toy keyboard turned into a friendly concert stage, neon purple, cyan and hot pink on deep dark blue with warm yellow spotlights and "
         "glowing details, much warmer and more cheerful than a night scene, a weird fun 1990s Japanese arcade feel, never scary.")
FAR = "raw/k_far.png"
CRE = "raw/w1_creatures_ref.png"
PROPS = "raw/poncho_props_a.png"
MARKET = "raw/market_ref.png"
LIVE = "friendly-mischievous: big round cartoon eyes with a cheeky smile, never scary"
FR = "Facing RIGHT. "
JOBS: dict = {}

JOBS["k_far"] = ("A very wide flat view of a concert stage inside a giant toy keyboard: fill the WHOLE picture edge to edge (no grey, no border). A deep blue stage backdrop with a glowing purple gradient, "
                 "big red velvet stage curtains tied back at the sides with golden cords, rows of yellow-white spotlights on a truss on top shining soft beams, tall black loudspeaker stacks with cyan cones, "
                 "colourful equaliser bars glowing in a row (pink, cyan, yellow), floating golden musical notes, a drum kit and a microphone stand on a stage in the middle. The bottom edge is the stage floor line. "
                 "The left 12% and the right 12% show only the plain backdrop and a few small notes so the picture joins its neighbour. " + STYLE, MARKET, WIDE)
JOBS["k_mid_a"] = ("A SPRITE SHEET of 5 stage objects seen from the front, each complete and standing on a baseline: (1) a tall black loudspeaker stack of three speakers with glowing cyan cones, (2) a big drum kit "
                   "with red drums, cymbals and a stool, (3) a microphone on a tall chrome stand with a round purple cable, (4) a wooden piano grand seen from the front with the lid open, (5) a round "
                   "glowing disco ball hanging on a chain with sparkles. " + ROW + STYLE + " " + FLAT + STRICT, FAR, WIDE)
JOBS["k_mid_b"] = ("A SPRITE SHEET of 6 stage objects, each complete: (1) a tall stage spotlight on a tripod stand shining a yellow cone upwards, (2) a gold trumpet standing on its bell, (3) a row of five big glowing "
                   "EQUALISER bars of different heights in pink, cyan and yellow on a black base, (4) a giant treble clef sign made of glowing neon purple tube, (5) a black speaker monitor wedge with a cyan cone, "
                   "(6) a stack of two black flight cases with silver corners and stickers. " + ROW + STYLE + " " + FLAT + STRICT, FAR, WIDE)
JOBS["k_mid_c"] = ("A SPRITE SHEET of 6 objects, each complete: (1) a long red velvet stage curtain with a golden tassel hanging from the top, straight, (2) a pair of floating golden eighth notes, (3) a floating pink "
                   "quarter note, (4) a floating cyan beamed pair of sixteenth notes, (5) a long glowing neon purple cable looped on the floor, (6) a string of five round stage lights in warm colours hanging in a curve. "
                   + ROW + STYLE + " " + FLAT + STRICT, FAR, WIDE)
JOBS["k_fore"] = ("A SPRITE SHEET of 6 things seen very close, big and bold, each complete: (1) a black microphone with a cable, (2) a pair of drumsticks crossed, (3) a guitar pick in pink, (4) a stack of two "
                  "headphones, (5) a coiled black jack cable, (6) a small cluster of three golden notes. " + ROW + STYLE + " " + FLAT + STRICT, FAR, WIDE)

JOBS["k_floor"] = ("ONE wide slab of a giant PIANO KEYBOARD stage floor seen from the side, filling the WHOLE picture edge to edge (no grey): the top 33% is the lit top of giant white piano keys (cream-white with soft "
                   "shading and thin dark gaps between them, each key about as wide as the picture's height) with a thin dark outline along the very top; below it the front face of the keys in white, and under that a deep "
                   "purple strip. The left and right edges are plain so the slab repeats. " + STYLE, FAR, WIDE)
JOBS["k_tiles_a"] = ("A SPRITE SHEET of 5 square tiles, each a perfect square seen straight on and filling its square, solid and stackable with dark outlines: (1) a glossy black piano key block (a raised black key) with a "
                     "pink shine, (2) a purple speaker cube with a cyan cone, (3) a yellow case with a golden note, (4) a pink case with a heart, (5) a plain grey flight case with silver corners. " + ROW + STYLE + " " + FLAT + STRICT, FAR, WIDE)
JOBS["k_tiles_b"] = ("A SPRITE SHEET of 6 objects: (1) a long straight MIDDLE section of a conveyor belt seen from the side, as tall as a square tile: a dark belt with a regular repeating row of glowing cyan "
                     "arrows pointing right, plain and repeating, under it a short steel band; (2) its LEFT END with a roller; (3) its RIGHT END with a roller; (4) a long SOLID FILLED ramp wedge twice as wide as tall "
                     "rising to the right made of white piano key and black key stripes, no holes; (5) a long STAGE PLANK four times as wide as tall: a flat wooden board with a row of small coloured stage lights on its "
                     "front; (6) a rolling flight-case on small wheels seen from the side, three times as wide as tall, with a flat top. " + ROW + STYLE + " " + FLAT + STRICT, FAR, WIDE)
JOBS["k_pad"] = ("A SPRITE SHEET of 3 frames of a bouncy round DRUM-SKIN pad seen from the front: a red drum on short legs with a taut white drum head: frame 1 taut slightly curved up, frame 2 pressed down in the "
                 "middle, frame 3 fully squashed down flat; same width and legs in all three. " + ROW + STYLE + " " + FLAT + STRICT, FAR, "@@1920x640")

JOBS["k_note"] = ("A SPRITE SHEET of 10 frames of a cute bouncing EIGHTH NOTE enemy: a glossy black note head with a stem and a flag, a cheeky cartoon face on the note head, tiny feet, " + LIVE + ": frames 1 to 8 a HOP cycle "
                  "(crouching, pushing off, stretched rising, at the top, falling, landing with a squash, a little wiggle), frame 9 HURT (spiral eyes, tilted), frame 10 DEFEATED (flat, X eyes, the flag drooping). " + ROW + STYLE + " " + FLAT + STRICT, CRE, WIDE)
JOBS["k_cable"] = ("A SPRITE SHEET of 13 frames of a PLUG-AND-CABLE SNAKE enemy: a thick purple audio cable forming a snake body with a silver jack plug as its head with two big cartoon eyes and a cheeky grin, " + LIVE
                   + ": frames 1 to 8 an eight-frame SLIDE cycle (the body undulating along the floor, the plug head lifted); frames 9 to 11 COIL: curling into a tight coil in three steps with the plug peeking out; "
                   "frames 12 to 13 DEFEATED (stretched flat with X eyes, the plug limp). " + FR + ROW + STYLE + " " + FLAT + STRICT, CRE, WIDE)
JOBS["k_speaker"] = ("A SPRITE SHEET of 10 frames of a friendly SPEAKER enemy: a black box loudspeaker with a big cyan cone that is also its round mouth, two big cartoon eyes above, tiny feet, " + LIVE + ": frames 1 to 6 a "
                     "PULSE loop (the cone bulging in and out, the box squashing and stretching a little, the eyes narrowing as it pumps), frames 7 to 8 SHOUT (leaning back then forward with the mouth wide open; "
                     "draw NO sound rings, the game adds them), frames 9 to 10 DEFEATED (spiral eyes, then tipped over with X eyes). " + FR + ROW + STYLE + " " + FLAT + STRICT, CRE, WIDE)
JOBS["k_bubble"] = ("A SPRITE SHEET of 10 frames of a flying 'SHH' CLOUD enemy: a puffy lilac-grey cloud with sleepy half-closed eyes, a tiny pursed mouth and one small raised finger on its lips, " + LIVE + ": frames 1 to 8 a "
                    "FLOAT cycle (puffing, bobbing, the edges wobbling, the finger wagging), frames 9 to 10 DEFEATED (the cloud bursting into small puffs with a smile and X eyes). " + FR + ROW + STYLE + " " + FLAT + STRICT, CRE, WIDE)

JOBS["k_coin"] = ("A SPRITE SHEET of 8 frames of a big golden COIN with an eighth note embossed in its middle, SPINNING: front view, narrowing, edge-on, narrowing the other way, back view in the same order, a small "
                  "glint travelling across, centred in each cell. " + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)
JOBS["k_pack"] = ("A SPRITE SHEET of 4 things, each complete: (1) a glowing pink HEART pickup with a white shine, (2) a golden five-point star pickup, "
                  "(3) a tall goal flag: a white pole with a golden treble clef on top and a small black speaker base, and a big magenta triangular pennant with a white eighth note, waving drawing A, "
                  "(4) the same flag with the pennant in a different wave. " + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)
JOBS["k_riser"] = ("A SPRITE SHEET of 2 objects, each complete: (1) a small stage RISER platform seen from the front with a red carpet top and black sides with a row of tiny lights, four times as wide as tall, "
                   "(2) the same riser with the lights glowing brighter. " + ROW + STYLE + " " + FLAT + STRICT, FAR, "@@1920x640")

SIL = ("EL GRAN SILENCIO, the final boss: a HUGE soft grey-lilac cloud or blanket creature with a round puffy body that trails in cloudy folds at the bottom, big sleepy half-closed eyes with heavy eyelids, a small "
       "round nose, a big raised hand with one finger held up to its lips in a 'shh' gesture, the mouth a dark round gentle opening, a little nightcap of the same cloud on top; tired and grumpy but never scary "
       "and never gory. About 5 times the height of the small enemies of the reference. ")
JOBS["sil_a"] = ("A SPRITE SHEET of 6 frames of " + SIL + "IDLE loop: breathing slowly (the cloud swelling and shrinking), the eyelids drooping, a slow blink, the finger swaying. " + FR + ROW + STYLE + " " + FLAT + STRICT, CRE, BIG)
JOBS["sil_b"] = ("A SPRITE SHEET of 6 frames of the SAME boss of the reference doing 'SHH': the finger to the lips and raising it, the whole body leaning forward, the cheeks puffing, then a big stern 'shh' with the "
                 "hand flat out in a stop gesture; draw NO rings or sound waves. " + FR + ROW + STYLE + " " + FLAT + STRICT, "raw/sil_a.png", BIG)
JOBS["sil_c"] = ("A SPRITE SHEET of 6 frames of the SAME boss of the reference SWALLOWING sound: the mouth opening wider and wider into a big dark round hole, the whole cloud body stretching toward it, "
                 "the cheeks hollow, then the mouth closing with a gulp and the body bloated; draw NO notes. " + FR + ROW + STYLE + " " + FLAT + STRICT, "raw/sil_a.png", BIG)
JOBS["sil_d"] = ("A SPRITE SHEET of 7 frames of the SAME boss of the reference: frames 1 to 3 HURT (flinching, a wince, the cloud edges ruffled, one eye squeezed shut), frames 4 to 7 ANGRY (heavy furious eyebrows, "
                 "the cloud turning darker grey-purple, the body trembling, teeth bared in the dark mouth, fists raised). " + FR + ROW + STYLE + " " + FLAT + STRICT, "raw/sil_a.png", BIG)
JOBS["sil_e"] = ("A SPRITE SHEET of 8 frames of the SAME boss of the reference: frames 1 to 4 STUNNED by rhythm: dizzy swirly eyes, the cloud wobbling, bursts of coloured light (pink, cyan, yellow) bursting "
                 "outwards from the body in a different pattern each frame; frames 5 to 8 DEFEATED, a happy redemption with no gore: the cloud shrinking in four steps from huge to a SMALL smiling pale lilac cloud, "
                 "the last frame a small cheerful cloud sitting with two tiny hands raised as if playing a keyboard. " + FR + ROW + STYLE + " " + FLAT + STRICT, "raw/sil_a.png", BIG)
