# 07:59 · Ocho mañanas (Pinyol) — v1

The whole campaign of the plan: eight mornings (7 to 14 July). Each one is a scene, the three calls to the saint (the whole chant,
harder every morning), choosing where to start, a briefing (with a choice of stretch on days 4, 7 and 8), the encierro (a real race
simulation: herd, runners, air and balance, ways out, rear and side views, a glance back), the review of the last seconds, the result
with the day's challenges, a closing scene that depends on how it went, and a notebook page. The last morning has three endings
(`story/days.lua`: the complete sequence, the photo he wanted, another morning). Data per morning: `data/days.lua`.

## Run

From the Pinyol repository root:

```sh
cmake -B build-mac && cmake --build build-mac --target pinyol_headless
build-mac/pinyol_headless --game games/ocho_mananas_v1 --fresh --validate --strict-assets
build-mac/pinyol_headless --game games/ocho_mananas_v1 --fresh --script games/ocho_mananas_v1/tests/flujo.script --strict-assets
```

Tests (`tests/*.script`): `campana` (a bot, `tests/bot.lua`, plays mornings 1 to 8 through the real flow and checks the save moves on), `flujo` (title to review), `canto` and `canto_fallo` (the calls, a late tap, the start choice),
`escenas` (the talking scenes), `lateral` (the side view's layers cover the screen), `galeria` (every actor at its
on-screen size). `python3 games/ocho_mananas_v1/art/qa_sprites.py` checks every sprite strip (cut frames, hopping feet,
breathing scale, stray fragments) and writes a contact sheet per asset to `art/qa/`. `tests/pilot.lua` has autopilots that play the run.

## Controls

- Title: left and right pick the morning among those reached (replay any). Briefing: left and right pick the stretch.
- Calls: touch the numbered circle as its ring closes on it; on long notes, follow the circle with a finger, go and come back along it, or circle the last one until the lights fill. B on the first card skips the calls.
- Start: left/right or touch, A to confirm.
- Run: left/right to change line, A pushes (spends air), B eases (recovers it), C looks back, START pauses.

## Art

Everything you see is generated art made to match the concept pictures of the master plan, rebuilt with
`art/build_sprites.py` (actors and props, from `art/raw/*_gen.png`), `art/build_scenery.py` (street, cobbles,
side layers, scenes) and `art/build_ui.py` (panels, icons, photo props, logo, title picture, notebook). `ui/frame.lua`
draws the stretchable panels and the icons; the type is Jersey (10, 15, 25) in `fonts/jersey_*.fnt`. The chant's own pictures are the `CH_*` assets, copied from `games/ocho_mananas`.
`race/camera.lua` holds the numbers that make the Mode 7 road meet the kerbs painted in `STREET_REAR`.

## Performance (measured on the Cirera, 2026-10-22)

Menus, scenes and the calls run at 52-60 fps. The race runs at about 30 (26-30) and drops to 20-24 for the moments when several
animals are at the camera: drawing any of the herd costs the frame 3 to 7 ms however many (3 to 9) or how big. Only the five nearest
are drawn, and an animal at the camera stops growing at 1.6 times its size. The race is accepted at 30 fps. Game time stays at 60 Hz
because the console catches up its ticks. Measured but not understood: a race scene stays at 20 fps for its first ~25 s and then
settles at 30; pre-drawing every picture before it did not change that. Details: `RENDIMIENTO.md`.

## Pending

- The chant is Pau's MIDI (`san_fermin_16bit_v2_agudo.mid`, copied to `output/canto_referencias/pau/`): all 17 notes sung by the crowd in every call. What the player touches depends on the difficulty (`chant/chart.lua`): 5 circles on the first call of the first morning up to all 17, with followed, there-and-back and circled notes later.
- Not tested on the Cirera: touch, audio latency, and the cost of drawing the actors as full-screen pictures.
- The balconies of the rear view's facade are fixed; only cobbles, lamps and banners move past.
