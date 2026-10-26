-- bgfx: the playroom behind Poncho, in layers of pictures from the image model (gen/env_*.py), all drawn as `img` columns of 160 px (lib/slices.lua: only the
-- columns on the screen cost anything). Back to front:
--   1. the wall (a window with red curtains, bunting, drawings): the slowest, 0.09 of the camera
--   2. a bookcase of toys along the wall: 0.27 (the second speed: the Mega Drive's two bands)
--   3. giant toys standing behind the floor, 0.62
--   4. (the world: floor, shelves, blocks, items, foes, Poncho)
--   5. a foreground of crayons, blocks and bricks in front of everything, 1.5
local K = require("core.const")
local Deco = require("core.deco")
local Slices = require("slices")
local FAR, CASE = require("data.far_slices"), require("data.case_slices")
local B = {}

function B.init() end

local function wide(def, factor, y, cam_x, o)
  local x = -math.floor(cam_x * factor) % def.w
  local n = Slices.draw(def, x - def.w, y, o)
  n = n + Slices.draw(def, x, y, o)
  return n
end

-- the wall and the bookcase. cam_y moves them a little (the bookcase more than the wall)
function B.scroll(cam_x, cam_y)
  wide(FAR, 0.09, -14 - math.floor(cam_y * 0.05), cam_x)
  wide(CASE, 0.27, 250 - math.floor(cam_y * 0.9), cam_x, {dim = 0.9})
end

local MID = { -- x in the layer, giant toy
  {80, "TEDDY"}, {330, "TOWER"}, {500, "ROCKET"}, {690, "DUCK"}, {900, "BALL"}, {1070, "CASTLE"}, {1300, "RINGS"}, {1480, "BUNNY"},
  {1740, "DRUM"}, {1900, "HORSE"}, {2150, "DINO"}, {2400, "TRAIN"}, {2560, "ROCKET"}, {2780, "TEDDY"},
}
local MID_PERIOD = 3000

function B.mid(cam_x, cam_y)
  local base = 360 - cam_y
  local shift = cam_x * 0.62
  for _, m in ipairs(MID) do
    local x = (m[1] - shift) % MID_PERIOD - 220
    if x < K.W + 60 and x > -220 then Deco.img("BG_G_" .. m[2], 0, math.floor(x), math.floor(base), {dim = 0.88}) end
  end
end

local FORE = {{300, "BG_FORE_CRAYON_R", 282}, {900, "BG_FORE_BLOCKS", 272}, {1500, "BG_FORE_CRAYON_G", 286}, {2000, "BG_FORE_BALL", 280},
              {2500, "BG_FORE_BRICKS", 288}, {2900, "BG_FORE_CRAYON_B", 288}}
local FORE_PERIOD = 3300

function B.fore(cam_x, cam_y)
  local shift = cam_x * 1.5
  for _, m in ipairs(FORE) do
    local x = math.floor((m[1] - shift) % FORE_PERIOD - 300)
    if x < K.W and x > -300 then Deco.img(m[2], 0, x, m[3]) end
  end
end

-- a stretch of floor for the title and the screens without a level
function B.floor(cam_x, y)
  local off = -(math.floor(cam_x) % 32)
  for x = off, K.W, 256 do
    Deco.img("BG_FLOOR8", 0, x, y)
  end
end

return B
