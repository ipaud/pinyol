-- level: asking the map. Solid tiles, one-way shelves and the two halves of each ramp; the ground under a point; the camera's bounds.
local K = require("core.const")
local M = require("core.map")
local L = {}

local TILE, ROWS = K.TILE, K.ROWS
local COLS, grid
L.plats = {}   -- carts: one-way platforms that move {x (left), y (top), w, vx, x0, x1}

-- (re)reads the level the map loaded (core/map.lua M.load): its size, grid and carts
function L.reload()
  if not M.cols then require("core.worlds").load(1) end
  COLS, grid = M.cols, M.grid
  L.W, L.H = COLS * TILE, ROWS * TILE
  L.grid = grid
  L.plats = {}
  for i, p in ipairs(M.plats or {}) do L.plats[i] = {x = p.x, y = p.y, w = p.w, vx = p.vx, x0 = p.x0, x1 = p.x1} end
end
L.reload()

local SOLID = {["#"] = true, W = true, T = true, K = true, [">"] = true, ["<"] = true}
local SLOPE = {a = {0, 16}, b = {16, 32}, c = {32, 16}, d = {16, 0}} -- the wedge's height at its left and right edges
L.SOLID, L.SLOPE = SOLID, SLOPE

-- the character at tile (c, r): the walls at both ends of the level are solid, above it and below it is air
function L.at(c, r)
  if c < 0 or c >= COLS then return "#" end
  if r < 0 or r >= ROWS then return " " end
  return grid[r][c]
end

function L.solid_at(x, y) return SOLID[L.at(x // TILE, y // TILE)] == true end

-- the top of what is at tile (c, r) under x, or nil (a solid tile, a shelf and a ramp are different surfaces)
-- returns y, kind where kind is "solid", "shelf" or "slope"
local function surface(c, r, x)
  local ch = L.at(c, r)
  if SOLID[ch] then return r * TILE, "solid", ch end
  if ch == "=" then return r * TILE, "shelf" end
  local s = SLOPE[ch]
  if s then
    local k = (x - c * TILE) / TILE
    if k < 0 then k = 0 elseif k > 1 then k = 1 end
    return (r + 1) * TILE - (s[1] + (s[2] - s[1]) * k), "slope", ch
  end
  return nil
end

-- the ground under column x for a body whose soles went from y0 to y1 (y1 >= y0): the highest surface the soles crossed or touch.
-- `tol` lets the soles be a little under a surface and still stand on it (walking up a ramp). `drop` ignores shelves.
-- returns y, kind, char or nil
function L.ground(x, y0, y1, tol, drop)
  local c = math.floor(x / TILE)
  local r0, r1 = math.floor((y0 - tol) / TILE), math.floor(y1 / TILE)
  for r = math.max(r0, 0), math.min(r1, ROWS - 1) do
    local s, kind, ch = surface(c, r, x)
    if s and s <= y1 + 0.001 and (y0 <= s + (kind == "slope" and tol or 0.5)) and not (drop and kind == "shelf") then
      return s, kind, ch
    end
  end
  if not drop then -- a cart under the feet
    for _, p in ipairs(L.plats) do
      if x >= p.x and x <= p.x + p.w and p.y <= y1 + 0.001 and y0 <= p.y + 0.5 then return p.y, "plat", p end
    end
  end
  return nil
end

-- the carts roll to and fro
function L.update_plats()
  for _, p in ipairs(L.plats) do
    p.x = p.x + p.vx
    if p.x < p.x0 then p.x, p.vx = p.x0, -p.vx elseif p.x > p.x1 then p.x, p.vx = p.x1, -p.vx end
  end
end

-- how far a body of this half width and height can go: is any of the body's edge points inside a solid tile
function L.wall_x(x, y, half_w, h, dir)
  local px = x + dir * half_w
  -- three probes: near the head, the middle and above the ramps' reach (the lowest probe is 20 px up, higher than a ramp rises under half the body)
  return L.solid_at(px, y - h + 3) or L.solid_at(px, y - h * 0.5) or L.solid_at(px, y - 20)
end

-- ceiling over the head: returns the tile row bottom (y) of the solid tile hit, or nil; probes left, middle, right
function L.ceiling(x, head_y, half_w)
  local l = L.solid_at(x - half_w + 2, head_y)
  local m = L.solid_at(x, head_y)
  local r = L.solid_at(x + half_w - 2, head_y)
  return l, m, r
end

-- crates (K) are solid and break: every crate that touches the box x0..x1, y0..y1 (pixels); returns how many broke (and where, in L.broke_at)
L.broke_at = {}
function L.break_crates(x0, y0, x1, y1)
  local n = 0
  for r = math.floor(y0 / TILE), math.floor(y1 / TILE) do
    for c = math.floor(x0 / TILE), math.floor(x1 / TILE) do
      if r >= 0 and r < ROWS and c >= 0 and c < COLS and grid[r][c] == "K" then
        grid[r][c] = " "
        n = n + 1
        L.broke_at[n] = {c * TILE + 16, r * TILE + 16}
      end
    end
  end
  return n
end

function L.reset_crates()
  L.reload()
  for _, p in ipairs(M.crates) do grid[p[2]][p[1]] = "K" end
end

return L
