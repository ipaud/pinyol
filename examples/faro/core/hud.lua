-- what Estel carries, in the corners: her warmth as little flames, the matches left, the lantern's oil (a ramp dithered as the PlayStation's), the
-- ánimas gone to sea, the time; the floor's name when it starts, its hint, and the toasts of the achievements.
local C = require("core.const")
local Run = require("core.run")
local lang = require("lang")
local H = {}

local BODY, SMALL, TITLE = "playstation_body", "playstation_small", "playstation_title"
H.BODY, H.SMALL, H.TITLE = BODY, SMALL, TITLE
local toasts = {}

function H.toast(s) toasts[#toasts + 1] = {s = s, t = 200} end
function H.update()
  if toasts[1] then
    toasts[1].t = toasts[1].t - 1
    if toasts[1].t <= 0 then table.remove(toasts, 1) end
  end
end

function H.time(ticks)
  local s = ticks // 60
  return string.format("%d:%02d", s // 60, s % 60)
end

local function flame(x, y, on, t)
  if on then
    local w = 1 + 0.15 * math.sin(t * 0.2 + x)
    circ(x, y + 3, 5, 0xE06018, true)
    tri(x - 5, y + 3, x + 5, y + 3, x, y - 9 * w, 0xF08020)
    circ(x, y + 4, 3, 0xFFD050, true)
    tri(x - 2, y + 4, x + 2, y + 4, x, y - 3 * w, 0xFFF0A0)
  else
    circ(x, y + 3, 5, 0x30405A, true)
    tri(x - 5, y + 3, x + 5, y + 3, x, y - 8, 0x30405A)
  end
end

function H.panel(x, y, w, h)
  grad(x, y, w, h, 0x101830, 0x05070F, {alpha = 0.72, dither = true})
  box(x, y, w, h, 0x8A6A38)
  box(x + 1, y + 1, w - 2, h - 2, 0x2A2030)
end

-- the bar of the oil: dithered from amber to a deep orange, as a 32-bit menu drew its gauges
local function oil_bar(x, y, frac, drained)
  rect(x - 1, y - 1, 82, 8, 0x120C08)
  local w = math.floor(80 * math.max(0, math.min(1, frac)))
  if w > 0 then grad(x, y, w, 6, drained and 0x806040 or 0xFFE070, drained and 0x403020 or 0xB04010, {across = true, dither = true}) end
end

-- st: {oil, drained, freed, quota, t, label}
function H.draw(st)
  H.panel(6, 6, 154, 40)
  for i = 1, C.WARMTH do flame(18 + (i - 1) * 14, 20, i <= Run.warmth, st.t) end
  -- matches
  for i = 1, Run.matches do
    local x = 96 + (i - 1) * 8
    line(x, 14, x, 26, 0xC8A070)
    circ(x, 13, 2, 0xD04030, true)
  end
  text(H.time(Run.ticks), 152, 10, {font = SMALL, color = 0xC8D0E8, align = "right"})
  oil_bar(14, 34, st.oil / C.OIL_MAX, st.drained)
  if st.label then
    local w = textw(st.label, SMALL) + 40
    H.panel(474 - w, 6, w, 26)
    img("SPR_ANIMA", 474 - w + 4, 5, {frame = 0, scale = 0.2, alpha = 0.85})
    text(st.label, 466, 12, {font = SMALL, color = 0xD8F4FF, align = "right"})
  end
  H.draw_toasts()
end

function H.draw_toasts()
  local t = toasts[1]
  if not t then return end
  local w = textw(t.s, BODY) + 30
  local y = 280
  H.panel(240 - w // 2, y, w, 30)
  text(t.s, 240, y + 6, {font = BODY, color = 0xFFE7A0, align = "center"})
end

-- the floor's name and its hint, in the first seconds
function H.card(name, hint, k)
  if k <= 0 then return end
  H.panel(20, 100, 440, 52)
  textbox(name, 30, 106, 420, 40, {font = TITLE, align = "center", valign = "middle", color = 0xFFF0C8, gradient = 0xE09030, shadow = 0x000000,
                                   fonts = {BODY}})
  if hint then
    local _, hh = textw(hint, {font = BODY, width = 400})
    H.panel(30, 160, 420, hh + 16)
    text(hint, 240, 168, {font = BODY, align = "center", width = 400, color = 0xE8ECF8})
  end
end

return H
