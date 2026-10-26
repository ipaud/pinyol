"""What was asked of the image model for WORLD 2 (the living fruit market) and the world-1 boss Capitan Cuerda. Same rules as gen/env_jobs.py: one reference per job, sheets in one row on a
flat grey ground, only the objects; run with gen/w2_run.py, cut with gen/w2_make.py, pack with gen/w2_build.py."""
from __future__ import annotations

import env_jobs as E

STYLE, FLAT, STRICT, ROW, WIDE = E.STYLE, E.FLAT, E.STRICT, E.ROW, E.WIDE
BIG = "@@3072x1024"
PLACE = "raw/market_ref.png"
SCENE1 = "raw/w1_scene_ref.png"
CRE = "raw/w1_creatures_ref.png"
PROPS = "raw/poncho_props_a.png"
FR = "Facing RIGHT. "
LIVE = "friendly-mischievous: big round cartoon eyes with a cheeky smile and a little attitude, never scary"

JOBS: dict = {}

JOBS["market_ref"] = ("A side-scrolling 16-bit platformer scene with NO characters: the LIVING FRUIT MARKET as a three-year-old sees it on a bright morning: cobblestone street along the bottom, wooden stalls with "
                      "red-and-white and green-and-yellow striped awnings full of apples, oranges and melons, wooden fruit crates stacked, a stone fountain, iron street lamps with lanterns, colourful bunting, "
                      "a bright blue sky with white clouds and town rooftops with chimneys behind. " + STYLE + " Fill the whole picture, no grey border.", SCENE1, "@@1920x1280")

# ------------------------------------------------------------------------------------------------------------ backgrounds
SKY = ("Fill the WHOLE picture edge to edge (no grey, no border, nothing in front). The top 55% is a flat bright morning sky in three clean soft bands of blue; big simple fluffy white clouds; the bottom 45% is a skyline "
       "of old town rooftops. The left 12% and the right 12% of the picture show only plain sky and the same low rooftops pattern with no tall objects, so the picture joins its neighbour. ")
JOBS["m_far_a"] = ("A very wide flat view of a morning sky above town rooftops: " + SKY + "Rooftops: red and orange tile roofs, chimneys with a little smoke, a church tower with a round clock, one hill with trees "
                   "behind, a warm low sun. " + STYLE, PLACE, WIDE)
JOBS["m_far_b"] = ("A very wide flat view of a morning sky above town rooftops: " + SKY + "Rooftops: tall narrow houses with shuttered windows and washing lines, a windmill, two hot-air balloons high "
                   "in the sky, a few flying birds, a flock of bunting flags between roofs. " + STYLE, PLACE, WIDE)
JOBS["m_mid_a"] = ("A SPRITE SHEET of 5 market STALLS seen from the front, each complete and standing on a baseline, with a wooden counter and a striped awning roof: (1) a fruit stall with a red-and-white striped awning and "
                   "tiers of apples and oranges, (2) a vegetable stall with a green-and-yellow striped awning and baskets of carrots and cabbages, (3) a flower stall with a blue-and-white awning and buckets "
                   "of flowers, (4) a bakery stall with a pink-and-white awning with loaves of bread and a cake, (5) a cheese-and-milk stall with an orange-and-white awning, cheese wheels and milk churns. "
                   + ROW + STYLE + " " + FLAT + STRICT, PLACE, WIDE)
JOBS["m_mid_b"] = ("A SPRITE SHEET of 6 market objects, each complete and standing on a baseline: (1) a round stone fountain with a basin and a spout of water, (2) a big wooden fruit cart on two large wheels piled with "
                   "green watermelons, (3) a stack of three wooden barrels, (4) a pyramid of wooden fruit crates full of red apples, (5) a tall black iron street lamp post with a glowing lantern, "
                   "(6) a stack of wooden crates full of yellow pears. " + ROW + STYLE + " " + FLAT + STRICT, PLACE, WIDE)
