-- play: the game itself, on the standing canvas's 160x240 pixels. The rocket, its shots, the foes and their bullets,
-- the pickups, the traca (the bomb), the stages one after another, the bell tower's bell and the moon. Bullets live in
-- swarms (moved, tested and drawn in C): one swarm a kind of bullet, so one picture each.
local Foes, Boss, Stages = require("foes"), require("boss"), require("stages")
local M, S, F = require("tunes"), require("sky"), require("finale")
local P = {}

P.SPEED = 0.5                 -- canvas pixels the sky scrolls a tick
local FAST, SLOW = 1.6, 0.7   -- the rocket's speed, and with B held
local HEART = 1               -- half the rocket's heart: only that is hit, as in those games
local FIRE_EVERY = 5
local GRAZE, METXA_FULL = 7, 360 -- the graze box's half size; grazes that light a new traca
local BOMBS_MAX, POWER_MAX = 5, 4
local EXTENDS = {30000, 100000}
local CREDITS, COUNTDOWN = 3, 600 -- a game and two continues; ten seconds to take one

local area = {-20, -24, 180, 264}
P.shots = swarm(300, area)
P.orbs, P.sparks, P.bigs, P.confs = swarm(900, area), swarm(900, area), swarm(300, area), swarm(700, area)
P.embers, P.glints = swarm(160, area), swarm(500, area)
P.BULLETS = {P.orbs, P.sparks, P.bigs, P.confs}
P.BULLET_R = {2.5, 1.5, 3.5, 1.5} -- each kind's radius (the pilot reads it)
local PICS = {"B_ORB", "B_SPARK", "B_BIG", "B_CONF"}

function P.init()
  P.new_game(1)
  P.idle_reset()
end

function P.new_game(stage)
  P.score, P.lives, P.bombs, P.power, P.shield = 0, 3, 3, 1, false
  P.metxa, P.graze, P.deaths, P.kills, P.colours = 0, 0, 0, 0, {}
  P.credits = CREDITS - 1 -- the continues left, as a cabinet's credits
  P.ext = 1
  P.me = {x = VW / 2, y = 200, safe = 90}
  P.t, P.fire_t = 0, 0
  P.traca, P.fin, P.flash = nil, nil, 0
  F.clear()
  if PILOT then PILOT.reset() end
  P.begin_stage(stage or 1)
  if (stage or 1) > 1 then P.power = math.min(POWER_MAX, stage) end -- the demo starts higher up, armed for it
end

function P.clear_bullets(glint) -- every enemy bullet gone; with glint, each turns into a spark worth 10 points
  for k, s in ipairs(P.BULLETS) do
    if glint then
      for i = 1, #s do
        local x, y = s:get(i)
        if not P.glints:add(x, y, 0, -1.2, 24) then break end
      end
      P.score = P.score + 10 * #s
    end
    s:clear()
  end
end

function P.begin_stage(n)
  P.stage, P.sc, P.st, P.hold = n, 0, 0, false
  P.foes, P.pickups, P.booms = {}, {}, {}
  P.bell, P.boss = nil, nil
  P.mode, P.mode_t = "play", 0
  P.hit_in_stage = false
  P.banner = {key = "stage_" .. n, t = 150, n = n}
  Stages.start(P, n)
  S.begin(P, n)
  P.clear_bullets(false)
  P.shots:clear()
  if n == 5 then M.play("boss") elseif n > 1 then M.play("fiesta") end
end

function P.idle_reset() -- the title's sky: the village at the bottom, nothing moving
  P.begin_stage(1)
  P.mode = "idle"
  P.banner = nil
end

function P.idle() -- the title and the end screens: only the bullets already out and the sparks go on
  P.t = P.t + 1
  for _, s in ipairs(P.BULLETS) do s:step() end
  P.glints:step()
  P.embers:step()
  for i = #P.booms, 1, -1 do
    local b = P.booms[i]
    b.t = b.t + 1
    if b.t >= 16 then table.remove(P.booms, i) end
  end
end

-- ------------------------------------------------------------------ helpers the foes and the boss use

