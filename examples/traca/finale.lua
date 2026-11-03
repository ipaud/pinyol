-- finale: the moon is gone and the rocket does what it was made for. It whistles up to the middle of the sky and
-- bursts as a palmera, the palm tree of light that closes a fiesta: forty heads of fire fly out, slow down and droop,
-- each leaving a trail that cools from white to orange to red (three swarms: the trail is the heads' own sparks,
-- left behind). The sky lights up once and fades; with reduce_flashing the light is a soft one.
local M = require("tunes")
local F = {}

local area = {-30, -30, VW + 30, VH + 30}
F.hot, F.warm, F.cool = swarm(400, area), swarm(1600, area), swarm(1600, area)
F.cyan, F.pink = swarm(700, area), swarm(700, area) -- the two smaller bursts after it, in coloured powder
local heads = {}

function F.start(P)
  P.fin = {t = 0, x = P.me.x, y = P.me.y, glow = 0}
  heads = {}
  M.sfx("SFX_WHISTLE")
end

local function burst(x, y, n, speed, trail)
  for i = 0, n - 1 do
    local a = i / n * math.pi * 2 + (i % 2) * 0.05
    local v = speed * (0.9 + (i % 3) * 0.06)
    heads[#heads + 1] = {x = x, y = y, vx = math.cos(a) * v, vy = math.sin(a) * v - 0.3, t = 0, trail = trail}
  end
end

function F.update(P) -- true when it is over
  local f = P.fin
  f.t = f.t + 1
  if f.t < 70 then -- the climb to the middle of the sky
    f.x = f.x + (VW / 2 - f.x) * 0.06
    f.y = f.y + (84 - f.y) * 0.05
    P.embers:add(f.x, f.y + 7, (math.random() - 0.5) * 0.4, 1.2, 14)
  elseif f.t == 70 then
    burst(f.x, f.y, 40, 2.1)
    f.glow = 1
    M.sfx("SFX_TRO")
    M.play("final")
  elseif f.t == 130 then
    burst(f.x - 30, f.y + 20, 20, 1.3, F.cyan)
    burst(f.x + 32, f.y + 14, 20, 1.3, F.pink)
    M.sfx("SFX_BANG")
  end
  if f.glow > 0 then f.glow = math.max(0, f.glow - 1 / 50) end
  for i = #heads, 1, -1 do
    local h = heads[i]
    h.t = h.t + 1
    h.vx, h.vy = h.vx * 0.975, (h.vy + 0.03) * 0.975
    h.x, h.y = h.x + h.vx, h.y + h.vy
    F.hot:add(h.x, h.y, 0, 0, 5)
    if h.trail then
      h.trail:add(h.x, h.y, 0, 0.08, 34)
    else
      F.warm:add(h.x, h.y, 0, 0.06, 26)
      if h.t % 2 == 0 then F.cool:add(h.x, h.y, (math.random() - 0.5) * 0.1, 0.16, 50) end
    end
    if h.t > 80 then table.remove(heads, i) end
  end
  F.hot:step() F.warm:step() F.cool:step() F.cyan:step() F.pink:step()
  return f.t > 330
end

function F.glow(P) -- how much the sky is lit now (one flash, never twice)
  local g = P.fin and P.fin.glow or 0
  return calm() and g * 0.15 or g * 0.6
end

function F.draw(P)
  local f = P.fin
  F.cool:draw("B_PALM_R")
  F.warm:draw("B_PALM_O")
  F.cyan:draw("B_PALM_C")
  F.pink:draw("B_PALM_P")
  F.hot:draw("B_PALM_G")
  if f.t < 70 then img("SPR_ROCKET", math.floor(f.x) - 4, math.floor(f.y) - 7, (f.t // 3) % 3) end
end

function F.clear()
  heads = {}
  F.hot:clear() F.warm:clear() F.cool:clear() F.cyan:clear() F.pink:clear()
end

return F
