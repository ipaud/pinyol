"""What was asked of the image model (gpt-image through the codex bridge) for El Faro de las Ánimas: one canonical picture of Estel, then her
sheets made WITH it as the only reference; the ánimas, the octopus of the storm, the props and the painted rooms of the lighthouse.

    python3 gen/gpt_run.py --plan          # what would be asked (a call is about 1% of a ChatGPT five-hour window)
    python3 gen/gpt_run.py                 # ask what is missing (raw/, ignored by git): references first
    python3 gen/gpt_run.py --only bg_      # only those
    python3 gen/gpt_make.py                # raw/ -> art/*.png, then tools/png2asset.py --packed -> assets/
"""
from __future__ import annotations

STYLE = ("Late-1990s 32-bit console 2D game art (a PlayStation / Sega Saturn gothic action-platformer): richly detailed hand-pixelled sprite art with up to 256 colours, "
         "smooth careful shading, crisp pixel edges, no anti-aliased blur. World: a Mediterranean fishing village on a rocky cape, a lighthouse, a stormy night.")
FLAT = "Plain flat transparent background, no ground, no shadow, no text, no labels, no numbers, no frame."
SHEET = ("Exactly the same character and art style as the reference image. A SPRITE SHEET: all frames in ONE horizontal row, left to right, evenly spaced with wide "
         "empty gaps between them, every frame the same scale as the reference, the feet of every frame on the same baseline, facing right. " + FLAT)
ROW = ("A SPRITE SHEET of separate objects: all the pictures in ONE horizontal row, left to right, evenly spaced with wide empty gaps between them, each one whole. " + FLAT)
BG = ("A painted 2D game background in late-1990s 32-bit console pixel art (PlayStation / Saturn era), 256 colours, fine ordered-dither gradients, moody night light in "
      "deep blues, teals and slate greys with warm amber accents, crisp pixels, no characters, no people, no text.")

ESTEL = ("ESTEL, a young lighthouse keeper of about twenty from a Catalan fishing village: a bright yellow oilskin raincoat to the knees with the hood down, a long knitted "
         "red scarf, dark green rubber boots, a thick dark-brown braid over her shoulder, rosy cheeks, a kind determined face; she carries an old brass storm lantern "
         "with warm amber glass in her right hand")

