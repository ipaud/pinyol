-- util: small helpers every module uses
local U = {}

function U.clamp(v, a, b) return v < a and a or (v > b and b or v) end
function U.sign(v) return v > 0 and 1 or (v < 0 and -1 or 0) end
function U.approach(v, target, step)
  if v < target then return math.min(v + step, target) end
  return math.max(v - step, target)
end
function U.lerp(a, b, k) return a + (b - a) * k end
function U.overlap(ax, ay, aw, ah, bx, by, bw, bh)
  return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah
end

-- true when a blink of the hero (hurt, invulnerable) may show: none for a player who asked for fewer flashes
function U.calm() return settings().reduce_flashing == true end

return U
