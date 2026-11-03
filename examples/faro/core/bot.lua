-- The player who knows the lighthouse: on a floor it calms every wild ánima that comes near with the lantern held high, fetches as many as the
-- hatch needs, walks them to the window, and climbs to the hatch, all along the routes core/route.lua flew with Estel's own body; in the lamp room it
-- carries fire from a pilot flame to the great lamp and steps out of the tentacles' way. The title's demo plays with it, and so does
-- tests/playtest/faro.lua (as buttons, through Bot.buttons).
local C = require("core.const")
local R = require("core.route")
local Bot = {}

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

local function head_dist(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - (b.y - 46)) ^ 2) end

-- the platform nearest under a point, among those that can be reached from `from`
local function plat_for(P, x, y, from)
  local best, bd, bx = nil, 1e9, x
  for i, p in ipairs(P.lv.plat) do
    if R.reach(P.edges, from, i) then
      local px = clamp(x, p[1] + 8, p[1] + p[3] - 8)
      local d = math.abs(px - x) + math.abs(p[2] - 46 - y) * 1.5
      if d < bd then best, bd, bx = i, d, px end
    end
  end
  return best, bx
end

local function walk_to(b, x)
  if b.x < x - 3 then return {dx = 1} end
  if b.x > x + 3 then return {dx = -1} end
  return {dx = 0}
end

-- what to do on a floor of play.lua
function Bot.floor(P)
  local b, lv = P.body, P.lv
  if P.state ~= "play" then return {} end
  local can_lift = b.ground and not P.drained
  local wild_near, fading = false, false
  for _, a in ipairs(P.animas) do
    local d = head_dist(a, b)
    if a.state == "wild" and d < C.LIFT_R - 10 then wild_near = true end
    if a.state == "follow" and a.calm < 150 and d < C.LIFT_R - 10 then fading = true end
  end
  if can_lift and (wild_near or fading) then return {lift = true} end
  -- where to go
  local goal, gx, at_window
  if (P.following or 0) > 0 and lv.window then
    local w = lv.window
    goal = lv.wplat
    gx = (w.x + w.w / 2 > 240) and (w.x + w.w - 14) or (w.x + 14)
    at_window = true
  else
    local need = P.freed + (P.following or 0) < lv.quota
    local target, td = nil, 1e9
    if need then
      for _, a in ipairs(P.animas) do
        if a.state == "wild" then
          local d = head_dist(a, b)
          if d < td then target, td = a, d end
        end
      end
    end
    if target and b.ground and b.on then
      goal, gx = plat_for(P, target.x, target.y, b.on)
    else
      goal = lv.hatch.plat
      gx = lv.hatch.x + lv.hatch.w / 2
    end
  end
  if not b.ground then return R.drive(b, P.bot_edge or {steer = 0, jump = false}) end
  if not b.on then return {dx = 0} end
  -- outside, in a gust: stay on the rung (walk against it), never jump into it
  local gusty = P.gust_soon(P.t, 60)
  if b.on == goal then
    if at_window and math.abs(b.x - gx) < 6 and can_lift then return {lift = true} end
    local m = walk_to(b, gx)
    if gusty and P.wind_at(P.t) ~= 0 and m.dx == 0 then
      local p = lv.plat[b.on]
      m = walk_to(b, clamp(b.x, p[1] + 10, p[1] + p[3] - 10))
    end
    return m
  end
  local e = R.next_edge(P.edges, b.on, goal)
  if not e then return walk_to(b, gx) end
  if gusty then
    local p = lv.plat[b.on]
    return walk_to(b, clamp(p[1] + p[3] / 2, p[1] + 12, p[1] + p[3] - 12))
  end
  P.bot_edge = e
  return R.drive(b, e)
end

-- what to do in the lantern room (core/boss.lua): out of every tentacle's way first, then fire from a pilot flame, then up to the lamp
function Bot.boss(B)
  local b = B.body
  if B.state ~= "fight" then return {} end
  if not b.ground then return R.drive(b, B.bot_edge or {steer = 0, jump = false}) end
  local goal, gx = B.task()
  local working = b.on == goal and math.abs(b.x - gx) < 6
  local t = B.danger(b.x, false, working)
  if t then
    local p = B.lv.plat[b.on or 1]
    local best
    for x = p[1] + 4, p[1] + p[3] - 4, 4 do
      if x > C.HW and x < 480 - C.HW and not B.danger(x) and (not best or math.abs(x - b.x) < math.abs(best - b.x)) then
        local clear = true -- never through a tentacle that is up
        for k = 1, 8 do if B.danger(b.x + (x - b.x) * k / 8, true) then clear = false break end end
        if clear then best = x end
      end
    end
    if best then return walk_to(b, best) end
    return {dx = b.x < t.x and -1 or 1}
  end
  if b.on == goal then
    if math.abs(b.x - gx) < 6 then return {lift = true} end
    local m = walk_to(b, gx)
    if m.dx ~= 0 and B.danger(b.x + m.dx * 10) then return {dx = 0} end
    return m
  end
  local e = b.on and R.next_edge(B.edges, b.on, goal)
  if not e then return walk_to(b, gx) end
  for k = 0, 4 do -- the whole flight clear, from where it leaves to where it lands
    if B.danger(e.x + (e.land - e.x) * k / 4) then return walk_to(b, b.x) end
  end
  B.bot_edge = e
  return R.drive(b, e)
end

-- the same input as the buttons a player holds (A jumps, B raises the lantern)
local was_a = false
function Bot.buttons(inp, grounded)
  local out = {}
  if inp.dx == -1 then out.left = true elseif inp.dx == 1 then out.right = true end
  local a = inp.jump or (inp.hold and not grounded)
  if inp.jump and was_a then a = false end -- a press needs the button up the tick before
  out.a = a or nil
  out.b = inp.lift or nil
  was_a = a and true or false
  return out
end

return Bot
