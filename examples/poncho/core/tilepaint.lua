-- tilepaint: the playroom's tiles (32x32) painted by code. Only the picture generator (decogen/build.py) draws them, once, into assets/BG_TILES;
-- the game then puts the packed pictures on the screen. Frame order: 1 floor top, 2 floor body, 3-6 letter blocks, 7 toy box, 8 shelf, 9-12 ramps a b c d,
-- and frame 12 (BG_FLOORCOL) a column of floor: a top and two bodies, 32x96.
local P = {}

local function floor_top()
  rect(0, 0, 32, 32, 0xC98A4B)
  rect(0, 0, 32, 8, 0xEDB66E)                  -- the lit edge of the boards
  rect(0, 7, 32, 2, 0x9C6430)
  line(0, 14, 32, 14, 0xB77A3E) line(0, 22, 20, 22, 0xB77A3E) line(26, 27, 32, 27, 0xB77A3E)
  rect(0, 0, 2, 32, 0x8F5A2B)                  -- board seam
  rect(9, 3, 2, 2, 0xF8D49A)                   -- a glint
  rect(24, 17, 2, 2, 0x9C6430)                 -- a nail
end
local function floor_body()
  rect(0, 0, 32, 32, 0xB27238)
  line(0, 9, 32, 9, 0x9A6030) line(0, 21, 32, 21, 0x9A6030) line(6, 29, 24, 29, 0x9A6030)
  rect(0, 0, 2, 32, 0x7C4C22)
  rect(0, 0, 32, 2, 0x9A6030)
  rect(20, 12, 2, 2, 0xD09858)
end

local BLOCKS = {{0xE04848, 0xFF8C8C, 0x9C2020}, {0x3E80E8, 0x92BEFF, 0x1E4C9C}, {0x44B864, 0x92E8A8, 0x1E7C3C}, {0xF2C434, 0xFFE88C, 0xA8801C}}
local function block(v)
  local c = BLOCKS[v]
  rect(0, 0, 32, 32, c[3])
  rect(2, 2, 28, 28, c[1])
  rect(2, 2, 28, 3, c[2]) rect(2, 2, 3, 28, c[2])
  rect(27, 5, 3, 25, c[3]) rect(5, 27, 25, 3, c[3])
  local e = 0xFFFFFF
  if v == 1 then circ(16, 16, 7, e, true)
  elseif v == 2 then tri(16, 8, 24, 24, 8, 24, e, true)
  elseif v == 3 then rect(9, 9, 14, 14, e)
  else poly({16, 7, 19, 13, 25, 14, 20, 19, 22, 25, 16, 22, 10, 25, 12, 19, 7, 14, 13, 13}, e, true) end
end
local function toybox()
  rect(0, 0, 32, 32, 0x7A3E12)
  rect(2, 2, 28, 28, 0xE0802E)
  rect(2, 2, 28, 3, 0xFFB46A)
  line(2, 11, 29, 11, 0xB8601E) line(2, 21, 29, 21, 0xB8601E)
  line(4, 4, 28, 28, 0xB8601E) line(28, 4, 4, 28, 0xB8601E)
  rect(0, 0, 6, 6, 0x55575E) rect(26, 0, 6, 6, 0x55575E) rect(0, 26, 6, 6, 0x55575E) rect(26, 26, 6, 6, 0x55575E)
  rect(2, 2, 2, 2, 0xC8CAD2) rect(28, 2, 2, 2, 0xC8CAD2) rect(2, 28, 2, 2, 0xC8CAD2) rect(28, 28, 2, 2, 0xC8CAD2)
end
local function shelf()
  rect(0, 0, 32, 11, 0x6E4222)
  rect(0, 0, 32, 4, 0xC8905A)
  rect(0, 4, 32, 2, 0x9C6A3C)
  rect(0, 10, 32, 1, 0x4A2A12)
  tri(3, 11, 15, 11, 3, 24, 0x5A3418, true)
  tri(29, 11, 17, 11, 29, 24, 0x5A3418, true)
end
local WOOD, WOOD_LIGHT, WOOD_DARK = 0xE09A4A, 0xFFD890, 0x9C5E24
local function wedge(pts, top)
  poly(pts, WOOD, true)
  line(pts[top[1]], pts[top[2]], pts[top[3]], pts[top[4]], WOOD_LIGHT)
  line(pts[top[1]], pts[top[2]] + 1, pts[top[3]], pts[top[4]] + 1, WOOD_LIGHT)
  line(pts[top[1]], pts[top[2]] + 4, pts[top[3]], pts[top[4]] + 4, WOOD_DARK)
end
local function ramp_a() wedge({0, 31, 31, 31, 31, 16}, {1, 2, 5, 6}) line(8, 31, 20, 24, WOOD_DARK) end
local function ramp_b() wedge({0, 31, 31, 31, 31, 0, 0, 16}, {7, 8, 5, 6}) line(0, 31, 31, 15, WOOD_DARK) end
local function ramp_c() wedge({0, 0, 31, 16, 31, 31, 0, 31}, {1, 2, 3, 4}) end
local function ramp_d() wedge({0, 16, 31, 31, 0, 31}, {1, 2, 3, 4}) end


local FRAMES = {floor_top, floor_body, function() block(1) end, function() block(2) end, function() block(3) end, function() block(4) end, toybox, shelf,
                ramp_a, ramp_b, ramp_c, ramp_d}
P.N = 12
function P.paint(f, x, y) -- frame f (0-based) with its top-left corner at x, y
  camera(-x, -y)
  if f == 12 then
    floor_top()
    camera(-x, -y - 32) floor_body()
    camera(-x, -y - 64) floor_body()
  else
    FRAMES[f + 1]()
  end
  camera()
end

return P
