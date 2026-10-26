-- boss: the end of a world. The last screen of the level is the arena: when the hero walks in, the camera and the hero's walls close on it, the boss's life
-- bar shows, and the fight goes in patterns. The boss can be hurt only while it is down (stunned, or tired); a hit (a stomp on it, or a costume's power) takes one
-- life and gives it a moment of invulnerability. At the last life it is beaten: the walls open and the flag, shut until then, is open.
--   cuerda  Capitan Cuerda, a giant wind-up robot (world 1, 6 lives): walks at the hero, winds up (a warning), charges across the arena (a jump clears it) and,
--           against the wall, is stunned. Below 4 lives it charges there and back; below 3 it throws toy cars.
--   sandia  Mama Sandia, a giant watermelon (world 2, 6 lives): rolls from wall to wall, stops in the middle and spits seeds, then she is tired with her mouth open.
-- Pictures: BOSS_CUERDA (idle 0-5, hurt 6-8, walk 9-16, stomp 17-22, angry 23-26, spin 27-32, defeated 33-36 with the golden key alone last) and BOSS_SANDIA (idle 0-5,
-- roll 6-13, spit 14-19, hurt 20-22, angry 23-26, defeated 27-30), both anchored at the soles.
local K = require("core.const")
local L = require("core.level")
local Hero = require("core.hero")
local Cam = require("core.cam")
local Fx = require("core.fx")
local Snd = require("core.sound")
local U = require("core.util")
local Foes = require("core.foes")
local Deco = require("core.deco")

local B = {}
local def          -- {id, x, y} from the map, or nil
local b            -- the boss
B.started, B.dead, B.events = false, false, {}
B.maxhp = 6

local SPEC = {
  cuerda = {w = 80, h = 84, name = "boss_cuerda"},
  sandia = {w = 110, h = 84, name = "boss_sandia"},
}

function B.reset(d)
  def = d
  B.started, B.dead, B.events, b = false, false, {}, nil
  Cam.lock, Hero.bounds = nil, nil
  if d then
    local sp = SPEC[d.id]
    b = {id = d.id, x = d.x, y = d.y, w = sp.w, h = sp.h, hp = B.maxhp, inv = 0, mode = "wait", mt = 0, dir = -1, vx = 0, t = 0, ang = 0, passes = 0, seeds = {}, shots = 0}
  end
end
function B.pending() return def ~= nil and not B.dead end
function B.beaten() return def == nil or B.dead end
function B.info() return b end
function B.name() return def and SPEC[def.id].name end
function B.hp() return b and b.hp or 0 end
function B.active() return B.started and not B.dead end

-- the fight is lost (the hero died): the arena opens and the boss starts again at full life, to be woken at the next try
function B.retry() if def and not B.dead then B.reset(def) end end

local function arena() return L.W - K.W, L.W end

local function hurt_hero(from) Hero.hurt(from) end

local function vulnerable() return b.mode == "stun" or b.mode == "tired" end

-- a hit: one life
local function damage(by_stomp)
  b.hp = b.hp - 1
  b.inv = 55
  Fx.sparkle(b.x, b.y - b.h * 0.7, 0xFFFFFF, 6)
  Fx.ring(b.x, b.y - b.h / 2, 10, 70, 0xFFD060, 14)
  Snd.play("pound")
  B.events.hit = true
  Cam.kick(10)
  if b.hp <= 0 then
    b.mode, b.mt = "dying", 0
    B.events.beaten_start = true
  end
end

local function steer(to, speed) b.dir = to > b.x and 1 or -1 b.x = b.x + b.dir * speed end

local function update_cuerda(s, x0, x1)
  local m = b.mode
  b.mt = b.mt + 1
  if m == "intro" then
    if b.mt > 50 then b.mode, b.mt = "walk", 0 end
  elseif m == "walk" then
    steer(s.x, 0.8)
    b.t = b.t + 1
    if b.mt > 80 then b.mode, b.mt, b.passes = "wind", 0, (b.hp <= 4) and 2 or 1 end
  elseif m == "wind" then
    b.dir = s.x > b.x and 1 or -1
    if b.mt == 1 and b.hp <= 2 then Foes.spawn("car", b.dir > 0 and x0 + 40 or x1 - 40, b.y, 6) end
    if b.mt > 42 then b.mode, b.mt = "charge", 0 b.start_dir = b.dir end
  elseif m == "charge" then
    local v = b.hp <= 2 and 6.4 or (b.hp <= 4 and 5.6 or 4.6)
    b.x = b.x + b.dir * v
    if b.x < x0 + 34 or b.x > x1 - 34 then
      b.x = U.clamp(b.x, x0 + 34, x1 - 34)
      Cam.kick(12) Snd.play("bump")
      b.passes = b.passes - 1
      if b.passes > 0 then b.dir = -b.dir else b.mode, b.mt = "stun", 0 end
    end
  elseif m == "stun" then
    if b.mt > 140 then b.mode, b.mt = "walk", 0 end
  end
end

local function update_sandia(s, x0, x1)
  local m = b.mode
  b.mt = b.mt + 1
  if m == "intro" then
    if b.mt > 50 then b.mode, b.mt, b.passes = "roll", 0, 3 b.dir = -1 end
  elseif m == "roll" then
    local v = b.hp <= 3 and 4.4 or 3.4
    b.x = b.x + b.dir * v
    b.ang = b.ang + b.dir * v * 2.2
    if b.x < x0 + 50 or b.x > x1 - 50 then
      b.x = U.clamp(b.x, x0 + 50, x1 - 50)
      b.dir = -b.dir
      Cam.kick(8) Snd.play("bump")
      b.passes = b.passes - 1
      if b.passes <= 0 then b.mode, b.mt, b.shots = "center", 0, 0 end
    end
  elseif m == "center" then
    local mid = (x0 + x1) / 2
    b.ang = b.ang + b.dir * 2
    if math.abs(b.x - mid) < 4 then b.mode, b.mt = "spit", 0 else steer(mid, 2.4) end
  elseif m == "spit" then
    local every = b.hp <= 3 and 18 or 26
    if b.mt % every == 5 then
      local n = b.hp <= 3 and 2 or 1
      for i = 1, n do
        local dx = (s.x - b.x) + (i - 1) * 70 - (n - 1) * 35
        b.seeds[#b.seeds + 1] = {x = b.x, y = b.y - 60, vx = U.clamp(dx / 42, -4.5, 4.5), vy = -7.5}
      end
      Snd.play("fire")
    end
    if b.mt > (b.hp <= 3 and 96 or 90) then b.mode, b.mt = "tired", 0 end
  elseif m == "tired" then
    if b.mt > 150 then b.mode, b.mt, b.passes = "roll", 0, 3 b.dir = s.x > b.x and 1 or -1 end
  end
  for i = #b.seeds, 1, -1 do -- the seeds fly in an arc and break on the floor
    local sd = b.seeds[i]
    sd.vy = sd.vy + 0.32
    sd.x, sd.y = sd.x + sd.vx, sd.y + sd.vy
    if sd.y >= b.y - 4 then
      table.remove(b.seeds, i)
      Fx.dust(sd.x, b.y, 2, 0, 1)
    elseif math.abs(sd.x - s.x) < 22 and sd.y > s.y - 62 and sd.y < s.y + 4 and s.inv == 0 and s.state == "play" then
      table.remove(b.seeds, i)
      hurt_hero(sd.x)
    end
  end
end

function B.update()
  B.events = {}
  if not b then return end
  local s = Hero.s
  local x0, x1 = arena()
  if not B.started then
    if s.x > x0 + 48 and s.state == "play" then
      B.started = true
      Cam.lock = {x0, x1}
      Hero.bounds = {x0, x1}
      b.mode, b.mt = "intro", 0
      B.events.start = true
    end
    return
  end
  if B.dead then return end
  if b.inv > 0 then b.inv = b.inv - 1 end
  if b.mode == "dying" then
    b.mt = b.mt + 1
    if b.mt % 6 == 0 then Fx.sparkle(b.x + (math.random() - 0.5) * 60, b.y - math.random() * b.h, 0xFFE060, 3) end
    if b.mt % 20 == 0 then Fx.ring(b.x, b.y - b.h / 2, 10, 80, 0xFFFFFF, 14) Snd.play("pound") end
    if b.mt > 110 then
      B.dead = true
      Cam.lock, Hero.bounds = nil, nil
      B.events.beaten = true
      Fx.confetti(b.x, b.y - 80, 20)
      Snd.play("win")
    end
    return
  end
  if b.id == "cuerda" then update_cuerda(s, x0, x1) else update_sandia(s, x0, x1) end
  if b.mode == "intro" or b.mode == "wait" then return end
  -- the hero meets it
  local bx0, by0 = b.x - b.w / 2, b.y - b.h
  local hx0, hy0, hw, hh = Hero.box()
  local touching = U.overlap(hx0 + 3, hy0 + 4, hw - 6, hh - 4, bx0, by0, b.w, b.h)
  local stomp = touching and s.vy > 0.3 and s.y < b.y - b.h * 0.55 and s.state == "play"
  if vulnerable() and b.inv == 0 then
    local ak, ax, ay, aw, ah = Hero.attack()
    if stomp then
      Hero.bounce(K.STOMP_V_HELD, true)
      damage(true)
    elseif ak and U.overlap(ax, ay, aw, ah, bx0 - 10, by0 - 10, b.w + 20, b.h + 20) then
      damage(false)
    end
  elseif touching and stomp then
    Hero.bounce(K.STOMP_V, false) -- it is not down: a bounce, no harm done
    Snd.play("bump")
  elseif touching and not vulnerable() and s.inv == 0 and s.state == "play" then
    hurt_hero(b.x)
  end
end

-- ---------------------------------------------------------------- drawing (world pixels, under camera())
local look = {}
local function hurt_frame(base) return base + (b.inv > 36 and 0 or (b.inv > 18 and 1 or 2)) end

function B.draw(cam_x)
  if not b then return end
  if not B.started and math.abs(b.x - cam_x - K.W / 2) > K.W then return end
  local x, y = math.floor(b.x), math.floor(b.y)
  look.sx, look.sy, look.alpha, look.mul, look.angle = nil, nil, nil, nil, nil
  look.flip = b.dir < 0
  if b.id == "cuerda" then
    local fr
    local m = b.mode
    if B.dead then Deco.img("BOSS_CUERDA", 36, x, y, look) return end -- the golden key, left behind
    if m == "dying" then fr = 33 + math.min(2, b.mt // 36)
    elseif b.inv > 0 and m == "stun" then fr = hurt_frame(6)
    elseif m == "intro" or m == "wait" then fr = (b.mt // 8) % 6
    elseif m == "walk" then fr = 9 + (b.mt // 5) % 8
    elseif m == "wind" then fr = b.hp <= 2 and 17 + math.min(5, b.mt * 6 // 42) or 23 + (b.mt // 4) % 4
    elseif m == "charge" then fr = 30 + (b.mt // 2) % 2
    elseif m == "stun" then fr = 32
    else fr = 0 end
    Deco.img("BOSS_CUERDA", fr, x + (m == "wind" and (b.mt % 2 == 0 and 2 or -2) or 0), y, look)
  else
    if B.dead then return end
    local fr
    local m = b.mode
    if m == "dying" then fr = 27 + math.min(3, b.mt // 28)
    elseif b.inv > 0 then fr = hurt_frame(20)
    elseif m == "intro" or m == "wait" then fr = (b.mt // 8) % 6
    elseif m == "roll" then fr = (b.hp <= 3 and 23 + (b.mt // 4) % 4) or (6 + math.floor(b.ang / 45) % 8)
    elseif m == "center" then fr = 23 + (b.mt // 4) % 4
    elseif m == "spit" then fr = 14 + math.min(5, (b.mt % 26) * 6 // 26)
    elseif m == "tired" then fr = 20
    else fr = 0 end
    Deco.img("BOSS_SANDIA", fr, x, y, look)
    for _, sd in ipairs(b.seeds) do rect(math.floor(sd.x) - 4, math.floor(sd.y) - 4, 9, 9, 0x202020) end
  end
  if b.mode == "stun" and b.id == "cuerda" then -- stars going round its head
    local a = b.mt * 0.18
    for i = 0, 1 do rect(x + math.floor(math.cos(a + i * 3.14) * 30) - 3, y - 128 + math.floor(math.sin(a + i * 3.14) * 6), 7, 7, 0xFFE060) end
  end
end

-- the life bar, in screen pixels: its name and a row of lives
function B.hud(lang)
  if not b or not B.started or B.dead then return end
  local w = 200
  local x, y = (K.W - w) // 2, 12
  rect(x - 3, y - 3, w + 6, 30, 0x2A1A3A)
  rect(x, y + 14, w, 9, 0x4A2A4A)
  rect(x, y + 14, math.floor(w * math.max(0, b.hp) / B.maxhp), 9, 0xE04050)
  text(lang.tr(SPEC[b.id].name), K.W // 2, y - 1, {font = "snes_small", color = 0xFFFFFF, align = "center"})
end

return B
