-- deco: every decoration of the playroom as a picture. Shapes (circ, poly) are dear on the console, so each one is drawn ONCE, here, by code, and the picture
-- generator (decogen/build.py, run by hand) photographs them into packed assets (assets/BG_*.pk, TOY_*.pk); the game then only `img`s them.
--   Deco.list: {id, w, h, ax, ay, n, draw(f, x, y)} where (x, y) is where the anchor (ax, ay) of the cell goes while painting
--   Deco.img(id, frame, x, y [, {flip, sx, sy}]): the picture with its anchor at x, y (flip mirrors about the anchor's column, sx / sy scale from the anchor)
local TP = require("core.tilepaint")
local D = {}

local list, by_id = {}, {}
D.list, D.by_id = list, by_id
local function def(id, w, h, ax, ay, n, draw)
  local s = {id = id, w = w, h = h, ax = ax, ay = ay, n = n, draw = draw}
  list[#list + 1] = s
  by_id[id] = s
end

-- ---------------------------------------------------------------- the tiles
def("BG_TILES", 32, 32, 0, 0, TP.N, function(f, x, y) TP.paint(f, x, y) end)
def("BG_FLOORCOL", 32, 96, 0, 0, 1, function(f, x, y) TP.paint(12, x, y) end)
def("BG_SHELF2", 64, 32, 0, 0, 1, function(f, x, y) for i = 0, 1 do TP.paint(7, x + 32 * i, y) end end)
def("BG_SHELF4", 128, 32, 0, 0, 1, function(f, x, y) for i = 0, 3 do TP.paint(7, x + 32 * i, y) end end)
def("BG_SHELF8", 256, 32, 0, 0, 1, function(f, x, y) for i = 0, 7 do TP.paint(7, x + 32 * i, y) end end)
def("BG_TBOX2", 64, 32, 0, 0, 1, function(f, x, y) for i = 0, 1 do TP.paint(6, x + 32 * i, y) end end)
def("BG_TBOX4", 128, 32, 0, 0, 1, function(f, x, y) for i = 0, 3 do TP.paint(6, x + 32 * i, y) end end)
def("BG_TBOX8", 256, 32, 0, 0, 1, function(f, x, y) for i = 0, 7 do TP.paint(6, x + 32 * i, y) end end)
def("BG_BODY1", 32, 96, 0, 0, 1, function(f, x, y) for i = 0, 0 do for j = 0, 2 do TP.paint(1, x + 32 * i, y + 32 * j) end end end)
def("BG_BODY2", 64, 96, 0, 0, 1, function(f, x, y) for i = 0, 1 do for j = 0, 2 do TP.paint(1, x + 32 * i, y + 32 * j) end end end)
def("BG_BODY4", 128, 96, 0, 0, 1, function(f, x, y) for i = 0, 3 do for j = 0, 2 do TP.paint(1, x + 32 * i, y + 32 * j) end end end)
def("BG_BODY8", 256, 96, 0, 0, 1, function(f, x, y) for i = 0, 7 do for j = 0, 2 do TP.paint(1, x + 32 * i, y + 32 * j) end end end)
def("BG_FLOOR2", 64, 96, 0, 0, 1, function(f, x, y) for i = 0, 1 do TP.paint(12, x + 32 * i, y) end end)
def("BG_FLOOR4", 128, 96, 0, 0, 1, function(f, x, y) for i = 0, 3 do TP.paint(12, x + 32 * i, y) end end)
def("BG_FLOOR8", 256, 96, 0, 0, 1, function(f, x, y) for i = 0, 7 do TP.paint(12, x + 32 * i, y) end end)

-- ---------------------------------------------------------------- giant toys far behind the floor (anchor: the toy's left, on the floor line)
local function blocks(x, base)
  rect(x, base - 70, 70, 70, 0xCDB4E8) rect(x, base - 70, 70, 6, 0xE4D6F6) rect(x + 56, base - 70, 14, 70, 0xB89CD8)
  circ(x + 33, base - 35, 18, 0xF6EEFF, true)
  rect(x + 14, base - 124, 56, 54, 0xA8D2F0) rect(x + 14, base - 124, 56, 6, 0xCDE8FA) rect(x + 56, base - 124, 14, 54, 0x90BCDC)
  tri(x + 42, base - 114, x + 58, base - 84, x + 26, base - 84, 0xF6FBFF, true)
end
local function teddy(x, base)
  local c, d = 0xD8AC84, 0xC09068
  circ(x + 40, base - 40, 38, c, true) circ(x + 40, base - 100, 28, c, true)
  circ(x + 18, base - 122, 12, c, true) circ(x + 62, base - 122, 12, c, true)
  circ(x + 40, base - 94, 11, 0xF0D8BC, true) circ(x + 34, base - 106, 3, 0x6A4A38, true) circ(x + 46, base - 106, 3, 0x6A4A38, true)
  circ(x + 6, base - 50, 14, d, true) circ(x + 74, base - 50, 14, d, true)
end
local function rocket(x, base)
  poly({x + 30, base - 170, x + 52, base - 110, x + 52, base - 16, x + 8, base - 16, x + 8, base - 110}, 0xF0F2FA, true)
  poly({x + 30, base - 170, x + 52, base - 110, x + 8, base - 110}, 0xE88C8C, true)
  circ(x + 30, base - 82, 9, 0x8CC8F0, true)
  tri(x + 8, base - 50, x - 8, base - 6, x + 8, base - 16, 0xE88C8C, true) tri(x + 52, base - 50, x + 68, base - 6, x + 52, base - 16, 0xE88C8C, true)
end
local function ball(x, base)
  circ(x + 40, base - 40, 40, 0xF4A8B8, true) circ(x + 40, base - 40, 40, 0xE08098, false)
  poly({x + 4, base - 40, x + 40, base - 44, x + 76, base - 40, x + 74, base - 28, x + 40, base - 32, x + 6, base - 28}, 0xFFF0A8, true)
end
local function tower(x, base)
  rect(x, base - 80, 90, 80, 0xB8D8B0) rect(x, base - 80, 90, 5, 0xD8F0D0)
  for i = 0, 3 do rect(x + i * 24, base - 98, 14, 18, 0xB8D8B0) end
  rect(x + 34, base - 44, 22, 44, 0x7EA878) rect(x + 30, base - 54, 30, 12, 0x7EA878)
end
def("BG_MID_BLOCKS", 72, 126, 1, 126, 1, function(f, x, y) blocks(x, y) end)
def("BG_MID_TEDDY", 98, 135, 9, 135, 1, function(f, x, y) teddy(x, y) end)
def("BG_MID_ROCKET", 78, 171, 9, 171, 1, function(f, x, y) rocket(x, y) end)
def("BG_MID_BALL", 82, 81, 1, 81, 1, function(f, x, y) ball(x, y) end)
def("BG_MID_TOWER", 92, 99, 1, 99, 1, function(f, x, y) tower(x, y) end)

-- ---------------------------------------------------------------- the foreground (anchor: top-left)
local function crayon(c) return function(f, x, y)
  poly({x, y + 22, x + 190, y, x + 194, y + 14, x + 4, y + 38}, c, true)
  poly({x + 190, y, x + 230, y + 4, x + 194, y + 14}, 0xF2E0B8, true)
  line(x, y + 22, x + 190, y, 0xFFFFFF)
end end
def("BG_FORE_CRAYON_R", 232, 40, 0, 0, 1, crayon(0xE04848))
def("BG_FORE_CRAYON_G", 232, 40, 0, 0, 1, crayon(0x44B864))
def("BG_FORE_BLOCK", 100, 40, 0, 0, 1, function(f, x, y)
  rect(x, y, 100, 40, 0x3E80E8) rect(x, y, 100, 6, 0x92BEFF) rect(x + 90, y, 10, 40, 0x1E4C9C)
end)
def("BG_FORE_BALL", 92, 92, 0, 0, 1, function(f, x, y)
  circ(x + 46, y + 46, 46, 0xF2C434, true) circ(x + 32, y + 30, 8, 0xFFF3B0, true)
end)

-- ---------------------------------------------------------------- things to pick up and touch (anchor: where it stands / its middle)
def("TOY_COIN", 28, 24, 14, 12, 5, function(f, x, y)  -- turning: five widths
  local w = 2 + 2 * f
  poly({x - w - 1, y - 11, x + w + 1, y - 11, x + w + 3, y, x + w + 1, y + 11, x - w - 1, y + 11, x - w - 3, y}, 0x9A5A00, true)
  poly({x - w, y - 10, x + w, y - 10, x + w + 2, y, x + w, y + 10, x - w, y + 10, x - w - 2, y}, 0xFFD43A, true)
  if w > 4 then rect(x - w + 3, y - 6, 2, 12, 0xFFF3A0) end
end)
def("TOY_CREAM", 28, 60, 14, 43, 1, function(f, x, y)
  tri(x - 11, y - 12, x + 11, y - 12, x, y + 16, 0xD9954A, true)
  line(x - 6, y - 12, x + 1, y + 10, 0xB06E2C)
  line(x + 6, y - 12, x - 1, y + 10, 0xB06E2C)
  circ(x, y - 18, 13, 0xFF8FC8, true)
  circ(x - 4, y - 22, 5, 0xFFC4E2, true)
  circ(x + 2, y - 33, 4, 0xE02030, true)
  line(x + 2, y - 36, x + 6, y - 42, 0x2E7A2E)
end)
local SPRING_C = {1, 0.7, 0.45}
def("TOY_SPRING", 36, 32, 18, 32, 3, function(f, x, y)
  local h = math.floor(22 * SPRING_C[f + 1])
  rect(x - 16, y - 4, 32, 4, 0xB03030)
  local top = y - 4 - h
  for i = 0, 3 do
    local yy = y - 4 - math.floor(h * i / 4)
    line(x - 11, yy, x + 11, yy - math.floor(h / 4), 0xE8E8E8)
    line(x - 11, yy - 1, x + 11, yy - math.floor(h / 4) - 1, 0x909090)
  end
  rect(x - 17, top - 4, 34, 5, 0xF04040)
  rect(x - 17, top - 4, 34, 2, 0xFF9090)
end)
def("TOY_KEYBOARD", 82, 54, 41, 54, 2, function(f, x, y)  -- 0 eyes open, 1 happy / blinking; the keys that light up are rects over it
  rect(x - 40, y - 34, 80, 34, 0x2C3E9A)
  rect(x - 40, y - 34, 80, 4, 0x5870E0)
  rect(x - 40, y - 4, 80, 4, 0x1C2870)
  for k = 0, 7 do
    rect(x - 36 + k * 9, y - 28, 8, 18, 0xFFFFFF)
    rect(x - 36 + k * 9, y - 12, 8, 2, 0xC0C0C0)
  end
  for _, k in ipairs({0, 1, 3, 4, 5}) do rect(x - 31 + k * 9, y - 28, 5, 11, 0x20202C) end
  rect(x - 40, y - 52, 80, 18, 0x3E54C0)
  rect(x - 40, y - 52, 80, 3, 0x6C84F0)
  if f == 1 then
    line(x - 22, y - 42, x - 17, y - 46, 0xFFFFFF) line(x - 17, y - 46, x - 12, y - 42, 0xFFFFFF)
    line(x + 12, y - 42, x + 17, y - 46, 0xFFFFFF) line(x + 17, y - 46, x + 22, y - 42, 0xFFFFFF)
  else
    circ(x - 17, y - 43, 5, 0xFFFFFF, true) circ(x + 17, y - 43, 5, 0xFFFFFF, true)
    circ(x - 16, y - 43, 2, 0x101030, true) circ(x + 18, y - 43, 2, 0x101030, true)
  end
  rect(x - 5, y - 40, 10, 2, 0xFF8FA0)
  circ(x - 28, y - 38, 3, 0xFF7090, true) circ(x + 28, y - 38, 3, 0xFF7090, true)
end)
def("TOY_NOTE", 14, 18, 3, 17, 1, function(f, x, y)
  circ(x, y - 4, 4, 0xFFE070, true) rect(x + 3, y - 16, 2, 12, 0xFFE070) rect(x + 3, y - 16, 8, 3, 0xFFE070)
end)
def("TOY_SCOOTER", 54, 70, 26, 67, 1, function(f, x, y)
  rect(x - 22, y - 12, 44, 7, 0x3E8CE8)
  rect(x - 22, y - 12, 44, 2, 0x8CC4FF)
  rect(x + 14, y - 62, 5, 52, 0x3E8CE8)
  rect(x + 8, y - 66, 18, 5, 0x2C2C34)
  circ(x - 18, y - 4, 7, 0xFF8A20, true) circ(x + 18, y - 4, 7, 0xFF8A20, true)
  circ(x - 18, y - 4, 3, 0xFFD090, true) circ(x + 18, y - 4, 3, 0xFFD090, true)
end)
def("TOY_FLAG", 82, 162, 22, 161, 6, function(f, x, y)  -- six frames of the cloth waving
  rect(x - 3, y - 150, 6, 150, 0xE8E0D0)
  circ(x, y - 154, 7, 0xFFD43A, true)
  local w = f * math.pi / 3
  local pts = {}
  for i = 0, 6 do pts[#pts + 1] = x + 3 + i * 9 pts[#pts + 1] = y - 146 + math.floor(math.sin(w + i * 0.7) * 3) end
  for i = 6, 0, -1 do pts[#pts + 1] = x + 3 + i * 9 pts[#pts + 1] = y - 106 + math.floor(math.sin(w + i * 0.7) * 3) end
  poly(pts, 0xE0343C, true)
  circ(x + 30, y - 126, 9, 0xFFE070, true)
  rect(x - 20, y - 6, 40, 6, 0x6A4426)
end)

-- ---------------------------------------------------------------- the toys that bother him (all face right; mirrored by the game)
def("TOY_CAR", 48, 34, 24, 32, 8, function(f, x, y)  -- the wheels turn: eight frames
  rect(x - 22, y - 20, 44, 20, 0xE02828)
  rect(x - 22, y - 20, 44, 3, 0xFF7070)
  rect(x - 14, y - 30, 22, 10, 0xC01C1C)
  rect(x - 11, y - 27, 16, 7, 0xA8E4FF)
  rect(x + 15, y - 14, 6, 5, 0xFFF080)
  for _, wx in ipairs({-13, 13}) do
    circ(x + wx, y - 6, 7, 0x20202A, true)
    circ(x + wx, y - 6, 3, 0xD8D8E0, true)
    local a = f * math.pi / 4
    line(x + wx, y - 6, x + wx + math.floor(math.cos(a) * 5), y - 6 + math.floor(math.sin(a) * 5), 0x20202A)
  end
end)
def("TOY_ROBOT", 52, 60, 26, 59, 12, function(f, x, y)  -- frames 0-5 the key turning, 6-11 the same with a ring over its head (winding)
  local k = f % 6
  rect(x - 9, y - 10, 7, 10, 0x4A6478) rect(x + 2, y - 10, 7, 10, 0x4A6478)
  local top = y - 44
  rect(x - 13, top + 14, 26, 22, 0x58B8C8)
  rect(x - 13, top + 14, 26, 3, 0xA8F0F8)
  rect(x - 10, top, 20, 16, 0x7A8CA0)
  circ(x - 4, top + 6, 2, 0xFFE070, true) circ(x + 4, top + 6, 2, 0xFFE070, true)
  line(x, top, x, top - 5, 0x7A8CA0) circ(x, top - 6, 2, 0xFF4040, true)
  local kx, ky, a = x - 17, y - 26, k * math.pi / 6
  poly({kx + math.cos(a) * 8, ky + math.sin(a) * 8, kx + math.cos(a + 1.57) * 4, ky + math.sin(a + 1.57) * 4,
        kx - math.cos(a) * 8, ky - math.sin(a) * 8, kx + math.cos(a - 1.57) * 4, ky + math.sin(a - 1.57) * 4}, 0xFFC030, true)
  if f >= 6 then circ(x + 2, top - 12, 3, 0xFFFFFF, false) end
end)
def("TOY_BALL", 32, 32, 16, 31, 8, function(f, x, y)  -- turning: the pattern repeats every 120 degrees
  local cy = y - 15
  circ(x, cy, 15, 0x3C78E8, true)
  circ(x, cy, 15, 0x1C3C90, false)
  for i = 0, 2 do
    local aa = f * (2.094 / 8) + i * 2.094
    line(x, cy, x + math.floor(math.cos(aa) * 13), cy + math.floor(math.sin(aa) * 13), 0xFFE070)
  end
  circ(x - 5, cy - 6, 3, 0xA8D0FF, true)
end)
def("TOY_PLANE", 46, 22, 23, 11, 9, function(f, x, y)  -- nine tilts, nose down to nose up
  local t = f - 4
  poly({x + 22, y + t, x - 18, y - 10, x - 14, y + 2, x - 18, y + 9}, 0xF6F6FF, true)
  poly({x + 22, y + t, x - 14, y + 2, x - 18, y + 9}, 0xBCC8E4, true)
  line(x + 22, y + t, x - 14, y + 2, 0x8090B8)
end)

-- ---------------------------------------------------------------- the status bar's little pictures: 0 heart, 1 empty heart, 2 coin, 3 ice cream, 4 scooter lit, 5 scooter dim
local function heart(x, y, full)
  local c, d = full and 0xFF4058 or 0x5A3A4E, full and 0xFF98A8 or 0x6E4C60
  circ(x + 8, y + 8, 8, 0x2A1A3A, true) circ(x + 20, y + 8, 8, 0x2A1A3A, true)
  tri(x - 1, y + 11, x + 29, y + 11, x + 14, y + 28, 0x2A1A3A, true)
  circ(x + 8, y + 8, 6, c, true) circ(x + 20, y + 8, 6, c, true)
  tri(x + 2, y + 11, x + 26, y + 11, x + 14, y + 24, c, true)
  if full then circ(x + 6, y + 6, 2, d, true) end
end
local function scooter_icon(x, y, on)
  local b, w = on and 0x3E8CE8 or 0x55607A, on and 0xFF8A20 or 0x6A6070
  rect(x + 2, y + 18, 34, 5, b) rect(x + 30, y + 2, 4, 20, b)
  circ(x + 6, y + 24, 5, w, true) circ(x + 32, y + 24, 5, w, true)
end
def("TOY_HEARTS", 96, 34, 0, 0, 4, function(f, x, y) for i = 0, 2 do heart(x + 2 + i * 32, y + 1, i < f) end end)
def("TOY_HUD", 44, 34, 0, 0, 6, function(f, x, y)
  if f <= 1 then heart(x + 2, y + 1, f == 0)
  elseif f == 2 then
    circ(x + 22, y + 17, 9, 0x9A5A00, true) circ(x + 22, y + 17, 7, 0xFFD43A, true) rect(x + 19, y + 12, 2, 10, 0xFFF3A0)
  elseif f == 3 then
    tri(x + 4, y + 13, x + 18, y + 13, x + 11, y + 29, 0xD9954A, true) circ(x + 11, y + 10, 8, 0xFF8FC8, true) circ(x + 11, y + 3, 3, 0xE02030, true)
  else scooter_icon(x, y, f == 4) end
end)
def("TOY_SHADOW", 40, 6, 20, 3, 2, function(f, x, y)
  local w = f == 0 and 40 or 32
  rect(x - w // 2 + 3, y - 3, w - 6, 6, 0x8A5A2C) rect(x - w // 2, y - 1, w, 2, 0x8A5A2C)
end)

-- ---------------------------------------------------------------- using them
local look = {}
function D.img(id, f, x, y, o)
  local s = by_id[id]
  local sx, sy = o and o.sx or 1, o and o.sy or 1
  local left = x - s.ax * sx
  if o and o.flip then left = x - (s.w - s.ax) * sx end
  look.frame, look.flip_x = f, (o and o.flip) or false
  look.scale_x, look.scale_y = sx ~= 1 and sx or nil, sy ~= 1 and sy or nil
  img(id, math.floor(left), math.floor(y - s.ay * sy), look)
end

-- for the picture generator: the cell of frame f painted with its top-left at (8, 8) on a plain ground
D.KEY = 0x00FF00
function D.paint(id, f)
  local s = by_id[id]
  rect(0, 0, 480, 320, D.KEY)
  s.draw(f, 8 + s.ax, 8 + s.ay)
end

return D
