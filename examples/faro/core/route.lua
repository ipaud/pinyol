-- The routes of a floor, worked out by flying Estel's own body (core/body.lua) ahead of time: from every platform, a jump (or a step off its edge) from
-- each place along it, steering left, straight or right, and where it lands. What lands somewhere else without touching a gear, the water or the sea is
-- an edge of a graph; the bot (and the title's demo, and tests/playtest/faro.lua) walk it with a breadth-first search. Nothing here is a shortcut: the
-- bot presses the same buttons a player would.
local C = require("core.const")
local Body = require("core.body")
local R = {}

local function static_y(p) return p[2] end

local function hits_hazard(lv, b)
  if lv.water and b.y > lv.water + 4 then return true end
  if lv.sea and b.y > lv.sea then return true end
  for _, g in ipairs(lv.gears or {}) do
    local cy = b.y - C.HH / 2
    local dx, dy = math.abs(b.x - g.x) - C.HW, math.abs(cy - g.y) - C.HH / 2
    if dx < g.r + 6 and dy < g.r + 6 then
      local ex, ey = math.max(0, dx), math.max(0, dy)
      if ex * ex + ey * ey < (g.r + 6) ^ 2 then return true end
    end
  end
  return false
end

-- one flight from x on platform i: jump (or walk off), steering `steer` all the way; the platform it lands on, or nil
local function fly(lv, i, x, steer, jump)
  local p = lv.plat[i]
  local b = Body.new(x, p[2])
  b.on = i
  if not jump then b.vx = steer * C.WALK end
  for t = 1, 140 do
    local ev = Body.step(b, {dx = steer, jump = jump and t == 1, hold = true}, lv.plat, static_y, 0)
    if hits_hazard(lv, b) then return nil end
    if ev == "land" then
      if b.on == i then return nil end
      local to = b.on
      for _ = 1, 6 do -- she must stay on it while she stops
        Body.step(b, {dx = 0}, lv.plat, static_y, 0)
        if not b.ground or b.on ~= to or hits_hazard(lv, b) then return nil end
      end
      return to, t, b.x
    end
    if t > 2 and b.ground and b.on == i then return nil end
  end
  return nil
end

-- every edge of a floor: R.edges[i] = {{to, x, lo, hi, steer, jump, ticks}, ...}
function R.build(lv)
  local edges = {}
  for i, p in ipairs(lv.plat) do
    edges[i] = {}
    local best = {}
    for _, steer in ipairs({-1, 0, 1}) do
      local run = nil
      local function close()
        if run then
          local key = run.to
          local width = run.hi - run.lo
          if not best[key] or width > best[key].hi - best[key].lo then best[key] = run end
          run = nil
        end
      end
      for x = math.max(C.HW, p[1] - 4), math.min(480 - C.HW, p[1] + p[3] + 4), 2 do
        local to, ticks, land = fly(lv, i, x, steer, true)
        if to and run and run.to == to then run.hi, run.lands[#run.lands + 1] = x, land
        else
          close()
          if to then run = {to = to, lo = x, hi = x, steer = steer, jump = true, ticks = ticks, lands = {land}} end
        end
      end
      close()
    end
    -- stepping off an edge
    for _, side in ipairs({-1, 1}) do
      local x = side < 0 and p[1] - 5 or p[1] + p[3] + 5
      if x > C.HW and x < 480 - C.HW then
        local to, ticks, land = fly(lv, i, x, side, false)
        if to and not best[to] then best[to] = {to = to, lo = x, hi = x, steer = side, jump = false, ticks = ticks, lands = {land}} end
      end
    end
    for to, e in pairs(best) do
      e.x = (e.lo + e.hi) / 2
      e.land = e.lands[math.max(1, math.floor(#e.lands / 2 + 0.5))] -- where the middle launch comes down
      e.lands = nil
      edges[i][#edges[i] + 1] = e
    end
    table.sort(edges[i], function(a, b) return a.to < b.to end) -- the same order on every machine
  end
  return edges
end

-- the first edge of the shortest way from platform a to platform b (nil if none, or a == b)
function R.next_edge(edges, a, b)
  if a == b then return nil end
  local prev, queue, head = {[a] = false}, {a}, 1
  while queue[head] do
    local i = queue[head]
    head = head + 1
    for _, e in ipairs(edges[i] or {}) do
      if prev[e.to] == nil then
        prev[e.to] = {from = i, e = e}
        if e.to == b then
          local n = b
          while prev[n].from ~= a do n = prev[n].from end
          return prev[n].e
        end
        queue[#queue + 1] = e.to
      end
    end
  end
  return nil
end

-- can b be reached from a
function R.reach(edges, a, b)
  return a == b or R.next_edge(edges, a, b) ~= nil
end

-- the input that takes the body along edge e: walk to its launch place, stand still, jump, steer
function R.drive(b, e)
  if b.ground then
    if e.jump then
      local lo, hi = math.max(e.lo, e.x - 2), math.min(e.hi, e.x + 2)
      if lo > hi - 1 then lo, hi = e.x - 0.6, e.x + 0.6 end
      if b.x < lo - 6 then return {dx = 1} end
      if b.x > hi + 6 then return {dx = -1} end
      if math.abs(b.vx) > 0.01 then return {dx = 0} end
      if b.x < lo then return {dx = 1} end
      if b.x > hi then return {dx = -1} end
      return {dx = e.steer, jump = true, hold = true}
    end
    return {dx = e.steer, hold = true} -- off the edge
  end
  return {dx = e.steer, hold = true}
end

return R