function P.boom(x, y) P.booms[#P.booms + 1] = {x = x, y = y, t = 0} end

function P.aim(x, y) return math.atan(P.me.y - y, P.me.x - x) end

function P.fan(s, x, y, n, spread, speed, a) -- n bullets of swarm s, spread over that many radians round angle a
  a = a or P.aim(x, y)
  for i = 1, n do
    local b = a + (n > 1 and (i - (n + 1) / 2) * spread / (n - 1) or 0)
    s:add(x, y, math.cos(b) * speed, math.sin(b) * speed)
  end
end

function P.ring(s, x, y, n, speed, turn)
  for i = 0, n - 1 do
    local a = i / n * 2 * math.pi + (turn or 0)
    s:add(x, y, math.cos(a) * speed, math.sin(a) * speed)
  end
end

function P.add_score(n)
  P.score = P.score + n
  local at = EXTENDS[P.ext]
  if at and P.score >= at then
    P.ext, P.lives = P.ext + 1, P.lives + 1
    extra_life()
  end
end

function P.drop(x, y) -- a bag of coloured powder: shooting it changes its colour, catching it gives what it is
  P.pickups[#P.pickups + 1] = {x = x, y = y, vy = -0.6, colour = 1, t = 0}
end

function P.killed(f, pts)
  P.add_score(pts)
  P.kills = P.kills + 1
  P.boom(f.x, f.y)
  M.sfx("SFX_POP")
  if f.kind == "lantern" then earn("farolillo") end
  if f.drop or P.kills % 18 == 0 then P.drop(f.x, f.y) end
end

-- ------------------------------------------------------------------ the rocket

local function read_input() -- the arrows as they point with the console on its side: its right is up, its down is right
  if P.ai then return PILOT.think(P) end
  return (btn("down") and 1 or 0) - (btn("up") and 1 or 0), (btn("left") and 1 or 0) - (btn("right") and 1 or 0),
         btn("b"), btn("a"), btnp("c")
end

local function fire(slow)
  local me = P.me
  local k = slow and 0.5 or 1
  local spread = ({{0}, {0, -0.7, 0.7}, {0, -0.7, 0.7, -1.4, 1.4}, {0, -0.5, 0.5, -1.1, 1.1, -1.7, 1.7}})[P.power]
  P.shots:add(me.x - 2, me.y - 8, 0, -5) P.shots:add(me.x + 2, me.y - 8, 0, -5)
  for i = 2, #spread do P.shots:add(me.x, me.y - 8, spread[i] * k, -4.8) end
  M.sfx("SFX_SHOT")
end

function P.bomb()
  if P.bombs <= 0 or P.traca then return end
  P.bombs = P.bombs - 1
  P.traca = {t = 0, x = P.me.x}
  P.me.safe = math.max(P.me.safe, 70)
  P.clear_bullets(true)
  earn("traca")
end

local function hurt()
  local me = P.me
  P.hit_in_stage = true
  if P.shield then
    P.shield, me.safe = false, 100
    P.clear_bullets(true)
    M.sfx("SFX_SHIELD")
    return
  end
  P.lives, P.deaths = P.lives - 1, P.deaths + 1
  P.boom(me.x, me.y)
  P.boom(me.x - 5, me.y + 4)
  P.clear_bullets(false)
  M.sfx("SFX_HIT")
  P.flash = calm() and 0 or 6
  if P.lives <= 0 then
    P.mode, P.mode_t = (P.credits > 0 and not P.ai) and "continue" or "over", 0
    return
  end
  P.mode, P.mode_t = "dying", 0
end

local function update_rocket()
  local me = P.me
  local dx, dy, slow, firing, bomb = read_input()
  local sp = slow and SLOW or FAST
  if dx ~= 0 and dy ~= 0 then sp = sp * 0.75 end
  me.x = math.max(5, math.min(VW - 5, me.x + dx * sp))
  me.y = math.max(28, math.min(VH - 14, me.y + dy * sp))
  if me.safe > 0 then me.safe = me.safe - 1 end
  P.fire_t = P.fire_t + 1
  if firing and P.fire_t >= FIRE_EVERY then P.fire_t = 0 fire(slow) end
  if bomb then P.bomb() end
  P.embers:add(me.x + (math.random() - 0.5) * 2, me.y + 7, (math.random() - 0.5) * 0.4, 1.0 + math.random() * 0.8, 12)
  -- grazes: the bullets that pass close (kept), each tick they are near
  local near = 0
  for _, s in ipairs(P.BULLETS) do near = near + s:hit(me.x - GRAZE, me.y - GRAZE, GRAZE * 2, GRAZE * 2, true) end
  if near > 0 and me.safe == 0 then
    P.graze, P.metxa = P.graze + near, P.metxa + near
    P.score = P.score + near
    if P.graze >= 600 then earn("roce") end
    if P.metxa >= METXA_FULL then
      P.metxa = 0
      if P.bombs < BOMBS_MAX then P.bombs = P.bombs + 1 M.sfx("SFX_PICK") end
    end
  end
  if me.safe > 0 then return end
  local hit = 0
  for _, s in ipairs(P.BULLETS) do hit = hit + s:hit(me.x - HEART, me.y - HEART, HEART * 2, HEART * 2) end
  if hit > 0 or Foes.touch(P, me.x, me.y) or (P.boss and Boss.touch(P, me.x, me.y)) then hurt() end
end

local function update_pickups()
  local me = P.me
  for i = #P.pickups, 1, -1 do
    local p = P.pickups[i]
    p.t, p.vy = p.t + 1, math.min(0.45, p.vy + 0.02)
    p.y = p.y + p.vy
    if P.shots:hit(p.x - 5, p.y - 5, 10, 10) > 0 and p.t > 10 then -- shot: the next colour, and a hop
      p.colour, p.vy, p.t = p.colour % 3 + 1, -1.0, 0
      M.sfx("SFX_BLIP")
    end
    if math.abs(p.x - me.x) < 8 and math.abs(p.y - me.y) < 10 then
      table.remove(P.pickups, i)
      P.colours[p.colour] = true
      if p.colour == 1 then
        if P.power < POWER_MAX then P.power = P.power + 1 else P.add_score(1000) end
      elseif p.colour == 2 then
        P.bombs = math.min(BOMBS_MAX, P.bombs + 1)
      else
        P.shield = true
      end
      P.add_score(500)
      M.sfx("SFX_PICK")
      if P.colours[1] and P.colours[2] and P.colours[3] then earn("colores") end
    elseif p.y > VH + 12 then
      table.remove(P.pickups, i)
    end
  end
end

local function update_traca() -- a string of firecrackers that goes off up the sky, bang after bang, and the last one
  local tr = P.traca
  tr.t = tr.t + 1
  if tr.t <= 44 then P.clear_bullets(true) end
  if tr.t % 4 == 0 and tr.t <= 48 then
    local k = tr.t // 4
    local x, y = VW / 2 + math.sin(k * 1.7) * 56, VH - k * 19
    P.boom(x, y)
    M.sfx(k == 12 and "SFX_TRO" or "SFX_BANG")
    Foes.damage_all(P, 2)
    if P.bell then P.bell.hp = P.bell.hp - 2 end
    if P.boss then Boss.damage(P, 3) end
  end
  if tr.t > 60 then P.traca = nil end
end

local function update_booms()
  for i = #P.booms, 1, -1 do
    local b = P.booms[i]
    b.t = b.t + 1
    if b.t >= 16 then table.remove(P.booms, i) end
  end
end

local function stage_over()
  if P.sc < Stages.length(P.stage) or #P.foes > 0 or P.bell or P.boss then return false end
  return true
end

function P.update()
  P.t, P.mode_t = P.t + 1, P.mode_t + 1
  if P.flash and P.flash > 0 then P.flash = P.flash - 1 end
  if P.banner then P.banner.t = P.banner.t - 1 if P.banner.t <= 0 then P.banner = nil end end
  if P.mode == "finale" then
    if F.update(P) then P.mode = "won" end
    P.embers:step() P.glints:step()
    return
  end
  if P.mode == "over" or P.mode == "won" then P.idle() return end
  if not P.hold then P.sc = P.sc + P.SPEED end
  P.st = P.st + 1
  Stages.update(P)
  if P.mode == "dying" then
    if P.mode_t > 70 then
      P.mode = "play"
      P.me = {x = VW / 2, y = 212, safe = 150}
      P.power = math.max(1, P.power - 1)
      P.bombs = math.max(P.bombs, 2)
    end
  elseif P.mode == "continue" then -- the countdown: A takes a credit and goes on from here, the score back to nought
    if P.mode_t > 40 and (btnp("a") or btnp("start")) then
      P.credits, P.lives, P.score, P.ext = P.credits - 1, 3, 0, 1
      P.bombs, P.mode = 3, "dying"
      P.mode_t = 60
      M.sfx("SFX_START")
    elseif P.mode_t > COUNTDOWN then
      P.mode = "over"
    end
  elseif P.mode == "clear" then
    if P.mode_t > 150 then P.begin_stage(P.stage + 1) end
  elseif P.mode == "play" then
    update_rocket()
    if P.mode == "play" and stage_over() then
      if P.stage == 5 then
        P.mode, P.mode_t = "finale", 0
        F.start(P)
        earn("palmera")
        return
      end
      P.mode, P.mode_t = "clear", 0
      P.banner = {key = "clear", t = 150}
      if not P.hit_in_stage then P.add_score(5000) earn("intacto") P.banner.perfect = true end
      M.sfx("SFX_CLEAR")
    end
  end
  if P.traca then update_traca() end
  Foes.update(P)
  if P.boss then Boss.update(P) end
  update_pickups()
  update_booms()
  P.shots:step()
  for _, s in ipairs(P.BULLETS) do s:step() end
  P.embers:step()
  P.glints:step()
end

-- ------------------------------------------------------------------ drawing

local function draw_rocket()
  local me = P.me
  if P.mode ~= "play" and P.mode ~= "clear" then return end
  if me.safe > 0 and not calm() and (P.t // 3) % 2 == 0 then return end
  img("SPR_ROCKET", math.floor(me.x) - 4, math.floor(me.y) - 7, (P.t // 3) % 3)
  if P.shield then circ(math.floor(me.x), math.floor(me.y), 9, 0x58E0F8, false) end
  if me.safe > 0 and calm() then circ(math.floor(me.x), math.floor(me.y), 11, 0x8078B0, false) end
end

local function draw_pickups()
  for _, p in ipairs(P.pickups) do img("SPR_POWDER", math.floor(p.x) - 5, math.floor(p.y) - 5, p.colour - 1) end
end

local function draw_booms()
  for _, b in ipairs(P.booms) do img("SPR_BOOM", math.floor(b.x) - 8, math.floor(b.y) - 8, b.t // 4) end
end

local function draw_hud()
  local lang = require("lang")
  text(string.format("%06d", P.score), 3, 3, {font = FONT_B, color = 0xFFFFFF, shadow = 0x0A0818})
  for i = 1, math.min(5, P.lives - 1) do img("SPR_ICONS", VW - 3 - i * 7, 3, 0) end
  for i = 1, P.bombs do img("SPR_ICONS", 2 + (i - 1) * 7, VH - 10, 1) end
  rect(2, VH - 12, 34, 1, 0x302850) -- the fuse that lights the next traca, filled by grazes
  rect(2, VH - 12, math.floor(34 * P.metxa / METXA_FULL), 1, 0xFF9030)
  local h = math.floor(200 * Stages.progress(P)) -- how high: a thread up the right edge
  rect(VW - 2, 20, 1, 200, 0x302850)
  rect(VW - 2, 220 - h, 1, h, 0xFFD848)
  if P.banner and P.banner.t > 0 then
    local s = lang.tr(P.banner.key)
    if P.banner.n then
      textbox(lang.tr("stage", {n = P.banner.n}), 10, 92, VW - 20, 10, {font = FONT_S, align = "center", color = 0xFFB0D0})
    end
    textbox(s, 8, 104, VW - 16, 20, {font = FONT_B, align = "center", color = 0xFFF0A0, shadow = 0x0A0818})
    if P.banner.perfect then textbox(lang.tr("perfect"), 10, 126, VW - 20, 10, {font = FONT_S, align = "center", color = 0x58E0F8}) end
  end
end

local function draw_continue()
  local lang = require("lang")
  rect(14, 80, VW - 28, 72, 0x140E30)
  box(14, 80, VW - 28, 72, 0xFFD848)
  textbox(lang.tr("continue"), 18, 88, VW - 36, 10, {font = FONT_B, align = "center", color = 0xFFF0A0})
  text(tostring(math.max(0, (COUNTDOWN - P.mode_t) // 60)), VW // 2, 104, {font = FONT_T, scale = 2, align = "center", color = 0xFFFFFF})
  textbox(lang.tr("credits", {n = P.credits}), 18, 126, VW - 36, 10, {font = FONT_S, align = "center", color = 0xC0B8E0})
  textbox(lang.tr("continue_keys"), 18, 138, VW - 36, 10, {font = FONT_S, align = "center", color = 0xC0B8E0})
end

function P.draw()
  S.draw(P)
  P.embers:draw("B_EMBER")
  P.shots:draw("B_SHOT")
  if P.boss then Boss.draw(P) end
  Foes.draw(P)
  draw_pickups()
  draw_booms()
  if P.mode == "finale" then F.draw(P) end
  draw_rocket()
  for i = #P.BULLETS, 1, -1 do P.BULLETS[i]:draw(PICS[i]) end
  P.glints:draw("B_GLINT")
  draw_hud()
  if P.mode == "continue" then draw_continue() end
end

return P
