-- sky: what is behind the play, drawn on the standing canvas every frame. A sky in twelve bands, as a 1985 board's
-- palette shaded one (it darkens as the rocket climbs), stars in two swarms at two speeds, and each stage's things
-- going past: the village, its houses' balconies and the bunting; the bell tower with its blue dome; the clouds; a
-- constellation; and, at the end, the real moon. A thing at height h is at y = scroll * parallax - h.
local Stages, Fin = require("stages"), require("finale")
local S = {}

local SKY = { -- the top and the bottom of the sky at each stage's start (the last pair is the night's very top)
  {0x1A1848, 0x52305E}, {0x161444, 0x382868}, {0x0E1038, 0x24286A}, {0x080828, 0x161A4E}, {0x05051E, 0x0E1240}, {0x03031A, 0x0A0E36},
}
local BANDS = 12

local far, near = swarm(120, {-4, -8, VW + 4, VH + 8}), swarm(60, {-4, -8, VW + 4, VH + 8})
local tw = {} -- a few bright stars that twinkle (drawn from Lua: there are eight)

function S.init()
  for i = 1, 8 do tw[i] = {x = (i * 37) % VW, y = (i * 71) % 200, p = i * 13} end
end

local function want(stage) return ({12, 30, 50, 90, 100})[stage] or 100, ({0, 6, 16, 40, 50})[stage] or 50 end

function S.begin(P, n)
  far:clear() near:clear()
  local nf, nn = want(n)
  for _ = 1, nf do far:add(math.random() * VW, math.random() * VH, 0, 0.12) end
  for _ = 1, nn do near:add(math.random() * VW, math.random() * VH, 0, 0.3) end
end

function S.update(P)
  if P.hold or P.mode == "idle" then return end
  local nf, nn = want(P.stage)
  if #far < nf and math.random() < 0.15 then far:add(math.random() * VW, -2, 0, 0.12) end
  if #near < nn and math.random() < 0.12 then near:add(math.random() * VW, -2, 0, 0.3) end
  far:step() near:step()
end

local function mix(a, b, k)
  local r = (a >> 16) + (((b >> 16) - (a >> 16)) * k) // 1
  local g = ((a >> 8) & 255) + ((((b >> 8) & 255) - ((a >> 8) & 255)) * k) // 1
  local bl = (a & 255) + (((b & 255) - (a & 255)) * k) // 1
  return (math.floor(r) << 16) | (math.floor(g) << 8) | math.floor(bl)
end
S.mix = mix

