-- The routes of a floor, worked out by flying Estel's own body (core/body.lua) ahead of time: from every platform, a jump (or a step off its edge) from
-- each place along it, steering left, straight or right, and where it lands. What lands somewhere else without touching a gear, the water or the sea is
-- an edge of a graph; the bot (and the title's demo, and tests/playtest/faro.lua) walk it with a breadth-first search. Nothing here is a shortcut: the
-- bot presses the same buttons a player would. Flying a floor takes the console seconds, so it is done here and kept in core/edges.lua (tests/faro.script
-- checks that file against the floors and the body, and prints it anew when they have changed).
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
  b.vx = steer * C.WALK -- a running jump (or step) in the way it steers; straight up from standing
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
        local back = x - steer * 10 -- room to run up to it on the same platform, and nothing that hurts there
        local to, ticks, land
        if back >= p[1] - 4 and back <= p[1] + p[3] + 4 and not hits_hazard(lv, {x = x, y = p[2]}) and not hits_hazard(lv, {x = back, y = p[2]}) then
          to, ticks, land = fly(lv, i, x, steer, true)
        end
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
      e.plo, e.phi = p[1], p[1] + p[3]
      e.land = e.lands[math.max(1, math.floor(#e.lands / 2 + 0.5))] -- where the middle launch comes down
      e.lands = nil
      edges[i][#edges[i] + 1] = e
    end
    table.sort(edges[i], function(a, b) return a.to < b.to end) -- the same order on every machine
  end
  return edges
end

-- the source of core/edges.lua: every floor's edges, and the boss's
function R.text(floors)
  local out = {"-- Made by core/route.lua: the routes of every floor, flown ahead of time. If tests/faro.script says they are stale, paste what it prints.", "return {"}
  local function floor(key, edges)
    out[#out + 1] = "  [" .. key .. "] = {"
    for _, list in ipairs(edges) do
      local row = {}
      for _, e in ipairs(list) do
        row[#row + 1] = string.format("{to = %d, x = %.17g, lo = %.17g, hi = %.17g, plo = %.17g, phi = %.17g, land = %.17g, steer = %d, jump = %s, ticks = %d}",
                                      e.to, e.x, e.lo, e.hi, e.plo, e.phi, e.land, e.steer, tostring(e.jump), e.ticks)
      end
      out[#out + 1] = "    {" .. table.concat(row, ",\n     ") .. "},"
    end
    out[#out + 1] = "  },"
  end
  for i, edges in ipairs(floors) do floor(i, edges) end
  floor('"boss"', floors.boss)
  out[#out + 1] = "}\n"
  return table.concat(out, "\n")
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

-- the input that takes the body along edge e: straight up from standing still in its window; to either side, a running jump through its window
function R.drive(b, e)
  if not b.ground then return {dx = e.steer, hold = true} end
  if not e.jump then return {dx = e.steer, hold = true} end -- off the edge
  local lo, hi = e.lo, e.hi
  if e.steer == 0 then
    lo, hi = e.lo + 2, e.hi - 2 -- every place of the window was flown and lands
    if lo > hi - 1 then lo, hi = e.x - 0.8, e.x + 0.8 end
    if b.x >= lo and b.x <= hi and math.abs(b.vx) <= 0.6 then return {dx = 0, jump = true, hold = true} end
    local mid = (lo + hi) / 2
    if b.x < lo - 6 or (b.x < lo and b.vx <= 0) then return {dx = 1} end
    if b.x > hi + 6 or (b.x > hi and b.vx >= 0) then return {dx = -1} end
    if math.abs(b.vx) > 0.3 then return {dx = 0} end
    if b.x < lo then return {dx = 1} end
    if b.x > hi then return {dx = -1} end
    return {dx = 0, jump = true, hold = true}
  end
  local s = e.steer
  local fast = b.vx * s >= C.WALK - 0.05
  local inwin = b.x >= lo and b.x <= hi
  if inwin and fast then return {dx = s, jump = true, hold = true} end
  local past = (s > 0 and b.x > hi) or (s < 0 and b.x < lo)
  if b.vx * s > 0 and not past then return {dx = s} end -- running at it, or through it until fast enough
  local start = math.max(e.plo + 2, math.min(e.phi - 2, s > 0 and lo - 9 or hi + 9))
  if math.abs(b.x - start) <= 1.5 then return {dx = s} end
  if b.x < start then return {dx = 1} end
  return {dx = -1}
end

return R
