#!/bin/sh
# The README's pictures of each look: a moment of play in each look's example, taken by the headless player.
#   sh docs/looks/shots.sh      (after cmake --build build; needs uv for the PNGs)
set -e
cd "$(dirname "$0")/../.."
tmp=$(mktemp -d)
shot() { # shot NAME GAME, the script's lines on stdin; it ends with "shot NAME"
  cat > "$tmp/$1.script"
  ./build/pinyol_headless --game "examples/$2" --saves "$tmp/$1" --fresh --script "$tmp/$1.script" >/dev/null
  uv run --quiet --with pillow python3 -c "from PIL import Image; Image.open('$tmp/$1/$1.ppm').save('docs/looks/$1.png', optimize=True)"
}
printf 'tick 5\nlua require("core.title").leave() require("core.game").reset() G.state = "play" require("core.hud").init() require("core.pal").fade("dark", 0)\nlua require("core.play").enter("overworld", 24, 16, "up")\ntick 40\nshot gameboy\n' | shot gameboy cerezo
printf 'tick 440\npress A\ntick 10\npress A\ntick 40\nhold RIGHT 20\ntick 10\nshot spectrum\n' | shot spectrum socavon
printf 'tick 5\nlua dbg_level(1)\ntick 30\nlua dbg_tp(43, 10)\ntick 40\nshot gba\n' | shot gba botin
printf 'tick 90\npress A\ntick 60\nlua D.tp(400)\nhold RIGHT 90\nin 16 RIGHT+A\nshot 16bits\n' | shot 16bits poncho
printf 'tick 5\nlua dbg_play("pinche", 3300)\ntick 20\nlua dbg_tractor()\ntick 60\nlua dbg_foe("soldier", -120)\nlua dbg_foe("drone", -30)\nlua dbg_foe("soldier", 40)\ntick 25\nhold RIGHT+A 20\nshot neogeo\n' | shot neogeo paella
printf 'tick 5\nlua dbg_play("tomas", 1, 300)\nlua dbg_god()\ntick 10\nlua dbg_foe("rodete", "r", 270)\nlua dbg_foe("resorte", "r", 290)\nlua dbg_part("hammer") require("core.play").banner_t = 0\nhold RIGHT 70\npress A\ntick 8\npress A\ntick 4\nshot cps2\n' | shot cps2 taller
printf 'tick 20\npress A\ntick 3\npress A\ntick 40\npress DOWN\ntick 46\nshot pico8\n' | shot pico8 tumba
printf 'tick 20\npress A\ntick 5\nhold LEFT+RIGHT 200\nshot lcd\n' | shot lcd malabar
printf 'tick 20\npress A\ntick 5\nlua G.begin_level(7)\ntick 200\nhold LEFT 20\npress A\ntick 8\nshot vector\n' | shot vector pozo
printf 'tick 30\npress A\ntick 2\nhold A 520\nshot vertical\n' | shot vertical traca
printf 'tick 30\npress A\ntick 30\npress A\ntick 5\npress A\ntick 40\nhold UP 50\nshot firstperson\n' | shot firstperson celler
printf 'tick 400\nshot loading\n' | shot loading socavon
printf 'tick 40\nlua dbg_floor(2)\ntick 100\nlua dbg_bot(true)\ntick 420\nshot 32bits\n' | shot 32bits faro
printf 'tick 40\nlua dbg_floor(4)\ntick 100\nlua dbg_bot(true)\ntick 1900\nshot 32bits_boss\n' | shot 32bits_boss faro
rm -rf "$tmp"
