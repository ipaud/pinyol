# World 4 (the keyboard stage) and BOSS_SILENCIO: the assets

Made by `gen/w4_*.py` (image model, same pipeline as worlds 1 to 3). Sizes, anchors and frames are in `data/deco4.lua` (same format as `data/deco.lua`); far layer columns in `data/km_far_slices.lua`.
Packed 8-bit, 32 colours; a strip in `pieces` is `<ID>_C<n>`. Total about 1.32 MB (far 0.16, cut-outs 0.50, boss 0.67).

| asset | w x h | anchor | frames | use |
|---|---|---|---|---|
| BOSS_SILENCIO | 240x190 | 120,187 | 33: idle_0..5, shh_0..5, swallow_0..5, hurt_0..2, angry_0..3, stun_0..3, def_0..3 | final boss EL GRAN SILENCIO (~170 px, cell 240x190, anchor soles; in pieces): idle_0..5, shh_0..5 (finger up, last two frames the flat stop hand), swallow_0..5 (mouth opens wide at 2..3, gulps), hurt_0..2, angry_0..3, stun_0..3 (dizzy, small colour stars; draw bigger bursts in code), def_0..3 (shrinks to a small smiling cloud; def_3 is the smallest) |
| KE_BUBBLE | 96x103 | 48,51 | 10: float_0..7, def_0..1 | flyer (shh cloud; anchor = body centre): float_0..7, def_0..1 |
| KE_CABLE | 92x56 | 46,53 | 13: slide_0..7, coil_0..2, def_0..1 | slider (cable snake): slide_0..7, coil_0..2 (coiled, can be a stompable pause), def_0..1 (soles) |
| KE_NOTE | 70x71 | 35,68 | 10: hop_0..7, hurt_0, def_0 | hopper (bouncing eighth note): hop_0..7, hurt_0, def_0 (soles) |
| KE_SPEAKER | 68x72 | 34,69 | 10: pulse_0..5, shout_0..1, hurt_0, def_0 | stationary shooter: pulse_0..5, shout_0..1 (fire the sound ring in code), hurt_0, def_0 (soles) |
| KI_COIN | 40x41 | 20,20 | 8: spin_0..7 | golden note coin spin_0..7, anchor centre |
| KI_FLAG | 164x154 | 82,151 | 4: wave_0..3 | goal flag wave_0..3 (2 distinct drawings A B A B), anchor pole base |
| KI_KEYBOARD | 120x85 | 60,84 | 6: idle_0..1, play_0..3 | checkpoint: mini keyboard on a stage riser: idle_0, idle_1, play_0..3 (riser lights brighter when playing). Anchor bottom centre |
| KI_LOLLI | 58x48 | 29,24 | 2: heart, star | pickups: heart, star (anchor centre) |
| KM_CABLE | 52x40 | 26,39 | 1 | cable loop on the floor |
| KM_CASES | 71x90 | 35,89 | 1 | mid cut-out, flight cases |
| KM_CLEF | 57x130 | 28,129 | 1 | mid cut-out, neon treble clef |
| KM_CURTAIN | 99x230 | 49,0 | 1 | hanging curtain with tassel (anchor top centre) |
| KM_DISCO | 52x100 | 26,0 | 1 | hanging disco ball (anchor top centre) |
| KM_DRUMS | 213x120 | 106,119 | 1 | mid cut-out, drum kit |
| KM_EQ | 167x110 | 83,109 | 1 | mid cut-out, equaliser bars (static) |
| KM_FORE_JACK | 90x78 | 0,0 | 1 | foreground, jack cable |
| KM_FORE_MIC | 67x90 | 0,0 | 1 | foreground cut-out (anchor top-left) microphone |
| KM_FORE_NOTES | 54x70 | 0,0 | 1 | foreground, gold notes |
| KM_FORE_PHONES | 56x80 | 0,0 | 1 | foreground, headphones |
| KM_FORE_PICK | 43x50 | 0,0 | 1 | foreground, guitar pick |
| KM_FORE_STICKS | 100x130 | 0,0 | 1 | foreground, drumsticks |
| KM_LIGHTS | 104x90 | 52,0 | 1 | hanging light string (anchor top centre) |
| KM_MIC | 89x150 | 44,149 | 1 | mid cut-out, mic stand |
| KM_MONITOR | 99x60 | 49,59 | 1 | mid cut-out, stage monitor |
| KM_NOTEPINK | 102x50 | 51,25 | 1 | floating pink note pair |
| KM_NOTES16 | 147x56 | 73,28 | 1 | floating cyan sixteenth notes |
| KM_NOTES2 | 59x60 | 29,30 | 1 | floating gold eighth notes (anchor centre) |
| KM_PIANO | 139x120 | 69,119 | 1 | mid cut-out, grand piano |
| KM_SPEAKERS | 87x180 | 43,179 | 1 | mid cut-out, 2-speaker stack (anchor bottom centre) |
| KM_SPOT | 68x170 | 34,169 | 1 | mid cut-out, spotlight tripod |
| KM_TRUMPET | 34x80 | 17,79 | 1 | mid cut-out, trumpet |
| KT_BODY1 | 32x96 | 0,0 | 1 | body 1 column |
| KT_BODY2 | 64x96 | 0,0 | 1 | 2 columns |
| KT_BODY4 | 128x96 | 0,0 | 1 | 4 columns |
| KT_BODY8 | 256x96 | 0,0 | 1 | 8 columns |
| KT_CART | 96x66 | 48,65 | 1 | moving platform: rolling flight case (96x66, anchor bottom centre) |
| KT_COUNTER2 | 64x32 | 0,0 | 1 | stage-plank strip 2 tiles (one-way) |
| KT_COUNTER4 | 128x32 | 0,0 | 1 | 4 tiles |
| KT_COUNTER8 | 256x32 | 0,0 | 1 | 8 tiles |
| KT_CRATES2 | 64x32 | 0,0 | 1 | plain flight cases strip, 2 |
| KT_CRATES4 | 128x32 | 0,0 | 1 | 4 |
| KT_CRATES8 | 256x32 | 0,0 | 1 | 8 |
| KT_FLOOR2 | 64x96 | 0,0 | 1 | floor strip 2 columns |
| KT_FLOOR4 | 128x96 | 0,0 | 1 | 4 columns |
| KT_FLOOR8 | 256x96 | 0,0 | 1 | 8 columns |
| KT_FLOORCOL | 32x96 | 0,0 | 1 | floor column (32x96) |
| KT_PAD | 70x47 | 35,44 | 3: taut, press, squash | bounce pad: drum skin taut / press / squash (anchor bottom centre) |
| KT_TILES | 32x32 | 0,0 | 18: t0..t17 | 32x32 tiles t0..t17 (same layout as FT_/CT_): t0 white key top, t1 key front, t2 black key block, t3 speaker cube, t4 note case, t5 heart case, t6 plain flight case (stackable), t7 stage plank with lights, t8..t11 ramps a b c d (piano-key stripes), t12..t15 conveyor belt (4-frame animation), t16 belt left end, t17 belt right end |

## Polish round additions

| asset | w x h | anchor | frames | use |
|---|---|---|---|---|
| KT_FLOORKEY | 32x96 | 0,0 | 2: blackkey, pressed | 32x96 floor columns with a raised black key (blackkey) and a pressed key sunk (pressed): drop-in for KT_FLOORCOL |
| KM_LIGHTS | 180x79 | 90,0 | 1: KM_LIGHTS | REPLACED: bigger light string (180x79, anchor top centre) |
| KI_FLAG | 104x154 | 21,151 | 4: wave_0, wave_1, wave_2, wave_3 | REPLACED: 4 distinct waves wave_0..3 |
| FX_BURST | 124x115 | 62,57 | 4: burst_0, burst_1, burst_2, burst_3 | stun burst effect for BOSS_SILENCIO: burst_0..3 (small flash, star ring, wide ring, fading sparkles), centre anchor 124x115 |
