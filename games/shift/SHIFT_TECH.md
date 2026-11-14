# SHIFT — technical notes

## Runtime and audit

Pinyol's local instructions and both README files identify Lua games under `games/<id>`. `docs/lua.md` and examples `plataformas`, `bolsillo`, `duelo`, and `calle` confirm 240×160 world drawing, 480×320 text/UI, 60 Hz `_update`, `btn/btnp/btnb`, touch, primitive shapes, `tone/sound/sfx`, and built-in effects/juice/particles. Pinyol has actual Game Boy, 16-bit, CPS2 and ZX Spectrum examples, but no reusable generic Era API. This game keeps era-specific rules local. No motor changes.

## Modules

- `main.lua`: loop, movement, collisions, level, asset rendering, HUD, input.
- `world.lua`: authoritative switch, checkpoint, enemy HP, wall and unlock state; functions map entity IDs to visibility/collision.
- `era.lua`: four era definitions and availability/cycling rules.
- `audio.lua`: one tune step counter, era-specific timbre, shift cue and SFX registration.
- `art.py`: source PNGs to compact packed backgrounds and four-frame NODI sheets via `tools/png2asset.py`.

`fresh()` resets world as a new session. `world.guardian_hp`, `world.wall_broken`, `world.switch`, `world.exit_open`, and `world.checkpoint` are logical state; drawing and collision query these values on each frame. Era switching carries player coordinates and velocity. A shift into overlapping solid geometry is refused.

## Add an era

Add one entry to `Era.list`, add an index in `Era.index`, and update `World.visible/solid` only for entities whose rules differ. Add a rendering branch in `draw_backdrop`, `draw_floor`, and `draw_player`, then map its sound timbre in `audio.lua`. Keep persistent state in `world.lua`; do not create a second level or reset entity state on shift.

## Controls and hardware

D-pad, A, B, C map to documented Cirera inputs. `touch()` supports swipe and era strip selection. Backgrounds and animated NODI use Pinyol's packed-image pipeline: recolored mountain/hill art from `examples/plataformas`, arcade street art from `examples/calle`, and a four-era generated sprite sheet. Gameplay collision and persistent state remain independent of these visuals. Effects use Pinyol's existing `mosaic`, `haze`, `juice`, and `particles`; no C API or engine allocation changes.

## Launch and tests

Run `uv run games/shift/art.py` to rebuild runtime art, then use simulator/headless commands in [README.md](README.md). `tests/shift.script` checks boot, unlocks, one-world persistence and ending. Cirera hardware profiling and physical controls remain pending; desktop/headless cannot establish device frame pacing or memory headroom.

Host Lua profile:

```sh
./build/pinyol_headless --game games/shift --fresh --script games/shift/tests/visuals.script --profile /tmp/shift.folded
```
