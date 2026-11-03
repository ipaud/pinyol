-- stages: the five stretches of sky, each a list of waves keyed by how far the sky has scrolled (canvas pixels), so
-- a pause in the climb (the bell, the moon) pauses them too. A wave: {at, kind, x, n = how many, dx = their spacing
-- across, gy = their spacing upwards (they come in one after another), side = "L"/"R" for bats, y for bats, colour,
-- drop = the last one carries a bag of powder}.
local Foes, Boss = require("foes"), require("boss")
local S = {}

S.BELFRY = 860   -- stage 2: the scroll at which the belfry's top reaches the screen's top (sky.lua draws it there)
S.BELL_STOP = 34 -- the belfry's top on the screen while the bell rings

local W = {
  { -- 1 · the rooftops: lanterns and bats
    len = 1150,
    {60, "lantern", 40, n = 3, gy = 22}, {150, "lantern", 120, n = 3, gy = 22}, {240, "bat", side = "L", y = 50, n = 4},
    {330, "lantern", 20, n = 5, dx = 30}, {420, "bat", side = "R", y = 70, n = 4}, {480, "lantern", 80, colour = 1, drop = true},
    {560, "lantern", 30, n = 3, dx = 12, gy = 18}, {560, "lantern", 130, n = 3, dx = -12, gy = 18},
    {660, "bat", side = "L", y = 40, n = 3}, {690, "bat", side = "R", y = 60, n = 3}, {760, "lantern", 50, n = 4, dx = 20, colour = 1},
    {860, "lantern", 80, drop = true}, {900, "bat", side = "L", y = 30, n = 5}, {980, "lantern", 20, n = 6, dx = 24, gy = 10},
    {1060, "lantern", 80, n = 3, colour = 1, gy = 20},
  },
  { -- 2 · the bell tower: more of them, and the bell
    len = 1250,
    {60, "bat", side = "L", y = 50, n = 4}, {120, "lantern", 110, n = 3, colour = 1, gy = 20}, {220, "bat", side = "R", y = 40, n = 4},
    {300, "lantern", 24, n = 5, dx = 28}, {380, "bat", side = "L", y = 60, n = 3}, {390, "bat", side = "R", y = 80, n = 3},
    {450, "lantern", 100, drop = true}, {520, "lantern", 60, n = 3, colour = 1, dx = 20}, {600, "bat", side = "L", y = 40, n = 5},
    {680, "lantern", 20, n = 6, dx = 24, gy = 8}, {920, "bat", side = "R", y = 50, n = 4}, {980, "lantern", 30, n = 5, dx = 25},
    {1060, "lantern", 80, colour = 1, drop = true}, {1120, "bat", side = "L", y = 40, n = 5},
  },
  { -- 3 · the clouds: fair balloons that got away
    len = 1200,
    {60, "balloon", 40}, {100, "balloon", 120, colour = 1}, {160, "lantern", 30, n = 4, dx = 32, colour = 1},
    {240, "balloon", 26, n = 4, dx = 36, colour = 2}, {330, "bat", side = "L", y = 50, n = 5}, {400, "balloon", 80, drop = true},
    {450, "balloon", 40, n = 3, dx = 40, colour = 1, gy = 12}, {520, "lantern", 30, n = 3, colour = 1, gy = 20},
    {520, "lantern", 130, n = 3, colour = 1, gy = 20}, {600, "bat", side = "R", y = 40, n = 5}, {680, "balloon", 16, n = 5, dx = 32},
    {760, "lantern", 80, drop = true}, {820, "balloon", 30, n = 3, dx = 50, colour = 2}, {850, "balloon", 55, n = 3, dx = 50},
    {920, "bat", side = "L", y = 40, n = 4}, {930, "bat", side = "R", y = 70, n = 4}, {1000, "balloon", 26, n = 4, dx = 36, colour = 1},
    {1020, "lantern", 80, n = 2, colour = 1, gy = 30}, {1100, "balloon", 50, n = 3, dx = 30, colour = 2},
  },
  { -- 4 · the stars: rockets that went off the wrong way
    len = 1200,
    {60, "drunk", 80}, {140, "balloon", 40, n = 3, dx = 40}, {200, "drunk", 40}, {210, "drunk", 120},
    {290, "bat", side = "L", y = 40, n = 6}, {360, "lantern", 25, n = 4, dx = 36, colour = 1}, {430, "drunk", 30, n = 3, dx = 50, gy = 20},
    {500, "balloon", 80, colour = 1, drop = true}, {560, "balloon", 16, n = 5, dx = 32, colour = 2}, {640, "drunk", 50, n = 2, dx = 60},
    {650, "bat", side = "R", y = 60, n = 4}, {720, "lantern", 20, n = 6, dx = 24}, {800, "drunk", 30, n = 3, dx = 50, gy = 24},
    {880, "lantern", 80, colour = 1, drop = true}, {940, "balloon", 30, n = 4, dx = 33, colour = 1}, {1020, "drunk", 20, n = 4, dx = 40, gy = 16},
    {1100, "bat", side = "L", y = 40, n = 4}, {1110, "bat", side = "R", y = 60, n = 4},
  },
  { -- 5 · the moon
    len = 130,
    {30, "lantern", 30, n = 4, dx = 33, colour = 1},
  },
}

function S.length(n) return W[n].len end

function S.progress(P) return math.min(1, ((P.stage - 1) + math.min(1, P.sc / W[P.stage].len)) / 5) end

function S.start(P, n)
  P.wave_i, P.bell_done, P.boss_done = 1, false, false
end

local function spawn_wave(P, w)
  local n = w.n or 1
  for i = 0, n - 1 do
    local o = {colour = w.colour, drop = w.drop and i == n - 1}
    if w[2] == "bat" then
      local left = w.side == "L"
      o.vx = left and 1.0 or -1.0
      Foes.spawn(P, "bat", left and -10 - i * 16 or VW + 10 + i * 16, w.y, o) -- one after another, a gap apart
    else
      Foes.spawn(P, w[2], w[3] + i * (w.dx or 0), -12 - i * (w.gy or 0), o)
    end
  end
end

function S.update(P)
  local list = W[P.stage]
  while list[P.wave_i] and P.sc >= list[P.wave_i][1] do
    spawn_wave(P, list[P.wave_i])
    P.wave_i = P.wave_i + 1
  end
  if P.stage == 2 and not P.bell_done and P.sc >= S.BELFRY + S.BELL_STOP then -- the belfry is in view: the climb stops
    P.bell_done, P.hold = true, true
    Foes.ring_bell(P, 30, S.BELL_STOP + 24)
  end
  if P.stage == 5 and not P.boss and not P.boss_done and P.sc >= 110 then
    P.boss_done, P.hold = true, true
    Boss.start(P)
  end
end

return S
