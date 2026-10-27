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
local In = require("core.input")
local Beat = require("core.beat")

local B = {}
local def          -- {id, x, y} from the map, or nil
local b            -- the boss
B.started, B.dead, B.events = false, false, {}
B.t_end = 0
B.meter = 100  -- Silencio's: the music meter, drained while it inhales

local SPEC = {
  cuerda = {w = 80, h = 84, name = "boss_cuerda"},
  sandia = {w = 110, h = 84, name = "boss_sandia"},
  silencio = {w = 120, h = 140, name = "boss_silencio", maxhp = 9},
}

function B.reset(d)
  def = d
  B.started, B.dead, B.events, b = false, false, {}, nil
  B.meter = 100
  Hero.frozen = false
  Cam.lock, Hero.bounds = nil, nil
  if d then
    local sp = SPEC[d.id]
    b = {id = d.id, x = d.x, y = d.y, w = sp.w, h = sp.h, hp = sp.maxhp or 6, maxhp = sp.maxhp or 6, inv = 0, mode = "wait", mt = 0, dir = -1, vx = 0, t = 0, ang = 0, passes = 0, seeds = {}, shots = 0}
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

-- ---------------------------------------------------------------- el Gran Silencio: a friend-to-be, three phases of three lives.
-- It cannot be hurt by jumping on it. Its cycle: idle, SHH (it inhales: within 320 px, standing low, he is pulled toward it and his music meter drains; at nothing left
-- it costs a heart; stay far, or high, or in the air), the WAVE of its breath along the floor (jump it), then the rhythm round: he stands at the stage's four keys
-- (left, A, B, right) and four rings close in on them, one a beat (30 ticks): press the key as a ring reaches it. A ring caught within 3 ticks is perfect (2 points), within
-- 8 good (1); up to 3 points a round hurt it (never past the end of the phase); no points and it recovers a life. A scooter dash into it also starts a round.
local LANES = {"left", "a", "b", "right"}
local PATTERN = {{2, 3, 1, 4}, {1, 3, 2, 4}, {4, 1, 3, 2}}   -- the lane of each of the four rings, per phase
local R_START, R_GAP = 50, 30                                  -- the first ring's beat (ticks into the round), and the beat between rings
local NOTE_NAMES = {"C5", "E5", "G5", "C6"}

