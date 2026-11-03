-- bot: a watchman who knows the cellar, pressing the same buttons a player has. It plays the title's demo, the tests'
-- whole night and the playtest's perfect games (tests/playtest.lua). It walks the real map square by square (a breadth
-- first search through the open squares and the doors it may open), shoots the ghost corks it can see, takes a candle
-- when the light runs low, pulls the levers, takes the key and goes down the stairs.
local W = require("world")
local B = {}

local path, goal, replan, last_a, last_b, stuck, last_x, last_y = nil, nil, 0, false, false, 0, 0, 0
local wiggle = 0

function B.reset() path, goal, replan, stuck, wiggle = nil, nil, 0, 0, 0 end

local function passable(x, y)
  if not W.solid(x, y) then return true end
  local d = W.door_at(x, y)
  if not d or not d.active and d.kind == "S" then return false end
  if d.kind == "D" then return true end
  if d.kind == "G" then return W.has_key end
  if d.kind == "H" then return d.opening end
  return false
end

local function targets() -- the squares worth going to now, best first; each {x, y, use = square to face and press B}
  local out = {}
  local low = W.wax < 38
  for _, it in ipairs(W.things) do
    local w = (it.kind == "candle" and low and 0) or (it.kind == "cork" and W.corks < 2 and 1) or (it.kind == "key" and 2) or nil
    if w then out[#out + 1] = {x = math.floor(it.x), y = math.floor(it.y), w = w, tx = it.x, ty = it.y} end
  end
  for _, lv in ipairs(W.levers) do
    if not lv.on then out[#out + 1] = {x = lv.x, y = lv.y, w = 3, use = true} end
  end
  if W.has_key or W.key_total == 0 then
    for y = 0, W.h - 1 do
      for x = 0, W.w - 1 do
        local c = W.cell(x, y)
        if c == "E" or c == "X" then out[#out + 1] = {x = x, y = y, w = 4, use = true} end
      end
    end
  end
  return out
end

local function search() -- the nearest of the best kind of target that can be reached, and the squares to it
  local sx, sy = math.floor(W.P.x), math.floor(W.P.y)
  local ts = targets()
  local want = {}
  for _, t in ipairs(ts) do want[t.y * 256 + t.x] = t end
  local parent, queue, head = {[sy * 256 + sx] = -1}, {sy * 256 + sx}, 1
  local found = {} -- target -> where it was reached; `order` keeps them in the order found (pairs over tables is not)
  local order = {}
  while queue[head] do
    local k = queue[head]
    head = head + 1
    local x, y = k % 256, k // 256
    for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
      local nx, ny = x + d[1], y + d[2]
      local nk = ny * 256 + nx
      if parent[nk] == nil then
        local t = want[nk]
        if t and t.use then -- a lever or the stairs: stand next to it
          if not found[t] then found[t] = {k = k, n = head} order[#order + 1] = t end
        elseif passable(nx, ny) then
          parent[nk] = k
          queue[#queue + 1] = nk
          if t and not found[t] then found[t] = {k = nk, n = head} order[#order + 1] = t end
        end
      end
    end
  end
  local best, bf = nil, nil
  for _, t in ipairs(order) do
    local f = found[t]
    if not best or t.w < best.w or (t.w == best.w and f.n < bf.n) then best, bf = t, f end
  end
  if not best then return nil end
  local cells, k = {}, bf.k
  while k and k ~= -1 do table.insert(cells, 1, k) k = parent[k] end
  table.remove(cells, 1) -- the square it stands in
  return best, cells
end

local function angle_to(x, y)
  local a = math.deg(math.atan(y - W.P.y, x - W.P.x))
  return ((a - W.P.a) + 540) % 360 - 180
end

local function steer(out, diff, walk)
  if diff > 6 then out.right = true elseif diff < -6 then out.left = true end
  if walk and math.abs(diff) < 30 then out.up = true end
end

local function press(out, b) -- a press, let go between presses
  if b == "a" then if not last_a then out.a = true end
  else if not last_b then out.b = true end end
end

local function target_ghost() -- the nearest ghost cork in sight, to shoot
  local best, bd = nil, 99
  for _, g in ipairs(W.ghosts) do
    if g.state ~= "pop" then
      local d = math.sqrt((g.x - W.P.x) ^ 2 + (g.y - W.P.y) ^ 2)
      if d < 5.5 and d < bd and W.grid:sees(math.floor(W.P.x), math.floor(W.P.y), math.floor(g.x), math.floor(g.y)) then
        best, bd = g, d
      end
    end
  end
  return best, bd
end

function B.think()
  local out = {}
  if W.mode ~= "play" then
    last_a, last_b = false, false
    return out
  end
  replan = replan - 1
  -- stuck against something (a ghost in a doorway, a corner): turn a little and go on
  if (W.P.x - last_x) ^ 2 + (W.P.y - last_y) ^ 2 < 1e-6 then stuck = stuck + 1 else stuck = 0 end
  last_x, last_y = W.P.x, W.P.y
  if stuck > 50 then wiggle, stuck, replan = 20, 0, 0 end
  if wiggle > 0 then
    wiggle = wiggle - 1
    out.down = wiggle > 10
    out.right = true
    last_a, last_b = false, false
    return out
  end
  local g, gd = target_ghost()
  if g and W.corks > 0 then
    local diff = angle_to(g.x, g.y)
    steer(out, diff, false)
    if math.abs(diff) < 4 and #W.shots == 0 and W.cool == 0 then press(out, "a") end
    if gd < 1.2 then out.down = true end -- too close: step back while aiming
    last_a, last_b = out.a == true, false
    return out
  end
  if g and gd < 2.5 then out.c = true end -- no corks: the lantern held up keeps them off
  if replan <= 0 or not path or #path == 0 then
    goal, path = search()
    replan = 30
  end
  if not goal then
    out.right = true -- nothing reachable yet (a door still sliding): look round
    last_a, last_b = false, false
    return out
  end
  local nk = path[1]
  if nk then
    local nx, ny = nk % 256 + 0.5, nk // 256 + 0.5
    if (nx - W.P.x) ^ 2 + (ny - W.P.y) ^ 2 < 0.2 * 0.2 then
      table.remove(path, 1)
      nk = path[1]
    end
  end
  if nk then
    steer(out, angle_to(nk % 256 + 0.5, nk // 256 + 0.5), true)
  elseif goal.use then -- next to the lever or the stairs: face it and use it
    local diff = angle_to(goal.x + 0.5, goal.y + 0.5)
    steer(out, diff, false)
    if math.abs(diff) < 8 then press(out, "b") out.up = true end
  elseif goal.tx then -- in the thing's square: to the thing itself
    steer(out, angle_to(goal.tx, goal.ty), true)
    if (goal.tx - W.P.x) ^ 2 + (goal.ty - W.P.y) ^ 2 < 0.04 then replan = 0 end
  else
    replan = 0
  end
  last_a, last_b = out.a == true, out.b == true
  return out
end

return B
