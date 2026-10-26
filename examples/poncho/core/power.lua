-- power: the four costumes and what C does in each (a TAP of C, up to K.TAP ticks, is the power; holding C runs):
--   barretina (red cap)   a headbutt dash: breaks crates and beats any toy it touches
--   dino (onesie)         C: breath of fire (beats paper planes and robots); DOWN in the air: a ground pound with a shock ring (beats toys around, breaks crates)
--   boots (green)         C: a splash jump, once more in the air (a higher jump, beats toys it touches)
--   futbol (shirt)        C: a dash and five seconds of being unbeatable and faster; toys it touches are beaten
-- A hit costs the costume, not a heart. The pickup of another costume replaces the one worn. Hero calls P.update each tick, Foes ask P.attack.
local K = require("core.const")
local L = require("core.level")
local Fx = require("core.fx")
local Snd = require("core.sound")
local In = require("core.input")

local P = {}
local H -- the hero module (set by it)
local HW = K.HALF_W

P.KINDS = {"barretina", "dino", "boots", "futbol"}
P.worn = {}   -- the kinds worn in this run, for the achievement

function P.init(hero) H = hero end
function P.reset_run() P.worn = {} end
function P.count_worn() local n = 0 for _ in pairs(P.worn) do n = n + 1 end return n end

function P.give(s, kind)
  H.costume = kind
  s.pw, s.fut_t, s.pw_cd, s.boots_air = nil, 0, 0, false
  P.worn[kind] = true
  Snd.play("dress")
  Fx.ring(s.x, s.y - 40, 12, 56, 0xFFFFFF, 16)
  H.events.costume = kind
end

function P.lose(s)
  H.costume, s.pw, s.fut_t = nil, nil, 0
  Fx.sparkle(s.x, s.y - 40, 0xFFFFFF, 10)
  H.events.costume_lost = true
end

local function start(s)
  local k = H.costume
  if k == "barretina" then
    s.pw = {kind = "dash", t = 0, len = K.HEAD_LEN}
    Snd.play("dash")
  elseif k == "dino" then
    s.pw = {kind = "fire", t = 0, len = K.FIRE_LEN}
    Snd.play("fire")
  elseif k == "boots" then
    if not s.ground and s.boots_air then return end
    if not s.ground then s.boots_air = true end
    s.vy, s.ground, s.jumped, s.jump_t, s.coyote = -K.BOOTS_V, false, false, 0, 0
    s.pw = {kind = "splash", t = 0, len = K.SPLASH_LEN}
    Fx.ring(s.x, s.y - 4, 8, 44, 0x8CD8FF, 16)
    Snd.play("splash")
  elseif k == "futbol" then
    s.pw = {kind = "dash", t = 0, len = K.FUT_LEN}
    s.fut_t = K.FUT_T
    Snd.play("dash")
    Fx.sparkle(s.x, s.y - 40, 0xFFFFFF, 6)
  end
end

local function finish(s, cd) s.pw, s.pw_cd = nil, cd or K.POWER_CD end

function P.update(s, down)
  local ev = H.events
  if s.pw_cd > 0 then s.pw_cd = s.pw_cd - 1 end
  if s.fut_t > 0 then
    s.fut_t = s.fut_t - 1
    s.inv = math.max(s.inv, 2)
  end
  if s.ground then s.boots_air = false end
  if not H.costume or s.scooter then s.pw = nil return end
  local pw = s.pw
  if not pw and s.act and s.pw_cd == 0 then start(s) pw = s.pw end
  if not pw and H.costume == "dino" and not s.ground and In.btnp("down") then
    s.pw = {kind = "pound", t = 0, len = 999}
    pw = s.pw
  end
  if not pw then return end
  pw.t = pw.t + 1
  local f = s.face
  local k = pw.kind
  if k == "dash" then
    local v = H.costume == "futbol" and K.FUT_V or K.HEAD_V
    s.vx, s.vy = f * v, math.max(-1, math.min(s.vy, 1))
    if H.costume == "barretina" then
      local xa, xb = s.x + f * (HW - 2), s.x + f * (HW + 14)
      local n = L.break_crates(math.min(xa, xb), s.y - 52, math.max(xa, xb), s.y - 6)
      if n > 0 then ev.crate = (ev.crate or 0) + n end
    end
    if pw.t % 3 == 1 then Fx.dust(s.x - f * 14, s.y, 1, -f, 0.6) end
    if pw.t >= pw.len then finish(s) end
  elseif k == "fire" then
    s.vx = s.vx * 0.86
    if pw.t >= pw.len then finish(s) end
  elseif k == "pound" then
    s.vx, s.vy = 0, K.POUND_V
    if s.ground then
      local n = L.break_crates(s.x - 70, s.y - 40, s.x + 70, s.y + 8)
      if n > 0 then ev.crate = (ev.crate or 0) + n end
      Fx.ring(s.x, s.y - 6, 10, 96, 0xFFD060, 18)
      Fx.dust(s.x, s.y, 6, 0, 3)
      Snd.play("pound")
      ev.pound = true
      s.pw = {kind = "shock", t = 0, len = 16}
    end
  elseif k == "shock" then
    s.vx = 0
    if pw.t >= pw.len then finish(s, 10) end
  elseif k == "splash" then
    if pw.t >= pw.len then finish(s) end
  end
  if ev.crate and ev.crate > 0 then
    for i = 1, math.min(2, #L.broke_at) do local b = L.broke_at[i] Fx.debris(b[1], b[2]) end
    Snd.play("crate")
  end
end

-- the box that beats toys now: kind, x, y, w, h (y the top), or nil
function P.attack(s)
  if s.fut_t > 0 then return "star", s.x - 20, s.y - 70, 40, 72 end
  local pw = s.pw
  if not pw or not H.costume then return nil end
  local f = s.face
  local k = pw.kind
  if k == "dash" and H.costume == "barretina" then
    return "head", f > 0 and s.x or s.x - (HW + 46), s.y - 64, HW + 46, 64
  elseif k == "fire" and pw.t >= 5 and pw.t <= 34 then
    return "fire", f > 0 and s.x + 20 or s.x - 130, s.y - 62, 110, 58
  elseif k == "shock" and pw.t <= 3 then
    return "shock", s.x - 96, s.y - 54, 192, 62
  elseif k == "pound" then
    return "shock", s.x - 24, s.y - 40, 48, 70
  elseif k == "splash" then
    return "splash", s.x - 26, s.y - 80, 52, 100
  end
  return nil
end

-- the kinds of toy each power beats
local FIRE = {plane = true, robot = true}
function P.beats(kind, foe) if kind == "fire" then return FIRE[foe] == true end return true end

return P