function S.sky(P, glow, warm) -- the bands; glow 0..1 brightens them towards warm (the palmera's light, a hit)
  local n = P.stage
  local k = math.min(1, P.sc / Stages.length(n))
  local top, bot = mix(SKY[n][1], SKY[n + 1][1], k), mix(SKY[n][2], SKY[n + 1][2], k)
  local h = VH // BANDS
  for i = 0, BANDS - 1 do
    local c = mix(top, bot, i / (BANDS - 1))
    if glow > 0 then c = mix(c, warm, glow) end
    rect(0, i * h, VW, h, c)
    if i > 0 then rect(0, i * h - 3, VW, 1, c) end -- the band's edge, dithered by a line of the next colour
  end
end

-- ------------------------------------------------------------------ each stage's things

local function at(sc, par, h) return math.floor(sc * par - h) end

local function stage1(sc)
  img("BG_HILLS", 0, at(sc, 0.06, -146))
  img("BG_TOWN", 0, at(sc, 0.12, -156))
  for k = 0, 9 do
    local y = at(sc, 1, 250 + k * 130)
    if y > -96 and y < VH then img("BG_FACADE_L", 0, y, k % 2) end
    y = at(sc, 1, 315 + k * 130)
    if y > -96 and y < VH then img("BG_FACADE_R", VW - 26, y, (k + 1) % 2) end
  end
  for k = 0, 4 do
    local y = at(sc, 1, 120 + k * 260)
    if y > -12 and y < VH then img("BG_BUNTING", 0, y) end
  end
end

local function stage2(sc)
  local top = at(sc, 1, Stages.BELFRY) -- the belfry's top
  local X = 10
  for j = 0, 40 do -- the tower's shaft below the belfry, a piece of bricks 32 high each
    local y = top + 44 + j * 32
    if y >= VH then break end
    if y > -32 then img("BG_TOWER", X, y, j == 1 and 2 or (j % 3 == 2 and 1 or 0)) end
  end
  if top > -44 and top < VH then img("BG_BELFRY", X, top) end
  local dome = top - 46
  if dome > -46 and dome < VH then img("BG_DOME", X, dome) end
end

local function stage3(sc)
  for k = 0, 12 do
    local y = at(sc, 0.4, -20 + k * 110)
    if y > -20 and y < VH then img("BG_CLOUDS", (k * 53) % 130 - 10, y, 1 + k % 2) end
  end
  for k = 0, 7 do
    local y = at(sc, 1.2, 60 + k * 190)
    if y > -26 and y < VH then img("BG_CLOUDS", (k * 71) % 120 - 20, y, 0) end
  end
end

local PAELLA = {{0, 0}, {14, -6}, {30, -4}, {40, 6}, {30, 16}, {14, 18}, {0, 12}, {-24, 4}} -- the Pan: a ring and its handle

local function stage4(sc, t)
  local ox, oy = 92, at(sc, 0.3, 40)
  if oy > -30 and oy < VH + 20 then
    for i = 1, 7 do
      local a, b = PAELLA[i], PAELLA[i % 7 + 1]
      if i < 7 then line(ox + a[1], oy + a[2], ox + b[1], oy + b[2], 0x2A3070) end
    end
    line(ox + PAELLA[1][1], oy + PAELLA[1][2], ox + PAELLA[7][1], oy + PAELLA[7][2], 0x2A3070)
    line(ox, oy + 6, ox - 24, oy + 4, 0x2A3070)
    for _, p in ipairs(PAELLA) do pset(ox + p[1], oy + p[2], 0xE8E8FF) end
  end
end

function S.draw_twinkles(t)
  for _, s in ipairs(tw) do
    local on = calm() and 1 or (t + s.p) % 90 < 60 and 1 or 0
    if on == 1 then
      pset(s.x, s.y, 0xFFFFFF)
      pset(s.x - 1, s.y, 0x8090D0) pset(s.x + 1, s.y, 0x8090D0) pset(s.x, s.y - 1, 0x8090D0) pset(s.x, s.y + 1, 0x8090D0)
    end
  end
end

function S.draw(P, glow, warm)
  local g = glow or 0
  if P.flash and P.flash > 0 and not calm() then g = math.max(g, 0.25) warm = 0xA02040 end
  if P.mode == "finale" then g = math.max(g, Fin.glow(P)) end
  S.sky(P, g, warm or 0xFFE8B0)
  far:draw("B_STAR")
  near:draw("B_STAR2")
  if P.stage >= 3 then S.draw_twinkles(P.t) end
  local sc = P.sc
  if P.stage == 1 then stage1(sc)
  elseif P.stage == 2 then stage2(sc)
  elseif P.stage == 3 then stage3(sc)
  elseif P.stage == 4 then stage4(sc, P.t)
  elseif P.boss_done and not P.boss then img("BG_MOON", 100, 26) end
end

function S.draw_title(t)
  S.draw(P)
  img("SPR_ROCKET", 76, 196, (t // 4) % 3) -- on its stick in the plaza, its fuse lit
  if (t // 3) % 2 == 0 then pset(80 + (t % 3) - 1, 212, 0xFFF0A0) end
  P.embers:draw("B_EMBER")
end

function S.title_tick(t) -- the fuse's sparks (in _update: a draw changes nothing)
  if t % 2 == 0 then P.embers:add(80 + (math.random() - 0.5) * 3, 209, (math.random() - 0.5) * 0.5, 0.4 + math.random() * 0.4, 10) end
end

return S
