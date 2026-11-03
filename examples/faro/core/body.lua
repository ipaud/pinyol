-- Estel's body: how she walks, jumps and lands on the one-way platforms. One step is a pure function of the body, the input and the platforms, so the
-- route planner (core/route.lua) can fly the same jump ahead of time and know where it lands.
local C = require("core.const")
local B = {}

function B.new(x, y)
  return {x = x, y = y, vx = 0, vy = 0, ground = true, on = nil, coyote = 0, buffer = 0, dir = 1, held = false}
end

function B.copy(b)
  return {x = b.x, y = b.y, vx = b.vx, vy = b.vy, ground = b.ground, on = b.on, coyote = b.coyote, buffer = b.buffer, dir = b.dir, held = b.held}
end

local function over(p, x) return x >= p[1] - 6 and x <= p[1] + p[3] + 6 end

-- plat_y(p) gives a platform's top this tick (a barrel bobs). input: {dx = -1/0/1, jump = pressed this tick, hold = held, lift = lantern up}
-- wind: pixels a tick pushed sideways. Returns "jump", "land" or nil.
function B.step(b, input, plats, plat_y, wind)
  local ev
  local speed = input.lift and b.ground and C.WALK_LIFT or C.WALK
  local want = (input.dx or 0) * speed
  if b.vx < want then b.vx = math.min(want, b.vx + C.ACC) elseif b.vx > want then b.vx = math.max(want, b.vx - C.ACC) end
  if input.dx and input.dx ~= 0 then b.dir = input.dx end
  if input.jump then b.buffer = 6 elseif b.buffer > 0 then b.buffer = b.buffer - 1 end
  if b.ground then b.coyote = 5 elseif b.coyote > 0 then b.coyote = b.coyote - 1 end
  if b.buffer > 0 and b.coyote > 0 and not input.lift then
    b.vy, b.ground, b.on, b.coyote, b.buffer, b.held = C.JUMP, false, nil, 0, 0, true
    ev = "jump"
  end
  if b.held and not input.hold then
    b.held = false
    if b.vy < 0 then b.vy = b.vy * C.CUT end
  end
  b.x = b.x + b.vx + (wind or 0)
  if b.x < C.HW then b.x, b.vx = C.HW, 0 end
  if b.x > 480 - C.HW then b.x, b.vx = 480 - C.HW, 0 end
  if b.ground then
    local p = plats[b.on]
    if not p or not over(p, b.x) then
      b.ground, b.on = false, nil
    else
      b.y = plat_y(p)
      b.vy = 0
    end
  end
  if not b.ground then
    local y0 = b.y
    b.vy = math.min(C.MAXFALL, b.vy + C.GRAV)
    b.y = b.y + b.vy
    if b.vy >= 0 then
      for i, p in ipairs(plats) do
        local py = plat_y(p)
        if y0 <= py + 1 and b.y >= py and over(p, b.x) then
          b.y, b.vy, b.ground, b.on, b.held = py, 0, true, i, false
          ev = "land"
          break
        end
      end
    end
  end
  return ev
end

return B
