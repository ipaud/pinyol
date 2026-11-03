# El Faro de las Ánimas: brief

The flagship demo of the `32bits` look (PlayStation · Saturn 2D, 1997), to replace `examples/gotico` once it is measured on the board.
Pau said to make it without asking: every decision below was taken here, one line each.

- **Universe**: our own. A stormy night on the Cap de les Ànimes, a Catalan fishing village; the lighthouse lamp has gone out. Estel, the keeper's
  daughter (yellow oilskin, red scarf, her grandfather's brass lantern), climbs the tower. The ánimas of drowned fishermen (striped jerseys,
  barretina caps, pipes) are not evil, only lost: wild they chill her, calm in the raised lantern they follow her to the window and go to sea.
  At the top, El Pop de la Tempesta, an octopus of storm cloud as big as the cape, has put the lamp out; tender ending (it swims off, dazzled
  and embarrassed, and a little light goes with the boats under the water since). Habaneras for the music: the sea songs of that coast.
- **Graphics**: the image model (gpt-image through the codex bridge), 17 calls (16 + the octopus asked again without a village on its head);
  prompts in `gen/gpt_jobs.py`, raw pictures in `raw/` (ignored), cut and fitted by `gen/gpt_make.py` into `art/`, packed by
  `tools/build_art.py` from `art.json`. Everything 8 bits packed (`--packed`), pictures at the screen's own 480x320.
- **Logo**: by code, the look's title font (Cinzel Decorative) with a gradient: it must read in es/ca/en, and a picture is one language.
- **Cover**: the title screen (the lighthouse dark in the storm, the title), `tools/cover.py` at a moment chosen by hand.
- **Where it lives**: the card and the web demo (es/ca/en, cover, test). 2.3 MB packed pictures, about 0.9 MB of sound.
- **Play**: a platformer by floors, four floors and the lantern room, 2-5 minutes. ‹ › walk, A (or up) jumps, B (or C) held raises the
  lantern (slower walk, no jumping, burns oil that refills when lowered). Four warmths (flames), three matches (a match lost = the floor again;
  none = game over). Floors: 1 the boats (tutorial, 1 ánima), 2 the cistern (water below, barrels that bob, 2 ánimas), 3 the clockwork
  (gears turning as quads, 3 ánimas, 2 needed), 4 the gallery outside (rain, gusts of wind every 7 s, ánimas from the sea that go off by
  themselves), 5 the lantern room (take fire from a pilot flame, carry it up to the lamp, three wicks, tentacles burst up where you stand).
- **The era's trick shown**: light and transparency on what moves (ánimas alpha 0.55; calm ones add their light; `light()` for the lantern,
  the wall lamps, the windows when lightning strikes; the room darkened through its palette, free); `quad()` for the gears (lit corners,
  `dither = true`), the tentacles (four quads along a bending spine, `uv`), the lens that turns; `distort(..., {screen = true})` over the
  cistern's water with Estel's reflection (flipped, alpha); `crt` as a title option; `grad(..., {dither = true})` for the oil gauge and
  panels; the `blocks` transition (the PlayStation's tile dissolve) between floors.
- **Sound**: every effect a `.vag` (ADPCM) made by code (`gen/sfx.py`), rain and sea as `.spum` streams, songs as MIDI on a bank
  (`gen/songs.py`, Taller's bank pruned to the instruments used: accordion, nylon guitar, upright bass, strings, flute, music box, bell,
  glockenspiel, pizzicato, timpani, brass), and ONE reverb room for all of it (`reverb("hall")` inside, `studio_large` outside).
- **How it works** (title item and console menu item): four pages, light that adds up, quads, water on the screen + crt, sound in a room.
- **Achievements** (7): primera, seca, abrigada, todas, faro, alba, curiosa. **Record**: the best time (`store("best")`).
- **Demo**: after 15 s on the title the game's own bot plays a floor. **Bot**: `core/bot.lua` on `core/route.lua` (jumps flown ahead with
  Estel's own body); the playtest adapter is `tests/playtest/faro.lua`, `-- playtest-gate: win`.
- **reduce_flashing**: lightning brightens the room to a third as much; a lightning is one flash every 7-13 s, never a strobe.
- **Not done here (needs the board)**: fps, the cost of `distort(screen = true)` (not measured on the console yet), crt's cost, the
  quads' and lights' budget in the lantern room.
