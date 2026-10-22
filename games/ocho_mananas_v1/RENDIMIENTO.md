# Medidas en la Cirera (22-oct-2026) — ocho_mananas_v1

Firmware d1f8178, panel 60 Hz. Enviado con tools/send_game.py (carpeta nueva en /sdcard/games, sin tocar otros juegos).
Escenas guiadas por un script dentro del juego (copia temporal `ocho_mananas_perf`), 12-15 s cada una, valores estables.

| Escena | fps | tick | world | strips | audio |
|---|---|---|---|---|---|
| Título, menús, escenas de diálogo | 60 | 0,4 ms | 4,8 | 6,4 | 17 % |
| Canto día 1 | 59-60 | 0,6 ms | 3,4 | 9,6-10 | 27-32 % |
| Canto día 8, llamada 3 (17 círculos, coro de 3 voces) | 52-55 | 0,6 ms | 4,2 | 10,4-10,9 | 40 % |
| Carrera trasera, manada lejos | 30 | 2,7-3 ms | 4,1-5,3 | 13-14 | 29 % |
| Carrera lateral, manada pegada | 26-29 | 3,1 ms | 6-9 | 15-18 | 34-45 % |
| Carrera trasera, manada pegada a Dani (peor caso) | 19-21 | 3 ms | 12-13 | 18-23 | 35-40 % |

0 underruns de audio en todas. Memoria interna libre 58-66 KB, PSRAM 2,8-4,3 MB. Sin fallos de arranque.

Ticks: el firmware ejecuta un tick por barrido del panel y los recupera tras un frame lento, así que el tiempo de juego
(canto, carrera) sigue a 60 Hz aunque el dibujo baje a 20-30 fps.

Coste aislado (carrera trasera, strips, ms): calle pintada 3,6 · HUD ~2 · corredores+Dani+pilastras+zona ~3,3 ·
toros 5-8 (y +6 ms de _draw) · sombra alfa 1-2 · capa Mode 7 ~0 · polvo ~0.

## Segunda ronda (misma fecha, volumen a 0 en las pruebas)

- Con la manada pegada a Dani: 0 animales dibujados 26-38 ms, 2 animales ~29, 3 a 9 animales 33-35 ms (23 fps). El coste NO depende del tamaño
  (escala máx. 2,6, 1,6 o 1,25: igual) ni casi del número: dibujar cualquier animal cuesta 3-7 ms.
- `perf()` (Lua) marca ~9 ms con o sin animales: el gasto está en el dibujo de las tiras, que `perf()` no ve.
- Pilastras y zona verde translúcida: coste ~0 en régimen estable. Sombra alfa frente a punteada frente a ninguna: 1-2 ms.
- Un tramo de carrera va a 20 fps los primeros ~25 s y luego a 30; precargar todas las imágenes antes no lo cambia (causa sin explicar).
- Decisión: carrera a 30 fps; se dibujan los 5 animales más cercanos.

## Tercera ronda: mañanas 2 a 8 en la Cirera (22-oct-2026, volumen 0)

Un script dentro del juego toca el canto (llamada 3, perfecto) y corre la carrera (piloto que lee el radar, sin morir) de cada mañana,
50 s cada una, 7 mañanas seguidas (~7 min). Sin reinicios ni cierres; 0 underruns de audio; memoria interna libre 64 KB; PSRAM libre >= 2,2 MB.

| Mañana | Canto fps (min / med) | Carrera fps (min / med) | audio máx |
|---|---|---|---|
| 2 | 58 / 59 | 22 / 30 | 42 % |
| 3 | 45 / 51 | 29 / 30 | 41 % |
| 4 (tramo largo) | 53 / 55 | 21 / 26 | 38 % |
| 5 | 51 / 54 | 20 / 30 | 39 % |
| 6 | 48 / 49 | 20 / 25 | 38 % |
| 7 (Mercaderes) | 53 / 54 | 24 / 28 | 38 % |
| 8 (Mercaderes) | 38 / 44 | 20 / 29 | 42 % |

Tres "slow tick" sueltos (59 y 51 ms, y 318 ms al arrancar). La carrera mantiene ~30 fps de mediana y baja a 20 con la manada pegada.
