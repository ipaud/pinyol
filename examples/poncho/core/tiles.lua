-- tiles: the playroom's blocks, put on the screen with `img` from the packed pictures BG_* (generated with the image model and fitted by gen/env_*.py)
-- A floor top with two floor bodies under it is one picture (BG_FLOORCOL), which spares two thirds of the commands along the floor.
local K = require("core.const")
local L = require("core.level")
local T = {}

local TILE = K.TILE
local look = {frame = 0}
local FRAME = {["="] = 7, T = 6, a = 8, b = 9, c = 10, d = 11}

function T.init() end -- (the pictures are assets)

local STRIP = {{8, "BG_FLOOR8"}, {4, "BG_FLOOR4"}, {2, "BG_FLOOR2"}, {1, "BG_FLOORCOL"}}
local one = {{frame = 7}, {frame = 6}}
local RUNS = {
  ["="] = {{8, "BG_SHELF8"}, {4, "BG_SHELF4"}, {2, "BG_SHELF2"}, {1, "BG_TILES", one[1]}},
  T = {{8, "BG_TBOX8"}, {4, "BG_TBOX4"}, {2, "BG_TBOX2"}, {1, "BG_TILES", one[2]}},
}
local BODY = {{8, "BG_BODY8"}, {4, "BG_BODY4"}, {2, "BG_BODY2"}, {1, "BG_BODY1"}}
local fcr, fbody = {}, {} -- for each visible column: the row of its floor column (a floor top with two bodies under it), or false

-- the tiles that show: cam_x, cam_y is the screen's top-left in level pixels; returns how many pictures.
-- Runs of floor columns are one picture each (strips of 8, 4, 2 or 1 columns).
function T.draw(cam_x, cam_y)
  local c0, c1 = math.max(0, math.floor(cam_x / TILE)), math.min(K.COLS - 1, math.floor((cam_x + K.W - 1) / TILE))
  local r0, r1 = math.max(0, math.floor(cam_y / TILE)), math.min(K.ROWS - 1, math.floor((cam_y + K.H - 1) / TILE))
  local g = L.grid
  local n = 0
  for c = c0, c1 do
    local fr = false
    for r = r0, r1 do
      if g[r][c] == "#" then
        local up = L.at(c, r - 1)
        if r + 2 == K.ROWS - 1 and L.at(c, r + 1) == "#" and L.at(c, r + 2) == "#" then
          fr = r
          fbody[c] = not (up == " " or up == "=")
          break
        end
      end
    end
    fcr[c] = fr
  end
  local c = c0
  while c <= c1 do
    local fr = fcr[c]
    if fr then
      local run = 1
      while c + run <= c1 and fcr[c + run] == fr and fbody[c + run] == fbody[c] do run = run + 1 end
      local i = c
      while i < c + run do
        for _, st in ipairs(fbody[c] and BODY or STRIP) do
          if i + st[1] <= c + run then img(st[2], i * TILE, fr * TILE) n = n + 1 i = i + st[1] break end
        end
      end
      c = c + run
    else
      c = c + 1
    end
  end
  for r = r0, r1 do
    local row = g[r]
    local c = c0
    while c <= c1 do
      local ch, fr = row[c], fcr[c]
      if ch == " " or (fr and r >= fr) then
        c = c + 1
      elseif RUNS[ch] then -- a run of shelf or toy boxes: strips of 8, 4, 2 or 1
        local e = c
        while e < c1 and row[e + 1] == ch and not (fcr[e + 1] and r >= fcr[e + 1]) do e = e + 1 end
        local i = c
        while i <= e do
          local took = false
          for _, st in ipairs(RUNS[ch]) do
            if i + st[1] - 1 <= e then img(st[2], i * TILE, r * TILE, st[3]) n = n + 1 i = i + st[1] took = true break end
          end
          if not took then i = i + 1 end
        end
        c = e + 1
      else
        if ch == "#" then
          local up = L.at(c, r - 1)
          look.frame = (up == " " or up == "=") and 0 or 1
        else
          look.frame = ch == "W" and (2 + ((c * 7 + r * 3) % 4)) or FRAME[ch]
        end
        img("BG_TILES", c * TILE, r * TILE, look)
        n = n + 1
        c = c + 1
      end
    end
  end
  return n
end

return T
