-- A floor of the lighthouse: Estel climbs from the bottom of a painted room 480x720 to the hatch at its top, through a camera of 480x320. The hatch
-- opens once enough ánimas have gone out to sea through the window. The room is darkened through its palette (free on a packed picture) and lit by
-- light() that adds: her lantern, the wall lamps, the window when lightning strikes. Gears turn as quads; the cistern's water ripples on the whole
-- screen (distort with screen = true) and holds her reflection; outside, the rain falls in two swarms and the wind pushes.
local C = require("core.const")
local L = require("core.levels")
local Body = require("core.body")
local A = require("core.animas")
local E = require("core.estel")
local R = require("core.route")
local S = require("core.sound")
local Run = require("core.run")
local P = {}

P.hook = function(id) end
P.input = function() return {} end
local rain_far, rain_near

local function plat_y(p)
  if p[4] == "barrel" then return p[2] + 2 * math.sin(P.t * 0.05 + p[1] * 0.1) end
  return p[2]
end
P.plat_y = plat_y

local GUST, GUST_ON, GUST_OFF = 420, 240, 380 -- outside: a gust every 7 seconds, from tick 240 to 380 of each
function P.wind_at(t)
  if not P.lv or not P.lv.outside then return 0 end
  local k = t % GUST
  if k < GUST_ON or k > GUST_OFF then return 0 end
  return -0.75 * math.sin(math.pi * (k - GUST_ON) / (GUST_OFF - GUST_ON))
end
function P.gust_soon(t, within)
  if not P.lv or not P.lv.outside then return false end
  for k = 0, within, 5 do if P.wind_at(t + k) ~= 0 then return true end end
  return false
end

function P.enter(n)
  local lv = L[n]
  P.n, P.lv, P.t = n, lv, 0
  P.body = Body.new(lv.start.x, lv.start.y)
  for i, p in ipairs(lv.plat) do if p[2] == lv.start.y and lv.start.x >= p[1] and lv.start.x <= p[1] + p[3] then P.body.on = i end end
  P.s = {t = 0, walked = 0, hurt = 0, lift = false}
  P.oil, P.drained = C.OIL_MAX, false
  P.animas = {}
  for i, d in ipairs(lv.animas) do P.animas[i] = A.new(d, i) end
  P.freed, P.state, P.state_t = 0, "play", 0
  P.cans = {}
  for i, o in ipairs(lv.oil or {}) do P.cans[i] = {x = o[1], y = o[2], got = false} end
  P.hatch_open = lv.quota == 0
  P.cam = math.max(0, math.min(720 - 320, P.body.y - 200))
  P.flash, P.next_bolt, P.bolt = 0, 200, nil
  P.hurt_here = false
  P.safe = nil
  P.edges = P.edges_of(n)
  P.card = 150
  rain_far = swarm(220, {-40, -40, 520, 360})
  rain_near = swarm(90, {-40, -40, 520, 360})
  S.music(lv.music)
  S.room(lv.outside and "outside" or "hall")
  S.ambient(lv.outside and "RAIN" or "SEA")
end

local edge_cache = {}
function P.edges_of(n)
  if not edge_cache[n] then edge_cache[n] = R.build(L[n]) end
  return edge_cache[n]
end

local function hurt(from_x, why)
  local s = P.s
  if s.hurt > 0 or P.state ~= "play" then return end
  Run.warmth = Run.warmth - 1
  P.hurt_here = true
  s.hurt = C.INVULN
  local b = P.body
  b.vx = (b.x < from_x and -1 or 1) * 2.4
  b.vy, b.ground, b.on = -3.2, false, nil
  S.at("HURT", b.x)
  P.hook("hurt", why)
  if Run.warmth <= 0 then
    P.state, P.state_t = "frozen", 0
    S.jingle("helada", 5, true)
  end
end
P.hurt = hurt

-- out of the water (or the sea): back on the last firm platform she stood on, where she stood
local function respawn()
  local lv, b = P.lv, P.body
  local sp = P.safe
  b.vx, b.vy, b.ground = 0, 0, true
  if sp then
    local p = lv.plat[sp.on]
    b.x, b.y, b.on = math.max(p[1] + 12, math.min(p[1] + p[3] - 12, sp.x)), p[2], sp.on
  else
    b.x, b.y, b.on = lv.start.x, lv.start.y, nil
    for i, p in ipairs(lv.plat) do if p[2] == lv.start.y and lv.start.x >= p[1] and lv.start.x <= p[1] + p[3] then b.on = i end end
  end
