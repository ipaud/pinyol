-- The rear view: the street's cobbles as a Mode 7 floor (the PPU's BG2) under the painted facades (STREET_REAR, a
-- 480x320 picture with the road cut out), and everything on it -- lamps, banners, runners, the herd, Dani -- as
-- pictures scaled by depth (views/actors.lua). Looking back puts the camera in front of Dani, turned round,
-- and mirrors the street so that left stays left (the facades are symmetric enough).
local C = require("race.camera")
local actors = require("views.actors")
local rear = {}

-- how tall, in screen pixels, each picture's standing figure is drawn at Dani's depth (scale 1)
local PROPS = {FAROLA = true, BANDERA = true, IKURRINA = true, NICO = true, RETIRO = true, FLECHA = true}
local SHOW = {DANI_BACK = 138, DANI_FRONT = 138, RUN_BACK = 105, RUN_FRONT = 105,
              TORO_BACK = 165, TORO_FRONT = 165, TORO_3QB = 165, TORO_3QF = 165,   -- the herd towers over the runners:
              CABE_BACK = 148, CABE_FRONT = 148, CABE_3QB = 148, CABE_3QF = 148,   -- 500 kg against 75
              FAROLA = 58, BANDERA = 65, IKURRINA = 58, NICO = 86, RETIRO = 88, FLECHA = 40}

function rear.init() end

rear.back = false
function rear.enter(back)
  rear.back = back or false
  if rear.back then rear.cb = C.CB end
  line_off()
  bg(1)
  bg(3)
  bg(2, {map = "FLOOR", mode = "affine", prio = 2, wrap = true})
  backdrop(0x3C3450)
end

local items = {}
local n_items = 0
local function add(id, frame, sx, sy, s, flip, d)
  n_items = n_items + 1
  local it = items[n_items]
  if not it then it = {}; items[n_items] = it end
  it.id, it.frame, it.sx, it.sy, it.s, it.flip, it.d = id, frame, sx, sy, s, flip, d
end

local function hash(k, side) return (k * 7919 + side * 104729 + 13) % 97 end

-- project a point of the street (x across, z along, ht above the cobbles)
local function at(x, z, ht)
  local mx = rear.back and 128 - x or 128 + x
  local sx, sy, scale, vis = project(2, mx, C.BASE - z)
  if not vis then return nil end
  local d = C.FOV / scale
  return sx, sy - (ht or 0) * scale, scale * C.CB / C.FOV, d
end

local function place(id, frame, x, z, ht, flip, min_s, min_d)
  local sx, sy, s, d = at(x, z, ht)
  if not sx or d < (min_d or 14) or s < (min_s or 0.1) then return end
  if s > 2.6 then s = 2.6 end
  add(id, frame, sx, sy, s, flip, d)
end

-- an animal: straight on when it is near the middle of the screen, three-quarters (head towards the middle of the
-- street going away, outwards coming at us) when it is off to a side
local function place_animal(tag, frame, b, z)
  local sx, sy, s, d = at(b.x, z, 0)
  if not sx or d < 14 or s < 0.1 then return end
  if s > 2.6 then s = 2.6 end
  -- straight on in the middle, three-quarters off to the side; with a margin so it does not flicker at the edge
  local off = math.abs(sx - 120)
  local oblique = b.oblique
  if oblique == nil or (oblique and off < 22) or (not oblique and off > 30) then oblique = off > 26 end
  b.oblique = oblique
  local from_behind = not rear.back
  local id = tag .. (oblique and (from_behind and "_3QB" or "_3QF") or (from_behind and "_BACK" or "_FRONT"))
  -- the three-quarter pictures have their head to the left
  local flip = oblique and ((sx < 120) == from_behind)
  add(id, frame, sx, sy, s, flip, d)
end

-- The camera pulls back while the herd is close behind, so the animals coming up can be seen at the bottom of
-- the screen (the facades do not mind: they are the same from any point along the street).
rear.cb = C.CB
function rear.update(r)  -- once a tick
  local dani = r.dani
  local want = C.CB
  if not rear.back and dani.state ~= "retire" then
    for _, b in ipairs(r.bulls) do
      local back = dani.z - b.z
      if back > -10 and back < 150 then want = 88 end
    end
  end
  rear.cb = rear.cb + (want - rear.cb) * 0.03
end

-- Dani's picture: the run is 0-5, a stumble 6, down 7, a sprint 8-11, a jog 12-15, a glance over his shoulder 16-17
local function dani_frame(dani)
  if dani.state == "down" then return 7 end
  if dani.stumble > 0 then return 6 end
  if dani.state == "retire" then return dani.retire_t < 18 and 16 or 17 end
  if dani.effort == "push" then return 8 + math.floor(dani.phase * 4) % 4 end
  if dani.effort == "ease" then return 12 + math.floor(dani.phase * 4) % 4 end
  return math.floor(dani.phase * 6) % 6
