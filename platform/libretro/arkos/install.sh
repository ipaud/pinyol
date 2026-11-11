#!/bin/bash
# Installs pinyol as a system of its own in ArkOS's EmulationStation (R36S, RG351 and the other ArkOS handhelds).
# Run once from Ports ("Instalar Pinyol"), from the card's ports/pinyol/ that pinyol-arkos.zip unpacks (docs/arkos.md):
# the core into RetroArch's cores folder, a <system> block into es_systems.cfg (backed up first, restored on any
# error), pinyol's art into the themes the card has, then EmulationStation restarts. Running it again updates the core
# and the art and leaves es_systems.cfg as it is.
DIR="$(cd "$(dirname "$0")" && pwd)"
PORTS="$(dirname "$DIR")"
ROMS="$(dirname "$PORTS")"
LOG="$DIR/install-log.txt"
exec > >(tee "$LOG") 2>&1
sudo chmod 666 /dev/tty1 2>/dev/null
say() { echo "$*"; echo "$*" > /dev/tty1 2>/dev/null; }
fail() { say "ERROR: $*"; say "Nada cambiado. Log: ports/pinyol/install-log.txt"; sleep 8; exit 1; }
printf '\033c' > /dev/tty1 2>/dev/null
say "Instalando Pinyol... $(date)"

# A Mac copying the zip onto the card leaves ._ files beside each one: the menu would list them as games
find "$ROMS/pinyol" "$PORTS" -maxdepth 1 -name '._*' -delete 2>/dev/null

command -v python3 >/dev/null || fail "no hay python3"
[ -f "$DIR/pinyol_libretro.so" ] || fail "falta pinyol_libretro.so"

# The file EmulationStation reads: the user's copy wins over the system one.
CFG="$HOME/.emulationstation/es_systems.cfg"
[ -f "$CFG" ] || CFG=/etc/emulationstation/es_systems.cfg
[ -f "$CFG" ] || fail "no encuentro es_systems.cfg"
say "es_systems: $CFG"

CORES="$HOME/.config/retroarch/cores"
[ -d "$CORES" ] || fail "no existe $CORES"
cp "$DIR/pinyol_libretro.so" "$CORES/" || sudo cp "$DIR/pinyol_libretro.so" "$CORES/" || fail "no puedo copiar el core"
cp "$DIR/pinyol_libretro.info" "$HOME/.config/retroarch/info/" 2>/dev/null
say "core -> $CORES"

if grep -q '<name>pinyol</name>' "$CFG"; then
  say "El sistema Pinyol ya estaba en es_systems.cfg"
else
  BAK="$CFG.antes-de-pinyol"
  [ -f "$BAK" ] || sudo cp "$CFG" "$BAK" || fail "no puedo hacer copia de seguridad"
  TMP="$(mktemp)"
  cp "$CFG" "$DIR/es_systems.cfg.copia" 2>/dev/null
  # Text, not an XML parse: ArkOS's own file is not always well-formed XML (EmulationStation's parser lets it
  # through). The block copies how the gba system starts RetroArch, so it starts like the rest of this card.
  python3 - "$CFG" "$TMP" "$CORES/pinyol_libretro.so" <<'PY' || { rm -f "$TMP"; fail "no pude generar el bloque"; }
import re, sys, os
import xml.etree.ElementTree as ET
src, out, core = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(src, "rb").read().decode("utf-8", "surrogateescape")
gba = next((m.group(0) for m in re.finditer(r"<system>.*?</system>", text, re.S)
            if re.search(r"<name>\s*gba\s*</name>", m.group(0))), "")
def field(tag):
    m = re.search(r"<%s>(.*?)</%s>" % (tag, tag), gba, re.S)
    return m.group(1).strip() if m else ""
cmd, path = field("command"), field("path")
roms = os.path.join(os.path.dirname(path.rstrip("/")) or "/roms", "pinyol") + "/"
emus = ""
if "%CORE%" in cmd:
    emus = ("\n\t\t<emulators>\n\t\t\t<emulator name=\"retroarch\">\n\t\t\t\t<cores>\n"
            "\t\t\t\t\t<core>pinyol</core>\n\t\t\t\t</cores>\n\t\t\t</emulator>\n\t\t</emulators>")
elif re.search(r"\S+_libretro\.so", cmd):
    cmd = re.sub(r"\S+_libretro\.so", core, cmd)
else:
    cmd = "/usr/local/bin/retroarch -L %s %%ROM%%" % core
block = ("\t<system>\n\t\t<name>pinyol</name>\n\t\t<fullname>Pinyol</fullname>\n"
         "\t\t<path>%s</path>\n\t\t<extension>.pinyol .PINYOL .zip .ZIP</extension>\n"
         "\t\t<command>%s</command>%s\n\t\t<platform>pinyol</platform>\n\t\t<theme>pinyol</theme>\n\t</system>\n"
         % (roms, cmd, emus))
i = text.rfind("</systemList>")
if i < 0:
    sys.exit("no </systemList>")
try:
    ET.fromstring(block)
except ET.ParseError:
    ET.fromstring(block.replace("&", "&amp;"))  # the block alone is XML once its & are escaped
new = text[:i] + block + text[i:]
assert new.replace(block, "", 1) == text  # the rest of the file is untouched
open(out, "wb").write(new.encode("utf-8", "surrogateescape"))
print("path:", roms)
print("command:", cmd)
PY
  sudo cp "$TMP" "$CFG" || { sudo cp "$BAK" "$CFG"; rm -f "$TMP"; fail "no pude escribir es_systems.cfg"; }
  rm -f "$TMP"
  grep -q '<name>pinyol</name>' "$CFG" && [ "$(stat -c %s "$CFG")" -gt "$(stat -c %s "$BAK")" ] \
    || { sudo cp "$BAK" "$CFG"; fail "es_systems.cfg quedo mal; restaurado"; }
  say "Sistema Pinyol anadido (copia: $BAK)"
fi

# pinyol's art for the themes this card has (only into a theme that is there: a folder of its own would show up in
# the theme list as a broken theme)
for t in "$DIR"/themes/*/; do
  name="$(basename "$t")"
  if [ -d "$ROMS/themes/$name" ]; then
    cp -r "$t". "$ROMS/themes/$name/" && say "tema: $name"
  fi
done

say "Listo. Reiniciando el menu..."
sleep 3
sudo systemctl restart emulationstation
