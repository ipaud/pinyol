-- The people and animals of the street, drawn as full-resolution pictures (480x320) over the PPU's street: the
-- views place them in the 240x160 world and scale them by depth; this draws them there, feet at (sx, sy).
-- Every picture's cell, feet row and standing height come from views/sizes.lua (art/build_sprites.py), so a view
-- says how tall a figure should stand on the screen and the scale follows.
local actors = {}

local SIZE = require("views.sizes")

local PROPS = {FAROLA = true, BANDERA = true, NICO = true, FLECHA = true}

-- How many of the herd's animals to draw: up to 5, fewer when the frames are running long. The race is meant to run at
-- 30 fps (the console measured 26-30 with the herd near and 19-21 with all nine drawn at the camera): each animal costs about
-- 1.3 ms, so when the game's own drawing time stays over the budget one fewer is drawn, and one more comes back when it is
-- well under. perf() gives the last _draw in milliseconds.
local MAX_ANIMALS, MIN_ANIMALS, BUDGET_HI, BUDGET_LO = 5, 3, 7.5, 5.5
local cap, load, cool = MAX_ANIMALS, 0, 0
function actors.animal_cap()
  local _, draw = perf()
  load = load * 0.9 + (draw or 0) * 0.1
  cool = cool - 1
  if cool <= 0 then
    if load > BUDGET_HI and cap > MIN_ANIMALS then cap, cool = cap - 1, 30
    elseif load < BUDGET_LO and cap < MAX_ANIMALS then cap, cool = cap + 1, 90 end
  end
  return cap
end
function actors.reset_cap() cap, load, cool = MAX_ANIMALS, 0, 0 end

function actors.has(id) return SIZE[id] ~= nil end

-- the scale that makes the picture's standing figure `px` screen pixels tall
function actors.fit(id, px) return px / SIZE[id].ref end

-- Draw a picture with its feet at (sx, sy) in world pixels, `scale` screen pixels per picture pixel. Nothing is
-- drawn (and nothing is cut) for one that is wholly off the screen.
function actors.draw(id, frame, sx, sy, scale, flip, alpha, flat)
  local z = SIZE[id]
  local sv = scale * (flat or 1)  -- `flat` squashes it lengthways: a marking painted on the road
  local x = sx * 2 - z.w * scale / 2
  local y = sy * 2 - z.foot * sv
  if x >= 480 or x + z.w * scale <= 0 or y >= 320 or y + z.h * sv <= 0 then return end
  if not PROPS[id] then  -- a soft shadow on the ground under the feet
    local w = z.body * scale
    local h = math.max(4, w * 0.2)
    img("SHADOW", math.floor(sx * 2 - w / 2), math.floor(sy * 2 - h * 0.35),
        {scale_x = w / 64, scale_y = h / 16, alpha = 0.42 * (alpha or 1)})
  end
  img(id, math.floor(x + 0.5), math.floor(y + 0.5), {frame = frame, scale_x = scale, scale_y = sv, flip_x = flip, alpha = alpha})
end

-- the marker over Dani's head, over everything
function actors.marker(sx, sy)
  local x, y = math.floor(sx * 2), math.floor(sy * 2)
  tri(x - 10, y - 14, x + 10, y - 14, x, y, 0x141B3A)
  tri(x - 7, y - 12, x + 7, y - 12, x, y - 3, 0xFFD23C)
end

return actors
