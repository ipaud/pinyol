-- tiles: the world's blocks, put on the screen with `img` from the packed pictures of its tile set (prefix BG_ for the playroom, FT_ for the market; a set the data
-- does not have yet is the playroom's, tinted: core/worlds.lua). A floor top with two floor bodies under it is one picture, and runs of floor, shelves and boxes
-- are strips of 8, 4, 2 or 1 tiles, which spares most commands.
local K = require("core.const")
local L = require("core.level")
local W = require("core.worlds")
local T = {}

local TILE = K.TILE
local FRAME = {["="] = 7, T = 6, a = 8, b = 9, c = 10, d = 11}
local FLOORISH = {["#"] = true, [">"] = true, ["<"] = true}

local plain, crate, one7, one6 = {frame = 0}, {frame = 6, dim = 0.6}, {frame = 7}, {frame = 6}
local prefix, STRIP, BODY, RUNS
local NAMES = {BG = {SHELF = "SHELF", TBOX = "TBOX"}, FT = {SHELF = "COUNTER", TBOX = "CRATES"}} -- (the market's shelves are stall counters, its boxes crates)
local function build(pre, mul)
  prefix = pre
  plain.mul, crate.mul, one7.mul, one6.mul = mul, mul, mul, mul
  crate.frame, crate.dim = (pre == "FT") and 3 or 6, (pre ~= "FT") and 0.6 or nil -- (an orange crate in the market, a darkened toy box in the playroom)
  local nm = NAMES[pre] or NAMES.BG
  local function strips(name, one) name = nm[name] return {{8, pre .. "_" .. name .. "8"}, {4, pre .. "_" .. name .. "4"}, {2, pre .. "_" .. name .. "2"}, one} end
  STRIP = {{8, pre .. "_FLOOR8"}, {4, pre .. "_FLOOR4"}, {2, pre .. "_FLOOR2"}, {1, pre .. "_FLOORCOL"}}
  BODY = {{8, pre .. "_BODY8"}, {4, pre .. "_BODY4"}, {2, pre .. "_BODY2"}, {1, pre .. "_BODY1"}}
  RUNS = {["="] = strips("SHELF", {1, pre .. "_TILES", one7}), T = strips("TBOX", {1, pre .. "_TILES", one6})}
end

function T.init() end -- (the pictures are assets)

-- the pictures of a stretch of tiles only change when the camera crosses a tile: they are kept as a list (id, x, y, look...) and drawn again until it does
local cache, cache_key, looks = {}, nil, {}
local function emit(id, x, y, look)
  if look then -- (the shared `look` tables change between calls: each picture keeps its own, one per kind)
    local k = (look.frame or "") .. "|" .. (look.dim or "") .. "|" .. (look.mul or "")
    local own = looks[k]
    if not own then own = {frame = look.frame, dim = look.dim, mul = look.mul} looks[k] = own end
    look = own
  end
  local n = #cache
  cache[n + 1], cache[n + 2], cache[n + 3], cache[n + 4] = id, x, y, look or false
  img(id, x, y, look)
end

local fcr, fbody = {}, {} -- for each visible column: the row of its floor column (a floor top with two bodies under it), or false
local belts = {}

-- the tiles that show: cam_x, cam_y is the screen's top-left in level pixels; returns how many pictures
function T.draw(cam_x, cam_y)
  if prefix ~= W.tile_prefix or plain.mul ~= W.tile_mul then build(W.tile_prefix, W.tile_mul) end
  local c0, c1 = math.max(0, math.floor(cam_x / TILE)), math.min(K.COLS - 1, math.floor((cam_x + K.W - 1) / TILE))
  local r0, r1 = math.max(0, math.floor(cam_y / TILE)), math.min(K.ROWS - 1, math.floor((cam_y + K.H - 1) / TILE))
  local g = L.grid
  local n = 0
  local key = table.concat({c0, c1, r0, r1, prefix, plain.mul or "", L.rev or 0}, ",")
  if key == cache_key then
    for i = 1, #cache, 4 do img(cache[i], cache[i + 1], cache[i + 2], cache[i + 3] or nil) end
    n = #cache // 4
  else
  for k in pairs(looks) do looks[k] = nil end
  for i = #cache, 1, -1 do cache[i] = nil end
  for c = c0, c1 do
    local fr = false
    for r = r0, r1 do
      if FLOORISH[g[r][c]] then
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
          if i + st[1] <= c + run then emit(st[2], i * TILE, fr * TILE, plain.mul and {mul = plain.mul} or nil) n = n + 1 i = i + st[1] break end
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
            if i + st[1] - 1 <= e then emit(st[2], i * TILE, r * TILE, st[3] or (plain.mul and {mul = plain.mul} or nil)) n = n + 1 i = i + st[1] took = true break end
          end
          if not took then i = i + 1 end
        end
        c = e + 1
      else
        local look = plain
        if ch == "K" then
          look = crate
        elseif ch == "#" or ch == ">" or ch == "<" then
          local up = L.at(c, r - 1)
          look.frame = (up == " " or up == "=") and 0 or 1
        else
          look.frame = ch == "W" and (2 + ((c * 7 + r * 3) % 4)) or FRAME[ch]
        end
        emit(prefix .. "_TILES", c * TILE, r * TILE, look)
        n = n + 1
        c = c + 1
      end
    end
  end
  cache_key = key
  end
  -- the conveyor belts: the market's tiles have the belt (4 frames sliding, an end cap on each side); the playroom has none (a dark band with dashes as a fallback)
  local tk = ticks()
  local c = c0
  while c <= c1 do
    local ch = g[K.FLOOR][c]
    if ch == ">" or ch == "<" then
      local e = c
      while e < c1 and g[K.FLOOR][e + 1] == ch do e = e + 1 end
      local f = (tk // 5) % 4
      if ch == "<" then f = 3 - f end
      for i = c, e do
        local fr = 12 + f
        if prefix == "FT" then
          if i == c and L.at(i - 1, K.FLOOR) ~= ch then fr = 16 elseif i == e and L.at(i + 1, K.FLOOR) ~= ch then fr = 17 end
          plain.frame = fr
          img("FT_TILES", i * TILE, K.FLOOR * TILE, plain)
          n = n + 1
        end
      end
      if prefix ~= "FT" then
        local x0, w = c * TILE, (e - c + 1) * TILE
        rect(x0, K.FLOOR * TILE, w, 8, 0x3A3F5A)
        for i = 0, w // 32 - 1 do
          local px = (i * 32 + (ch == ">" and 1 or -1) * (tk // 2)) % w
          if px + 14 <= w then rect(x0 + px, K.FLOOR * TILE + 2, 14, 4, 0xFFD43A) end
        end
        n = n + 1 + w // 32
      end
      c = e + 1
    else
      c = c + 1
    end
  end
  return n
end

return T
