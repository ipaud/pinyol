-- The people and animals of the street, drawn as full-resolution pictures (480x320) over the PPU's street: the
-- views place them in the 240x160 world and scale them by depth; this draws them there, feet at (sx, sy).
-- Every picture's cell, feet row and standing height come from views/sizes.lua (art/build_sprites.py), so a view
-- says how tall a figure should stand on the screen and the scale follows.
local actors = {}

local SIZE = require("views.sizes")

local PROPS = {FAROLA = true, BANDERA = true, IKURRINA = true, NICO = true, RETIRO = true, FLECHA = true,
               LAT_RET_FAR = true, LAT_RET_NEAR = true}

function actors.has(id) return SIZE[id] ~= nil end

-- the scale that makes the picture's standing figure `px` screen pixels tall
function actors.fit(id, px) return px / SIZE[id].ref end

-- Draw a picture with its feet at (sx, sy) in world pixels, `scale` screen pixels per picture pixel. Nothing is
-- drawn (and nothing is cut) for one that is wholly off the screen.
function actors.draw(id, frame, sx, sy, scale, flip, alpha)
  local z = SIZE[id]
  local x = sx * 2 - z.w * scale / 2
  local y = sy * 2 - z.foot * scale
  if x >= 480 or x + z.w * scale <= 0 or y >= 320 or y + z.h * scale <= 0 then return end
  if not PROPS[id] then  -- a soft shadow on the ground under the feet
    local w = z.body * scale
    local h = math.max(4, w * 0.2)
    img("SHADOW", math.floor(sx * 2 - w / 2), math.floor(sy * 2 - h * 0.35),
        {scale_x = w / 64, scale_y = h / 16, alpha = 0.42 * (alpha or 1)})
  end
  img(id, math.floor(x + 0.5), math.floor(y + 0.5), {frame = frame, scale = scale, flip_x = flip, alpha = alpha})
end

-- the marker over Dani's head, over everything
function actors.marker(sx, sy)
  local x, y = math.floor(sx * 2), math.floor(sy * 2)
  tri(x - 10, y - 14, x + 10, y - 14, x, y, 0x141B3A)
  tri(x - 7, y - 12, x + 7, y - 12, x, y - 3, 0xFFD23C)
end

return actors