JOBS["m_mid_c"] = ("A SPRITE SHEET of 6 market objects, each complete: (1) a long string of colourful triangular bunting flags hanging in a smooth curve, (2) a hanging string of three glowing paper lanterns, "
                   "(3) a wooden signboard on a post with a painted red apple and no letters, (4) a wooden wheelbarrow full of orange pumpkins standing on its wheel and legs, (5) a heap of three flour sacks, "
                   "(6) a big round striped market parasol on a pole with a stand. " + ROW + STYLE + " " + FLAT + STRICT, PLACE, WIDE)
JOBS["m_fore"] = ("A SPRITE SHEET of 6 market things seen very close, big and bold, each complete: (1) a pile of three green cabbages, (2) a sitting ginger cat with a curled tail, (3) a wicker basket of red apples, "
                  "(4) a green watering can, (5) a brown sack of potatoes, (6) a bunch of orange carrots with green tops. " + ROW + STYLE + " " + FLAT + STRICT, PLACE, WIDE)

# ------------------------------------------------------------------------------------------------------------ tiles
JOBS["t_floor"] = ("ONE wide slab of a COBBLESTONE market street seen from the side, filling the WHOLE picture edge to edge (no grey): the top 33% is the lit top surface of the street made of warm grey and beige round "
                   "cobblestones with a thin dark outline along the very top edge, below it the front face of the street: big rough stone blocks in grey-brown with mortar lines and a few moss patches; the left and "
                   "right edges are plain stone so the slab repeats. " + STYLE, PLACE, WIDE)
JOBS["t_crates"] = ("A SPRITE SHEET of 5 square wooden FRUIT CRATE tiles, each a perfect square seen straight on, slatted pale wood with dark nails, stackable: (1) full of red apples, (2) full of oranges, "
                    "(3) full of green pears, (4) full of purple grapes, (5) an empty plain slatted crate. " + ROW + STYLE + " " + FLAT + STRICT, PLACE, WIDE)
JOBS["t_awning"] = ("A SPRITE SHEET of 3 frames of a bouncy striped red-and-white fabric AWNING pad stretched horizontally between two small wooden posts, seen from the front: frame 1 taut with a slight upward curve, "
                    "frame 2 pressed down in the middle, frame 3 fully squashed flat down between the posts. The posts and the width are the same in all three frames. " + ROW + STYLE + " " + FLAT + STRICT, PLACE, "@@1920x640")
JOBS["t_belt"] = ("A SPRITE SHEET of 3 objects: (1) a long straight MIDDLE section of a conveyor belt seen from the side, as tall as a square tile: a thick dark-grey rubber belt whose whole surface carries a regular repeating row of bright yellow chevrons pointing right, under it a short band of steel frame, plain and repeating, no ends; "
                  "(2) the LEFT END of the conveyor with a round roller with bolts; (3) the RIGHT END of the conveyor with a round roller with bolts. " + ROW + STYLE + " " + FLAT + STRICT, PLACE, WIDE)
JOBS["t_ramp"] = ("A SPRITE SHEET of 4 objects: (1) a long wooden loading RAMP seen from the side: a SOLID FILLED wedge twice as wide as tall rising to the right, the whole side face one solid surface of pale horizontal planks with a thin metal edge along the slope, NO open frame, NO truss, NO triangular holes, (2) a wide wooden market stall COUNTER "
                  "plank seen from the front, four times as wide as tall, with a striped cloth trim, (3) a wooden two-wheeled handcart seen from the side with a flat top, three times as wide as tall, "
                  "(4) a small wooden wedge. " + ROW + STYLE + " " + FLAT + STRICT, PLACE, WIDE)

# ------------------------------------------------------------------------------------------------------------ enemies (the living fruit)
JOBS["apple_a"] = ("A SPRITE SHEET of 12 frames of a cute red APPLE enemy with a green leaf and a brown stem, " + LIVE + ", tiny feet and little arms: frames 1 to 8 an eight-frame WALK cycle, bouncy, one foot then the other; "
                   "frames 9 to 12 CURLING into a ball: the feet and arms tucking in, the body squashing rounder, the eyes narrowing, ending as a tight round ball with only the eyes showing. " + FR + ROW
                   + STYLE + " " + FLAT + STRICT, CRE, WIDE)
