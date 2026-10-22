-- The people and animals of the street, drawn as full-resolution pictures (480x320) over the PPU's street: the
-- views place them in the 240x160 world and scale them by depth; this draws them there, feet at (sx, sy).
local actors = {}

-- frame size of each picture (art/build_sprites.py)
local SIZE = {
  DANI_BACK = {84, 160}, DANI_FRONT = {84, 160}, DANI_SIDE = {124, 160},
  RUN_BACK = {70, 130}, RUN_FRONT = {70, 130}, RUN_SIDE = {100, 130},
  TORO_BACK = {124, 140}, TORO_FRONT = {124, 140}, TORO_SIDE = {200, 130},
  CABE_BACK = {124, 140}, CABE_FRONT = {124, 140}, CABE_SIDE = {200, 130},
  TORO_3QB = {124, 140}, TORO_3QF = {124, 140}, CABE_3QB = {124, 140}, CABE_3QF = {124, 140},
  FAROLA = {48, 72}, BANDERA = {56, 72}, IKURRINA = {64, 72}, NICO = {80, 96},
  RETIRO = {40, 80}, FLECHA = {64, 40}, LAT_RET_FAR = {56, 96}, LAT_RET_NEAR = {96, 40},
}

function actors.has(id) return SIZE[id] ~= nil end

local PROPS = {FAROLA = true, BANDERA = true, IKURRINA = true, NICO = true, RETIRO = true, FLECHA = true,
               LAT_RET_FAR = true, LAT_RET_NEAR = true}

function actors.draw(id, frame, sx, sy, s, flip)
  local sz = SIZE[id]
  if not PROPS[id] then  -- a soft shadow on the ground under the feet
    local w = sz[1] * s * 0.62
    local h = math.max(4, w * 0.22)
    img("SHADOW", math.floor(sx * 2 - w / 2), math.floor(sy * 2 - h * 0.6), {scale_x = w / 64, scale_y = h / 16, alpha = 0.42})
  end
  img(id, math.floor(sx * 2 - sz[1] * s / 2), math.floor(sy * 2 - sz[2] * s), {frame = frame, scale = s, flip_x = flip})
end

-- the marker over Dani's head, over everything
function actors.marker(sx, sy)
  local x, y = math.floor(sx * 2), math.floor(sy * 2)
  tri(x - 10, y - 14, x + 10, y - 14, x, y, 0x141B3A)
  tri(x - 7, y - 12, x + 7, y - 12, x, y - 3, 0xFFD23C)
end

return actors
