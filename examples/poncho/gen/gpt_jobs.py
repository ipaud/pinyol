"""What was asked of the image model to make Poncho's hero art: ONE canonical picture per outfit, then one-row animation sheets made WITH that picture as the only reference.
Every strip ends in 15 colours, the boy about 40 px tall.

    python3 gen/gpt_run.py --plan               # what would be asked
    python3 gen/gpt_run.py                      # ask what is missing (the references first)
    python3 gen/gpt_make.py [id ...]            # raw sheets -> art/<id>.png + .json
    python3 gen/build.py                        # art/ -> assets/SPR_*.pk + data/sheets.lua"""
from __future__ import annotations

STYLE = ("16-bit SNES / Mega Drive era pixel art, hand-pixelled with hard square pixels and no anti-aliasing, a dark brown outline, cel shading with 2 or 3 tones per material, only about 15 colours "
         "in total, big dark eyes, rosy pink cheeks, a cheerful 1990s Japanese mascot look. Exactly the style of the reference image.")
FLAT = "Plain flat uniform mid-grey background (no checkerboard, no gradient), no ground, no shadow, no text, no labels, no numbers."
SHEET = ("exactly the same character, proportions and art style as the reference image. A SPRITE SHEET: all frames in ONE horizontal row, left to right, in the order described, evenly spaced "
         "with wide empty gaps between them (no frame touches another), every frame the same scale as the reference, the feet of every frame on the same baseline, the character facing RIGHT "
         "(in profile or three-quarter view, as in the reference). " + FLAT)
STRICT = (" STRICT: clean, readable poses; flat solid colours with hard pixel edges; no dithering, no noise, no gradients, no blur; every frame the same outfit, the same scale and the same "
          "head size; the face and both eyes clearly visible in every frame; limbs never hidden or cut.")
WIDE = "@@2304x768"   # read by gen/bridge.sh: asks for a wide picture (3:1) so ten frames still get room

BOY = ("PONCHO, a 3-year-old boy with curly mid-length brown hair that always shows round the head and ears (his key trait), big dark eyes, rosy cheeks, a cheerful open mouth, "
       "a short chubby body and big head (chibi proportions)")
BASE = "a cream five-panel cap worn high, a black-and-white zebra-striped t-shirt, yellow shorts, white sneakers with light-blue sides"

# id: ref (a prompt: asked) or None (a free crop of a raw picture, see gpt_run.crops); height of the body in px; sheets
# a sheet: (name, frames, what, frame names, index of the upright frame that sets its scale or "auto", size marker)
CHARS: dict = {}

CHARS["poncho"] = {
    "ref": None, "height": 80,
    "sheets": [
        ("idle", 8, "eight frames of an IDLE loop standing still, a platformer hero's: frames 1 to 3 a slow breath (shoulders and chest rising a little, the hair bouncing a little), frame 4 a BLINK "
                    "(eyes shut), frames 5 and 6 the head turned to look around (up and a little back), frame 7 a happy bounce on the toes, frame 8 back to the standing pose",
         [f"idle_{i}" for i in range(8)], 0, WIDE),
        ("walk", 8, "an eight-frame smooth WALK cycle, relaxed and bouncy, arms swinging opposite to the legs: contact, down, passing, up, then the same for the other leg",
         [f"walk_{i}" for i in range(8)], "auto", WIDE),
        ("run", 10, "a ten-frame fast RUN cycle leaning forward, arms pumping, one foot on the ground then both feet in the air, big strides, the hair streaming back; every frame a different phase "
                    "of the stride so the loop is smooth",
         [f"run_{i}" for i in range(10)], "auto", WIDE),
        ("jump", 8, "eight frames of one JUMP in order: 1 a deep, BIG crouch winding up, drawn as large as the standing pose (the whole body fills the frame height as much as possible) (the knees clearly bent, both arms swung back behind him, the head up and the whole face visible, looking forward), 2 the take-off pushing off the toes (body stretched, arms up), 3 rising, 4 the apex "
                    "(knees tucked, arms up, mouth open), 5 falling (legs reaching down, arms out), 6 landing squash (knees clearly bent, crouched low, arms out for balance, the whole face visible), 7 recovering (half up), 8 standing upright and relaxed",
         ["jump_0", "jump_1", "jump_2", "jump_3", "fall_0", "land_0", "land_1", "land_2"], 7, WIDE),
        ("hurt", 6, "six frames in order: 1 getting HIT (flinching, eyes shut tight, head back), 2 a stronger flinch recoiling backwards, 3 knocked up into the air spinning backwards, 4 falling "
                    "head over heels, 5 lying flat on his back, eyes as two spirals and a wobbly dazed mouth, arms and legs spread (comic, cute, no blood, no tears), 6 DIFFERENT from frame 5: sitting up on the floor with a hand on his head, one eye a spiral and one open, a goofy dazed smile",
         ["hurt_0", "hurt_1", "die_0", "die_1", "die_2", "die_3"], 0, "@@1920x640"),
        ("win", 8, "eight frames of a joyful VICTORY dance in order: 1 a happy crouch, 2 jumping up with both fists in the air, 3 at the top shouting YAY, 4 landing, 5 a fist pump with a wink, "
                   "6 a turn on one foot with arms wide, 7 hands on hips and chin up proudly, 8 a big thumbs-up and a huge smile",
         [f"win_{i}" for i in range(8)], "auto", WIDE),
    ],
}

