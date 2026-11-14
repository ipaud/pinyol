# SHIFT — iteration log

## Done

- Four distinct eras with gameplay and visual/audio changes.
- Persistent world state, SYNC/DESYNC, checkpoints, touch and physical controls.
- Continuous BOOT sector, guardian, destructible barrier, ending teaser.
- Packed animated NODI sprites and era backdrops use Pinyol demo art pipeline; gameplay still uses engine primitives. No engine changes.
- Headless regression script added.
- Applied supplied four-era visual direction; regenerated same-camera screenshots at shared landmarks.
- Replaced primitive NODI and scene backdrops with packed sprites and demo-derived layered art.

## Pending

- Play pacing and tune costs with a human; slice duration is not yet measured.
- Measure FPS/memory on Cirera and adjust effect budgets.
- Improve midair control feedback, landing feedback and guardian attack animation.
- Add visual/audio corruption hint near exit; currently only teaser language.
- Future era profiles: LCD, ZX Spectrum, GBA, vector, PS1.

## Known limitations

- Machines, doors and guardian still use primitive placeholder art; music remains synthesized.
- This first pass uses one broad tune phrase and discrete era timbres; audio does not crossfade at a shared musical bar.
- Vertical slice is shorter than 8–12 minutes until measured and expanded through playtesting.
