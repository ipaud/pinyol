-- The side view: three painted layers that wrap sideways (the buildings, the cobbled ground, the fence with the
-- crowd in front of everything), each scrolling at its own pace (parallax), and the street's actors between the
-- ground and the fence. The route runs to the right; up the screen is the street's left (the far wall), down is
-- its right (the near side). All of it is drawn at the screen's full 480x320; the PPU only has its backdrop.
local C = require("race.camera")
local actors = require("views.actors")
local side = {}

local PERIOD = 400                                       -- the layers' width: they wrap every 400 pixels
local WALL_Y, GROUND_Y, FENCE_Y = 0, 203, 253            -- where each layer starts on the screen
local WALL_K, GROUND_K, FENCE_K = 3.4, 4.0, 5.2          -- screen pixels each layer moves for a unit of route
-- how tall, in screen pixels, each picture's standing figure is drawn
local SHOW = {FLECHA = 84, DANI_SIDE = 100, RUN_SIDE = 70, TORO_SIDE = 105, CABE_SIDE = 92}

function side.init() end

function side.enter()
  bg(1)
  bg(2)
  bg(3)
  backdrop(0x3C3450)
end

local DEPTH = (C.SIDE_BOTTOM - C.SIDE_TOP) / 64
local function k_at(x) return 1.7 + (x + 32) / 64 * 0.6 end   -- world pixels per route unit at that depth
function side.y(x) return C.SIDE_TOP + (x + 32) * DEPTH end
function side.x(dani, x, z) return C.SIDE_X + (z - dani.z) * k_at(x) end

local function layer(id, y, k, z)
  local x = -((z * k - C.SIDE_X * 2) % PERIOD)
  while x < 480 do  -- 2 or 3 copies, however the wrap falls
    img(id, math.floor(x), y)
    x = x + PERIOD
  end
end

-- Dani's picture: the run is 0-5, a stumble 6, a sprint 7-10, a jog 11-14
local function dani_frame(dani)
  if dani.stumble > 0 or dani.state == "down" then return 6 end
  if dani.effort == "push" then return 7 + math.floor(dani.phase * 4) % 4 end
  if dani.effort == "ease" then return 11 + math.floor(dani.phase * 4) % 4 end
  return math.floor(dani.phase * 6) % 6
end

function side.draw(r, tick)
  local dani = r.dani
  local list = {}
  local function add(id, frame, sx, y, flip)
    list[#list + 1] = {id = id, frame = frame, sx = sx, y = y, flip = flip}
  end
  for _, b in ipairs(r.bulls) do
    local sx = side.x(dani, b.x, b.z)
    if sx > -20 and sx < 300 then
      add(b.kind == "toro" and "TORO_SIDE" or "CABE_SIDE", math.floor(b.phase * 4) % 4, sx - 20, side.y(b.x), false)
    end
  end
  for _, ru in ipairs(r.runners) do
    if ru.state ~= "gone" then
      local sx = side.x(dani, ru.x, ru.z)
      local f = ru.state == "down" and 16 + ru.var or ru.var * 4 + math.floor(ru.phase * 4) % 4
      if sx > -20 and sx < 260 then add("RUN_SIDE", f, sx, side.y(ru.x), false) end
    end
  end
  local dy = side.y(dani.x)
  add("DANI_SIDE", dani_frame(dani), C.SIDE_X, dy, false)
  table.sort(list, function(a, b) return a.y < b.y end)  -- the nearest (lowest on the screen) drawn last, on top
  layer("LAT_WALL", WALL_Y, WALL_K, dani.z)
  layer("LAT_GROUND", GROUND_Y, GROUND_K, dani.z)
  -- the stretches where a way out can be taken: a green band on the cobbles by their wall, chevrons leading to it
  for _, zn in ipairs(r.zones) do
    local lane = zn.side < 0 and -22 or 22
    local y0 = zn.side < 0 and 214 or 238
    local xa, xb = math.max(0, side.x(dani, lane, zn.z0) * 2), math.min(480, side.x(dani, lane, zn.z1) * 2)
    if xb > xa then
      local ya, yb = zn.side < 0 and y0 + 12 or y0, zn.side < 0 and y0 or y0 + 12  -- the light edge is towards the street
      quad("ZONE", xa, ya, xb, ya, xb, yb, xa, yb, {alpha = 0.66})
    end
    for z = zn.z0 - 84, zn.z0 - 8, 28 do
      local sx = side.x(dani, lane, z)
      if sx > -20 and sx < 260 then actors.draw("FLECHA", 2, sx, side.y(lane) + 3, actors.fit("FLECHA", SHOW.FLECHA), false, nil, 0.6) end
    end
  end
  for _, it in ipairs(list) do actors.draw(it.id, it.frame, it.sx, it.y, actors.fit(it.id, SHOW[it.id]), it.flip) end
  layer("LAT_FENCE", FENCE_Y, FENCE_K, dani.z)
  if dani.state ~= "retire" then actors.marker(C.SIDE_X, dy - SHOW.DANI_SIDE / 2 - 4 + math.sin(tick / 8) * 1.5) end
  return C.SIDE_X, dy
end

return side
