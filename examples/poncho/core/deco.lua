-- deco: the playroom's pictures (tiles, giant toys, foes, items, icons), generated with the image model (gen/env_*.py) and packed as assets.
-- data/deco.lua says each one's size, anchor and frames. Deco.img(id, frame, x, y [, {flip, sx, sy}]): the picture with its anchor at x, y
-- (frame: a number or a frame's name; flip mirrors about the anchor's column, sx / sy scale from the anchor).
local Data = require("data.deco")
local D = {}
D.by_id = Data

local look = {}
function D.img(id, f, x, y, o)
  local s = Data[id]
  if type(f) == "string" then f = s.frames[f] end
  local sx, sy = o and o.sx or 1, o and o.sy or 1
  local left = x - s.ax * sx
  if o and o.flip then left = x - (s.w - s.ax) * sx end
  look.frame, look.flip_x = f, (o and o.flip) or false
  look.scale_x, look.scale_y = sx ~= 1 and sx or nil, sy ~= 1 and sy or nil
  look.dim = o and o.dim or nil
  local aid = id
  if s.pieces then aid, look.frame = id .. "_C" .. (f // s.per), f % s.per end
  img(aid, math.floor(left), math.floor(y - s.ay * sy), look)
end

return D
