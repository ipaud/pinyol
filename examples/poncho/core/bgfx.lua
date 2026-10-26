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
local W = require("core.worlds")
local B = {}

function B.init() end

local look = {}
local function wide(l, cam_x, y)
  local def = l.def
  look.dim, look.mul = l.dim, l.mul
  local x = -math.floor(cam_x * l.speed) % def.w
  local n = Slices.draw(def, x - def.w, y, look)
  n = n + Slices.draw(def, x, y, look)
  return n
end

-- the wall and the bookcase. cam_y moves them a little (the bookcase more than the wall)
function B.scroll(cam_x, cam_y)
  if W.far and W.far.fill then rect(0, 0, K.W, K.H, W.far.fill) end -- (the far layer is only 150 px tall: a colour under it)
  if W.far then wide(W.far, cam_x, W.far.y - math.floor(cam_y * W.far.ycam)) end
  if W.case then wide(W.case, cam_x, W.case.y - math.floor(cam_y * W.case.ycam)) end
end

local mlook = {}
function B.mid(cam_x, cam_y)
  local mid = W.theme.mid
  if not mid then return end
  local base = 360 - cam_y
  local shift = cam_x * mid.speed
  mlook.dim = mid.dim
  for _, m in ipairs(mid.list) do
    local x = (m[1] - shift) % mid.period - 220
    if x < K.W + 60 and x > -220 then
      local id, own = m[2], Deco.has(m[2])
      mlook.mul = (not own) and mid.mul or nil
      local o = m[4]
      mlook.sx, mlook.sy = o and o.sx, o and o.sx
      if o and o.top then -- hung from the top of the screen
        if own then Deco.img(id, 0, math.floor(x), o.top, mlook) end
      else
        Deco.img(own and id or (m[3] or id), 0, math.floor(x), math.floor(base), mlook)
      end
    end
  end
end

local flook = {}
function B.fore(cam_x, cam_y)
  local fore = W.theme.fore
  if not fore then return end
  local shift = cam_x * fore.speed
  for _, m in ipairs(fore.list) do
    local x = math.floor((m[1] - shift) % fore.period - 300)
    if x < K.W and x > -300 then
      local own = Deco.has(m[2])
      flook.mul = (not own) and W.theme.mid and W.theme.mid.mul or nil
      Deco.img(own and m[2] or (m[4] or m[2]), 0, x, m[3], flook)
    end
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
