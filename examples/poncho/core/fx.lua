-- fx: little particles in world pixels (dust at the soles, sparkles, confetti), a fixed pool, drawn under camera()
local F = {}
local MAXN = 4
local ps = {}
local n = 0
local bursts, nb = {}, 0

local rings, nr = {}, 0 -- up to three rings (a shock, a splash): one command each
function F.clear() n, nr, nb = 0, 0, 0 end
function F.count() return n + nr + nb end

-- a burst picture (FX_BURST, 4 frames) where something is beaten or broken: up to two at once, 12 ticks
function F.burst(x, y)
  if not require("core.deco").has("FX_BURST") then return end
  if nb >= 2 then table.remove(bursts, 1) nb = nb - 1 end
  nb = nb + 1
  bursts[nb] = {x = x, y = y, t = 12}
end

-- a ring that grows from r0 to r1 in `life` ticks (about a wave: ground pound, splash)
function F.ring(x, y, r0, r1, color, life)
  if nr >= 3 then table.remove(rings, 1) nr = nr - 1 end
  nr = nr + 1
  rings[nr] = {x = x, y = y, r0 = r0, r1 = r1, color = color, life = life, max = life}
end


local function add(x, y, vx, vy, life, size, color, grav)
  if n >= MAXN then return end
  n = n + 1
  local p = ps[n]
  if not p then p = {} ps[n] = p end
  p.x, p.y, p.vx, p.vy, p.life, p.max, p.size, p.color, p.grav = x, y, vx, vy, life, life, size, color, grav
end

function F.debris(x, y)
  for _ = 1, 4 do
    add(x + (math.random() - 0.5) * 20, y + (math.random() - 0.5) * 20, (math.random() - 0.5) * 4, -1 - math.random() * 3, 24 + math.random(10), 5,
        math.random() < 0.5 and 0xB8742E or 0x8A5222, 0.18)
  end
end

function F.dust(x, y, count, dir, spread)
  for _ = 1, count do
    add(x + (math.random() - 0.5) * 8, y - 2, (dir or 0) * (0.4 + math.random() * 0.8) + (math.random() - 0.5) * (spread or 1.2),
        -0.3 - math.random() * 0.6, 14 + math.random(10), 3 + math.random(3), 0xF4E6C8, -0.01)
  end
end

function F.sparkle(x, y, color, count)
  for _ = 1, count or 6 do
    local a = math.random() * 6.283
    local s = 0.8 + math.random() * 1.8
    add(x, y, math.cos(a) * s, math.sin(a) * s - 0.6, 16 + math.random(10), 3, color or 0xFFE060, 0.06)
  end
end

local CONFETTI = {0xFF5050, 0xFFD040, 0x50C0FF, 0x70E070, 0xFF80D0}
function F.confetti(x, y, count)
  for i = 1, count do
    add(x + (math.random() - 0.5) * 60, y, (math.random() - 0.5) * 5, -3 - math.random() * 5, 70 + math.random(40), 4,
        CONFETTI[i % #CONFETTI + 1], 0.12)
  end
end

function F.update()
  for i = nb, 1, -1 do local b = bursts[i] b.t = b.t - 1 if b.t <= 0 then table.remove(bursts, i) nb = nb - 1 end end
  for i = nr, 1, -1 do
    local r = rings[i]
    r.life = r.life - 1
    if r.life <= 0 then table.remove(rings, i) nr = nr - 1 end
  end
  local i = 1
  while i <= n do
    local p = ps[i]
    p.life = p.life - 1
    if p.life <= 0 then
      ps[i], ps[n] = ps[n], p
      n = n - 1
    else
      p.x, p.y = p.x + p.vx, p.y + p.vy
      p.vy = p.vy + p.grav
      i = i + 1
    end
  end
end

function F.draw()
  for i = 1, nb do local b = bursts[i] require("core.deco").img("FX_BURST", math.min(3, (12 - b.t) // 3), math.floor(b.x), math.floor(b.y)) end
  for i = 1, nr do
    local r = rings[i]
    local k = 1 - r.life / r.max
    circ(math.floor(r.x), math.floor(r.y), math.floor(r.r0 + (r.r1 - r.r0) * k), r.color, false)
  end
  for i = 1, n do
    local p = ps[i]
    local s = p.size
    if p.max < 40 then s = math.max(1, math.floor(s * p.life / p.max + 0.5)) end
    rect(math.floor(p.x - s / 2), math.floor(p.y - s / 2), s, s, p.color)
  end
end

return F