JOBS["apple_b"] = ("A SPRITE SHEET of 8 frames of the SAME red apple enemy of the reference, as a tight ROLLING BALL: frames 1 to 6 six rotations of the rolling ball (the face, leaf and stem are in a different turned position "
                   "in each frame, steady scale), frame 7 HURT (dazed, spiral eyes), frame 8 DEFEATED (a flattened squashed apple with X eyes). " + FR + ROW + STYLE + " " + FLAT + STRICT,
                   "raw/apple_a.png", "@@2304x768")
JOBS["banana"] = ("A SPRITE SHEET of 13 frames of a BANANA PEEL creature enemy: a yellow banana with its peel opened into three floppy flaps at the bottom, big cartoon eyes, a cheeky grin, " + LIVE + ": frames 1 to 8 an eight-frame "
                  "SLIDE cycle, sliding along the floor leaning forward with the peel flaps rippling; frames 9 to 11 SQUASH: squashed flat in three steps; frames 12 to 13 DEFEATED: lying flat with X eyes. " + FR + ROW
                  + STYLE + " " + FLAT + STRICT, CRE, WIDE)
JOBS["bee"] = ("A SPRITE SHEET of 14 frames of a chubby BEE enemy with a black and yellow striped round body, a little stinger, big round eyes and a cheeky grin, small translucent wings, " + LIVE + ": frames 1 to 8 an eight-frame "
               "FLY cycle (the wings in different positions, the body bobbing), frames 9 to 12 DIVE: diving down nose first with the stinger forward, frames 13 to 14 DEFEATED: spiral eyes, falling, wings limp. "
               + FR + ROW + STYLE + " " + FLAT + STRICT, CRE, WIDE)
JOBS["cherry"] = ("A SPRITE SHEET of 10 frames of a pair of twin red CHERRIES joined by a green stem with a leaf, each cherry with a face, big round eyes and a cheeky grin, " + LIVE + ": frames 1 to 8 an eight-frame BOUNCE cycle "
                  "with squash and stretch (squashed on the ground, stretched tall rising, round at the top, stretched falling), frames 9 to 10 DEFEATED: squashed flat then X eyes. " + ROW + STYLE + " " + FLAT + STRICT, CRE, WIDE)

# ------------------------------------------------------------------------------------------------------------ boss MAMA SANDIA
SAND = ("MAMA SANDIA, a giant watermelon matron boss: a huge round green striped watermelon body with big rosy cheeks, large round eyes with long lashes, a wide mischievous grin with a gap in the teeth, a red "
        "polka-dot kerchief tied on top with a knot, tiny strong arms and little stubby feet, friendly-mischievous never scary. About 3 times the height of the small enemies of the reference. ")
JOBS["sandia_a"] = ("A SPRITE SHEET of 6 frames of " + SAND + "IDLE loop: breathing, the kerchief wobbling, a blink, a big grin, hands on hips. " + FR + ROW + STYLE + " " + FLAT + STRICT, CRE, BIG)
JOBS["sandia_b"] = ("A SPRITE SHEET of 8 frames of the SAME boss of the reference rolled up into a heavy ROLLING BALL: the stripes and the face in a different turned position in each of the eight frames, angry eyes, "
                    "the kerchief flying. " + FR + ROW + STYLE + " " + FLAT + STRICT, "raw/sandia_a.png", BIG)
JOBS["sandia_c"] = ("A SPRITE SHEET of 6 frames of the SAME boss of the reference SPITTING SEEDS: leaning back, the cheeks puffing, then the mouth wide open leaning forward spitting, recovering. Draw NO seeds. "
                    + FR + ROW + STYLE + " " + FLAT + STRICT, "raw/sandia_a.png", BIG)
