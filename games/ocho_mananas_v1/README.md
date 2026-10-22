# 07:59 · Ocho mañanas (Pinyol) — v1

The first morning: the three calls to the saint (07:55, 07:57, 07:59), choosing where to start, then the encierro
in Estafeta: a real race simulation (herd, runners, air and balance, ways out), a rear view with a glance back, a
cut to the side view, Nico's photo, and the review of the last seconds.

## Run

From the Pinyol repository root:

```sh
cmake -B build-mac && cmake --build build-mac --target pinyol_headless
build-mac/pinyol_headless --game games/ocho_mananas_v1 --fresh --validate --strict-assets
build-mac/pinyol_headless --game games/ocho_mananas_v1 --fresh --script games/ocho_mananas_v1/tests/flujo.script --strict-assets
```

Tests (`tests/*.script`): `flujo` (title to review), `canto` and `canto_fallo` (the calls, a late tap, the start choice),
`escenas` (the talking scenes), `lateral` (the side view's layers cover the screen), `galeria` (every actor at its
on-screen size). `python3 games/ocho_mananas_v1/art/qa_sprites.py` checks every sprite strip (cut frames, hopping feet,
breathing scale, stray fragments) and writes a contact sheet per asset to `art/qa/`. `tests/pilot.lua` has autopilots that play the run.

## Controls

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

Menus, scenes and the calls run at 52-60 fps; the race at about 30 (26-30 with the herd near, 19-21 when nine animals were drawn
at the camera, hence the cap on the animals drawn: up to 5, fewer when the frame runs long). Game time stays at 60 Hz because
the console catches up its ticks. Details and the cost of each element: `output/cirera/RESULTADOS.md`. The race is accepted at 30 fps.

## Pending

- The chant is Pau's MIDI (`san_fermin_16bit_v2_agudo.mid`, copied to `output/canto_referencias/pau/`): all 17 notes sung by the crowd in every call. What the player touches depends on the difficulty (`chant/chart.lua`): 5 circles on the first call of the first morning up to all 17, with followed, there-and-back and circled notes later. Only the first morning is built.
- Not tested on the Cirera: touch, audio latency, and the cost of drawing the actors as full-screen pictures.
- The balconies of the rear view's facade are fixed; only cobbles, lamps and banners move past.
