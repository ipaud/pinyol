# Entrehilos — prototipo jugable

Primera prueba de juego bordado para Pinyol. Incluye dos pantallas conectadas, río que bloquea el paso y puente que se construye eligiendo hilo para tres puntadas. Puente terminado queda guardado al salir y reiniciar.

## Jugar

Desde raíz del motor:

```sh
./build/pinyol_sim --game games/entrehilos
```

Cruceta para moverse. A cerca del río abre bordado. Izquierda/derecha eligen hueco; arriba/abajo cambian hilo; A cose; B sale. Colores indicados sobre cada hueco. Al completar puente, cruza hacia derecha y vuelve por izquierda.

## Comprobar

```sh
./build/pinyol_headless --game games/entrehilos --fresh --script games/entrehilos/tests/entrehilos.script --check-strips --strict-assets
```

`art.py` genera PNG de tela, paisaje, personaje y puente con cruces visibles. Para regenerar recursos tras cambiar arte:

```sh
python3 games/entrehilos/art.py
python3 tools/png2asset.py games/entrehilos/art/river.png games/entrehilos/assets BG_RIVER --packed --colours 32 --type background
python3 tools/png2asset.py games/entrehilos/art/farbank.png games/entrehilos/assets BG_FARBANK --packed --colours 32 --type background
python3 tools/png2asset.py games/entrehilos/art/bridge.png games/entrehilos/assets BRIDGE --packed --colours 32
python3 tools/png2asset.py games/entrehilos/art/hero.png games/entrehilos/assets HERO --packed --colours 32
```

Arte y mecánica son primer boceto. Falta probar rendimiento y controles en consola Cirera.
