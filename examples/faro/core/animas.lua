-- The ánimas: drowned fishermen lost in the dark tower. Wild, they wander and their touch chills Estel to the bone; touched by the lantern held high
-- they calm, turn warm and follow her, and an ánima that reaches the window goes out to sea as a light. Drawn half seen through (img's alpha) and,
-- when calm, adding their warm light to what is under them (img's add): the PlayStation's semi-transparency.
local C = require("core.const")
local A = {}

function A.new(def, i)
  return {x = def.x, y = def.y, cx = def.x, cy = def.y, ax = def.ax, ay = def.ay, drift = def.drift, ph = i * 1.7, state = "wild", calm = 0,
          follow_t = 0, t = 0, out = 0, slot = i}
end

local function lerp(a, b, k) return a + (b - a) * k end

-- e: Estel {x, y (feet), dir, lift}; returns "touch" when a wild one reaches her, "calm" when one is calmed, "free" when one goes out
function A.update(a, e, lv, light_r)
  a.t = a.t + 1
  local px = a.x
  local hx, hy = e.x, e.y - 46
  local d = math.sqrt((a.x - hx) ^ 2 + (a.y - hy) ^ 2)
  local ev
  if a.state == "wild" then
    if e.lift and d < light_r then
      a.state, a.calm, a.follow_t = "follow", C.CALM_T, 0
      ev = "calm"
    else
      local s = a.t * 0.012 + a.ph
      local tx, ty = a.cx + a.ax * math.sin(s), a.cy + a.ay * math.sin(s * 1.9)
      if a.drift and d < 200 then -- the ones outside are drawn to the lantern
        a.cx = lerp(a.cx, hx, 0.004)
        a.cy = lerp(a.cy, hy, 0.004)
      end
      a.x, a.y = lerp(a.x, tx, 0.05), lerp(a.y, ty, 0.05)
      if d < C.TOUCH then ev = "touch" end
    end
  elseif a.state == "follow" then
    a.follow_t = a.follow_t + 1
    if e.lift and d < light_r then a.calm = C.CALM_T else a.calm = a.calm - 1 end
    local tx, ty = e.x - e.dir * (26 + a.slot * 10), e.y - 70 - a.slot * 6 + 4 * math.sin(a.t * 0.05 + a.ph)
    local k = 0.06
    a.x, a.y = lerp(a.x, tx, k), lerp(a.y, ty, k)
    local w = lv.window
    if w and a.x > w.x and a.x < w.x + w.w and a.y > w.y and a.y < w.y + w.h then
      a.state, a.out = "free", 0
      a.ox, a.oy = w.x + w.w / 2, w.y + w.h / 2
      ev = "free"
    elseif lv.outside and a.follow_t > 150 then -- outside, a calm one goes off over the sea by itself
      a.state, a.out = "free", 0
      a.ox, a.oy = a.x - 160, a.y - 120
      ev = "free"
    elseif a.calm <= 0 then
      a.state, a.cx, a.cy = "wild", a.x, a.y
    end
  elseif a.state == "free" then
    a.out = a.out + 1
    a.x, a.y = lerp(a.x, a.ox, 0.05), lerp(a.y, a.oy, 0.05)
    if a.out > 90 then a.state = "gone" end
  end
  if a.x - px > 0.15 then a.face = 1 elseif a.x - px < -0.15 then a.face = -1 end
  return ev
end

function A.draw(a, cam)
  if a.state == "gone" then return end
  local f = (a.t // 9) % 5
  local flip = (a.face or 1) < 0
  local x, y = a.x - 56, a.y - cam - 56
  if a.state == "wild" then
    img("SPR_ANIMA", x, y + 2 * math.sin(a.t * 0.07), {frame = f, alpha = 0.55, flip_x = flip})
    light(a.x, a.y - cam, 30, 0x40C0D0, {intensity = 0.35})
  elseif a.state == "follow" then
    local k = math.min(1, a.calm / 60)
    img("SPR_ANIMA", x, y, {frame = f, alpha = 0.45, mul = 0xFFE0B0, flip_x = flip})
    img("SPR_ANIMA", x, y, {frame = f, add = true, alpha = 0.35 * k, mul = 0xFFB060, flip_x = flip})
  else
    local k = 1 - a.out / 90
    local s = 0.4 + 0.6 * k
    img("SPR_ANIMA", a.x - 56 * s, a.y - cam - 56 * s, {frame = f, add = true, alpha = 0.6 * k, scale = s, mul = 0xFFD090})
    light(a.x, a.y - cam, 40 * k + 10, 0xFFD080, {intensity = 0.8 * k})
  end
end

return A
