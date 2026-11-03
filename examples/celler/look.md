# Look: First person (1992 · Wolfenstein 3D)

Start from `examples/laberinto`. World: 240x160 raycast canvas shown twice as big under a status bar. Art: code. Style line: *early 1990s raycaster, 32x32 or 64x64 wall textures, 32x32 sprites in the maze*.

## Do
- raycast() onto a 240x160 canvas shown twice as big
- walls are 32x32 (or 64x64) textures, sprites 32x32 pictures standing in the maze

## Avoid
- textures bigger than 64x64

The template's room, hero and gems (`art.py`, `room.lua`, `art/`, `assets/`) are placeholders in no look: replace them with art made by these rules.

Limits (checked by `uv run tools/look_check.py examples/celler`): {"sprite": [64, 64]}.
Rules in full: docs/art.md, section 'Choose a look'.
