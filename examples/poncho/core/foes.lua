-- foes: four toys that bother Poncho, drawn from code for now (placeholders): a rolling car, a wind-up robot, a bouncing ball, a paper plane.
-- Jump on one from above and it is done; touch it any other way and it costs a heart. They sleep when far from the hero.
local K = require("core.const")
local M = require("core.map")
local L = require("core.level")
local U = require("core.util")
local Hero = require("core.hero")
local Fx = require("core.fx")
local Snd = require("core.sound")
local In = require("core.input")
local Power = require("core.power")
local Deco = require("core.deco")
local Beat = require("core.beat")

local F = {}
F.list = {}
F.events = {}

-- hitboxes (w, h; feet at the bottom middle, a flyer's body centred), 90% of the art's visible body: gen/hitbox_check.py compares them with the pictures
local SIZE = {car = {57, 37}, robot = {38, 56}, ball = {43, 42}, plane = {56, 42},
              apple = {40, 50}, banana = {45, 45}, bee = {50, 53}, cherry = {46, 55}, melon = {36, 41}, pigeon = {46, 51}, snail = {63, 46},
              note = {42, 54}, cable = {54, 42}, speaker = {41, 52}, bubble = {70, 58}}
local WAKE = 640

F.rings = {} -- the speakers' sound rings in flight
function F.clear() F.list, F.events, F.rings = {}, {}, {} end

local function spawn(kind, x, y, range)
  local sz = SIZE[kind]
  local f = {kind = kind, x = x, y = y, w = sz[1], h = sz[2], vx = 0, vy = 0, dir = -1, t = 0, dead = 0, home = x, range = (range or 5) * K.TILE,
             phase = 0, mode = "walk", mt = 0, base_y = y}
  if kind == "car" then f.vx = -1.25
  elseif kind == "ball" then f.vx = -0.9 f.vy = 0
  elseif kind == "plane" then f.vx = -1.3
  elseif kind == "robot" then f.vx = -0.55
  elseif kind == "apple" then f.vx = -0.8
  elseif kind == "banana" then f.vx = -1.0
  elseif kind == "bee" then f.vx = -1.4
  elseif kind == "cherry" then f.vx = -0.8
  elseif kind == "note" then f.vx = -0.5 f.vy = 0
  elseif kind == "cable" then f.vx = -1.0
  elseif kind == "speaker" then f.vx = 0 f.pulse = 0
  elseif kind == "bubble" then f.vx = -0.8
  elseif kind == "pigeon" then f.vx = -0.9
  elseif kind == "snail" then f.vx = -0.35
  elseif kind == "melon" then f.vx = -2.0 f.immune = true end
  F.list[#F.list + 1] = f
  return f
end
F.spawn = spawn

function F.init()
  F.clear()
  for _, d in ipairs(M.foes) do
    local y = d.y
    if d.kind ~= "plane" and d.kind ~= "bee" and d.kind ~= "bubble" then -- walkers and balls start on the ground under their tile
      y = L.ground(d.x, d.y - 40, d.y + 200, 40) or d.y
    end
    local f = spawn(d.kind, d.x, y, d.range)
    if d.phase then f.vy = d.phase f.t = d.phase * 7 end -- (cherries in pairs bounce out of step)
  end
end

-- is there ground to step on a little ahead, and no wall in the way
local function can_go(f, dir)
  local ax = f.x + dir * (f.w / 2 + 4)
  if L.solid_at(ax, f.y - 8) or L.solid_at(ax, f.y - f.h + 4) then return false end
  if not L.ground(ax, f.y - 6, f.y + 24, 0) then return false end
  return true
end

local function walk(f, speed)
  if f.dir ~= (f.vx < 0 and -1 or 1) then f.vx = f.dir * math.abs(f.vx) end
  local d = f.dir
  if not can_go(f, d) or (f.x + d * 6 - f.home) * d > f.range then
    f.dir = -d
    f.vx = -f.vx
    return
  end
  f.x = f.x + d * speed
  local gy = L.ground(f.x, f.y - 12, f.y + 14, 12)
  if gy then f.y = gy end
end

local function update_one(f, hx)
  f.t = f.t + 1
  local k = f.kind
  if k == "car" then
    walk(f, 1.25)
    f.phase = f.phase + 1.25 * f.dir / 9
  elseif k == "robot" then
    f.mt = f.mt + 1
    if f.mode == "walk" then
      walk(f, 0.55)
      f.phase = f.phase + 0.05
      if f.mt > 100 then f.mode, f.mt = "wind", 0 f.dir = (hx > f.x) and 1 or -1 f.vx = f.dir * math.abs(f.vx) end
    elseif f.mode == "wind" then
      f.phase = f.phase + 0.5
      if f.mt > 34 then f.mode, f.mt = "dash", 0 end
    else
      walk(f, 1.9)
      f.phase = f.phase + 0.12
      if f.mt > 52 then f.mode, f.mt = "walk", 0 end
    end
  elseif k == "ball" then
    f.x = f.x + f.dir * 0.9
    f.vy = f.vy + 0.42
    f.y = f.y + f.vy
    local gy = L.ground(f.x, f.y - f.vy - 2, f.y, 2)
    if gy then f.y, f.vy = gy, -8.6 f.squash = 6 end
    if L.solid_at(f.x + f.dir * 16, f.y - 16) or (f.x - f.home) * f.dir > f.range then f.dir = -f.dir end
    f.phase = f.phase + f.dir * 0.07
    if f.squash and f.squash > 0 then f.squash = f.squash - 1 end
  elseif k == "apple" then
    if f.mode == "roll" then -- stomped once: curled into a ball that rolls fast, then uncurls
      f.mt = f.mt + 1
      walk(f, 3.4)
      f.phase = f.phase + f.dir * 0.4
      if f.mt > 170 then f.mode, f.mt = "walk", 0 end
    else
      walk(f, 0.8)
      f.phase = f.phase + 0.09
    end
  elseif k == "banana" then -- it slides: slow, then a long fast slide at the hero when he is near and in front
    f.mt = f.mt + 1
    if f.mode == "walk" then
      walk(f, 0.9)
      f.phase = f.phase + 0.08
      if math.abs(hx - f.x) < 260 and f.mt > 60 then f.mode, f.mt, f.dir = "slide", 0, (hx > f.x) and 1 or -1 f.vx = f.dir * math.abs(f.vx) end
    elseif f.mode == "slide" then
      walk(f, 3.6)
      f.phase = f.phase + 0.3
      if f.mt > 46 then f.mode, f.mt = "rest", 0 end
    else
      if f.mt > 40 then f.mode, f.mt = "walk", 0 end
    end
  elseif k == "bee" then -- a sine path, and a dive at the hero when he is near below it
    f.mt = f.mt + 1
    if f.mode == "dive" then
      f.x = f.x + f.dir * 2.4
      f.y = f.y + 3.4
      if f.mt > 26 or L.solid_at(f.x, f.y) then f.mode, f.mt = "up", 0 end
    elseif f.mode == "up" then
      f.y = f.y - 2.2
      f.x = f.x + f.dir * 0.6
      if f.y <= f.base_y - 96 then f.mode, f.mt = "walk", 0 f.t = 0 end
    else
      f.x = f.x + f.dir * 1.4
      if (f.x - f.home) * f.dir > f.range then f.dir = -f.dir end
      f.y = f.base_y - 96 + math.sin(f.t / 20) * 26
      if f.mt > 90 and math.abs(hx - f.x) < 90 then f.mode, f.mt, f.dir = "dive", 0, (hx > f.x) and 1 or -1 end
    end
    f.phase = f.t
  elseif k == "cherry" then -- a high bouncer
    f.x = f.x + f.dir * 0.5
    f.vy = f.vy + 0.45
    f.y = f.y + f.vy
    f.bt = (f.bt or 0) + 1
    local gy = L.ground(f.x, f.y - f.vy - 2, f.y, 2)
    if gy then f.y, f.vy = gy, -10.4 f.squash = 6 f.bt = 0 end
    if L.solid_at(f.x + f.dir * 16, f.y - 16) or (f.x - f.home) * f.dir > f.range then f.dir = -f.dir end
    if f.squash and f.squash > 0 then f.squash = f.squash - 1 end
  elseif k == "pigeon" then -- struts, stops to peck the ground (a moment when it is easy to jump on), then struts on
    f.mt = f.mt + 1
    if f.mode == "walk" then
      walk(f, 0.9)
      f.phase = f.phase + 0.1
      if f.mt > 110 then f.mode, f.mt = "peck", 0 end
    else
      if f.mt > 46 then f.mode, f.mt = "walk", 0 end
    end
  elseif k == "snail" then -- very slow; stomped once it hides in its shell (harmless, you can stand on it) and comes out again, stomped twice it is gone
    f.mt = f.mt + 1
    if f.mode == "shell" then
      f.stun = true
      if f.mt > 160 then f.mode, f.mt, f.stun, f.h = "walk", 0, nil, 34 end
    else
      walk(f, 0.35)
      f.phase = f.phase + 0.04
    end
  elseif k == "note" then -- a note that hops on every beat, drifting a little
    f.vy = f.vy + 0.42
    f.y = f.y + f.vy
    local gy = L.ground(f.x, f.y - f.vy - 2, f.y, 2)
    if gy then
      f.y, f.vy = gy, 0
      if Beat.downbeat() then f.vy = -9.2 f.squash = 6 end
    end
    if f.vy ~= 0 then
      f.x = f.x + f.dir * 0.6
      if L.solid_at(f.x + f.dir * 16, f.y - 16) or (f.x - f.home) * f.dir > f.range then f.dir = -f.dir end
    end
    f.phase = f.phase + 0.1
    if f.squash and f.squash > 0 then f.squash = f.squash - 1 end
  elseif k == "cable" then -- a cable slithers, then shoots along the floor at the hero
    f.mt = f.mt + 1
    if f.mode == "walk" then
      walk(f, 0.9)
      f.phase = f.phase + 0.1
      if math.abs(hx - f.x) < 260 and f.mt > 60 then f.mode, f.mt, f.dir = "slide", 0, (hx > f.x) and 1 or -1 f.vx = f.dir * math.abs(f.vx) end
    elseif f.mode == "slide" then
      walk(f, 3.2)
      f.phase = f.phase + 0.3
      if f.mt > 40 then f.mode, f.mt = "rest", 0 end
    else
      if f.mt > 50 then f.mode, f.mt = "walk", 0 end
    end
  elseif k == "speaker" then -- it stands still and, every second beat, sends a sound ring along the floor toward the hero
    f.dir = (hx > f.x) and 1 or -1
    if f.pulse > 0 then f.pulse = f.pulse - 1 end
    if Beat.t % 60 == 0 and math.abs(hx - f.x) < 420 and #F.rings < 6 then
      F.rings[#F.rings + 1] = {x = f.x + f.dir * 22, y = f.y - 30, dir = f.dir, t = 0}
      f.pulse = 10
      Snd.play("wind", 0.6)
    end
  elseif k == "bubble" then -- a mute cloud: floats in a sine, leaning toward the hero
    f.t = f.t + 0
    local d = (hx > f.x) and 1 or -1
    if math.abs(hx - f.x) < 320 then f.x = f.x + d * 0.7 f.dir = d end
    f.y = f.base_y - 90 + math.sin(f.t / 24) * 30
    f.phase = f.t
  elseif k == "melon" then -- a rolling melon: it cannot be beaten, only jumped over
    walk(f, 2.0)
    f.phase = f.phase + f.dir * 3.2
  elseif k == "plane" then
    f.x = f.x + f.dir * 1.3
    if (f.x - f.home) * f.dir > f.range then f.dir = -f.dir end
    f.y = f.base_y - 96 + math.sin(f.t / 26) * 30
    f.tilt = math.cos(f.t / 26) * 0.5
  end
end

-- the spotlight: a beam sweeps the stage's zone; a toy in it stands still
local beam_x = nil
local function frozen(f)
  local sp = M.spot
  if not sp or f.x < sp.x0 or f.x > sp.x1 then return false end
  return math.abs(f.x - beam_x) < 74
end
function F.beam() return beam_x end

-- the sound rings: they fly along the floor and are gone on a wall; a ring that meets him costs a heart (a jump clears it)
local function update_rings(s)
  local rs = F.rings
  for i = #rs, 1, -1 do
    local r = rs[i]
    r.t = r.t + 1
    r.x = r.x + r.dir * 2.4
    if r.t > 150 or L.solid_at(r.x, r.y) then rs[i] = rs[#rs] rs[#rs] = nil
    elseif s.state == "play" and s.inv == 0 and math.abs(r.x - s.x) < 22 and r.y > s.y - K.BODY_H - 8 and r.y < s.y + 6 then
      rs[i] = rs[#rs] rs[#rs] = nil
      Hero.hurt(r.x)
      F.events.hurt = true
    end
  end
end

function F.update()
  F.events = {}
  local sp = M.spot
  if sp then beam_x = sp.x0 + (sp.x1 - sp.x0) * (0.5 + 0.5 * math.sin(Beat.t / 70)) end
  update_rings(Hero.s)
  local s = Hero.s
  local hx0, hy0, hw, hh = Hero.box()
  for i = #F.list, 1, -1 do
    local f = F.list[i]
    if f.dead > 0 then
      f.dead = f.dead + 1
      if f.dead > 26 then table.remove(F.list, i) end
    elseif math.abs(f.x - s.x) < WAKE then
      if not frozen(f) then update_one(f, s.x) else f.t = f.t + 1 end
      local ak, ax, ay, aw, ah = Hero.attack()
      if ak and f.dead == 0 and not f.immune and Power.beats(ak, f.kind) and U.overlap(ax, ay, aw, ah, f.x - f.w / 2, f.y - f.h, f.w, f.h) then
        f.dead = 1
        F.events.power = true
        Snd.play("stomp")
        Fx.sparkle(f.x, f.y - f.h / 2, 0xFFFFFF, 8)
      end
      if f.dead == 0 and (s.state == "play" or s.state == "hurt") then
        local fx0, fy0 = f.x - f.w / 2, f.y - f.h
        if U.overlap(hx0 + 3, hy0 + 4, hw - 6, hh - 4, fx0, fy0, f.w, f.h) then
          local stomp = s.vy > 0.3 and s.y < f.y - f.h * 0.35 and s.state == "play"
          if stomp then
            Hero.bounce(In.btn("a") and K.STOMP_V_HELD or K.STOMP_V, In.btn("a"))
            Snd.play("stomp")
            Fx.sparkle(f.x, f.y - f.h / 2, 0xFFFFFF, 8)
            Fx.burst(f.x, f.y - f.h / 2)
            if f.immune then -- a melon: a bounce and nothing more
            elseif f.kind == "snail" and f.mode ~= "shell" then
              f.mode, f.mt, f.h = "shell", 0, 26
              F.events.curl = true
            elseif f.kind == "apple" and f.mode ~= "roll" then -- the first stomp curls it into a ball
              f.mode, f.mt, f.dir = "roll", 0, (f.x >= s.x) and 1 or -1
              f.h = 30
              F.events.curl = true
            else
              f.dead = 1
              F.events.stomp = true
            end
          elseif s.inv == 0 and s.state == "play" and not f.stun then
            Hero.hurt(f.x)
            F.events.hurt = true
          end
        end
      end
    end
  end
end

-- ---------------------------------------------------------------- drawing

-- pictures (core/deco.lua) face right; `flip` turns them. A beaten toy is squashed flat with sy.
local function over(f) return f.dead > 0 end

local function car(f)
  local fr = math.floor(f.phase * 1.27) % 8
  if over(f) then fr = f.dead < 12 and 8 or 9 end
  Deco.img("TOY_CAR", fr, math.floor(f.x), math.floor(f.y), {flip = f.dir < 0})
end

local function robot(f)
  local fr = math.floor(f.phase * 1.9) % 10
  if f.mode == "wind" then fr = 10 + (f.mt // 4) % 2 end
  if over(f) then fr = f.dead < 10 and 12 + (f.dead // 4) % 2 or 14 + (f.dead // 5) % 2 end
  Deco.img("TOY_ROBOT", fr, math.floor(f.x), math.floor(f.y), {flip = f.dir < 0})
end

local function ball(f)
  local fr = 0
  if f.squash and f.squash > 0 then fr = 1
  elseif f.vy < -4 then fr = 2
  elseif f.vy < -1 then fr = 3
  elseif f.vy < 1 then fr = 4
  elseif f.vy < 4 then fr = 5
  else fr = 6 end
  if over(f) then fr = f.dead < 12 and 8 or 9 end
  Deco.img("TOY_BALL", fr, math.floor(f.x), math.floor(f.y))
end

local function plane(f)
  local fr = (f.t // 3) % 8
  if over(f) then fr = f.dead < 8 and 8 or 9 end
  Deco.img("TOY_PLANE", fr, math.floor(f.x), math.floor(f.y - f.h / 2 + (f.dead > 0 and f.dead * 2 or 0)), {flip = f.dir < 0})
end

-- the market's toys (FE_*: soles anchored, except the bee, anchored at its body). Frames: apple walk 0-7, curl 8-11, roll 12-17, hurt 18, defeated 19; banana slide 0-7,
-- squash 8-10, defeated 11-12; bee fly 0-7, dive 8-11, defeated 12-13; cherry bounce 0-7, defeated 8-9. The melon is Mama Sandia's rolling ball, small.
local alook = {}
local function market(f)
  local k, x, y = f.kind, math.floor(f.x), math.floor(f.y)
  alook.flip, alook.sx, alook.sy, alook.mul = f.dir < 0, nil, nil, nil
  if k == "apple" then
    local fr = math.floor(f.phase) % 8
    if f.mode == "roll" then fr = f.mt < 14 and 8 + f.mt // 4 or 12 + math.floor(f.phase) % 6 end
    if over(f) then fr = f.dead < 10 and 18 or 19 end
    Deco.img("FE_APPLE", fr, x, y, alook)
  elseif k == "banana" then
    local fr = math.floor(f.phase) % 8
    if over(f) then fr = f.dead < 10 and 8 + f.dead // 4 or 11 + (f.dead // 8) % 2 end
    Deco.img("FE_BANANA", fr, x, y, alook)
  elseif k == "bee" then
    local fr = (f.t // 3) % 8
    if f.mode == "dive" then fr = 8 + (f.mt // 4) % 4 end
    if over(f) then fr = f.dead < 12 and 12 or 13 end
    Deco.img("FE_BEE", fr, x, y - f.h // 2 + (f.dead > 0 and f.dead * 2 or 0), alook)
  elseif k == "cherry" then
    local fr = math.min(7, (f.bt or 0) * 8 // 46)
    if over(f) then fr = f.dead < 12 and 8 or 9 end
    Deco.img("FE_CHERRY", fr, x, y, alook)
  elseif Deco.has("FE_MELON") then -- the melon: roll_0..5 (frames 8-13), hurt 14, defeated 15
    local fr = 8 + math.floor(f.phase / 40) % 6
    if over(f) then fr = 15 end
    Deco.img("FE_MELON", fr, x, y, alook)
  else -- (the stand-in: Mama Sandia's rolling picture, small)
    alook.sx, alook.sy = 0.4, 0.4
    Deco.img("BOSS_SANDIA", 6 + math.floor(f.phase / 45) % 8, x, y, alook)
  end
end

-- the chalk park's walkers: CE_PIGEON (walk 0-7, peck 8-11, defeated last two) and CE_SNAIL (slide 0-7, shell 8-10, defeated last two) when the data has them, else
-- the market's apple and banana, tinted
-- the stage's toys (KE_*) when the data has them, else the park's, tinted: a note hops, a cable slides, a speaker pulses, a bubble floats
local KE = {note = {"KE_NOTE", "CE_BALL", 0xE0A0FF}, cable = {"KE_CABLE", "CE_SNAIL", 0xFFE070}, bubble = {"KE_BUBBLE", "CE_KITE", 0xB0B0D0}}
local function stage(f)
  local k, x, y = f.kind, math.floor(f.x), math.floor(f.y)
  alook.flip, alook.sx, alook.sy, alook.mul = f.dir < 0, nil, nil, nil
  if k == "speaker" then
    local own = Deco.has("KE_SPEAKER")
    if own then
      local fr = f.pulse > 0 and 6 + (f.pulse // 5) % 2 or (Beat.t // 5) % 6 -- pulse 0-5, shout 6-7
      if over(f) then fr = f.dead < 12 and 8 or 9 end
      Deco.img("KE_SPEAKER", fr, x, y, alook)
    else -- a box with two cones, swelling on the pulse
      local g = f.pulse > 0 and 3 or 0
      if over(f) then g = -8 end
      rect(x - 22 - g, y - 56 - g, 44 + 2 * g, 56 + g, 0x302848)
      circ(x, y - 38, 12 + g, 0x6A60A0, true)
      circ(x, y - 14, 8 + g, 0x6A60A0, true)
    end
    return
  end
  local e = KE[k]
  local own = Deco.has(e[1])
  local id = own and e[1] or e[2]
  alook.mul = (not own) and e[3] or nil
  local n = Deco.count(id)
  local fr = math.floor(f.phase) % math.max(1, n - 2)
  if own and k == "cable" then fr = (f.mode == "rest") and 8 + (f.mt // 10) % 3 or math.floor(f.phase) % 8 end -- slide 0-7, coil 8-10
  if k == "bubble" then y = y - f.h // 2 end -- (the body's centre: the hitbox hangs from f.y)
  if over(f) then fr = n - 2 + (f.dead < 12 and 0 or 1) end
  Deco.img(id, fr, x, y, alook)
end

local function park(f)
  local k, x, y = f.kind, math.floor(f.x), math.floor(f.y)
  local own = Deco.has(k == "pigeon" and "CE_PIGEON" or "CE_SNAIL")
  local id = own and (k == "pigeon" and "CE_PIGEON" or "CE_SNAIL") or (k == "pigeon" and "FE_APPLE" or "FE_BANANA")
  alook.flip, alook.sx, alook.sy = f.dir < 0, nil, nil
  alook.mul = (not own) and (k == "pigeon" and 0xB8C0D8 or 0xE0B090) or nil
  local n = Deco.count(id)
  local fr = math.floor(f.phase) % 8
  if k == "pigeon" and f.mode == "peck" then fr = own and ((f.mt // 7) % 2 == 0 and 1 or 3) or 8 + (f.mt // 8) % 4 end
  if k == "snail" and f.mode == "shell" then fr = 8 + math.min(2, f.mt // 6) end
  if not own then fr = fr % math.max(1, n - 2) end
  if over(f) then fr = n - 2 + (f.dead < 12 and 0 or 1) end
  Deco.img(id, fr, x, y, alook)
end

function F.draw(cam_x)
  for _, r in ipairs(F.rings) do circ(math.floor(r.x), math.floor(r.y), 10 + (r.t // 6) % 3 * 2, 0xE8E0FF, false) end
  for _, f in ipairs(F.list) do
    local dx = f.x - cam_x
    if dx > -80 and dx < K.W + 80 then
      local k = f.kind
      if k == "car" then car(f) elseif k == "robot" then robot(f) elseif k == "ball" then ball(f) elseif k == "plane" then plane(f) elseif k == "pigeon" or k == "snail" then park(f) elseif k == "note" or k == "cable" or k == "speaker" or k == "bubble" then stage(f) else market(f) end
    end
  end
end

return F
