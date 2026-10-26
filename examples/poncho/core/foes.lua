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
local Deco = require("core.deco")

local F = {}
F.list = {}
F.events = {}

local SIZE = {car = {54, 32}, robot = {30, 54}, ball = {36, 36}, plane = {46, 26}}
local WAKE = 640

function F.clear() F.list, F.events = {}, {} end

local function spawn(kind, x, y, range)
  local sz = SIZE[kind]
  local f = {kind = kind, x = x, y = y, w = sz[1], h = sz[2], vx = 0, vy = 0, dir = -1, t = 0, dead = 0, home = x, range = (range or 5) * K.TILE,
             phase = 0, mode = "walk", mt = 0, base_y = y}
  if kind == "car" then f.vx = -1.25
  elseif kind == "ball" then f.vx = -0.9 f.vy = 0
  elseif kind == "plane" then f.vx = -1.3
  elseif kind == "robot" then f.vx = -0.55 end
  F.list[#F.list + 1] = f
  return f
end
F.spawn = spawn

function F.init()
  F.clear()
  for _, d in ipairs(M.foes) do
    local y = d.y
    if d.kind ~= "plane" then -- walkers and balls start on the ground under their tile
      y = L.ground(d.x, d.y - 40, d.y + 200, 40) or d.y
    end
    spawn(d.kind, d.x, y, d.range)
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
  elseif k == "plane" then
    f.x = f.x + f.dir * 1.3
    if (f.x - f.home) * f.dir > f.range then f.dir = -f.dir end
    f.y = f.base_y - 96 + math.sin(f.t / 26) * 30
    f.tilt = math.cos(f.t / 26) * 0.5
  end
end

function F.update()
  F.events = {}
  local s = Hero.s
  local hx0, hy0, hw, hh = Hero.box()
  for i = #F.list, 1, -1 do
    local f = F.list[i]
    if f.dead > 0 then
      f.dead = f.dead + 1
      if f.dead > 26 then table.remove(F.list, i) end
    elseif math.abs(f.x - s.x) < WAKE then
      update_one(f, s.x)
      if s.state == "play" or s.state == "hurt" then
        local fx0, fy0 = f.x - f.w / 2, f.y - f.h
        if U.overlap(hx0 + 3, hy0 + 4, hw - 6, hh - 4, fx0, fy0, f.w, f.h) then
          local stomp = s.vy > 0.3 and s.y < f.y - f.h * 0.35 and s.state == "play"
          if stomp then
            f.dead = 1
            Hero.bounce(In.btn("a") and K.STOMP_V_HELD or K.STOMP_V, In.btn("a"))
            F.events.stomp = true
            Snd.play("stomp")
            Fx.sparkle(f.x, f.y - f.h / 2, 0xFFFFFF, 8)
          elseif s.inv == 0 and s.state == "play" then
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

function F.draw(cam_x)
  for _, f in ipairs(F.list) do
    local dx = f.x - cam_x
    if dx > -80 and dx < K.W + 80 then
      local k = f.kind
      if k == "car" then car(f) elseif k == "robot" then robot(f) elseif k == "ball" then ball(f) else plane(f) end
    end
  end
end

return F
