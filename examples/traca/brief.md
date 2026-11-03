# Traca: the brief (decided without asking: Pau said "decide yourself")

- Look: `vertical` (1985 cabinet with the monitor stood up). Replaces `examples/tormenta` once measured on the board.
- Graphics: drawn by code (`gen/art.py`, letters as text and PIL shapes), all packed; no image model.
- Logo: by code, the arcade_80s title font with a gradient, an outline and a shadow (`text` styles). Cover: composed for the wide menu by `gen/cover.py` (the game stands up, so a shot would lie on its side in the menu).
- Universe: our own. A firework rocket climbs a Valencian village's fiesta night to burst as the last palmera; paper lanterns, bats, fair balloons, drunk rockets, the bell tower's bell and the fair's cardboard moon. Tender humour: a granny waving from her balcony, a cat on a roof, the moon with a plaster, a constellation shaped like a paella pan.
- Where it lives: the web demo and the card (es/ca/en, a cover, a test); small art (about 100 KB of packed pictures).
- Canvas: 160x240 standing, shown `img("V", 80, -80, {angle = 90, scale = 2})`, not the 320x480 that docs/art.md and looks.json name: docs/measurements.md says clearing a 320x480 canvas cost 18 ms a frame and the turned blit is fastest at scale 2 (tormenta, 60 fps). Fonts made at one pixel a font pixel (`gen/fonts.py`) for that canvas.
- Controls (the console held on its side, its left edge down): arrows turned (console RIGHT = up, DOWN = right), A fire (held), B slow, C a traca (bomb).
- Five stages: the rooftops, the bell tower (the bell, a mid-boss, stops the climb), the clouds, the stars, the cardboard moon (three moods). About 3.8 minutes for a perfect player.
- Extras: powder bags that change colour when shot (red more fire, green a traca, blue a shield), grazes that fill a fuse for a new traca, extends at 30 000 and 100 000, three credits (two continues, the score back to nought, as cabinets did).
- Eight achievements; "Cómo funciona" in the console's menu, four pages; a demo that plays itself from the title (the pilot thinks every 2 ticks); the record kept with `store`.
- reduce_flashing: no blinking words, no red wash on a hit, a steady ring instead of the blinking rocket, the palmera's light at a quarter.
- Sound: three tone voices (square, triangle, noise) on a step counter, a pasacalle, a tune in A minor for the moon, a fanfare; effects from numbers.
