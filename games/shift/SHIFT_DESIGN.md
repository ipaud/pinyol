# SHIFT — design

**SAME WORLD. DIFFERENT RULES.** SHIFT is an action platformer about reading one place through four generations of hardware. Era shifts change what exists, what collides, how NODI moves, and how the same musical phrase sounds.

## Sector 01 — BOOT

Brief system boot leads straight into play. The player crosses an industrial memory-space, learns to pass a machine that 8-bit hardware cannot represent, climbs Game Boy-only micro-platforms to reach a 16-bit switch, then enters Arcade combat. Destroyed guardian/barrier state and the opened route persist. Checkpoints restore progress and recover SYNC. Exit gives a short future-modes teaser.

## Era roles

| Era | Rule | Slice behavior |
|---|---|---|
| 8-BIT | simplify | Machine ceases to exist and stops colliding; coarse shapes and square-wave tune |
| GAME BOY | precision | Extra stepping stones bridge two pits; tighter, quicker movement and four-tone look |
| 16-BIT | understand | Richest scene; shared machine, switch, guardian and route are legible |
| ARCADE | force | Stronger movement and strikes; guardian loses persistent health; barrier breaks permanently |

## Visual direction

The supplied blueprints define one camera-sized slice of the same route, rendered with distinct hardware readings. 8-bit uses four bold colors and block silhouettes; Game Boy uses four green tones and precision platforms; 16-bit adds blue sky, clouds, hills and foliage; Arcade uses a dense night skyline, lit windows and hazard accents. Shared landmarks keep identical world coordinates and collision rules.

Adjacent shifts cost 10 SYNC; a two-era jump costs 18. SYNC recovers slowly, at checkpoints, and on key actions. At zero, DESYNC picks a neighboring unlocked era, restores 42 SYNC and briefly locks shifts. Shift is rejected if newly solid geometry would overlap NODI.

## World rules

One entity state is authoritative. Era code only interprets that state: machine visibility/collision follows era; micro-platform collision exists in Game Boy; switch changes one shared route flag; guardian HP and broken wall survive all era changes. No duplicated maps or per-era progression.

## Feel and tone

NODI is a seed-shaped digital creature with era-specific packed sprite sheets. The 16-bit backdrop reads as a layered landscape; Arcade shifts the same route into a dense neon street; 8-bit and Game Boy reduce those layers to four tones. Landmarks keep shared coordinates and collision, so scenery deepens each hardware reading without creating alternate level state. Environment source art comes from Pinyol examples; NODI is original generated art.
