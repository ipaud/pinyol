-- The interface's pictures: panels that stretch to any size (PANELS: 6 looks x 9 tiles, a 3x3 grid cut from one
-- ornate square) and the icons (ICONS, 40x40 each). All of it drawn at the screen's 480x320.
local frame = {}

local T = 20
local LOOK = {navy = 0, paper = 1, teal = 2, red = 3, gold = 4, ink = 5}
local ICON = {A = 0, B = 1, C = 2, START = 3, AIR = 4, BAL = 5, CAM = 6, FLASH = 7, BULL = 8, RUN = 9, LEFT = 10,
              RIGHT = 11, CHECK = 12, CROSS = 13, STAR = 14, CLOCK = 15, SELECT = 16, REFUGE = 17}

-- one tile stretched over w x h, in pieces (the engine draws a scale up to 8 at a time)
local MAXP = 8 * T
local function stretch(f, x, y, w, h, tw, th)
  local oy = 0
  while oy < h do
    local ph = math.min(MAXP, h - oy)
    local ox = 0
    while ox < w do
      local pw = math.min(MAXP, w - ox)
      img("PANELS", x + ox, y + oy, {frame = f, scale_x = pw / tw, scale_y = ph / th})
      ox = ox + pw
    end
    oy = oy + ph
  end
end

-- A panel of that look at (x, y), w x h. Small ones (under 40 px) shrink their corners to fit.
function frame.panel(look, x, y, w, h)
  local p = LOOK[look] * 9
  local t = math.min(T, w // 2, h // 2)
  local k = t / T
  local mw, mh = w - 2 * t, h - 2 * t
  stretch(p + 4, x + t, y + t, mw, mh, T, T)
  stretch(p + 1, x + t, y, mw, t, T, T)
  stretch(p + 7, x + t, y + h - t, mw, t, T, T)
  stretch(p + 3, x, y + t, t, mh, T, T)
  stretch(p + 5, x + w - t, y + t, t, mh, T, T)
  img("PANELS", x, y, {frame = p, scale = k})
  img("PANELS", x + w - t, y, {frame = p + 2, scale = k})
  img("PANELS", x, y + h - t, {frame = p + 6, scale = k})
  img("PANELS", x + w - t, y + h - t, {frame = p + 8, scale = k})
end

-- An icon with its top-left at (x, y); `size` in pixels (40 as drawn).
function frame.icon(name, x, y, size)
  img("ICONS", x, y, {frame = ICON[name], scale = (size or 40) / 40})
end

return frame
