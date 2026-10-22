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

- Calls: touch the numbered circle as its ring closes on it. B on the first screen skips them.
- Start: left/right or touch, A to confirm.
- Run: left/right to change line, A pushes (spends air), B eases (recovers it), C looks back, START pauses.

## Art

Everything you see is generated art made to match the concept pictures of the master plan, rebuilt with
`art/build_sprites.py` (actors and props, from `art/raw/*_gen.png`), `art/build_scenery.py` (street, cobbles,
side layers, scenes) and `art/build_ui.py` (panels, icons, photo props, logo, title picture, notebook). `ui/frame.lua`
draws the stretchable panels and the icons; the type is Jersey (10, 15, 25) in `fonts/jersey_*.fnt`. The chant's own pictures are the `CH_*` assets, copied from `games/ocho_mananas`.
`race/camera.lua` holds the numbers that make the Mode 7 road meet the kerbs painted in `STREET_REAR`.

## Pending

- The chant's melody is PROVISIONAL: the first line as an automatic pitch tracker heard it in a crowd recording, not confirmed by ear (see chant/song.lua). Replace with a verified transcription.
- Not tested on the Cirera: touch, audio latency, and the cost of drawing the actors as full-screen pictures.
- The balconies of the rear view's facade are fixed; only cobbles, lamps and banners move past.
