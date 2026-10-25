-- bgfx: the playroom behind Poncho, in four layers.
--   1. the wall with its window (a bitmap layer of the 240x160 world, painted by code once): moves slowest
--   2. a bookcase of toys (the same bitmap, lower lines): moves faster, faster still toward the floor (per-line scroll, the Mega Drive's trick)
--   3. giant toys standing far behind the floor (shapes, overlay), at 0.62 of the camera
--   4. a foreground of crayons and blocks in front of everything, at 1.5 of the camera
local K = require("core.const")
local Deco = require("core.deco")
local B = {}

local CW, CH = 320, 176
local SPLIT = 68          -- the line where the wall ends and the bookcase begins
local made = false

local seed = 1
local function rnd(n) seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF return (seed >> 8) % n end

local function paint_wall()
  grad(0, 0, CW, CH, 0xFCEBC6, 0xF1CB9C)
  -- a stripe of painted stars on the wall, every 40 px (so it wraps)
  for x = 20, CW - 1, 40 do
    local y = 12 + (x // 40 % 3) * 9
    poly({x, y - 3, x + 1, y - 1, x + 3, y - 1, x + 1, y + 1, x + 2, y + 4, x, y + 2, x - 2, y + 4, x - 1, y + 1, x - 3, y - 1, x - 1, y - 1}, 0xF6D79C, true)
  end
  -- the window
  rect(106, 3, 112, 62, 0xF4EAD8)
  rect(106, 3, 112, 3, 0xFFFFFF)
  grad(110, 7, 104, 54, 0x62C0F4, 0xCDEEFF)
  circ(180, 24, 16, 0xFFF3B0, true)
  circ(180, 24, 10, 0xFFE070, true)
  circ(136, 20, 6, 0xFFFFFF, true) circ(144, 17, 8, 0xFFFFFF, true) circ(153, 21, 6, 0xFFFFFF, true) rect(136, 20, 18, 7, 0xFFFFFF)
  poly({110, 61, 110, 48, 126, 40, 142, 47, 160, 38, 182, 46, 200, 40, 214, 48, 214, 61}, 0x7CCB6C, true)
  poly({110, 61, 110, 55, 130, 50, 150, 55, 175, 51, 214, 56, 214, 61}, 0x5CB058, true)
  rect(158, 7, 3, 54, 0xF4EAD8)                  -- mullions
  rect(110, 33, 104, 3, 0xF4EAD8)
  rect(100, 62, 124, 5, 0xD8C8A8)                -- sill
  -- curtains
  poly({96, 0, 110, 0, 110, 60, 106, 64, 98, 60, 94, 66, 92, 20}, 0xD8444C, true)
  poly({96, 0, 100, 0, 101, 62, 96, 60, 94, 30}, 0xB02E3A, true)
  poly({228, 0, 214, 0, 214, 60, 218, 64, 226, 60, 230, 66, 232, 20}, 0xD8444C, true)
  poly({228, 0, 224, 0, 223, 62, 228, 60, 230, 30}, 0xB02E3A, true)
  rect(88, 0, 148, 5, 0x9C6A3C)
  -- a child's drawing and a framed picture
  rect(254, 14, 40, 34, 0xFFFFFF) rect(254, 14, 40, 34, 0xC8A060) rect(256, 16, 36, 30, 0xFFFFFF)
  circ(266, 26, 5, 0xFFC020, true) poly({262, 44, 262, 34, 274, 28, 286, 34, 286, 44}, 0xE05A48, true) rect(272, 36, 6, 8, 0x7A4A20)
  rect(26, 18, 34, 30, 0x8A5A2C) rect(28, 20, 30, 26, 0xBDE7FF)
  poly({30, 44, 36, 32, 42, 38, 48, 28, 56, 44}, 0x6CC070, true)
  circ(52, 26, 3, 0xFFE060, true)
end

local BOOKS = {0xD06060, 0x6088D8, 0x70B870, 0xE0B848, 0xA878C8, 0xE88860}
local function toys_on(x0, x1, base)
  local x = x0
  while x < x1 - 8 do
    local pick = rnd(7)
    if pick <= 2 then -- books
      for _ = 1, 2 + rnd(3) do
        local w, h = 5 + rnd(3), 12 + rnd(10)
        if x + w > x1 then break end
        rect(x, base - h, w, h, BOOKS[1 + rnd(#BOOKS)])
        x = x + w + 1
      end
    elseif pick == 3 then -- a teddy
      circ(x + 8, base - 8, 8, 0xB07848, true) circ(x + 8, base - 20, 6, 0xB07848, true)
      circ(x + 3, base - 25, 3, 0xB07848, true) circ(x + 13, base - 25, 3, 0xB07848, true) circ(x + 8, base - 18, 3, 0xE0B888, true)
      x = x + 20
    elseif pick == 4 then -- a train
      rect(x, base - 10, 22, 8, 0xC03838) rect(x + 14, base - 17, 8, 8, 0x3858C8) rect(x + 3, base - 14, 5, 4, 0x383838)
      circ(x + 5, base - 2, 3, 0x202020, true) circ(x + 17, base - 2, 3, 0x202020, true)
      x = x + 26
    elseif pick == 5 then -- blocks
      rect(x, base - 10, 10, 10, 0xE0C040) rect(x + 10, base - 10, 10, 10, 0x50A8E0) rect(x + 5, base - 20, 10, 10, 0xE06060)
      x = x + 24
    elseif pick == 6 then -- a ball and a spinning top
      circ(x + 7, base - 7, 7, 0xE05A5A, true) circ(x + 5, base - 9, 2, 0xFFFFFF, true)
      tri(x + 19, base, x + 27, base, x + 23, base - 14, 0x58B8A0, true) rect(x + 18, base - 16, 10, 4, 0xF0C850)
      x = x + 32
    else x = x + 12 end
  end
end

local function paint_case()
  rect(0, SPLIT, CW, CH - SPLIT, 0xB98A58)
  rect(0, SPLIT, CW, 4, 0xE9C592)
  -- compartments: backs a darker wood, boards between, posts every 80 px
  local boards = {94, 122, 150}
  local top = SPLIT + 4
  for i, by in ipairs(boards) do
    rect(0, top, CW, by - top, 0x9A6E40)
    rect(0, by, CW, 5, 0x7C5530) rect(0, by, CW, 2, 0xC89A66)
    seed = 7 + i * 31
    for p = 0, 3 do toys_on(p * 80 + 8, p * 80 + 76, by) end
    top = by + 5
  end
  rect(0, top, CW, CH - top, 0x9A6E40)
  seed = 99
  for p = 0, 3 do toys_on(p * 80 + 8, p * 80 + 76, CH) end
  for p = 0, 3 do rect(p * 80, SPLIT, 6, CH - SPLIT, 0x7C5530) rect(p * 80, SPLIT, 2, CH - SPLIT, 0xB98A58) end
end

function B.init()
  if not made then
    made = true
    canvas("BACK", CW, CH)
    target("BACK")
    paint_wall()
    paint_case()
    target()
  end
  bg(3, {image = "BACK", prio = 3})
end

-- the bands at their speeds: the wall slowest, then each shelf of the bookcase a little faster than the one above (a band is one speed: a ramp of speeds
-- would shear the posts into slants). The bands end where a shelf board is, which hides the step.
local BANDS = {{0, 0.09}, {SPLIT, 0.27}}
function B.scroll(cam_x, cam_y)
  scroll(3, 0, math.floor(cam_y * 0.06 / 2))
  for i, b in ipairs(BANDS) do
    local x = math.floor(cam_x * b[2] / 2) % CW
    local last = BANDS[i + 1] and BANDS[i + 1][1] - 1 or 159
    line_scroll_ramp(3, b[1], last, x, x)
  end
end

-- ---------------------------------------------------------------- the layers drawn over the world, in screen pixels

local MID = { -- x in the layer, kind: giant toys, muted so they sit far behind
  {80, "blocks"}, {380, "teddy"}, {700, "rocket"}, {980, "ball"}, {1180, "tower"}, {1500, "blocks"}, {1780, "teddy"}, {2060, "rocket"}, {2320, "tower"},
}
local MID_PERIOD = 2560

local MID_ID = {blocks = "BG_MID_BLOCKS", teddy = "BG_MID_TEDDY", rocket = "BG_MID_ROCKET", ball = "BG_MID_BALL", tower = "BG_MID_TOWER"}

function B.mid(cam_x, cam_y)
  local base = 360 - cam_y
  local shift = cam_x * 0.62
  for _, m in ipairs(MID) do
    local x = (m[1] - shift) % MID_PERIOD - 200
    if x < K.W and x > -200 then Deco.img(MID_ID[m[2]], 0, math.floor(x), math.floor(base)) end
  end
end

local FORE = {{300, "crayon", "BG_FORE_CRAYON_R"}, {1100, "block", "BG_FORE_BLOCK"}, {1700, "crayon", "BG_FORE_CRAYON_G"}, {2400, "ball", "BG_FORE_BALL"}}
local FORE_PERIOD = 3000

function B.fore(cam_x, cam_y)
  local shift = cam_x * 1.5
  for _, m in ipairs(FORE) do
    local x = math.floor((m[1] - shift) % FORE_PERIOD - 300)
    if x < K.W and x > -300 then
      if m[2] == "crayon" then img(m[3], x, 296)
      elseif m[2] == "block" then img(m[3], x, 296)
      else img(m[3], x - 6, 288) end
    end
  end
end

-- a stretch of floor for the title and the screens without a level: parquet across the bottom
function B.floor(cam_x, y)
  local off = -(math.floor(cam_x) % 32)
  for x = off, K.W, 32 do
    img("BG_FLOORCOL", x, y)
    for yy = y + 96, K.H, 32 do img("BG_TILES", x, yy, {frame = 1}) end
  end
end

return B
