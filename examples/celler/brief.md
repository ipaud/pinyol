# El Celler: brief

Decided without asking (Pau: "hazlo todo sin preguntar").

- Look: firstperson (1992, raycaster), the demo that replaces examples/laberinto.
- Graphics: drawn by code (art.py): 64x64 wall textures, 32x32 things standing in the maze, hands and icons packed, the face an indexed PPU sprite.
- Logo: by code, the dos_vga title font with a gradient; no generated pictures.
- Universe: our own. A night watchman (sereno) at Cal Rovelló, a cava cellar of a Penedès village; the cava corks have come out of their bottles as
  ghosts that blow out candles. Non-violent: a toy fairground cork gun turns them back into corks, which are picked up again.
- Cover: the title at 118 ticks (the barrel hall, a ghost cork floating), tools/cover.py --at 118.
- Where it lives: the card and the web (es/ca/en, cover, test); no big raw pictures drawn with img.
- Size: five galleries (ramp, bottle racks, barrel hall, riddling racks, old well), about 2.5 min for a perfect player, 4-6 for a person.
- Controls: d-pad walk/turn (B held: step aside), A cork, B open/lever/push, C held lantern up, START map.
- Rules: the candle is the fog distance (it burns down; a fresh one at every stair, candles on the floor, 3 matches relight it);
  a ghost cork that reaches you blows 18 % of it; the lantern held up sees further and scares them but burns 2.5x.
- Era tricks used that laberinto did not: doors that slide in their frames with jambs (engine: raycast doors, this branch), a secret rack,
  levers and gates, grid fov for the map (revealed by the candle's reach), grid sees/distances/rescan for the ghost corks (chase, flee),
  lib/light on the status bar's face (palette entries as surfaces, lit by the flame), voxels for the dawn over the vineyards,
  AdLib-style FM music (tone wave "fm") and lib/voice blips for the gallery cards.
- How it works (menu): the rays on the map and the view built column by column; a column's numbers (distance, height, texture column,
  light); doors and things drawn far to near behind the z-buffer.
- Achievements (9): primera_llave, taponazo, espantar, reserva, cartografo, todos, una_vela, amanecer, curioso.
- Tests: tests/celler.script (by hand, then bot.lua: the same buttons), tests/playtest.lua (perfect = bot.lua), finish_game.
