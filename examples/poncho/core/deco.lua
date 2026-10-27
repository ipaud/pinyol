-- deco: the playroom's pictures (tiles, giant toys, foes, items, icons), generated with the image model (gen/env_*.py) and packed as assets.
-- data/deco.lua says each one's size, anchor and frames. Deco.img(id, frame, x, y [, {flip, sx, sy}]): the picture with its anchor at x, y
-- (frame: a number or a frame's name; flip mirrors about the anchor's column, sx / sy scale from the anchor).
local Data = require("data.deco")
for _, name in ipairs({"data.deco2", "data.deco3", "data.deco4"}) do -- the next worlds' pictures (the art agent writes them, same format)
  local ok, more = pcall(require, name)
  if ok and type(more) == "table" then for k, v in pairs(more) do Data[k] = v end end
end
local D = {}
D.by_id = Data
D.alias = {}   -- a world's own pictures for the common ones (worlds.lua): TOY_COIN = "FI_COIN"; used when the data has them

function D.has(id) return Data[id] ~= nil end
function D.id(id) local a = D.alias[id] return (a and Data[a]) and a or id end
function D.count(id) local s = Data[id] return s and s.n or 0 end

local look = {}
local piece_ids = {} -- piece_ids[id][n] = "id_Cn"
function D.img(id, f, x, y, o)
  local a = D.alias[id]
  if a and Data[a] then id = a end
  local s = Data[id]
  if type(f) == "string" then f = s.frames[f] end
  local sx, sy = o and o.sx or 1, o and o.sy or 1
  local left = x - s.ax * sx
  if o and o.flip then left = x - (s.w - s.ax) * sx end
  look.frame, look.flip_x = f, (o and o.flip) or false
  look.scale_x, look.scale_y = sx ~= 1 and sx or nil, sy ~= 1 and sy or nil
  look.dim = o and o.dim or nil
  look.mul, look.angle, look.alpha = o and o.mul or nil, o and o.angle or nil, o and o.alpha or nil
  local aid = id
  if s.pieces then
    local pc = piece_ids[id]
    if not pc then pc = {} piece_ids[id] = pc end
    local p = f // s.per
    aid = pc[p]
    if not aid then aid = id .. "_C" .. p pc[p] = aid end
    look.frame = f % s.per
  end
  img(aid, math.floor(left), math.floor(y - s.ay * sy), look)
end

return D
