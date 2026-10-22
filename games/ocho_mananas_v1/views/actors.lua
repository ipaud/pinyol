-- The people and animals of the street, drawn as full-resolution pictures (480x320) over the PPU's street: the
-- views place them in the 240x160 world and scale them by depth; this draws them there, feet at (sx, sy).
local actors = {}

-- frame size of each picture (art/build_sprites.py)
local SIZE = {
  DANI_BACK = {36, 68}, DANI_FRONT = {36, 68}, DANI_SIDE = {52, 68},
  RUN_BACK = {36, 68}, RUN_FRONT = {36, 68}, RUN_SIDE = {52, 68},
  TORO_BACK = {60, 68}, TORO_FRONT = {60, 68}, TORO_SIDE = {104, 64},
  CABE_BACK = {60, 68}, CABE_FRONT = {60, 68}, CABE_SIDE = {104, 64},
  TORO_3QB = {60, 68}, TORO_3QF = {60, 68}, CABE_3QB = {60, 68}, CABE_3QF = {60, 68},
  FAROLA = {48, 72}, BANDERA = {56, 72}, IKURRINA = {64, 72}, NICO = {80, 96},
  RETIRO = {40, 80}, FLECHA = {64, 40}, LAT_RET_FAR = {56, 96}, LAT_RET_NEAR = {96, 40},
}

function actors.has(id) return SIZE[id] ~= nil end

function actors.draw(id, frame, sx, sy, s, flip)
  local sz = SIZE[id]
  img(id, math.floor(sx * 2 - sz[1] * s / 2), math.floor(sy * 2 - sz[2] * s), {frame = frame, scale = s, flip_x = flip})
end

-- the marker over Dani's head, over everything
function actors.marker(sx, sy)
  local x, y = math.floor(sx * 2), math.floor(sy * 2)
  tri(x - 10, y - 14, x + 10, y - 14, x, y, 0x141B3A)
  tri(x - 7, y - 12, x + 7, y - 12, x, y - 3, 0xFFD23C)
end

return actors