end

local function gear_hit(g, b)
  local cy = b.y - C.HH / 2
  local dx, dy = math.max(0, math.abs(b.x - g.x) - C.HW), math.max(0, math.abs(cy - g.y) - C.HH / 2)
  return dx * dx + dy * dy < g.r * g.r
end

local function update_weather()
  local lv = P.lv
  if P.flash > 0 then P.flash = P.flash - 1 end
  P.next_bolt = P.next_bolt - 1
  if P.next_bolt <= 0 then
    P.next_bolt = 420 + (P.t * 37 + P.n * 91) % 360
    P.flash = 10
    local bx = lv.outside and (60 + (P.t * 13) % 220) or (lv.windows[1] and lv.windows[1][1] or 240)
    P.bolt = {x = bx, t = 12, seed = P.t}
    S.play("THUNDER", {delay = 0.4 + (P.t % 40) / 40, var = 2})
  end
  if P.bolt then P.bolt.t = P.bolt.t - 1 if P.bolt.t <= 0 then P.bolt = nil end end
  if lv.outside then
    local w = P.wind_at(P.t)
    for _ = 1, 4 do rain_far:add(math.random(-40, 520), -20, -0.6 + w * 3, 5 + math.random() * 1.5, 80) end
    for _ = 1, 2 do rain_near:add(math.random(-40, 520), -30, -1 + w * 5, 9 + math.random() * 2, 50) end
    rain_far:step()
    rain_near:step()
  end
end

function P.update()
  P.t = P.t + 1
  local s, b, lv = P.s, P.body, P.lv
  s.t = P.t
  if P.card > 0 then P.card = P.card - 1 end
  update_weather()
  for _, g in ipairs(lv.gears or {}) do g.a = (g.a or 0) + g.speed end
  if P.state == "frozen" then
    P.state_t = P.state_t + 1
    if P.state_t > 170 then
      Run.matches = Run.matches - 1
      if Run.matches > 0 then
        Run.warmth, Run.freed = C.WARMTH, Run.freed - P.freed -- the floor again: its ánimas are back in it
        P.enter(P.n)
        P.hook("retry")
      else P.state = "over" end
    end
    return
  end
  if P.state == "hatch" then
    P.state_t = P.state_t + 1
    b.y = b.y - 1.2
    if P.state_t > 70 then P.state = "clear" end
    return
  end
  if P.state ~= "play" then return end
  Run.ticks = Run.ticks + 1
  if s.hurt > 0 then s.hurt = s.hurt - 1 end
  local inp = P.input(P) or {}
  -- the lantern held high burns oil; empty, it must fill again before it can be raised
  local want_lift = inp.lift and b.ground and not P.drained
  if want_lift then
    P.oil = P.oil - 1
    if P.oil <= 0 then P.drained = true end
  else
    P.oil = math.min(C.OIL_MAX, P.oil + 0.8)
    if P.drained and P.oil >= C.OIL_MIN then P.drained = false end
  end
  if want_lift and not s.lift then S.at("LIFT", b.x) end
  s.lift = want_lift
  local x0 = b.x
  local ev = Body.step(b, {dx = inp.dx, jump = inp.jump, hold = inp.hold, lift = s.lift}, lv.plat, plat_y, P.wind_at(P.t))
  s.walked = s.walked + math.abs(b.x - x0)
  if ev == "jump" then S.at("JUMP", b.x) elseif ev == "land" then S.at("LAND", b.x) end
  if b.ground and b.on and lv.plat[b.on][4] ~= "barrel" then P.safe = {on = b.on, x = b.x} end
  if b.ground and math.abs(b.vx) > 0.5 and math.floor(s.walked / 22) ~= math.floor((s.walked - math.abs(b.x - x0)) / 22) then S.at("STEP", b.x, {var = 3}) end
  -- water and sea
  if (lv.water and b.y > lv.water + 14) or (lv.sea and b.y > lv.sea) then
    S.at("SPLASH", b.x)
    P.hook("wet")
    respawn() -- a soaking and the climb back costs time, not warmth: the cistern is for learning the barrels
    s.hurt = C.INVULN - 20
  end
  for _, g in ipairs(lv.gears or {}) do
    if gear_hit(g, b) then hurt(g.x, "gear") S.at("GEAR", g.x) end
  end
  -- the ánimas
  local light_r = s.lift and C.LIFT_R or 0
  local following = 0
  for _, a in ipairs(P.animas) do
    local e = A.update(a, {x = b.x, y = b.y, dir = b.dir, lift = s.lift}, lv, light_r)
    if e == "touch" then hurt(a.x, "anima") S.at("MOAN", a.x, {var = 2})
    elseif e == "calm" then S.at("CALM", a.x)
    elseif e == "free" then
      P.freed = P.freed + 1
      Run.freed = Run.freed + 1
      Run.score = Run.score + 100
      S.at("FREE", a.x)
      P.hook("free")
      if not P.hatch_open and P.freed >= lv.quota then P.hatch_open = true S.play("HATCH") P.hook("hatch") end
    end
    if a.state == "follow" then following = following + 1 end
    if a.state == "wild" and a.t % 400 == (a.slot * 97) % 400 then S.at("MOAN", a.x, {gain = 0.4, var = 3}) end
  end
  P.following = following
  for _, c in ipairs(P.cans) do
    if not c.got and math.abs(b.x - c.x) < 18 and math.abs(b.y - c.y) < 30 then
      c.got = true
      P.oil, P.drained = C.OIL_MAX, false
      Run.warmth = math.min(C.WARMTH, Run.warmth + 1) -- a warm can in cold hands
      Run.score = Run.score + 50
      S.at("OIL", c.x)
    end
  end
  -- up the hatch
  local h = lv.hatch
  if P.hatch_open and b.ground and b.on == h.plat and b.x > h.x and b.x < h.x + h.w then
    P.state, P.state_t = "hatch", 0
    S.play("HATCH")
    S.jingle("planta", 4, false)
    if not P.hurt_here then P.hook("warm") end
    P.hook("floor_done")
  end
  local want = math.max(0, math.min(720 - 320, b.y - 190))
  P.cam = P.cam + (want - P.cam) * 0.12