JOBS["sandia_d"] = ("A SPRITE SHEET of 7 frames of the SAME boss of the reference: frames 1 to 3 HURT (flinching, the kerchief askew, a crack on the rind, eyes squeezed), frames 4 to 7 ANGRY (furious eyebrows, "
                    "the body shaking and leaning forward, teeth bared, the rind a darker green). " + FR + ROW + STYLE + " " + FLAT + STRICT, "raw/sandia_a.png", BIG)
JOBS["sandia_e"] = ("A SPRITE SHEET of 4 frames of the SAME boss of the reference being DEFEATED, comic and no gore: cracking open, splitting into two big halves showing juicy red flesh with black seeds, the two halves "
                    "rocking, ending as two halves lying on the ground with a dizzy face and the kerchief on top. " + FR + ROW + STYLE + " " + FLAT + STRICT, "raw/sandia_a.png", BIG)

# ------------------------------------------------------------------------------------------------------------ items
JOBS["w2_coin"] = ("A SPRITE SHEET of 8 frames of a big golden COIN with a red apple embossed in its middle, SPINNING: front view, narrowing, edge-on, narrowing the other way, back view in the same order, a small "
                   "glint travelling across, centred in each cell. " + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)
JOBS["w2_pack"] = ("A SPRITE SHEET of 5 market things, each complete: (1) a big swirly rainbow LOLLIPOP on a white stick, (2) a pink strawberry lollipop on a stick, (3) a green apple lollipop on a stick, "
                   "(4) a small wooden market TABLE with a red-and-white checked cloth, flat top, seen from the front, (5) a small wooden market table with a blue striped cloth. " + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)
JOBS["w2_flag"] = ("A SPRITE SHEET of 6 frames of an end-of-level triangular PENNANT FLAG on a tall striped red-and-white pole with a golden apple on top and a small wooden crate as its base: the green pennant cloth with a "
                   "golden apple emblem waving in a six-frame loop. " + ROW + STYLE + " " + FLAT + STRICT, PROPS, WIDE)

# ------------------------------------------------------------------------------------------------------------ boss CAPITAN CUERDA (world 1)
CAP = ("CAPITAN CUERDA, a giant tin wind-up toy robot CAPTAIN boss, the big brother of the small tin robot of the reference: a boxy teal body with brass buttons, a red captain's cap with a gold badge, a square silver head "
       "with big glowing yellow eyes and a big silver moustache, a huge golden wind-up key on his back, thick arms with red boxing-glove fists, red boots; friendly-mischievous never scary. About 3 times the height of "
       "the small robot. ")
JOBS["cuerda_a"] = ("A SPRITE SHEET of 9 frames of " + CAP + "Frames 1 to 6 an IDLE loop (swaying, the key turning slowly, a blink), frames 7 to 9 HURT (flinching, the cap tilted, eyes squeezed shut). " + FR + ROW
                    + STYLE + " " + FLAT + STRICT, CRE, BIG)
JOBS["cuerda_b"] = ("A SPRITE SHEET of 8 frames of the SAME boss of the reference in a heavy stiff WALK cycle, the key turning, the arms swinging. " + FR + ROW + STYLE + " " + FLAT + STRICT, "raw/cuerda_a.png", BIG)
JOBS["cuerda_c"] = ("A SPRITE SHEET of 10 frames of the SAME boss of the reference: frames 1 to 6 a STOMP-SLAM attack (raising both fists high, slamming them down on the ground, staying bent, recovering), "
                    "frames 7 to 10 ANGRY (furious eyebrows, the body shaking, steam-free, fists clenched). " + FR + ROW + STYLE + " " + FLAT + STRICT, "raw/cuerda_a.png", BIG)
JOBS["cuerda_d"] = ("A SPRITE SHEET of 10 frames of the SAME boss of the reference: frames 1 to 6 a SPIN-CHARGE: winding up with the key spinning fast, then spinning round like a top with the arms out, "
                    "and dizzily stopping; frames 7 to 10 DEFEATED (comic, no gore): staggering, falling over, lying on the back with spiral eyes, the golden key flopped beside him. " + FR + ROW + STYLE + " " + FLAT + STRICT,
                    "raw/cuerda_a.png", BIG)
