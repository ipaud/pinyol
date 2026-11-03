-- pilot: the machine that plays Traca, for the title's demo and for the playtest's perfect player
-- (tests/playtest/traca.lua). It knows what the game knows: where every bullet is and how it moves (swarm:get), so
-- it tries each of the 17 ways it could hold the arrows (8 directions fast and slow, or still), follows each a few
-- ticks into the future with the bullets and the foes moving on, and takes the safest one that keeps it under its
-- target: the foe nearest overhead, the bell, the moon, or a bag of powder (shot to the colour it wants, then
-- caught). When nothing is safe it lights a traca. It returns what the player's input gives: dx, dy (the rocket's
-- own directions, not the console's), slow, fire, bomb.
local Foes = require("foes")
local A = {}

A.every = 2 -- think every n ticks (the demo on the console); the playtest sets 1
local FAST, SLOW = 1.6, 0.7
local TS_FULL, WT_FULL = {2, 4, 7, 11, 16}, {8, 5, 3, 1.6, 1}
local TS_DEMO, WT_DEMO = {2, 6, 14}, {8, 3.5, 1.2} -- the title's demo on the console: three looks ahead, not five (its tick fits the frame)
local CANDS, CANDS_DEMO = {}, {} -- every way to hold the arrows; the demo's: fast or still only (half the thinking)
for dy = -1, 1 do
  for dx = -1, 1 do
    CANDS[#CANDS + 1] = {dx, dy, false}
    CANDS_DEMO[#CANDS_DEMO + 1] = CANDS[#CANDS]
    if dx ~= 0 or dy ~= 0 then CANDS[#CANDS + 1] = {dx, dy, true} end
  end
end

local bx, by, bvx, bvy, br, near = {}, {}, {}, {}, {}, {}
local last, last_bomb = nil, -99

local function gather(P)
  local me, n = P.me, 0
  for k, s in ipairs(P.BULLETS) do -- the bullets near enough to matter, in one call a swarm
    local m = A.every > 1 and s:collect(me.x - 35, me.y - 50, 70, 80, near) -- (the demo looks 14 ticks ahead: nearer is enough)
      or s:collect(me.x - 50, me.y - 70, 100, 110, near)
    local r = P.BULLET_R[k] + 1.8
    for i = 0, m - 1 do
      n = n + 1
      bx[n], by[n], bvx[n], bvy[n], br[n] = near[4 * i + 1], near[4 * i + 2], near[4 * i + 3], near[4 * i + 4], r
    end
  end
  for _, f in ipairs(P.foes) do -- a foe is a bullet too: touching it hurts
    local k = Foes.KINDS[f.kind]
    n = n + 1
    bx[n], by[n], bvx[n], bvy[n], br[n] = f.x, f.y + (k.dy or 0), f.x - f.px, f.y - f.py, math.max(k.w, k.h) / 2 + 2
  end
  local b = P.boss
  if b and not b.fall then n = n + 1 bx[n], by[n], bvx[n], bvy[n], br[n] = b.x, b.y, 0, 0, 30 end
  return n
end

local function wanted(P)
  if P.power < 4 then return 1 elseif P.bombs < 5 then return 2 elseif not P.shield then return 3 end
  return 1
end

local function goal(P) -- where it wants to be: x, y, and whether it holds its fire
  local me = P.me
  for _, p in ipairs(P.pickups) do
    if p.y > 24 and p.y < VH - 20 then
      if p.colour == wanted(P) then return p.x, math.max(p.y + 4, 40), math.abs(p.x - me.x) < 14 end
      return p.x, math.max(196, p.y + 40), false
    end
  end
  if P.boss then return P.boss.x, 204, false end
  if P.bell then return P.bell.x, 196, false end
  local best, bd = nil, 1e9
  for _, f in ipairs(P.foes) do
    if f.y > 2 and f.y < me.y - 12 then
      local d = math.abs(f.x - me.x) + (me.y - f.y) * 0.25
      if d < bd then best, bd = f, d end
    end
  end
  return best and best.x or VW / 2, 196, false
end

local function clamp(v, a, b) return v < a and a or v > b and b or v end

function A.think(P)
  if A.every > 1 and last and P.t % A.every ~= 0 then return last[1], last[2], last[3], last[4], false end
  local me = P.me
  local n = gather(P)
  local tx, ty, hold_fire = goal(P)
  local TS, WT, cands = TS_FULL, WT_FULL, CANDS
  if A.every > 1 then TS, WT, cands = TS_DEMO, WT_DEMO, CANDS_DEMO end
  local best, bs, bdanger = nil, -1e18, 0
  for _, c in ipairs(cands) do
    local sp = c[3] and SLOW or FAST
    if c[1] ~= 0 and c[2] ~= 0 then sp = sp * 0.75 end
    local danger, early = 0, 0
    local px4, py4
    for k = 1, #TS do
      local tt = TS[k]
      local px, py = clamp(me.x + c[1] * sp * tt, 5, VW - 5), clamp(me.y + c[2] * sp * tt, 28, VH - 14)
      if k == 2 then px4, py4 = px, py end
      for j = 1, n do
        local ex, ey = bx[j] + bvx[j] * tt - px, by[j] + bvy[j] * tt - py
        local d2, lim = ex * ex + ey * ey, br[j]
        if d2 < lim * lim then
          danger = danger + WT[k] * (1 + lim - math.sqrt(d2))
          if k <= 2 then early = early + 1 end
        elseif d2 < (lim + 5) * (lim + 5) then
          danger = danger + WT[k] * 0.04
        end
      end
    end
    local s = -danger * 100 - math.abs(px4 - tx) * 0.6 - math.abs(py4 - ty) * 0.25 - (c[3] and 0.3 or 0)
    if s > bs then best, bs, bdanger = c, s, early end
  end
  local bomb = bdanger > 0 and P.bombs > 0 and not P.traca and me.safe == 0 and P.t - last_bomb > 30
  if bomb then last_bomb = P.t end
  last = {best[1], best[2], best[3], not hold_fire}
  return best[1], best[2], best[3], not hold_fire, bomb
end

function A.buttons(P) -- the same as the console's buttons, turned: for the playtest's bot
  local dx, dy, slow, fire, bomb = A.think(P)
  return {down = dx > 0, up = dx < 0, right = dy < 0, left = dy > 0, a = fire, b = slow, c = bomb}
end

function A.reset() last, last_bomb = nil, -99 end

return A
