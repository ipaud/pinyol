-- Estel drawn: which picture and frame for what her body is doing, where her lantern is in that frame, and her light. Her frames are 128x144 with the
-- soles on row 142 and the feet in column 64 (tools/build_art.py, "fit": "feet").
local C = require("core.const")
local E = {}

-- the lantern in each pose, from her feet, facing right
local LANT = {walk = {-12, -30}, lift = {-6, -98}, idle = {-12, -30}, jump = {30, -42}, fall = {28, -30}, hurt = {-4, -52}, win = {-16, -84}}

-- pose(b, s): s holds what the body does not (lift, hurt timer, win, step distance)
function E.pose(b, s)
  if s.win then return "SPR_ESTEL_MOVES", 4, "win" end
  if s.hurt and s.hurt > C.INVULN - 30 then return "SPR_ESTEL_MOVES", 3, "hurt" end
  if not b.ground then
    if b.vy < 0 then return "SPR_ESTEL_MOVES", 1, "jump" end
    return "SPR_ESTEL_MOVES", 2, "fall"
  end
  local step = math.floor((s.walked or 0) / 11) % 5
  if s.lift then return "SPR_ESTEL_LIFT", math.abs(b.vx) > 0.1 and step or 0, "lift" end
  if math.abs(b.vx) > 0.1 then return "SPR_ESTEL_WALK", step, "walk" end
  return "SPR_ESTEL_MOVES", 0, "idle"
end

function E.lantern(b, s)
  local _, _, p = E.pose(b, s)
  local o = LANT[p]
  return b.x + o[1] * b.dir, b.y + o[2]
end

-- the light first or last: the caller decides (it adds to what is under it)
function E.draw(b, s, cam, opts)
  local id, f = E.pose(b, s)
  local o = {frame = f, flip_x = b.dir < 0}
  if s.hurt and s.hurt > 0 and (s.hurt // 4) % 2 == 0 then o.mul = 0x90C8FF end -- shivering: blue, on her only (never the screen)
  if opts then for k, v in pairs(opts) do o[k] = v end end
  img(id, b.x - 64, b.y - cam - 142, o)
end

-- her reflection on still water at row `water`: the frame mirrored upside down, faint, cut at the surface
function E.reflect(b, s, cam, water)
  if water - b.y > 120 then return end
  local id, f = E.pose(b, s)
  local top = 2 * water - b.y - 2 - cam
  clip(0, water - cam, 480, 320)
  img(id, b.x - 64, top, {frame = f, flip_x = b.dir < 0, flip_y = true, alpha = 0.3, mul = 0x8090C0})
  clip()
end

function E.light(b, s, cam, r, charged)
  local lx, ly = E.lantern(b, s)
  local flick = 1 + 0.06 * math.sin(s.t * 0.31) + 0.04 * math.sin(s.t * 0.83)
  light(lx, ly - cam, r * flick, charged and 0xFFD070 or 0xFFA850, {intensity = charged and 1.1 or 0.85})
  light(lx, ly - cam, 9 * flick, 0xFFF0C0, {intensity = 1.2})
end

return E
