# Zebby: Fora de guió — primer prototipo

Prototipo jugable del plató P1 «El magatzem impossible», basado en el documento de diseño v0.2 de `Downloads/zebby-game1`. Es una prueba de control y dirección visual, no la campaña de seis mundos.

Arte actual: máquinas, cajas, cámara, REC y salida separados directamente de la captura de objetos aportada, sin cambio de tamaño. Fondo panorámico dibujado a 1440×320, sin escalado. Zebby dibujado a 64×64 píxeles finales con cuerpo cuadrado redondeado, cara pequeña, brazos blancos y guantes según los originales de `Downloads/Proyectos/ZEBA/Zebby/imagenes`. Los dibujos del escenario y del personaje aún son una reinterpretación, no una copia exacta de sus referencias.

## Jugar

Desde la raíz de Pinyol:

```sh
./build/pinyol_sim --game games/zebby
```

Flechas: mover. A: saltar. B: empujar caja o activar REC con 3 fragmentos. C: correr. Prensa transforma a Zebby en plano para pasar bajo persiana; rodillo restaura su forma. Recoge tres fragmentos, activa REC y vuelve a salida. Agotar reloj permite reintentar desde REC sin perder fragmentos; completar guarda primera secuencia.

## Comprobar

```sh
./build/pinyol_headless --game games/zebby --fresh --script games/zebby/tests/zebby.script --check-strips --strict-assets
./build/pinyol_headless --game games/zebby --validate --strict-assets
```

Los scripts de arte necesitan Pillow solo para regenerar PNG. Recursos convertidos están incluidos para jugar sin Python:

`prop_art.py` necesita `raw/props_native_reference.png`, copia local de la lámina facilitada. `art.py` genera los clips sencillos que usa el prototipo. Desde la raíz de Pinyol:

```sh
python3 games/zebby/art.py
python3 games/zebby/background_native.py
python3 games/zebby/sprite_art.py
python3 games/zebby/prop_art.py
python3 tools/png2asset.py games/zebby/art/props.png games/zebby/assets PROPS --packed --frames 7 --colours 16
python3 tools/png2asset.py games/zebby/art/zebby_native.png games/zebby/assets ZEBBY_NATIVE --packed --frames 64 --colours 16
python3 tools/png2asset.py games/zebby/art/warehouse_a.png games/zebby/assets WAREHOUSE_A --packed --colours 128 --type background
python3 tools/png2asset.py games/zebby/art/warehouse_b.png games/zebby/assets WAREHOUSE_B --packed --colours 128 --type background
for name in press roller shutter box camera light rec exit; do
  upper=$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]')
  python3 tools/png2asset.py "games/zebby/art/${name}_native.png" games/zebby/assets "${upper}_NATIVE" --packed --frames 2 --colours 128
done
```

Atlas Zebby, 64 frames: reposo 0–5, caminar 6–11, saltar 12–17, empujar 18–23, caminar alternativo 24–31, correr 32–39, embestida 40–45, daño 46–51, aplanar 52–57, recuperar 58–63. `main.lua` marca duración y uso de cada secuencia. La pose plana detiene el movimiento durante 24 ticks para que la altura visible y la colisión no discrepen.

Faltan microjuegos, demás platós, estudio central y estreno. Rendimiento/control en Cirera pendiente de prueba física.