CHARS["poncho_scooter"] = {
    "ref": None, "height": 84,
    "sheets": [
        ("push", 8, "an eight-frame PUSH cycle on his blue-and-orange kick SCOOTER (blue stem and handlebar, orange deck and wheels): one hand on each side of the handlebar, the front foot on the deck, "
                    "the other foot kicking off the ground behind: foot down, kick back, foot lifts, swings forward, and again, the body bobbing, the hair bouncing; the scooter in every frame",
         [f"scooter_push_{i}" for i in range(8)], "auto", WIDE),
        ("glide", 8, "eight frames on the scooter in order: frames 1 to 4 a GLIDE (both feet on the deck, knees slightly bent, a happy face, the body bobbing slightly, the hair blowing back) and "
                     "frames 5 to 8 a DRIFT (leaning hard into a turn, the scooter angled and the rear wheel sliding sideways, arms wide for balance, an excited grin)",
         [f"scooter_glide_{i}" for i in range(4)] + [f"scooter_drift_{i}" for i in range(4)], 0, WIDE),
        ("brake", 8, "eight frames on the scooter in order: frames 1 to 4 a BRAKE (one foot stomping on the rear fender, leaning back, a surprised face, ending upright and stopped; in every frame BOTH wheels, the whole deck, stem and handlebar are drawn complete and uncut, with a clear gap to the next frame) "
                     "and frames 5 to 8 a scooter JUMP (crouch, kicked up into the air with the scooter's nose raised, the apex with the whole scooter complete and horizontal beneath his feet with its stem and handlebar attached and his hands holding the handlebar, landing)",
         [f"scooter_brake_{i}" for i in range(4)] + [f"scooter_jump_{i}" for i in range(4)], 3, WIDE),
    ],
}

COSTUME_SHEETS = lambda action, action_names, action_desc: [
    ("a", 10, "ten frames in order: frames 1 to 4 a calm IDLE loop standing (a slow breath, a blink, a little bounce), then frames 5 to 10 a six-frame fast RUN cycle leaning forward, arms pumping",
     [f"idle_{i}" for i in range(4)] + [f"run_{i}" for i in range(6)], 0, WIDE),
    ("b", 6, action_desc, action_names, "auto", "@@1920x640"),
]
OUTFITS = {
    "barretina": ("PONCHO wearing a tall red Catalan BARRETINA (a floppy red stocking cap with a black band, flopping to one side) instead of his cap, curls peeking out below it, otherwise the "
                  "zebra-striped t-shirt, yellow shorts and white sneakers with light-blue sides", 84,
                  "six frames of a HEADBUTT attack: crouching and leaning back, a fast lunge forward head first with the red hat leading, the impact with the head at its furthest, holding, pulling back, "
                  "standing again", [f"headbutt_{i}" for i in range(6)]),
    "dino": ("PONCHO wearing a green DINOSAUR onesie with the hood up: the hood is a cute dinosaur head with big white teeth and yellow spikes along the top, his curly-haired face peeking out of the open "
             "mouth, a green body with a pale belly, yellow spikes and a little tail, green dino feet", 82,
             "six frames in order: 1 to 3 a STOMP (lifting one leg high with a clean green dino foot with white claws, the foot slamming down hard with the whole body, the knees bent at the impact) and 4 to 6 a FIRE BREATH (leaning back, "
             "chest out, mouth wide open roaring and leaning forward; draw NO flames, the game adds them)", [f"stomp_{i}" for i in range(3)] + [f"fire_{i}" for i in range(3)]),
    "boots": ("PONCHO wearing shiny green RAIN BOOTS up to his knees (instead of the sneakers), with his cream cap, zebra-striped t-shirt and yellow shorts", 80,
              "six frames of a SPLASH JUMP: a crouch, jumping up with the boots first, the apex with the legs tucked, plunging down boots first, the boots landing in a puddle with the knees bent "
              "(draw NO water, the game adds the splash), standing up again", [f"splash_{i}" for i in range(6)]),
    "futbol": ("PONCHO wearing a green-and-white vertically striped FOOTBALL SHIRT (short sleeves, a round collar) instead of the zebra t-shirt, with his cream cap, yellow shorts and white sneakers "
               "with light-blue sides", 80,
               "six frames of a proud, fast DASH: a super-hero sprint leaning far forward with the fists clenched and the chin up, a determined grin, a long stride, BOTH arms swinging clearly away from the chest (one fist forward, one back; no hand over the chest) (draw NO sparkles or glow, the game adds them)",
               [f"dash_{i}" for i in range(6)]),
}
for _k, (_look, _h, _desc, _names) in OUTFITS.items():
    CHARS[f"poncho_{_k}"] = {
        "ref": (_look + ". Full body, standing, facing RIGHT in three-quarter view, a cheerful stance, big head and short body like the reference. " + STYLE + " " + FLAT),
        "height": _h, "sheets": COSTUME_SHEETS(_k, _names, _desc),
    }
