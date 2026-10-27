# World 3 (the chalk park): the assets

Made by `gen/w3_*.py` (image model, same pipeline as worlds 1 and 2). Sizes, anchors and frame numbers are in `data/deco3.lua` (same format as `data/deco.lua`); the far layer's columns are `data/cm_far_slices.lua`.
All are packed 8-bit pictures (`type background`, 32 colours); a strip in `pieces` is split into `<ID>_C<n>`. Packed total about 0.60 MB (far layer 0.16 MB, the rest 0.45 MB).

Performance design: ONE opaque layer only (CM_FAR, 190 px tall). Everything else is a cut-out.

| asset | w x h | anchor | frames | use |
|---|---|---|---|---|
| CE_BALL | 66x69 | 33,66 | 10: bounce_0..7, hurt_0, def_0 | bouncer (striped beach ball): bounce_0..7 (squash and stretch), hurt_0, def_0 (anchor soles) |
| CE_KITE | 60x72 | 30,36 | 10: fly_0..7, def_0..1 | flyer (anchor = body centre): fly_0..7, def_0..1 |
| CE_PIGEON | 70x64 | 35,61 | 10: walk_0..7, hurt_0, def_0 | walker: walk_0..7, hurt_0, def_0 (anchor soles) |
| CE_SNAIL | 92x67 | 46,64 | 13: slide_0..7, hide_0..2, def_0..1 | slider with shell: slide_0..7, hide_0..2 (pulls into the shell: invulnerable shell), def_0..1 (anchor soles) |
| CI_COIN | 38x41 | 19,20 | 8: spin_0..7 | chalk star coin, spin_0..7 (loop), anchor = centre |
| CI_FLAG | 222x154 | 111,151 | 4: wave_0..3 | goal flag with a yellow smiley-sun pennant: wave_0..3 (only 2 distinct drawings, alternate A B A B), anchor = pole base |
| CI_KEYBOARD | 116x109 | 58,108 | 6: idle_0..1, play_0..3 | checkpoint: Poncho's toy keyboard on a picnic blanket: idle_0, idle_1 (blink), play_0..3. Anchor = bottom centre of the blanket |
| CI_LOLLI | 34x60 | 17,30 | 2: icecream, lolly | ice-cream pickup: frames icecream, lolly (two kinds), anchor = centre |
| CM_BENCH | 132x70 | 66,69 | 1 | mid cut-out, green park bench |
| CM_CHALKBOW | 122x110 | 61,109 | 1 | mid cut-out, chalk rainbow patch |
| CM_CHALKHOUSE | 141x130 | 70,129 | 1 | mid cut-out, chalk house patch |
| CM_CHALKSUN | 131x120 | 65,119 | 1 | mid cut-out, giant chalk sun on a dark asphalt patch (it lies on the ground: put it low, in front of the far layer) |
| CM_FORE_BALL | 67x66 | 0,0 | 1 | foreground, football |
| CM_FORE_BOTTLE | 32x70 | 0,0 | 1 | foreground, water bottle |
| CM_FORE_CHALKBOX | 80x78 | 0,0 | 1 | foreground cut-out (anchor top-left), chalk box |
| CM_FORE_HOOP | 69x90 | 0,0 | 1 | foreground, hula hoop |
| CM_FORE_LEAVES | 96x65 | 0,0 | 1 | foreground, leaf pile |
| CM_FORE_SCOOTER | 100x69 | 0,0 | 1 | foreground, scooter parts |
| CM_FOUNTAIN | 51x80 | 25,79 | 1 | mid cut-out, small drinking fountain |
| CM_LAMP | 51x190 | 25,189 | 1 | mid cut-out, park lamp post |
| CM_SANDBOX | 113x60 | 56,59 | 1 | mid cut-out, sandbox |
| CM_SEESAW | 155x70 | 77,69 | 1 | mid cut-out, seesaw |
| CM_SLIDE | 156x170 | 78,169 | 1 | mid cut-out, playground tower with slide |
| CM_SWINGS | 233x150 | 116,149 | 1 | mid cut-out, red swing set (anchor bottom centre) |
| CM_TREE | 226x220 | 113,219 | 1 | mid cut-out, big leafy tree (220 px) |
| CT_BODY1 | 32x96 | 0,0 | 1 | body rows, 1 column (32x96) |
| CT_BODY2 | 64x96 | 0,0 | 1 | 2 columns |
| CT_BODY4 | 128x96 | 0,0 | 1 | 4 columns |
| CT_BODY8 | 256x96 | 0,0 | 1 | 8 columns |
| CT_CART | 96x36 | 48,35 | 1 | moving platform: a skateboard (96x36, anchor bottom centre) |
| CT_COUNTER2 | 64x32 | 0,0 | 1 | hopscotch plank strip 2 tiles (one-way platform) |
| CT_COUNTER4 | 128x32 | 0,0 | 1 | 4 tiles |
| CT_COUNTER8 | 256x32 | 0,0 | 1 | 8 tiles |
| CT_CRATES2 | 64x32 | 0,0 | 1 | plain chalk boxes strip 2 tiles |
| CT_CRATES4 | 128x32 | 0,0 | 1 | 4 tiles |
| CT_CRATES8 | 256x32 | 0,0 | 1 | 8 tiles |
| CT_FLOOR2 | 64x96 | 0,0 | 1 | floor strip, 2 columns |
| CT_FLOOR4 | 128x96 | 0,0 | 1 | floor strip, 4 columns |
| CT_FLOOR8 | 256x96 | 0,0 | 1 | floor strip, 8 columns (256x96) |
| CT_FLOORCOL | 32x96 | 0,0 | 1 | floor column top + 2 bodies (32x96) |
| CT_PAD | 70x29 | 35,26 | 3: taut, press, squash | trampoline bounce pad: taut / press / squash (70x29, anchor bottom centre) |
| CT_TILES | 32x32 | 0,0 | 18: t0..t17 | 32x32 tiles t0..t17 (same layout as FT_TILES): t0 pavement top (kerb + asphalt), t1 kerb body, t2..t5 chalk boxes (circle, star, heart, sun), t6 plain box (stackable), t7 hopscotch plank, t8..t11 ramps a b c d, t12..t15 conveyor belt (4-frame animation, arrows slide 8 px a frame), t16 belt left end, t17 belt right end |

## Polish round additions

| asset | w x h | anchor | frames | use |
|---|---|---|---|---|
| CT_HOP | 110x37 | 55,34 | 2: normal, cracked | hopscotch board object (chalk 1 2 3): normal, cracked (the cracked one when it breaks). Anchor bottom centre, 110x37 |
| CT_RAMP_RB | 32x32 | 0,0 | 4: a, b, c, d | chalk-rainbow ramp tiles a b c d (same geometry as the ramps in CT_TILES t8..t11) |
| CI_PUDDLE | 68x29 | 34,26 | 3: calm, ripple_0, ripple_1 | puddle item: calm, ripple_0, ripple_1 (play ripples when stepped in). Anchor bottom centre |
| CI_SEESAW | 142x61 | 71,58 | 2: left_down, right_down | seesaw object: left_down, right_down (an object on the floor). Anchor bottom centre |
| CE_PIGEON_PECK | 78x60 | 39,57 | 4: peck_0, peck_1, peck_2, peck_3 | pigeon peck frames peck_0..3 (separate strip: same scale as CE_PIGEON walk), anchor soles |
