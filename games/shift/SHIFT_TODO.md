# SHIFT — iteration log

## Done

- Four distinct eras with gameplay and visual/audio changes.
- Persistent world state, SYNC/DESYNC, checkpoints, touch and physical controls.
- Continuous BOOT sector, guardian, destructible barrier, ending teaser.
- Code-drawn NODI/world; no added dependencies or engine changes.
- Headless regression script added.

## Pending

- Play pacing and tune costs with a human; slice duration is not yet measured.
- Capture/inspect all four era screens and transitions in simulator.
- Measure FPS/memory on Cirera and adjust effect budgets.
- Improve midair control feedback, landing feedback and guardian attack animation.
- Add visual/audio corruption hint near exit; currently only teaser language.
- Future era profiles: LCD, ZX Spectrum, GBA, vector, PS1.

## Known limitations

- Art and music are code-drawn/synthesized placeholders.
- This first pass uses one broad tune phrase and discrete era timbres; audio does not crossfade at a shared musical bar.
- Vertical slice is shorter than 8–12 minutes until measured and expanded through playtesting.
