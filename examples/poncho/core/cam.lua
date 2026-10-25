-- cam: the camera. It looks ahead of where the hero is going (more the faster he goes), follows smoothly, and moves up and down only when he leaves a deadzone,
-- or settles when he stands on something for a while. Positions are the screen's top-left in level pixels.
local K = require("core.const")
local L = require("core.level")
local U = require("core.util")

local C = {x = 0, y = 0, lead = 0, still = 0, shake = 0}

local MAXX, MAXY = L.W - K.W, L.H - K.H

function C.snap(h)
  C.lead = 0
  C.x = U.clamp(h.x - K.W / 2, 0, MAXX)
  C.y = U.clamp(h.y - K.CAM_FEET, 0, MAXY)
  C.still = 0
end

function C.update(h)
  -- look-ahead follows the speed, slowly, so a turn does not snap the view
  local want = U.clamp(h.vx * K.CAM_LEAD, -K.CAM_LEAD_MAX, K.CAM_LEAD_MAX)
  if math.abs(h.vx) < 0.3 then want = h.face * 36 end
  C.lead = C.lead + (want - C.lead) * 0.045
  local tx = h.x - K.W / 2 + C.lead
  local d = tx - C.x
  local k = K.CAM_LERP + math.min(0.2, math.abs(d) / 1600)  -- a long way behind: catch up faster
  C.x = U.clamp(C.x + d * k, 0, MAXX)

  -- vertical: deadzone around where the feet normally are on screen
  local feet = h.y - C.y
  local ty = C.y
  if feet < K.CAM_FEET - K.CAM_UP then ty = h.y - (K.CAM_FEET - K.CAM_UP)
  elseif feet > K.CAM_FEET + K.CAM_DOWN then ty = h.y - (K.CAM_FEET + K.CAM_DOWN) end
  if h.ground then C.still = C.still + 1 else C.still = 0 end
  if C.still > 24 then ty = h.y - K.CAM_FEET end
  local ky = (h.vy > 3 and 0.2) or (C.still > 24 and 0.06) or 0.1
  C.y = U.clamp(C.y + (ty - C.y) * ky, 0, MAXY)

  if C.shake > 0 then C.shake = C.shake - 1 end
end

function C.kick(n) C.shake = math.max(C.shake, n) end

-- the offsets to draw with (whole pixels, a shake added)
function C.view()
  local sx, sy = 0, 0
  if C.shake > 0 then
    sx = (C.shake % 2 == 0 and 1 or -1) * math.min(3, C.shake // 2)
    sy = (C.shake % 3 == 0 and 1 or -1) * math.min(2, C.shake // 3)
  end
  return math.floor(C.x + 0.5) + sx, math.floor(C.y + 0.5) + sy
end

return C
