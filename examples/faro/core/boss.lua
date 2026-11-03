-- The lantern room: El Pop de la Tempesta, an octopus of storm cloud as big as the cape, peers in over the railing and puts the lamp out. Estel takes
-- fire from a pilot flame (lantern held high beside it), climbs to the great lamp and lights one of its three wicks, while tentacles burst up through
-- the floor where she stands. Each tentacle is a chain of quads bending along a spine (the Saturn's distorted sprites, the PlayStation's textured
-- quads), the lamp's lens turns as a quad, and the beam is a cone of light added to the room.
local C = require("core.const")
local Body = require("core.body")
local E = require("core.estel")
local R = require("core.route")
local S = require("core.sound")
local Run = require("core.run")
local B = {}

B.hook = function(id) end
B.input = function() return {} end
local CAM = 300                 -- the room is painted 480x720; the arena is its rows 300..620
local FLOOR = 300
local PILOTS = {{x = 50, y = 138}, {x = 432, y = 138}}
local LAMP_X, LAMP_Y = 240, 96
B.lv = {
  plat = {{0, FLOOR, 480, "none"}, {108, 246, 84, "iron"}, {288, 246, 84, "iron"}, {188, 192, 104, "iron"}},
  quota = 0,
}
local TOP = 4

function B.enter()
  B.t, B.state, B.state_t = 0, "intro", 0
  B.body = Body.new(80, FLOOR)
  B.body.on = 1
  B.s = {t = 0, walked = 0, hurt = 0, lift = false}
  B.wicks, B.charged, B.work = 0, false, 0
  B.tents, B.next_tent, B.wave = {}, 200, 0
  B.pop = {rise = 0, face = 0, hit = 0}
  B.oil, B.drained = C.OIL_MAX, false
  B.lens_a, B.beam = 0, 0
  B.edges = B.edges or R.build(B.lv)
  B.flash = 0
  B.hurt_here = false
  S.music("pop")
  S.room("hall")
  S.ambient("RAIN")
  S.play("ROAR", {delay = 0.8})
end

local function hurt(from_x)
  local s, b = B.s, B.body
  if s.hurt > 0 or B.state ~= "fight" then return end
  Run.warmth = Run.warmth - 1
  B.hurt_here = true
  s.hurt = C.INVULN
  b.vx, b.vy, b.ground, b.on = (b.x < from_x and -1 or 1) * 2.6, -3.6, false, nil
  if B.charged then B.charged = false B.work = 0 end
  S.at("HURT", b.x)
  B.hook("hurt")
  if Run.warmth <= 0 then
    B.state, B.state_t = "frozen", 0
    S.jingle("helada", 5, true)
  end
end

local function plat_y(p) return p[2] end

