-- foes: what gets in the rocket's way. Each kind moves its own way and fires its own bullets into the play's swarms:
--   lantern  a paper lantern drifting down; red ones fire one orb at the rocket, green ones a fan of three
--   bat      swoops in from a side along a wave; it only hurts if touched (from the bell tower on: a spark too)
--   balloon  a fair balloon floating down; burst, the confetti inside flies out in a ring
--   drunk    a rocket that went off the wrong way, zigzagging down and spitting sparks in a spiral
-- and the bell of the bell tower (stage 2), which rings rings of orbs until it is silenced.
local M = require("tunes")
local F = {}

local KINDS = {
  lantern = {hp = 4, pts = 100, w = 12, h = 16, pic = "SPR_LANTERN", fw = 12, fh = 17},
  bat = {hp = 1, pts = 50, w = 13, h = 7, pic = "SPR_BAT", fw = 16, fh = 10},
  balloon = {hp = 5, pts = 200, w = 11, h = 13, pic = "SPR_BALLOON", fw = 12, fh = 21, dy = -3},
  drunk = {hp = 5, pts = 300, w = 7, h = 13, pic = "SPR_DRUNK", fw = 7, fh = 16},
}
F.KINDS = KINDS

function F.spawn(P, kind, x, y, o) -- o: vx, vy, colour, drop, fire (ticks to the first shot)
  o = o or {}
  local k = KINDS[kind]
  local f = {kind = kind, x = x, y = y, x0 = x, y0 = y, t = 0, hp = k.hp, vx = o.vx or 0, vy = o.vy or 0.4,
             colour = o.colour or 0, drop = o.drop, fire = o.fire or (40 + math.random(60)), hit = 0, px = x, py = y}
  P.foes[#P.foes + 1] = f
  return f
end

local function shoot(P, f)
  local st = P.stage
  if f.kind == "lantern" then
    if f.colour == 1 then P.fan(P.orbs, f.x, f.y + 4, 3, 0.55, 0.95 + st * 0.05) else P.fan(P.orbs, f.x, f.y + 4, 1, 0, 1.0 + st * 0.05) end
    f.fire = 100 + math.random(50)
  elseif f.kind == "bat" then
    if st >= 3 then P.fan(P.sparks, f.x, f.y, 1, 0, 1.3) end
    f.fire = 999
  elseif f.kind == "drunk" then
    local a = f.t / 9
    P.sparks:add(f.x, f.y + 6, math.cos(a) * 0.9, math.sin(a) * 0.9)
    P.sparks:add(f.x, f.y + 6, -math.cos(a) * 0.9, -math.sin(a) * 0.9)
    f.fire = 9
  end
end

local function move(P, f)
  f.px, f.py = f.x, f.y
  local t = f.t
  if f.kind == "lantern" then
    f.y = f.y + f.vy
    f.x = f.x0 + math.sin(t / 45 + f.x0) * 9
  elseif f.kind == "bat" then
    f.x = f.x + f.vx
    f.y = f.y0 + math.sin(t / 18) * 14 + t * 0.25
  elseif f.kind == "balloon" then
    f.y = f.y + f.vy
    f.x = f.x0 + math.sin(t / 60 + f.y0) * 14
  elseif f.kind == "drunk" then
    if t % 40 == 0 then f.vx = (math.random() < 0.5 and -1 or 1) * (0.5 + math.random() * 0.6) end
    if f.x < 14 then f.vx = math.abs(f.vx) elseif f.x > VW - 14 then f.vx = -math.abs(f.vx) end
    f.x = f.x + f.vx
    f.y = f.y + (f.y < 70 and 0.7 or 0.18)
  end
end

local function burst(P, f)
  if f.kind == "balloon" then P.ring(P.confs, f.x, f.y - 3, 8, 0.7, f.t / 10) end
end

function F.update(P)
  for i = #P.foes, 1, -1 do
    local f = P.foes[i]
    f.t = f.t + 1
    move(P, f)
    local k = KINDS[f.kind]
    if f.hit > 0 then f.hit = f.hit - 1 end
    local on = f.y > 6 and f.y < VH * 0.72 and f.x > 4 and f.x < VW - 4
    f.fire = f.fire - 1
    if f.fire <= 0 and on and P.mode == "play" then shoot(P, f) end
    local n = P.shots:hit(f.x - k.w / 2, f.y - k.h / 2 + (k.dy or 0), k.w, k.h)
    if n > 0 then f.hp, f.hit = f.hp - n, 3 end
    if f.hp <= 0 then
      table.remove(P.foes, i)
      burst(P, f)
      P.killed(f, k.pts)
    elseif f.y > VH + 20 or f.y < -60 or (f.t > 30 and (f.x < -24 or f.x > VW + 24)) then
      table.remove(P.foes, i)
    end
  end
  if P.bell then F.update_bell(P) end
end

function F.damage_all(P, n)
  for _, f in ipairs(P.foes) do if f.y > 0 then f.hp, f.hit = f.hp - n, 3 end end
end

function F.touch(P, x, y) -- does a foe's body touch the rocket's heart?
  for _, f in ipairs(P.foes) do
    local k = KINDS[f.kind]
    if math.abs(f.x - x) < k.w / 2 - 1 and math.abs(f.y + (k.dy or 0) - y) < k.h / 2 - 1 then return true end
  end
  return false
end

function F.draw(P)
  for _, f in ipairs(P.foes) do
    local k = KINDS[f.kind]
    local frame = 0
    if f.kind == "lantern" then frame = f.colour * 2 + (f.t // 12) % 2
    elseif f.kind == "bat" then frame = (f.t // 6) % 2
    elseif f.kind == "balloon" then frame = f.colour
    elseif f.kind == "drunk" then frame = (f.t // 5) % 2 end
    local x, y = math.floor(f.x - k.fw / 2), math.floor(f.y - k.fh / 2)
    if f.hit > 0 then img(k.pic, x, y, {frame = frame, tint = 0xFFFFFF}) else img(k.pic, x, y, frame) end
  end
  if P.bell then F.draw_bell(P) end
end

-- ------------------------------------------------------------------ the bell

F.BELL_HP = 110

function F.ring_bell(P, x, y) -- the bell hangs in the belfry at (x, y): it starts ringing
  P.bell = {x = x, y = y, hp = F.BELL_HP, t = 0, hit = 0, life = 2400}
  M.sfx("SFX_DING")
end

function F.update_bell(P)
  local b = P.bell
  b.t, b.life = b.t + 1, b.life - 1
  if b.hit > 0 then b.hit = b.hit - 1 end
  local n = P.shots:hit(b.x - 8, b.y - 8, 16, 16)
  if n > 0 then b.hp, b.hit = b.hp - n, 3 end
  if b.hp <= 0 then -- silenced: it gives a last, small "dong" and hangs still
    P.bell = nil
    P.add_score(5000)
    P.boom(b.x, b.y)
    earn("campana")
    M.sfx("SFX_DONG")
    P.banner = {key = "silence", t = 120}
    P.hold = false
    return
  end
  if b.life <= 0 then P.bell, P.hold = nil, false return end -- it tires: the climb goes on
  if b.t % 70 == 35 then -- the swing's end: DING, a ring
    P.ring(P.orbs, b.x, b.y + 6, 12, 0.7, b.t / 50)
    M.sfx("SFX_DING")
  end
  if b.t % 140 == 105 then P.fan(P.sparks, b.x, b.y + 6, 3, 0.45, 1.25) end
  if b.t % 160 == 80 then -- bats out of the belfry
    local f = F.spawn(P, "bat", b.x, b.y, {vx = 1.1})
    f.y0 = b.y
    f = F.spawn(P, "bat", b.x, b.y, {vx = -1.1})
    f.y0 = b.y
  end
end

function F.draw_bell(P)
  local b = P.bell
  local s = math.sin(b.t / 70 * math.pi * 2 - math.pi / 2)
  local frame = s < -0.4 and 0 or s > 0.4 and 2 or 1
  if b.hit > 0 then img("SPR_BELL", math.floor(b.x) - 10, math.floor(b.y) - 9, {frame = frame, tint = 0xFFF0A0})
  else img("SPR_BELL", math.floor(b.x) - 10, math.floor(b.y) - 9, frame) end
  rect(math.floor(b.x) - 10, math.floor(b.y) + 13, math.floor(20 * b.hp / F.BELL_HP), 1, 0xFF5070)
end

return F
