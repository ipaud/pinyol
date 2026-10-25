# Look: Super Nintendo · Mega Drive (1991 · speed and per-line scroll)

Start from `examples/veloz`. World: 240x160. Art: code. Style line: *16-bit console pixel art, 15 colours per sprite, bold outlines, saturated colours, no anti-aliasing*.

## Do
- sprites up to 32x32 (bigger in a few), 15 colours each or fewer
- Mega Drive: far layers at a different speed per line (line_scroll); SNES: line_backdrop sky, blend water, mosaic between scenes, Mode 7 floors

## Avoid
- anti-aliased edges

The template's room, hero and gems (`art.py`, `room.lua`, `art/`, `assets/`) are placeholders in no look: replace them with art made by these rules.

Limits (checked by `uv run tools/look_check.py examples/poncho`): {"pal_bank_colours": 15, "sprite": [64, 64]}.
Rules in full: docs/art.md, section 'Choose a look'.