end

function rear.draw(r, tick, shake)
  local dani = r.dani
  local cz = rear.back and dani.z + C.CB or dani.z - rear.cb
  local oy = shake or 0  -- the ground shakes as the herd goes by: floor, facades and actors move together
  mode7(2, 128, C.BASE - cz, rear.back and 180 or 0, C.CAM_H, C.HOR + oy, C.FOV)
  n_items = 0
  -- what hangs on the walls: a pattern fixed to the street, so it slides past as Dani runs
  local z_near, z_far
  if rear.back then z_near, z_far = cz - 540, cz - 22 else z_near, z_far = cz + 22, cz + 540 end
  for k = math.floor(z_near / 30), math.floor(z_far / 30) do
    local z = k * 30 + 15
    for side = -1, 1, 2 do
      local h = hash(k, side)
      local flip = side < 0
      if h % 5 == 2 then place("BANDERA", (tick // 20 + k) % 2, side * 30, z - 8, 52, flip, 0.12, 80) end
      if h % 7 == 3 then place("IKURRINA", (tick // 16 + k) % 2, side * 30, z + 4, 4, flip, 0.12, 80) end
      if k % 3 == 0 then place("FAROLA", 1, side * 30, z + 12, 40, flip, 0.14, 80) end
    end
  end
  local ph = r.day.photo
  if ph then
    local flash = r.photo and r.photo.taken and r.t - r.photo.at < 24 and (tick // 3) % 2 or 0
    place("NICO", flash, ph.side * 30, ph.at, 20, ph.side < 0, 0.12, 60)
  end
  for _, zn in ipairs(r.zones) do
    if zn.z1 > z_near and zn.z0 < z_far then
      local fl = zn.side < 0
      for z = zn.z0 + 8, zn.z1, 18 do place("FLECHA", 0, zn.side * 22, z, 0, fl, 0.15) end
      for _, z in ipairs({zn.z0, (zn.z0 + zn.z1) / 2, zn.z1}) do
        place("RETIRO", (tick // 15) % 2, zn.side * 31, z, 0, fl, 0.1)
      end
    end
  end
  -- the herd: from behind its rumps (the body's middle is behind the head), from the front its faces
  for _, b in ipairs(r.bulls) do
    place_animal(b.kind == "toro" and "TORO" or "CABE", math.floor(b.phase * 4) % 4, b, rear.back and b.z - 4 or b.z - 12)
  end
  for _, ru in ipairs(r.runners) do
    if ru.state ~= "gone" then
      if ru.state == "down" then
        place("RUN_BACK", 20 + ru.var, ru.x, ru.z, 0, ru.x > 0, 0.1)
      elseif ru.state == "trip" then
        place("RUN_BACK", 16 + ru.var, ru.x, ru.z, 0, ru.x > 0, 0.1)
      elseif rear.back then
        place("RUN_FRONT", ru.var * 2 + math.floor(ru.phase * 2) % 2, ru.x, ru.z, 0, false, 0.1)
      elseif ru.lean > 0 then
        place("RUN_BACK", 16 + ru.var, ru.x, ru.z, 0, (ru.pending or ru.x) > ru.x, 0.1)
      else
        place("RUN_BACK", ru.var * 4 + math.floor(ru.phase * 4) % 4, ru.x, ru.z, 0, false, 0.1)
      end
    end
  end
  -- Dani, always at the same depth from the camera
  local dsx, dsy, ds, dd = at(dani.x, dani.z, 0)
  if dsx then
    local id, frame = "DANI_BACK", dani_frame(dani)
    if rear.back then id, frame = "DANI_FRONT", math.floor(dani.phase * 4) % 4 end
    add(id, frame, dsx, dsy, ds, false, dd - 0.01)
  end
  local list = {}
  for i = 1, n_items do list[i] = items[i] end
  table.sort(list, function(a, b) return a.d > b.d end)  -- the far ones first
  img("STREET_REAR", 0, 2 * oy)
  for _, it in ipairs(list) do
    -- an animal coming up out of the camera's near plane fades in instead of popping
    local fade = (not PROPS[it.id] and it.d < 28) and math.max(0.05, (it.d - 14) / 14) or nil
    actors.draw(it.id, it.frame, it.sx, it.sy, it.s * actors.fit(it.id, SHOW[it.id]), it.flip, fade)
  end
  if dsx and dani.state ~= "retire" then actors.marker(dsx, dsy - SHOW.DANI_BACK / 2 * ds - 5 + math.sin(tick / 8) * 1.5) end
  rear.used = n_items
  return dsx, dsy
end

-- where on the screen (480x320) a point of the street is, for the overlay's marks
function rear.screen(x, z, ht)
  local sx, sy = at(x, z, ht)
  if not sx then return nil end
  return sx * 2, sy * 2
end

return rear
