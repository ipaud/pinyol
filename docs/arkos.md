# pinyol on ArkOS handhelds: R36S, RG351 and the rest

ArkOS, and the systems made from it that cheap handhelds like the R36S come with, play games through RetroArch, and
pinyol is a libretro core ([libretro.md](libretro.md)). One zip installs it with the site's games, as a system of
its own in the menu, with each game's cover:
[pinyol-arkos.zip](https://github.com/ipaud/pinyol/releases/download/libretro/pinyol-arkos.zip).

Tested on an R36S clone ("R36S V5", RK3326) with its ArkOS-based system, theme Cyber2077: installed, every game in
the list, played. Any other ArkOS handheld (RG351P/M/V, RGB10, RK2020, the R36S family) should take it the same way;
if yours does not, [say so](https://github.com/ipaud/pinyol/issues) with `ports/pinyol/install-log.txt`.

## Install it

1. Take the microSD out of the handheld and put it in a computer. Of its partitions, open `EASYROMS` (the one with
   a folder per system: `gba`, `nes`, `ports`...).
2. Unzip `pinyol-arkos.zip` into it, as it is: its `ports/` and `pinyol/` go beside the ones there (`ports/` already
   exists; nothing in it is replaced).
3. Put the card back, start the handheld and open **Ports → Instalar Pinyol**. It takes a few seconds; the menu
   restarts by itself and **Pinyol** is there, with the games.

Once is enough. To update, unzip a newer `pinyol-arkos.zip` on top and run *Instalar Pinyol* again: it puts the new
core and art in and leaves the system as it is.

## What the installer does

`ports/pinyol/install.sh` (here `platform/libretro/arkos/install.sh`):

- copies the core into RetroArch's cores folder (`~/.config/retroarch/cores`);
- adds a `<system>` for Pinyol to EmulationStation's `es_systems.cfg` (`~/.emulationstation/` if there is one,
  `/etc/emulationstation/` otherwise). It backs the file up first as `es_systems.cfg.antes-de-pinyol`, copies how the
  `gba` system starts RetroArch, and adds its block before `</systemList>` as text, leaving every other byte as it was
  (ArkOS's file is not always well-formed XML, and EmulationStation reads it all the same). If anything goes wrong it
  puts the backup back and says so on the screen;
- copies pinyol's art into each theme of the card that it knows (Cyber2077, Epic, Epic Noir, Woody-Cody, Arkos Carbon,
  Switch, Switch Black, NES-box, Freeplay, Simple, Simple Comic Book): the system's poster, logo and console. A theme
  it does not know shows Pinyol with its name only;
- restarts EmulationStation.

Everything it does goes into `ports/pinyol/install-log.txt`, on the card.

## Playing

The d-pad moves; A is A, B is B, X or Y is C, START is START and SELECT is MENU. SELECT and START together leave the
game, as in every system of ArkOS. Saves go where RetroArch keeps them.

The handheld's screen is 640×480 and pinyol draws 480×320: the picture is scaled, with bands above and below. The
R36S has no touch screen, so the games that need one cannot be played there.

More games: any game's `.zip` or `.pinyol` (the site and the Library have their downloads) goes into `pinyol/` on
the card. Without a line in `pinyol/gamelist.xml` it shows with its file's name and no cover.

## Making the zip

```sh
python3 platform/libretro/arkos/make_kit.py pinyol_libretro-linux-arm64.zip    # -> dist/pinyol-arkos.zip
```

The core is the release's (`gh release download libretro -p pinyol_libretro-linux-arm64.zip`), or one built for
arm64 Linux (`platform/libretro/release.sh arm64`). The games are the ones the site plays (`site/page.py`,
`example_ids`), each packed by `tools/pack_game.py`, with its `cover.rgb565` as its picture. The workflow
`.github/workflows/arkos.yml` makes it again whenever the release gets a new core, and when the kit or the games
change, and uploads it to the release `libretro`.

The themes' art is in `platform/libretro/arkos/themes/<theme>/`, at the paths each theme reads (`_art/posters/`,
`_art/controllers/`, `<system>/theme.xml`...). All of it is pinyol's: the seed, the Cirera, the logo and the games'
screens; none of the themes' own pictures.