local function phase() return math.min(3, 3 - (b.hp - 1) // 3) end
function B.phase() return b and phase() or 0 end

local function start_round()
  b.mode, b.mt = "rhythm", 0
  b.notes, b.perfect, b.good = {}, 0, 0
  local pat = PATTERN[phase()]
  for i = 1, 4 do b.notes[i] = {lane = pat[i], T = R_START + R_GAP * (i - 1), done = false} end
  b.waves = {}
  Hero.frozen = true
  B.events.round_start = true
end

local function end_round()
  Hero.frozen = false
  local ph = phase()
  local dmg = math.min(3, b.perfect * 2 + b.good, b.hp - (3 - ph) * 3)
  B.events.round = {perfect = b.perfect, good = b.good}
  if dmg > 0 then
    b.hp = b.hp - dmg
    b.inv = 55
    Fx.sparkle(b.x, b.y - b.h * 0.7, 0xFFFFFF, 8)
    Fx.ring(b.x, b.y - b.h / 2, 10, 80, 0xFFD060, 14)
    Snd.play("pound")
    Cam.kick(10)
    B.events.hit = true
    if b.hp <= 0 then b.mode, b.mt = "dying", 0 B.events.beaten_start = true return end
  else
    b.hp = math.min((4 - ph) * 3, b.hp + 1) -- it recovers
  end
  b.mode, b.mt = "recover", 0
end

-- the rhythm round's key presses: a lane (1-4) judged against the ring nearest its beat
function B.press(lane)
  if not b or b.mode ~= "rhythm" then return end
  b.lit = b.lit or {}
  b.lit[lane] = 8
  for _, nt in ipairs(b.notes) do
    if not nt.done and nt.lane == lane and math.abs(b.mt - nt.T) <= 8 then
      nt.done = true
      local perfect = math.abs(b.mt - nt.T) <= 3
      if perfect then b.perfect = b.perfect + 1 else b.good = b.good + 1 end
      nt.hit = perfect and 2 or 1
      Snd.note(NOTE_NAMES[lane], 0.45)
      Fx.sparkle(Hero.s.x, Hero.s.y - 60, perfect and 0xFFE070 or 0x80E0FF, 5)
      return
    end
  end
end

-- for the bot: the lane and how many ticks to the beat of the next ring still to be played (nil when none)
function B.next_note()
  if not b or b.mode ~= "rhythm" then return nil end
  for _, nt in ipairs(b.notes) do
    if not nt.done and b.mt - nt.T <= 8 then return nt.lane, nt.T - b.mt end
  end
end
function B.waves() return b and b.waves or {} end

local function update_silencio(s, x0, x1)
  local m, ph = b.mode, phase()
  b.mt = b.mt + 1
  b.dir = s.x > b.x and 1 or -1
  if b.lit then for k, v in pairs(b.lit) do b.lit[k] = v > 1 and v - 1 or nil end end
  if m == "intro" then
    if b.mt > 60 then b.mode, b.mt = "idle", 0 end
  elseif m == "idle" then
    B.meter = math.min(100, B.meter + 0.6)
    if b.mt > (ph == 1 and 70 or 50) then b.mode, b.mt = "shh", 0 end
  elseif m == "shh" then
    if b.mt > 25 then
      local low = s.y >= b.y - 30 and s.state == "play"
      if low and math.abs(s.x - b.x) < 320 then
        s.vx = s.vx + (b.x > s.x and 1 or -1) * 0.17 * (1 + 0.25 * (ph - 1))
        B.meter = B.meter - 0.9
        if B.meter <= 0 then Hero.hurt(b.x) B.meter = 60 end
      else
        B.meter = math.min(100, B.meter + 0.5)
      end
    end
    if b.mt > 100 + 20 * (ph - 1) then
      b.mode, b.mt = "wave", 0
      b.waves = {{x = b.x - 40, dir = -1}}
    end
  elseif m == "wave" then
    if ph >= 2 and b.mt == 50 then b.waves[#b.waves + 1] = {x = b.x - 40, dir = -1} end
    local v = ph == 3 and 3.6 or 3.0
    local alive = 0
    for _, w in ipairs(b.waves) do
      if not w.gone then
        w.x = w.x + w.dir * v
        if w.x < x0 + 12 then w.gone = true
        else
          alive = alive + 1
          if s.state == "play" and s.inv == 0 and s.y > b.y - 26 and math.abs(w.x - s.x) < 24 then Hero.hurt(w.x) end
        end
      end
    end
    if alive == 0 and (ph < 2 or b.mt > 50) then start_round() end
  elseif m == "rhythm" then
    for lane = 1, 4 do if In.btnp(LANES[lane]) then B.press(lane) end end
    if b.mt > R_START + R_GAP * 3 + 20 then end_round() end
  elseif m == "recover" then
    if b.mt > 60 then b.mode, b.mt = "idle", 0 end
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
  if b.id == "cuerda" then update_cuerda(s, x0, x1) elseif b.id == "silencio" then update_silencio(s, x0, x1) else update_sandia(s, x0, x1) end
  if b.mode == "intro" or b.mode == "wait" then return end
  if b.id == "silencio" then -- it is not hurt by jumping on it; a scooter dash starts the rhythm round; in the round it is harmless
    if b.mode == "rhythm" or b.mode == "dying" then return end
    local bx0, by0 = b.x - b.w / 2, b.y - b.h
    local hx0, hy0, hw, hh = Hero.box()
    if U.overlap(hx0 + 3, hy0 + 4, hw - 6, hh - 4, bx0, by0, b.w, b.h) and s.state == "play" then
      if s.scooter and math.abs(s.vx) > 5.5 and (b.mode == "idle" or b.mode == "shh" or b.mode == "wave") then
        s.vx = (s.x < b.x) and -4 or 4
        Fx.ring(b.x, b.y - 50, 10, 70, 0xFFFFFF, 12)
        start_round()
      elseif s.vy > 0.3 and s.y < b.y - b.h * 0.55 then
        Hero.bounce(K.STOMP_V, false) Snd.play("bump")
      elseif s.inv == 0 then
        Hero.hurt(b.x)
      end
    end
    return
  end
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
  if b.id == "silencio" then
    -- BOSS_SILENCIO when the art is in the data (frames by name: idle_0.., inhale_0.., wave_0.., hurt_0.., def_0..), else Mama Sandia's picture, dimmed and tinted
    local own = Deco.has("BOSS_SILENCIO")
    local id = own and "BOSS_SILENCIO" or "BOSS_SANDIA"
    local m, fr = b.mode, 0
    if B.dead then -- beaten: a small smiling cloud at the stage's keyboard
      B.t_end = B.t_end + 1
      if own then
        Deco.img(id, "def_3", x, y - 24 + math.floor(math.sin(B.t_end / 14) * 4), look)
      else
        local cx, cy = x, y - 40 + math.floor(math.sin(B.t_end / 14) * 4)
        circ(cx - 16, cy, 14, 0xE8E4FF, true) circ(cx + 4, cy - 8, 18, 0xE8E4FF, true) circ(cx + 22, cy, 14, 0xE8E4FF, true) rect(cx - 16, cy, 38, 14, 0xE8E4FF)
        circ(cx - 3, cy - 4, 3, 0x2A1A3A, true) circ(cx + 12, cy - 4, 3, 0x2A1A3A, true)
      end
      rect(x - 30, y - 8, 60, 8, 0x2A1A3A) rect(x - 28, y - 6, 56, 3, 0xF4F0FF) -- the keyboard it plays
      return
    end
    if m == "dying" then fr = own and ("def_" .. math.min(2, b.mt // 36)) or 27 + math.min(3, b.mt // 28)
    elseif b.inv > 0 then fr = own and ("hurt_" .. (b.inv > 36 and 0 or (b.inv > 18 and 1 or 2))) or hurt_frame(20)
    elseif m == "shh" then fr = own and ("swallow_" .. (b.mt // 7) % 6) or 14 + math.min(5, b.mt // 14)
    elseif m == "wave" then fr = own and ("shh_" .. math.min(5, b.mt // 8)) or 23 + (b.mt // 4) % 4
    elseif m == "recover" or m == "rhythm" then fr = own and ("stun_" .. (b.mt // 8) % 4) or 20
    else fr = own and ("idle_" .. (b.mt // 8) % 6) or (b.mt // 8) % 6 end
    look.flip = false
    if not own then look.mul, look.sx, look.sy = 0x8878B0, 1, 1 end
    Deco.img(id, fr, x, y, look)
    look.sx, look.sy = nil, nil
    for _, w in ipairs(b.waves or {}) do -- the breath's wave along the floor
      if not w.gone then rect(math.floor(w.x) - 8, y - 38 - (b.mt // 3 % 2) * 4, 16, 38, 0xD8D0FF) end
    end
    if m == "shh" and b.mt > 25 then circ(x, y - 55, 150 - (b.mt * 3) % 120, 0xB8A8F0, false) end -- the pull, drawn as a ring closing in
    return
  end
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
function B.rhythm_round() return b ~= nil and B.started and not B.dead and b.mode == "rhythm" end

function B.hud(lang)
  if not b or not B.started or B.dead then return end
  local w = 170
  local x, y = 214, 12 -- (between the counters on the left and the clock on the right)
  rect(x - 3, y - 3, w + 6, 30, 0x2A1A3A)
  rect(x, y + 14, w, 9, 0x4A2A4A)
  rect(x, y + 14, math.floor(w * math.max(0, b.hp) / b.maxhp), 9, 0xE04050)
  text(lang.tr(SPEC[b.id].name), x + w // 2, y - 1, {font = "snes_small", color = 0xFFFFFF, align = "center"})
  if b.id ~= "silencio" then return end
  -- the music meter, under the life bar
  rect(x - 3, y + 30, w + 6, 12, 0x2A1A3A)
  rect(x, y + 33, math.floor(w * math.max(0, B.meter) / 100), 6, B.meter < 35 and 0xFF5050 or 0x70E0FF)
  if b.mode ~= "rhythm" then return end
  -- the four keys, and the rings closing on them
  local COL = {0xFF7090, 0x70D0FF, 0xFFD060, 0x90E070}
  local LAB = {"<", "A", "B", ">"}
  for lane = 1, 4 do
    local kx = 150 + 60 * (lane - 1)
    local lit = b.lit and b.lit[lane]
    rect(kx - 22, 214, 44, 28, lit and 0xFFFFFF or COL[lane])
    text(LAB[lane], kx, 219, {font = "snes_body", color = 0x2A1A3A, align = "center"})
  end
  for _, nt in ipairs(b.notes) do
    local dt = nt.T - b.mt
    if not nt.done and dt <= 60 and dt >= -8 then
      circ(150 + 60 * (nt.lane - 1), 228, 12 + math.max(0, dt) * 2 // 3, COL[nt.lane], false)
    end
  end
end

return B