# name: (size or None, reference or None, prompt)
JOBS = {
    "estel_ref": (None, None, ESTEL + ". Full body, side view facing RIGHT in three-quarter view, standing relaxed, the lantern lit and held low at her side, about 90 pixels "
                  "tall in the game. " + STYLE + " " + FLAT),
    "estel_walk": ("1536x1024", "estel_ref", "Five frames of this character: a WALK cycle, the lantern swinging gently in her hand at her side. " + STYLE + " " + SHEET),
    "estel_lift": ("1536x1024", "estel_ref", "Five frames of this character walking slowly and carefully while holding the lit lantern HIGH ABOVE HER HEAD with her right arm "
                   "fully raised, a walk cycle of five steps. " + STYLE + " " + SHEET),
    "estel_moves": ("1536x1024", "estel_ref", "Five frames of this character: 1) standing idle holding the lantern low, 2) JUMPING up, knees tucked, the lantern held out, "
                    "3) FALLING with arms out and the braid flying up, 4) HURT and shivering with cold, eyes shut, hugging herself, 5) a happy VICTORY pose, the lantern held "
                    "up high and the other fist raised. " + STYLE + " " + SHEET),
    "anima": ("1536x1024", None, "Five frames of a floating GHOST animation: the ánima of a drowned old fisherman, pale cyan-white and glowing, a long white beard, a "
              "red Catalan barretina cap gone pale, a thick striped fisherman's jersey, a pipe in his mouth, kindly sad eyes, no legs: his body fades into a curling "
              "wisp of sea mist below the waist, arms gently floating; the wisp and arms sway from frame to frame. Facing right. " + STYLE + " " + ROW),
    "pop": ("1536x1024", None, "Four frames of a giant boss: EL POP DE LA TEMPESTA, a huge octopus made of storm cloud and dark sea water, deep indigo and violet skin "
            "with pale glowing spots, enormous round sad yellow eyes, a little grumpy mouth, seen from the front as a HEAD AND MANTLE ONLY rising from below (no "
            "tentacles drawn, the bottom edge is cut straight; NOTHING on its head: no buildings, no village, no lighthouse, no landscape, no lightning bolts): 1) watching, 2) blinking, 3) angry, frowning, 4) hit and dazzled, eyes squeezed shut. " + STYLE + " " + ROW),
    "tentacle": ("1024x1536", None, "One single giant OCTOPUS TENTACLE standing perfectly straight and vertical, thick at the bottom and tapering to a curled tip at the top, "
                 "deep indigo-violet skin with pale suckers along its right side, wet highlights. Only the tentacle, centred, filling the picture's height. " + STYLE + " " + FLAT),
    "props": ("1536x1024", None, "Five objects: a heavy dark-iron COG GEAR wheel seen perfectly flat-on from the front (a round wheel with sixteen teeth and six spokes); "
              "a lighthouse FRESNEL LENS seen from the front (a round glass beehive of concentric prism rings in a brass frame, unlit); a brass OIL BURNER with three "
              "wicks; a small tin OIL CAN; a wooden BARREL lying on its side. " + STYLE + " " + ROW),
    "planks": ("1536x1024", None, "Three long horizontal platform pieces for a platform game, stacked one above the other with wide empty gaps, each one a long thin strip seen "
               "from the side: 1) a weathered wooden plank walkway with iron nails and a beam under it, 2) a carved granite stone ledge with moss and a dark underside, "
               "3) a riveted iron grating catwalk painted dark green with rust. Plain flat transparent background, no text. " + STYLE),
    "bg_f1": ("1024x1536", None, "The tall interior of the GROUND FLOOR of an old round stone lighthouse at night, seen straight on: whitewashed curved stone walls with "
              "damp patches, a big arched wooden sea door at the bottom left with storm water seeping under it, a rowing boat, fishing nets, ropes, cork floats and "
              "crates on the stone floor at the bottom, a large arched WINDOW with small panes on the right wall about two thirds of the way up showing the stormy sea "
              "and lightning outside, old oil lamps on hooks; the middle of the picture is open empty wall (the game adds its own platforms). " + BG),
    "title": ("1536x1024", None, "A tall white lighthouse with a red band on a rocky Mediterranean cape at night in a violent storm, huge waves crashing on the rocks, slanted "
              "rain, purple lightning in heavy clouds, a little fishing village of white houses and a chapel below, tiny fishing boats with lamps fighting the waves; "
              "the lighthouse lamp at the top is DARK. The lighthouse stands on the right third; the dark sky in the upper left two thirds is empty, for the title. " + BG),
}
# second wave: they take a picture of the first as their reference (the same lighthouse, the same light)
JOBS2 = {
    "bg_f2": ("1024x1536", "bg_f1", "The same lighthouse, the floor above: an old flooded CISTERN vault inside the tower, round stone walls and brick arches, a big dark pool "
              "of still water filling the bottom quarter with reflections, rusty pipes and a hand pump, a small arched WINDOW high on the left wall showing the storm; "
              "the middle is open empty wall. " + BG),
    "bg_f3": ("1024x1536", "bg_f1", "The same lighthouse, higher up: the CLOCKWORK ROOM that turns the lamp, curved stone walls, a tall brass column of the rotation machine "
              "in the middle background, chains and a hanging counterweight, brass pipes, a big round WINDOW on the right wall high up showing the storm; open empty "
              "space in front for the game's platforms. " + BG),
    "bg_f4": ("1024x1536", "title", "Outside the top of the same lighthouse in the storm, seen from the side: the curved white stone tower wall with the red band, a "
              "narrow iron balcony gallery near the top, iron rungs on the wall, the black stormy sea and foam far below at the bottom, slanted rain, purple lightning, "
              "the lantern room's glass windows at the very top, dark. " + BG),
    "bg_lamp": ("1536x1024", "bg_f1", "Inside the LANTERN ROOM at the top of the same lighthouse: a round room of tall glass windows in an iron frame all around, rain "
                "streaming down the glass, the stormy night sea and lightning outside, an iron grating floor along the bottom, a brass railing, an empty brass "
                "pedestal in the centre at the bottom (no lens on it), small brass oil burners on low stands at the left and right. " + BG),
    "ending": ("1536x1024", "title", "The same lighthouse on the same cape at DAWN after the storm: a calm sea shining pink and gold, the lighthouse lamp ON with a soft "
               "beam, fishing boats coming home to the little harbour, gulls, a few clouds lit by the sunrise; the sky in the upper left two thirds is calm and empty "
               "for text. " + BG),
}
