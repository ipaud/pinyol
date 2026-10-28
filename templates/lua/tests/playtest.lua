-- playtest adapter (docs/playtest.md): tells tools/playtest.py how this game is played, so a bot can play it start to finish.
-- playtest-gate: win   (ctest then fails if the perfect player below ever stops finishing the game)
-- Keep it true while the game grows: `uv run tools/finish_game.py <this game>` plays 50 perfect and 50 imperfect games and says if it is done.
local CELL, TILE = 4, 8 -- the player's position as a grid of 4 px cells, to search for a way to the gems
local SOLID = {["#"] = true, ["T"] = true, ["~"] = true}

local function tile_at(px, py)
  local tx, ty = math.floor(px / TILE), math.floor(py / TILE)
  if tx < 0 or ty < 0 or tx >= #ROOM[1] or ty >= #ROOM then return "#" end
  return ROOM[ty + 1]:sub(tx + 1, tx + 1)
end
local function blocked(x, y) -- as main.lua: the feet box
  return SOLID[tile_at(x + 3, y + 10)] or SOLID[tile_at(x + 12, y + 10)] or SOLID[tile_at(x + 3, y + 15)] or SOLID[tile_at(x + 12, y + 15)]
end
local function touches(x, y)
  for _, g in ipairs(gems) do
    if math.abs(x + 8 - (g.x + 4)) < 7 and math.abs(y + 10 - (g.y + 4)) < 7 then return true end
  end
end

local wx, wy, replan = nil, nil, 0
local function plan() -- breadth first search over the room, from the player to the nearest gem: where to head next
  local sx, sy = math.floor(player.x / CELL + 0.5), math.floor(player.y / CELL + 0.5)
  local parent, queue, head = {[sx .. "," .. sy] = false}, {{sx, sy}}, 1
  while queue[head] do
    local cx, cy = queue[head][1], queue[head][2]
    head = head + 1
    if touches(cx * CELL, cy * CELL) then
      local k = cx .. "," .. cy
      while parent[k] and parent[parent[k]] do k = parent[k] end -- back to the cell next to the start
      local x, y = k:match("(-?%d+),(-?%d+)")
      return tonumber(x) * CELL, tonumber(y) * CELL
    end
    for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
      local nx, ny = cx + d[1], cy + d[2]
      local k = nx .. "," .. ny
      if parent[k] == nil and not blocked(nx * CELL, ny * CELL) then
        parent[k] = cx .. "," .. cy
        queue[#queue + 1] = {nx, ny}
      end
    end
  end
end

PLAYTEST = {
  playing = function() return state == "play" end,
  progress = function() return -#gems end,                    -- fewer gems left = further
  done = function() if state == "done" then return "win" end end,
  where = function() return "gems_left_" .. #gems end,
  perfect = function(pt)
    replan = replan - 1
    if replan <= 0 or not wx then wx, wy = plan(); replan = 5 end
    local out = {}
    if wx then
      if player.x < wx - 0.5 then out.right = true elseif player.x > wx + 0.5 then out.left = true end
      if player.y < wy - 0.5 then out.down = true elseif player.y > wy + 0.5 then out.up = true end
    end
    return out
  end,
}
