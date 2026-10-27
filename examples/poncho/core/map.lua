-- map: the levels of every world, written with a few builders (the kit). A world's level is core/maps/w<N>.lua: a function that gets the kit and calls it.
-- Characters of the grid (32 px tiles, ROWS = 14, the floor's surface is the top of row FLOOR):
--   '#' floor   'W' a wooden letter block   'T' a toy box / fruit crate   'K' a crate that breaks   '=' a shelf (solid from above only)
--   'a' 'b' the two halves of an up ramp (rising to the right)   'c' 'd' the two halves of a down ramp   '>' '<' a conveyor belt (moving floor)   ' ' air
-- Everything a block or a tile does is in level.lua; this file only says where things are. Heights are in tiles above the floor's surface.
local K = require("core.const")
local M = {}

local ROWS, FR = K.ROWS, K.FLOOR

-- M.load(i): builds world i's level; afterwards M.grid, M.objs, M.foes, M.plats, M.crates, M.boss, M.start_c, M.cols say what is where
function M.load(i, cols)
  cols = cols or require("core.worlds").defs[i].cols
  local grid = {}
  for r = 0, ROWS - 1 do
    grid[r] = {}
    for c = 0, cols - 1 do grid[r][c] = " " end
  end
  local objs, foes, plats = {}, {}, {}
  M.spot = nil
  local kit = {FR = FR, COLS = cols, ROWS = ROWS}
  local boss, start_c = nil, 3

  local function set(c, r, ch) if c >= 0 and c < cols and r >= 0 and r < ROWS then grid[r][c] = ch end end
  local function fill(c0, c1, r0, r1, ch) for r = r0, r1 do for c = c0, c1 do set(c, r, ch) end end end
  function kit.floor(c0, c1) fill(c0, c1, FR, ROWS - 1, "#") end
  function kit.gap(c0, c1) fill(c0, c1, FR, ROWS - 1, " ") end
  function kit.blocks(c, n, w, ch, base) fill(c, c + w - 1, (base or FR) - n, (base or FR) - 1, ch or "W") end
  function kit.shelf(c0, c1, h) fill(c0, c1, FR - h, FR - h, "=") end
  function kit.conveyor(c0, c1, dir) fill(c0, c1, FR, FR, dir > 0 and ">" or "<") end
  function kit.ramp(c, n, base)  -- up ramp: n steps of 32 px, two tiles long each
    base = base or FR
    for i = 0, n - 1 do
      local r = base - 1 - i
      set(c + 2 * i, r, "a") set(c + 2 * i + 1, r, "b")
      for rr = r + 1, base - 1 do set(c + 2 * i, rr, "#") set(c + 2 * i + 1, rr, "#") end
    end
  end
  function kit.rampdown(c, n, base)
    base = base or FR
    for i = 0, n - 1 do
      local r = base - n + i
      set(c + 2 * i, r, "c") set(c + 2 * i + 1, r, "d")
      for rr = r + 1, base - 1 do set(c + 2 * i, rr, "#") set(c + 2 * i + 1, rr, "#") end
    end
  end

  -- things: x is the middle of tile column c, y the bottom of the row `FR - h - 1` (so h = 0 stands on the floor)
  local function at(c, h) return c * 32 + 16, (FR - h) * 32 end
  function kit.obj(kind, c, h, extra)
    local x, y = at(c, h)
    local o = {kind = kind, x = x, y = y}
    if extra then for k, v in pairs(extra) do o[k] = v end end
    objs[#objs + 1] = o
  end
  function kit.coins(c, h, n, dc, dh) -- n coins from (c, h): h is the height of their middle above the floor, in tiles
    for i = 0, n - 1 do
      local x, y = at(c + i * (dc or 1), h + i * (dh or 0))
      objs[#objs + 1] = {kind = "coin", x = x, y = y - 16}
    end
  end
  function kit.arc(c, h, n, rise) -- coins on an arch
    for i = 0, n - 1 do
      local x, y = at(c + i, h)
      local k = n > 1 and (i / (n - 1)) or 0
      objs[#objs + 1] = {kind = "coin", x = x, y = y - 16 - math.sin(k * math.pi) * rise * 32}
    end
  end
  function kit.foe(kind, c, h, extra)
    local x, y = at(c, h)
    local f = {kind = kind, x = x, y = y}
    if extra then for k, v in pairs(extra) do f[k] = v end end
    foes[#foes + 1] = f
  end
  -- a cart that rolls to and fro over a pit: a one-way platform (its top at height h) from column c0 to c1 (its left edge), vx pixels a tick
  function kit.cart(c0, c1, h, vx)
    local _, y = at(c0, h)
    plats[#plats + 1] = {x = c0 * 32, y = y, w = 96, vx = vx, x0 = c0 * 32, x1 = c1 * 32}
  end
  -- a hopscotch tile ('H': the first step cracks it, the second makes it vanish) at height h above the floor
  function kit.hop(c, h) set(c, FR - h, "H") end
  -- a swing: a seat that swings to and fro (a pendulum) around column c at height h, amp tiles each way, one swing in `period` ticks
  function kit.swing(c, h, amp, period, phase)
    local _, y = at(c, h)
    plats[#plats + 1] = {kind = "swing", x = c * 32 - 64, y = y, w = 128, vx = 0, x0 = c * 32 - 64, x1 = c * 32 - 64, cx = c * 32 - 64, amp = amp * 32,
                         period = period, phase = phase or 0, y0 = y, t = 0}
  end
  -- the stage: a stretch of piano keys ('P', a white key each tile: it sinks and plays a note), black keys ('B': solid blocks), a spotlight zone (a beam sweeps it, foes in it freeze)
  function kit.piano(c0, c1) fill(c0, c1, FR, FR, "P") end
  function kit.black(c, n, w, base) fill(c, c + (w or 1) - 1, (base or FR) - n, (base or FR) - 1, "B") end
  function kit.spot(c0, c1) M.spot = {x0 = c0 * 32, x1 = (c1 + 1) * 32} end
  function kit.boss(id, c) boss = {id = id, x = c * 32 + 16, y = FR * 32} end
  function kit.start(c) start_c = c end

  kit.floor(0, cols - 1)
  require("core.maps.w" .. i)(kit)

  local crates = {}
  for r = 0, ROWS - 1 do for c = 0, cols - 1 do if grid[r][c] == "K" then crates[#crates + 1] = {c, r} end end end
  local hops = {}
  for r = 0, ROWS - 1 do for c = 0, cols - 1 do if grid[r][c] == "H" then hops[#hops + 1] = {c, r} end end end
  M.hops = hops
  M.cols, M.grid, M.objs, M.foes, M.plats, M.crates, M.boss, M.start_c = cols, grid, objs, foes, plats, crates, boss, start_c
  K.COLS = cols
  return M
end

return M
