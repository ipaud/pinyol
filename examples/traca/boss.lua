-- boss: the fair's cardboard moon, hung from two strings at the top of the sky. It swings and smiles (big orbs in
-- fans, rings of them), gets cross (a spiral of sparks, fans of confetti), and once patched up with a plaster it lets
-- confetti rain in curtains with a gap in them. Beaten, its strings snap and it falls, dizzy, past the rocket: behind
-- it was the real moon all along.
local M = require("tunes")
local B = {}

B.HP = 1500
local A2, A3 = 1000, 500 -- the hp at which it gets cross, and patched up

function B.start(P)
  P.boss = {x = VW / 2, y = -40, hp = B.HP, t = 0, hit = 0, phase = 1, fall = nil, vy = 0}
  P.banner = {key = "boss", t = 150}
  M.sfx("SFX_DING")
end

function B.damage(P, n)
  local b = P.boss
  if b.fall then return end
  b.hp, b.hit = b.hp - n, 3
end

function B.touch(P, x, y)
  local b = P.boss
  if b.fall then return false end
  local dx, dy = x - b.x, y - b.y
  return dx * dx + dy * dy < 26 * 26
end

local function attack(P, b)
  local t = b.t
  if b.phase == 1 then
    if t % 50 == 0 then P.fan(P.bigs, b.x, b.y + 20, 5, 0.9, 1.1) end
    if t % 110 == 55 then P.ring(P.orbs, b.x, b.y, 20, 0.8, t / 30) end
  elseif b.phase == 2 then
    if t % 6 == 0 then
      local a = t / 22
      P.sparks:add(b.x, b.y + 8, math.cos(a) * 1.0, math.sin(a) * 1.0)
      P.sparks:add(b.x, b.y + 8, math.cos(a + math.pi) * 1.0, math.sin(a + math.pi) * 1.0)
    end
    if t % 100 == 50 then P.fan(P.confs, b.x, b.y + 20, 7, 1.1, 1.2) end
  else
    if t % 36 == 0 then -- a curtain of confetti with a gap that moves
      local gap = 30 + ((t // 36) * 37) % 100
      for x = 6, VW - 6, 10 do
        if math.abs(x - gap) > 15 then P.confs:add(x, -4, 0, 0.95) end
      end
    end
    if t % 70 == 35 then P.fan(P.bigs, b.x, b.y + 20, 3, 0.5, 1.4) end
    if t % 150 == 0 then P.ring(P.orbs, b.x, b.y, 16, 0.7, t / 40) end
  end
end

function B.update(P)
  local b = P.boss
  b.t = b.t + 1
  if b.hit > 0 then b.hit = b.hit - 1 end
  if b.fall then -- it falls, spinning its eyes, and is gone
    b.vy = b.vy + 0.08
    b.y = b.y + b.vy
    if b.y > VH + 50 then P.boss, P.hold = nil, false end
    return
  end
  if b.y < 62 then b.y = b.y + 0.5 return end
  local swing = b.phase == 3 and 22 or 40
  b.x = VW / 2 + math.sin(b.t / 110) * swing
  local n = P.shots:hit(b.x - 24, b.y - 24, 48, 44)
  if n > 0 then b.hp, b.hit = b.hp - n, 3 end
  local phase = b.hp > A2 and 1 or b.hp > A3 and 2 or 3
  if phase ~= b.phase then
    b.phase = phase
    P.clear_bullets(true)
    M.sfx("SFX_BOING")
  end
  if b.hp <= 0 then
    b.fall, b.vy, b.t = true, -1.5, 0
    P.clear_bullets(true)
    P.add_score(20000)
    for k = 0, 5 do P.boom(b.x + math.cos(k) * 20, b.y + math.sin(k) * 20) end
    M.sfx("SFX_BOING")
    M.play(nil)
    return
  end
  attack(P, b)
end

function B.draw(P)
  local b = P.boss
  local x, y = math.floor(b.x), math.floor(b.y)
  if not b.fall then -- the strings from the top of the sky (one of them torn, at the end)
    line(VW // 2 - 30, 0, x - 10, y - 30, 0xC0C8D8)
    if b.phase < 3 then line(VW // 2 + 30, 0, x + 10, y - 30, 0xC0C8D8) else line(VW // 2 + 30, 0, VW // 2 + 26, 14, 0xC0C8D8) end
  end
  local mood = b.fall and 3 or b.phase - 1
  if b.hit > 0 then img("SPR_MOON", x - 32, y - 32, {frame = mood, tint = 0xFFF8E0})
  else img("SPR_MOON", x - 32, y - 32, mood) end
  if not b.fall then
    rect(20, 12, 120, 2, 0x302850)
    rect(20, 12, math.floor(120 * math.max(0, b.hp) / B.HP), 2, 0xFF5070)
  end
end

return B
