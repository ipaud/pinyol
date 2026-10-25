-- fx: little particles in world pixels (dust at the soles, sparkles, confetti), a fixed pool, drawn under camera()
local F = {}
local MAXN = 64
local ps = {}
local n = 0

function F.clear() n = 0 end

local function add(x, y, vx, vy, life, size, color, grav)
  if n >= MAXN then return end
  n = n + 1
  local p = ps[n]
  if not p then p = {} ps[n] = p end
  p.x, p.y, p.vx, p.vy, p.life, p.max, p.size, p.color, p.grav = x, y, vx, vy, life, life, size, color, grav
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
  for i = 1, n do
    local p = ps[i]
    local s = p.size
    if p.max < 40 then s = math.max(1, math.floor(s * p.life / p.max + 0.5)) end
    rect(math.floor(p.x - s / 2), math.floor(p.y - s / 2), s, s, p.color)
  end
end

return F
