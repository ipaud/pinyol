# World 2 (the living fruit market) and BOSS_CUERDA: the assets

Made by `gen/w2_*.py` (image model, the same pipeline as the playroom). Sizes, anchors and frame numbers are in `data/deco2.lua` (same format as `data/deco.lua`: `w h ax ay n pieces per frames`);
the far layer's columns are `data/fm_far_slices.lua`. All are packed 8-bit pictures (`type background`, 32 colours), so `Deco.img` style drawing works as for world 1; a strip in `pieces` is split into `<ID>_C<n>`
(frame f is piece f // per, frame f % per). Memory: everything below packed is about 1.65 MB, 1.25 MB without BOSS_CUERDA.

Performance design: ONE opaque layer only (FM_FAR, 150 px tall, 480 visible). Everything else is a cut-out (transparent: it costs only its opaque pixels).

| asset | w x h | anchor | frames | use |
|---|---|---|---|---|
| BOSS_CUERDA | 140x150 | 70,147 | 37: idle_0..5, hurt_0..2, walk_0..7, stomp_0..5, angry_0..3, spin_0..5, def_0..3 | world-1 boss CAPITAN CUERDA (~140 px): idle_0..5, hurt_0..2, walk_0..7, stomp_0..5 (fists raised, slam), angry_0..3, spin_0..5 (spin_0..2 the wind-up, spin_3..4 spinning like a top, spin_5 dizzy stop), def_0..3 (def_0 falling, def_1 lying, def_2 lying with stars, def_3 = the golden key alone, a prop to drop). Anchor = soles. In pieces |
| BOSS_SANDIA | 262x157 | 131,154 | 31: idle_0..5, roll_0..7, spit_0..5, hurt_0..2, angry_0..3, def_0..3 | boss MAMA SANDIA (~140 px): idle_0..5, roll_0..7, spit_0..5 (draw the seeds in code), hurt_0..2, angry_0..3, def_0..3 (cracks, splits, two halves rocking, lying). Cell 262x157 (the halves are wide). Anchor = soles. In pieces |
| FE_APPLE | 78x64 | 39,61 | 20: walk_0..7, curl_0..3, roll_0..5, hurt_0, def_0 | enemy apple: walk_0..7, curl_0..3 (curling into a ball), roll_0..5 (rolling ball; loop and mirror), hurt_0, def_0 (defeated). Anchor = soles |
| FE_BANANA | 64x56 | 32,53 | 13: slide_0..7, squash_0..2, def_0..1 | enemy banana peel: slide_0..7, squash_0..2, def_0..1. Anchor = soles |
| FE_BEE | 64x82 | 32,41 | 14: fly_0..7, dive_0..3, def_0..1 | enemy bee (flies; anchor = body centre): fly_0..7, dive_0..3, def_0..1 |
| FE_CHERRY | 66x84 | 33,81 | 10: bounce_0..7, def_0..1 | enemy twin cherries: bounce_0..7 (squash and stretch), def_0..1. Anchor = soles |
| FI_COIN | 38x40 | 19,20 | 8: spin_0..7 | apple coin, spin_0..7 (loop), anchor = centre |
| FI_FLAG | 102x154 | 20,151 | 6: wave_0..5 | goal pennant flag: wave_0..5 (loop), anchor = the pole's base |
| FI_KEYBOARD | 110x160 | 55,159 | 6: idle_0..1, play_0..3 | the checkpoint: Poncho's toy keyboard on the checked-cloth table: idle_0, idle_1 (blink), play_0..3 (playing, with notes). Anchor = bottom centre of the table |
| FI_LOLLI | 42x56 | 21,28 | 3: rainbow, pink, green | lollipop pickups (frames rainbow, pink, green: three kinds, or one kind), anchor = centre |
| FI_TABLE_1 | 110x73 | 55,72 | 1 | market table with a checked cloth (110x73), anchor bottom centre |
| FI_TABLE_2 | 110x72 | 55,71 | 1 | market table with a blue striped cloth |
| FM_BARRELS | 77x90 | 38,89 | 1 | mid cut-out, three barrels |
| FM_BUNTING | 440x153 | 220,0 | 1 | hang from the top: anchor = top centre; 440x153 is big, draw it scaled (sx 0.6) or between two lamps |
| FM_CART | 131x110 | 65,109 | 1 | mid cut-out, wooden cart with watermelons |
| FM_CRATEPEAR | 90x100 | 45,99 | 1 | mid cut-out, crates of pears |
| FM_CRATEPYR | 115x120 | 57,119 | 1 | mid cut-out, pyramid of apple crates |
| FM_FORE_BASKET | 75x70 | 0,0 | 1 | foreground cut-out, basket of apples |
| FM_FORE_CABBAGE | 100x78 | 0,0 | 1 | foreground cut-out (anchor top-left) |
| FM_FORE_CAN | 90x64 | 0,0 | 1 | foreground cut-out, watering can |
| FM_FORE_CARROTS | 90x106 | 0,0 | 1 | foreground cut-out, carrots |
| FM_FORE_CAT | 67x80 | 0,0 | 1 | foreground cut-out, ginger cat |
| FM_FORE_SACK | 85x76 | 0,0 | 1 | foreground cut-out, potato sack |
| FM_FOUNTAIN | 121x150 | 60,149 | 1 | mid cut-out, stone fountain (water drawn static) |
| FM_LAMP | 59x210 | 29,209 | 1 | mid cut-out, iron street lamp (210 px) |
| FM_LANTERNS | 113x90 | 56,0 | 1 | hang from the top: anchor = top centre |
| FM_PARASOL | 149x170 | 74,169 | 1 | mid cut-out, striped parasol |
| FM_SACKS | 72x60 | 36,59 | 1 | mid cut-out, flour sacks |
| FM_SIGN | 91x130 | 45,129 | 1 | mid cut-out, signboard with an apple |
| FM_STALL_1 | 172x180 | 86,179 | 1 | mid cut-out, market stall (red/white awning, apples), anchor = bottom centre (stands on the floor line) |
| FM_STALL_2 | 176x180 | 88,179 | 1 | mid cut-out, vegetable stall (green/yellow awning) |
| FM_STALL_3 | 167x180 | 83,179 | 1 | mid cut-out, flower stall (blue/white awning) |
| FM_STALL_4 | 177x180 | 88,179 | 1 | mid cut-out, bakery stall (pink/white awning) |
| FM_STALL_5 | 171x180 | 85,179 | 1 | mid cut-out, cheese and milk stall (orange awning) |
| FM_WHEELBARROW | 109x70 | 54,69 | 1 | mid cut-out, wheelbarrow of pumpkins |
| FT_BODY1 | 32x96 | 0,0 | 1 | 3 rows of stone body, 1 column (32x96) |
| FT_BODY2 | 64x96 | 0,0 | 1 | same, 2 columns |
| FT_BODY4 | 128x96 | 0,0 | 1 | same, 4 columns |
| FT_BODY8 | 256x96 | 0,0 | 1 | same, 8 columns |
| FT_CART | 96x40 | 48,39 | 1 | handcart platform, 96x46, anchor bottom centre |
| FT_COUNTER2 | 64x32 | 0,0 | 1 | stall counter strip, 2 tiles (one-way platform like a shelf) |
| FT_COUNTER4 | 128x32 | 0,0 | 1 | same, 4 tiles |
| FT_COUNTER8 | 256x32 | 0,0 | 1 | same, 8 tiles |
| FT_CRATES2 | 64x32 | 0,0 | 1 | empty crates strip, 2 tiles |
| FT_CRATES4 | 128x32 | 0,0 | 1 | same, 4 tiles |
| FT_CRATES8 | 256x32 | 0,0 | 1 | same, 8 tiles |
| FT_FLOOR2 | 64x96 | 0,0 | 1 | floor strip of 2 columns (64x96) |
| FT_FLOOR4 | 128x96 | 0,0 | 1 | floor strip 4 columns |
| FT_FLOOR8 | 256x96 | 0,0 | 1 | floor strip 8 columns (256x96) |
| FT_FLOORCOL | 32x96 | 0,0 | 1 | a floor column: top + 2 bodies (32x96), like BG_FLOORCOL |
| FT_PAD | 70x31 | 35,28 | 3: taut, press, squash | awning bounce pad (3 frames: taut / press / squash), 70x31, anchor bottom centre |
| FT_TILES | 32x32 | 0,0 | 18: t0..t17 | the 32x32 tiles, frames t0..t17: t0 cobble top, t1 stone body, t2 apple crate, t3 orange crate, t4 pear crate, t5 grape crate, t6 empty crate (stackable), t7 stall counter (awning trim), t8..t11 ramps a b c d (same geometry as world 1), t12..t15 conveyor belt (4-frame animation: the chevrons slide 8 px a frame), t16 belt left end, t17 belt right end |

`FM_FAR` (far layer) is `art/w2/FM_FAR.png` 820x150, assets `FM_FAR_0..FM_FAR_5` (160 px columns), loops seamlessly (period 820).

Check: `python3 gen/w2_verify.py` (nothing cut), `raw/w2_mock.png` is a composed mock of a market scene.

## Polish round additions

| asset | w x h | anchor | frames | use |
|---|---|---|---|---|
| FE_MELON | 94x55 | 47,52 | 16: walk_0, walk_1, walk_2, walk_3, walk_4, walk_5, walk_6, walk_7, roll_0, roll_1, roll_2, roll_3, roll_4, roll_5, hurt_0, def_0 | real melon foe: walk_0..7, roll_0..5 (loop), hurt_0, def_0 (split in two halves, wide cell). Anchor soles |
| FI_PEEL | 50x30 | 25,27 | 2: peel, peel_shine | banana peel patch (replaces the code-drawn one): peel, peel_shine; stepping on it slips |
| FT_PAD | 70x37 | 35,34 | 3: taut, press, squash | REPLACED: strong hot-pink/white awning pad with a yellow up arrow: taut, press, squash (same name, 3 frames, anchor bottom centre) |
