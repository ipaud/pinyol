-- spr: drawing frames of the strips (data/sheets.lua, made by gen/build.py). A frame is found by its name and placed by its anchor (the soles);
-- a strip cut in pieces (so the console never needs one big block of memory) is found by frame number. Sizes come from the data, never from here.
local D = require("data.sheets")
local S = {}

S.sheets = D.sheets
local look = {}
local counts = {}

function S.has(sheet, frame) local s = D.sheets[sheet] return s ~= nil and s.frames[frame] ~= nil end

-- how many frames a strip has of a run named prefix_0, prefix_1...
function S.n(sheet, prefix)
  local key = sheet .. "." .. prefix
  local n = counts[key]
  if not n then
    n = 0
    local s = D.sheets[sheet]
    while s and s.frames[prefix .. "_" .. n] do n = n + 1 end
    counts[key] = n
  end
  return n
end

-- the frame `prefix_i` (i wraps round the run), or nil when the strip has no such run
function S.seq(sheet, prefix, i)
  local n = S.n(sheet, prefix)
  if n == 0 then return nil end
  return prefix .. "_" .. (math.floor(i) % n)
end

function S.size(sheet) local s = D.sheets[sheet] return s.w, s.h, s.ax, s.ay end

-- S.draw(sheet, frame, x, y [, {flip, tint, alpha, dx, dy}]): x, y is where the anchor goes on the screen
function S.draw(name, frame, x, y, o)
  local sh = D.sheets[name]
  local idx = sh.frames[frame]
  if not idx then return false end
  local id = sh.id
  if sh.pieces then
    id = id .. "_C" .. (idx // sh.per)
    idx = idx % sh.per
  end
  local flip = o and o.flip
  local left = flip and x - (sh.w - sh.ax) or x - sh.ax
  look.frame, look.flip_x = idx, flip or false
  look.tint, look.alpha = o and o.tint or nil, o and o.alpha or nil
  img(id, math.floor(left + (o and o.dx or 0)), math.floor(y - sh.ay + (o and o.dy or 0)), look)
  return true
end

-- the pictures of a strip's pieces, read from the card now (so the first step does not wait)
function S.preload(names)
  local ids = {}
  for _, n in ipairs(names) do
    local sh = D.sheets[n]
    if sh then
      if sh.pieces then for p = 0, (sh.n - 1) // sh.per do ids[#ids + 1] = sh.id .. "_C" .. p end
      else ids[#ids + 1] = sh.id end
    end
  end
  preload({images = ids})
end

return S
