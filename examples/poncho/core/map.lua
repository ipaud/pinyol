-- map: the level "the giant playroom", written with a few builders. The grid is 192 x 14 tiles of 32 px (6144 x 448 px):
--   '#' floor (parquet)   'W' a wooden letter block   'T' a toy box   '=' a shelf (solid from above only)
--   'a' 'b' the two halves of an up ramp (rising to the right)   'c' 'd' the two halves of a down ramp   ' ' air
-- Everything a block or a tile does is in level.lua; this file only says where things are. Heights are in tiles above the floor's surface.
local K = require("core.const")
local COLS, ROWS, FR = K.COLS, K.ROWS, K.FLOOR

local grid = {}
for r = 0, ROWS - 1 do
  grid[r] = {}
  for c = 0, COLS - 1 do grid[r][c] = " " end
end
local objs, foes = {}, {}

local function set(c, r, ch) if c >= 0 and c < COLS and r >= 0 and r < ROWS then grid[r][c] = ch end end
local function fill(c0, c1, r0, r1, ch) for r = r0, r1 do for c = c0, c1 do set(c, r, ch) end end end
local function floor(c0, c1) fill(c0, c1, FR, ROWS - 1, "#") end
local function gap(c0, c1) fill(c0, c1, FR, ROWS - 1, " ") end
local function blocks(c, n, w, ch, base) fill(c, c + w - 1, (base or FR) - n, (base or FR) - 1, ch or "W") end
local function shelf(c0, c1, h) fill(c0, c1, FR - h, FR - h, "=") end
local function ramp(c, n, base)  -- up ramp: n steps of 32 px, two tiles long each
  base = base or FR
  for i = 0, n - 1 do
    local r = base - 1 - i
    set(c + 2 * i, r, "a") set(c + 2 * i + 1, r, "b")
    for rr = r + 1, base - 1 do set(c + 2 * i, rr, "#") set(c + 2 * i + 1, rr, "#") end
  end
end
local function rampdown(c, n, base)
  base = base or FR
  for i = 0, n - 1 do
    local r = base - n + i
    set(c + 2 * i, r, "c") set(c + 2 * i + 1, r, "d")
    for rr = r + 1, base - 1 do set(c + 2 * i, rr, "#") set(c + 2 * i + 1, rr, "#") end
  end
end

-- things: x is the middle of tile column c, y the bottom of the row `FR - h - 1` (so h = 0 stands on the floor)
local function at(c, h) return c * 32 + 16, (FR - h) * 32 end
local function obj(kind, c, h, extra)
  local x, y = at(c, h)
  local o = {kind = kind, x = x, y = y}
  if extra then for k, v in pairs(extra) do o[k] = v end end
  objs[#objs + 1] = o
end
local function coins(c, h, n, dc, dh) -- n coins from (c, h): h is the height of their middle above the floor, in tiles
  for i = 0, n - 1 do
    local x, y = at(c + i * (dc or 1), h + i * (dh or 0))
    objs[#objs + 1] = {kind = "coin", x = x, y = y - 16}
  end
end
local function arc(c, h, n, rise) -- coins on an arch
  for i = 0, n - 1 do
    local x, y = at(c + i, h)
    local k = n > 1 and (i / (n - 1)) or 0
    objs[#objs + 1] = {kind = "coin", x = x, y = y - 16 - math.sin(k * math.pi) * rise * 32}
  end
end
local function foe(kind, c, h, extra)
  local x, y = at(c, h)
  local f = {kind = kind, x = x, y = y}
  if extra then for k, v in pairs(extra) do f[k] = v end end
  foes[#foes + 1] = f
end

floor(0, COLS - 1)

-- 1. the start: room to walk, run and jump
coins(8, 1, 5, 1, 0)
blocks(15, 1, 2, "T")
arc(14, 1, 5, 1.4)
-- 2. steps up and down, a shelf with the first ice cream, a toy car
blocks(20, 1, 2) blocks(22, 2, 3) blocks(25, 1, 2)
shelf(28, 33, 3)
coins(29, 4, 4, 1, 0)
obj("icecream", 31, 5)
foe("car", 36, 0, {range = 5})
-- costume 1: the barretina (red cap, headbutt), then the toy car it can beat
obj("cos_barretina", 18, 0)
-- 3. a gap that asks for a jump, a spring to a high shelf, a ball
blocks(38, 1, 2, "T")
gap(41, 44)
arc(40, 2, 6, 2)
obj("spring", 48, 0)
shelf(45, 52, 5)
coins(46, 6, 5, 1, 0)
obj("icecream", 51, 6)
foe("ball", 53, 0, {range = 4})
-- 4. the toy keyboard (checkpoint, a friend), the scooter, a long flat run and a ramp over a gap
obj("keyboard", 57, 0)
obj("scooter", 62, 0)
blocks(66, 1, 2, "K")  -- crates: a headbutt, a stomp or the scooter at speed breaks them
coins(64, 1, 6, 1, 0)
ramp(70, 2)
gap(74, 78)
arc(74, 3, 5, 1.2)
-- 5. toy boxes to climb, a paper plane, a spring
coins(82, 1, 3, 1, 0)
obj("cos_dino", 85, 0)  -- costume 2: the dinosaur onesie (fire, ground pound)
foe("ball", 90, 0, {range = 3})
blocks(88, 1, 2, "T") blocks(90, 2, 2, "T")
shelf(93, 99, 3)
blocks(95, 1, 2, "K", FR - 3)
foe("plane", 97, 4, {range = 6})
coins(94, 4, 5, 1, 0)
obj("spring", 101, 0)
shelf(103, 108, 5)
obj("icecream", 105, 6)
coins(107, 6, 3, 1, 0)
-- 6. a wide gap with floating toys, then wind-up robots
gap(112, 118)
shelf(113, 114, 2) shelf(116, 117, 2)
coins(113, 3, 2, 3, 0)
obj("cos_boots", 120, 0)  -- costume 3: green boots (a splash jump in the air), for the secret shelf above the robots
shelf(125, 131, 6)
arc(125, 7, 7, 0.8)
obj("icecream", 128, 7)
foe("robot", 124, 0, {range = 5})
foe("robot", 129, 0, {range = 5})
-- 7. the second toy keyboard, a hill of blocks
obj("keyboard", 134, 0)
blocks(139, 1, 6, "T") blocks(140, 1, 4, "W", FR - 1) blocks(141, 1, 2, "T", FR - 2)
foe("car", 146, 0, {range = 6})
foe("plane", 148, 3, {range = 6})
-- 8. the long run: a ramp up to a shelf in the air, robots and balls along the floor
coins(152, 1, 5, 1, 0)
blocks(150, 1, 2, "K")
obj("cos_futbol", 155, 0)  -- costume 4: the football shirt (a dash, invulnerable for 5 s)
ramp(158, 2)
shelf(164, 171, 4)
coins(165, 5, 5, 1, 0)
foe("ball", 168, 0, {range = 3})
foe("robot", 174, 0, {range = 4})
-- 9. the end: steps to the flag
blocks(179, 1, 2) blocks(181, 2, 8, "T")
obj("flag", 187, 2)
coins(182, 3, 3, 1, 0)

-- the crates, to put them back at a new game
local crates = {}
for r = 0, ROWS - 1 do for c = 0, COLS - 1 do if grid[r][c] == "K" then crates[#crates + 1] = {c, r} end end end

return {crates = crates, grid = grid, objs = objs, foes = foes, start_c = 3}