local function spawn_tent(x)
  x = math.max(36, math.min(444, x))
  B.tents[#B.tents + 1] = {x = x, st = "warn", t = 0, h = 0, ph = B.t * 0.1}
end

local function update_tents()
  local b = B.body
  B.next_tent = B.next_tent - 1
  local busy = false
  for _, t in ipairs(B.tents) do if t.st ~= "sink" then busy = true end end
  if busy and B.next_tent < 30 then B.next_tent = 30 end -- a new wave only once the last has gone down: there is always a way out
  if B.next_tent <= 0 and B.pop.hit <= 0 then
    B.wave = B.wave + 1
    B.next_tent = 140 - 20 * B.wicks
    local off = ((B.wave * 37) % 50) - 25
    spawn_tent(b.x + off)
    if B.wicks >= 1 then spawn_tent(b.x + (B.wave % 2 == 0 and 110 or -110)) end
    if B.wicks >= 2 and B.wave % 3 == 0 then spawn_tent(b.x + (B.wave % 2 == 0 and -200 or 200)) end
  end
  local keep = {}
  for _, t in ipairs(B.tents) do
    t.t = t.t + 1
    if t.st == "warn" and t.t > 72 then t.st, t.t = "rise", 0 S.at("SLAM", t.x) end
    if t.st == "rise" then t.h = math.min(176, t.h + 16) if t.h >= 176 then t.st, t.t = "hold", 0 end end
    if t.st == "hold" and (t.t > 40 or B.pop.hit > 0) then t.st, t.t = "sink", 0 end
    if t.st == "sink" then t.h = t.h - 10 end
    if (t.st == "rise" or t.st == "hold") and math.abs(b.x - t.x) < 15 + C.HW and b.y > FLOOR - t.h then hurt(t.x) end
    if t.st ~= "sink" or t.h > 0 then keep[#keep + 1] = t end
  end
  B.tents = keep
end

-- for the bot: where it is not safe to stand (a tentacle warned, rising or up); `up` only the ones risen, which cannot be walked through;
-- `late` only the warnings about to rise (there is time to finish a moment's work first)
function B.danger(x, up, late)
  for _, t in ipairs(B.tents) do
    local on = (up and (t.st == "rise" or t.st == "hold")) or (not up and t.st ~= "sink" and not (late and t.st == "warn" and t.t < 34))
    if on and math.abs(x - t.x) < 18 + C.HW + (up and 2 or 8) then return t end
  end
  return nil
end

function B.task()
  if B.charged then return TOP, LAMP_X end
  local b = B.body
  local p = math.abs(b.x - PILOTS[1].x) <= math.abs(b.x - PILOTS[2].x) and PILOTS[1] or PILOTS[2]
  return 1, p.x
end

function B.update()
  B.t = B.t + 1
  local s, b = B.s, B.body
  s.t = B.t
  if B.flash > 0 then B.flash = B.flash - 1 end
  local pop = B.pop
  if pop.hit > 0 then pop.hit = pop.hit - 1 end
  if B.state == "intro" then
    B.state_t = B.state_t + 1
    pop.rise = math.min(1, B.state_t / 120)
    if B.state_t > 150 then B.state = "fight" end
    return
  end
  if B.state == "frozen" then
    B.state_t = B.state_t + 1
    if B.state_t > 170 then
      Run.matches = Run.matches - 1
      if Run.matches > 0 then
        Run.warmth = C.WARMTH
        local w = B.wicks
        B.enter()
        B.wicks = w -- the wicks already lit stay lit
        B.hook("retry")
      else B.state = "over" end
    end
    return
  end
  if B.state == "lit" then
    B.state_t = B.state_t + 1
    B.lens_a = B.lens_a + 2.2
    pop.rise = math.max(0, 1 - B.state_t / 200)
    pop.face = 3
    if B.state_t > 330 then B.state = "won" end
    return
  end
  if B.state ~= "fight" then return end
  Run.ticks = Run.ticks + 1
  if s.hurt > 0 then s.hurt = s.hurt - 1 end
  local inp = B.input(B) or {}
  local want_lift = inp.lift and b.ground and not B.drained
  if want_lift then B.oil = B.oil - 1 if B.oil <= 0 then B.drained = true end
  else B.oil = math.min(C.OIL_MAX, B.oil + 0.8) if B.drained and B.oil >= C.OIL_MIN then B.drained = false end end
  if want_lift and not s.lift then S.at("LIFT", b.x) end
  s.lift = want_lift
  local x0 = b.x
  local ev = Body.step(b, {dx = inp.dx, jump = inp.jump, hold = inp.hold, lift = s.lift}, B.lv.plat, plat_y, 0)
  s.walked = s.walked + math.abs(b.x - x0)
  if ev == "jump" then S.at("JUMP", b.x) elseif ev == "land" then S.at("LAND", b.x) end
  -- fire: from a pilot flame into the lantern, from the lantern into a wick
  local working = false
  if s.lift then
    if not B.charged and b.on == 1 then
      for _, p in ipairs(PILOTS) do
        if math.abs(b.x - p.x) < 34 then working = true end
      end
    elseif B.charged and b.on == TOP and math.abs(b.x - LAMP_X) < 40 then
      working = true
    end
  end
  if working then
    B.work = B.work + 1
    if B.work >= C.FIRE_T then
      B.work = 0
      if not B.charged then
        B.charged = true
        S.at("BURNER", b.x)
      else
        B.charged = false
        B.wicks = B.wicks + 1
        Run.warmth = C.WARMTH -- the lamp's fire warms her through
        Run.score = Run.score + 300
        S.play("BURNER")
        S.play("ROAR", {delay = 0.2})
        pop.hit, pop.face = 100, 3
        B.next_tent = 200
        B.flash = 8
        B.hook("wick")
        if B.wicks >= 3 then
          B.state, B.state_t = "lit", 0
          B.tents = {}
          S.play("LAMP")
          S.play("HORN", {delay = 1.0})
          S.music("fin", 2000)
          B.hook("lamp")
        end
      end
    end
  elseif not s.lift and B.work > 0 and B.t % 4 == 0 then
    B.work = B.work - 1 -- what was done stays a while: stepping out of a tentacle's way does not lose it
  end
  pop.rise = 1
  if pop.hit <= 0 then pop.face = (#B.tents > 0) and 2 or ((B.t // 90) % 6 == 5 and 1 or 0) end
  update_tents()
end

-- ------------------------------------------------------------------ drawing

-- a tentacle: its picture (48x128) cut in four bands, each a quad laid along a spine that bends more the higher it goes
local function draw_tent(t)
  local n = 4
  local base = FLOOR + 6
  local h = t.h
  if t.st == "warn" then
    local k = t.t / 72
    light(t.x, FLOOR - 4, 30 + 10 * k, 0x101020, {sub = true, intensity = 0.8 * k})
    if t.t % 12 == 0 then circ(t.x + ((t.t * 7) % 21) - 10, FLOOR - 4, 3, 0x8090C0, false) end
    return
  end
  local pts = {}
  for i = 0, n do
    local k = i / n
    local bend = math.sin(B.t * 0.09 + t.ph + k * 2.2) * 22 * k * k
    pts[i] = {t.x + bend, base - h * k, 1 - 0.6 * k}
  end
  for i = 0, n - 1 do
    local a, c = pts[i], pts[i + 1]
    local wa, wc = 22 * a[3], 22 * c[3]
    local v0, v1 = 128 - 32 * i, 128 - 32 * (i + 1)
    quad("TEX_TENTACLE", c[1] - wc, c[2], c[1] + wc, c[2], a[1] + wa, a[2], a[1] - wa, a[2],
         {uv = {0, v1, 47, v1, 47, v0, 0, v0}, lights = {0x9080B0, 0x9080B0, 0x706090, 0x706090}, dither = true})
  end
end

local function draw_lens()
  local lit = B.wicks
  local a = math.rad(B.lens_a)
  local w = 36 * math.abs(math.cos(a)) + 8
  local hh = 38
  local glow = lit / 3
  local col = B.state == "lit" and 0xFFFFE0 or (lit > 0 and 0xA09070 + 0x101008 * lit or 0x606070)
  quad("TEX_LENS", LAMP_X - w, LAMP_Y - hh, LAMP_X + w, LAMP_Y - hh, LAMP_X + w, LAMP_Y + hh, LAMP_X - w, LAMP_Y + hh,
       {light = col, dither = true})
  if lit > 0 then light(LAMP_X, LAMP_Y, 30 + 20 * glow, 0xFFD080, {intensity = 0.4 + 0.3 * glow}) end
end

local function draw_beam()
  if B.state ~= "lit" then return end
  local k = math.min(1, B.state_t / 60)
  local ang = (B.lens_a * 1.0) % 360
  light(LAMP_X, LAMP_Y, 420, 0xFFF0C0, {cone = {angle = ang, width = 22}, intensity = 0.9 * k})
  light(LAMP_X, LAMP_Y, 420, 0xFFF0C0, {cone = {angle = ang + 180, width = 22}, intensity = 0.9 * k})
end

function B.draw_world()
  local b, s = B.body, B.s
  local lit = B.state == "lit"
  local dim = 0.58 + 0.08 * B.wicks + (lit and 0.3 * math.min(1, B.state_t / 120) or 0)
  img("BG_LAMP", 0, -CAM, {dim = math.min(1, dim)})
  -- the octopus over the railing, seen through the glass: half see-through, cut at the railing
  local pop = B.pop
  if pop.rise > 0 then
    local bob = 4 * math.sin(B.t * 0.03)
    local y = -260 + 163 * pop.rise + bob -- its eyes (rows 150-168 of the frame) just over the railing at full height
    clip(0, 0, 480, 100)
    img("SPR_POP", 240 - 144 + 10 * math.sin(B.t * 0.013), y, {frame = pop.face, alpha = 0.8, mul = pop.hit > 0 and 0xFFE8C0 or 0xC0B8E0})
    clip()
  end
  for _, p in ipairs(PILOTS) do
    local f = 1 + 0.1 * math.sin(B.t * 0.3 + p.x)
    light(p.x, p.y, 34 * f, 0xFF9030, {intensity = 0.7})
  end
  draw_lens()
  img("PROP_BURNER", LAMP_X - 25, 192 - 54)
  for i = 1, B.wicks do light(LAMP_X - 16 + (i - 1) * 16, 140, 14, 0xFFC050, {intensity = 1}) end
  for i = 2, #B.lv.plat do require("core.play").draw_plat(B.lv.plat[i], 0) end
  for _, t in ipairs(B.tents) do if t.st == "warn" then draw_tent(t) end end
  if B.state ~= "over" then E.draw(b, s, 0, lit and {} or nil) end
  for _, t in ipairs(B.tents) do if t.st ~= "warn" then draw_tent(t) end end
  local r = s.lift and C.LIFT_R or C.LANT_R
  if B.state == "frozen" then r = C.LANT_R * math.max(0, 1 - B.state_t / 60) end
  if r > 2 then E.light(b, s, 0, r * (B.charged and 1.1 or 1), B.charged) end
  if B.work > 0 then
    local lx, ly = E.lantern(b, s)
    local k = B.work / C.FIRE_T
    circ(lx, ly, 16, 0x403020, false)
    for i = 0, math.floor(k * 16) - 1 do
      local a = -math.pi / 2 + i * math.pi / 8
      pset(lx + math.cos(a) * 16, ly + math.sin(a) * 16, 0xFFE090)
    end
  end
  draw_beam()
end

return B