end

-- ------------------------------------------------------------------ drawing

local PL = {wood = "PL_WOOD", stone = "PL_STONE", iron = "PL_IRON"}

local function draw_plat(p, cam)
  local k = p[4]
  local y = math.floor(plat_y(p) - cam)
  if y < -40 or y > 330 then return end
  if k == "barrel" then
    img("PROP_BARREL", p[1] + (p[3] - 63) // 2, y - 4)
    return
  end
  local id = PL[k]
  if not id then return end
  local x, x1 = p[1], p[1] + p[3]
  img(id .. "_L", x, y - 2)
  local m = x + 16
  while m < x1 - 16 do
    local w = math.min(64, x1 - 16 - m)
    clip(m, y - 4, w, 40)
    img(id .. "_M", m, y - 2)
    clip()
    m = m + 64
  end
  img(id .. "_R", x1 - 16, y - 2)
end
P.draw_plat = draw_plat

local function draw_gear(g, cam)
  local r = g.r + 6
  local a = math.rad(g.a or 0)
  local cx, cy = g.x, g.y - cam
  if cy < -60 or cy > 380 then return end
  local pts = {}
  for i = 0, 3 do
    local t = a + math.pi / 4 + i * math.pi / 2
    pts[#pts + 1] = cx + math.cos(t) * r * 1.414
    pts[#pts + 1] = cy + math.sin(t) * r * 1.414
  end
  -- lit from the lantern's side: a colour a corner, dithered in the PlayStation's 4x4 pattern
  quad("TEX_GEAR", pts[5], pts[6], pts[7], pts[8], pts[1], pts[2], pts[3], pts[4],
       {lights = {0x9080A0, 0xC0A080, 0x605070, 0x403850}, dither = true})
end
P.draw_gear = draw_gear

local function draw_hatch(cam)
  local h = P.lv.hatch
  local y = h.y - cam
  if y < -60 or y > 330 then return end
  if h.door then
    light(h.x + h.w / 2, y + 30, 50, P.hatch_open and 0xFFC060 or 0x60C0D0, {intensity = 0.5 + 0.15 * math.sin(P.t * 0.08)})
    return
  end
  clip(h.x, y, h.w, 26)
  img("PL_WOOD_M", h.x, y - 2)
  img("PL_WOOD_M", h.x, y + 12)
  clip()
  box(h.x, y, h.w, 26, 0x201810)
  if P.hatch_open then
    light(h.x + h.w / 2, y + 14, 46, 0xFFC060, {intensity = 0.55 + 0.1 * math.sin(P.t * 0.1)})
  else -- sealed by a mist the ánimas keep there: it lifts when enough have gone to sea
    light(h.x + h.w / 2, y + 14, 44, 0x50B8D0, {intensity = 0.45 + 0.15 * math.sin(P.t * 0.06)})
  end
end

local function draw_bolt(cam)
  local bt = P.bolt
  if not bt or not P.lv.outside then return end
  local x, y = bt.x, -10
  local seed = bt.seed
  for i = 1, 7 do
    seed = (seed * 1103515245 + 12345) % 2147483648
    local nx, ny = x + (seed % 41) - 20, y + 26 + (seed // 41) % 18
    line(x, y, nx, ny, 0xE8D8FF)
    line(x + 1, y, nx + 1, ny, 0xB090FF)
    x, y = nx, ny
  end
end

function P.dim()
  local lv = P.lv
  local base = lv.outside and 0.72 or 0.6
  local f = P.flash / 10
  if settings().reduce_flashing then f = f * 0.35 end
  if lv.outside then return math.min(1, base + 0.3 * f) end
  return base + 0.08 * f
end

function P.draw_world()
  local lv, b, s, cam = P.lv, P.body, P.s, math.floor(P.cam)
  img(lv.bg, 0, -cam, {dim = P.dim()})
  local f = P.flash / 10
  if settings().reduce_flashing then f = f * 0.35 end
  if f > 0 then -- the window lights up only while the lightning lasts (a light costs every pixel it reaches)
    for _, w in ipairs(lv.windows) do light(w[1], w[2] - cam, 80, 0x5068C0, {intensity = 0.8 * f}) end
  end
  for i, l in ipairs(lv.lamps) do
    local fl = 1 + 0.08 * math.sin(P.t * 0.21 + i) + 0.05 * math.sin(P.t * 0.67 + i * 2)
    light(l[1], l[2] - cam, 44 * fl, 0xFF9038, {intensity = 0.55})
  end
  draw_bolt(cam)
  for _, g in ipairs(lv.gears or {}) do draw_gear(g, cam) end
  draw_hatch(cam)
  for _, p in ipairs(lv.plat) do draw_plat(p, cam) end
  for _, c in ipairs(P.cans) do
    if not c.got then
      local y = c.y - cam - 28 + 2 * math.sin(P.t * 0.08 + c.x)
      img("PROP_OILCAN", c.x - 10, y)
      light(c.x, y + 14, 16, 0xFFC060, {intensity = 0.3})
    end
  end
  for _, a in ipairs(P.animas) do if a.state == "wild" then A.draw(a, cam) end end
  if lv.water then E.reflect(b, s, cam, lv.water) end
  if P.state ~= "over" then E.draw(b, s, cam, P.state == "hatch" and {alpha = math.max(0, 1 - P.state_t / 70)} or nil) end
  for _, a in ipairs(P.animas) do if a.state ~= "wild" then A.draw(a, cam) end end
  local frozen = P.state == "frozen"
  local r = s.lift and C.LIFT_R or C.LANT_R
  if frozen then r = C.LANT_R * math.max(0, 1 - P.state_t / 60) end
  if r > 2 then E.light(b, s, cam, r) end
  if lv.water and lv.water - cam < 320 then
    local wy = math.max(0, lv.water - cam)
    distort(0, wy, 480, 320 - wy, {screen = true, kind = "water", amp = 2, period = 18, speed = 0.35})
  end
  if lv.outside then
    rain_far:draw("FX_RAIN_FAR", {alpha = 0.55}) -- far drops half seen through, near ones add their light
    rain_near:draw("FX_RAIN_NEAR", {add = true, alpha = 0.8})
  end
end

return P
