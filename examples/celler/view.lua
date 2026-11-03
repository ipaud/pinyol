-- view: what the watchman sees. raycast() draws the gallery onto a 240x136 canvas, a column at a time (walls, doors
-- sliding in their frames, the things and ghost corks standing in it), shown twice as big; his hands are drawn over
-- it, and under it the status bar: a tile layer of the picture processor with his face, an indexed sprite lit by the
-- lantern's flame through its palette (lib/light). The map (START) is drawn square by square as the candle reveals it.
local W = require("world")
local palette_light = require("light") -- (the global light() is the glow)
local lang = require("lang")
local V = {}

V.VW, V.VH = 240, 136   -- the view's canvas; on the screen 480x272, the bar under it
local SH = V.VH * 2
local WALLS = {["#"] = "TEX_ROCK", V = "TEX_VAULT", B = "TEX_RACKS", S = "TEX_SECRET", R = "TEX_BARRELS", P = "TEX_PUPITRE",
               D = "TEX_DOOR", G = "TEX_GATE", H = "TEX_GATE_LEVER", L = "TEX_LEVER", M = "TEX_LEVER_ON",
               E = "TEX_STAIRS", X = "TEX_WAY_OUT"}
V.WALLS = WALLS
local PIC = {key = "SPR_KEY", candle = "SPR_CANDLE", bottle = "SPR_BOTTLE", reserva = "SPR_RESERVA", cork = "SPR_CORK",
             barrel = "SPR_BARREL", demijohn = "SPR_DEMIJOHN"}
V.CEIL, V.FLOOR = 0x2E241C, 0x4C3C2C
local view = {walls = WALLS, fov = 66, jamb = "TEX_JAMB", ceiling = V.CEIL, floor = V.FLOOR, sprites = {}, doors = {}}
V.view = view

local face_sheet, lamp
local SMALL = {font = "dos_vga_small", scale = 2, color = 0xE8D8B0}
local LABEL = {font = "dos_vga_small", color = 0xB89868}

function V.init()
  canvas("VIEW", V.VW, V.VH)
  bg(1, {map = "BAR", prio = 1})
  palette("OBJ", true)
  face_sheet = sheet("FACE")
  local base, normals = {}, {}
  for _, s in ipairs(require("gen.face")) do base[s.entry], normals[s.entry] = s.colour, s.normal end
  lamp = palette_light.new({bank = 0, obj = true, base = base, normals = normals, ambient = 0.28})
end

-- ------------------------------------------------------------------ the first-person view
local function put(list, n, x, y, pic, frame, scale)
  n = n + 1
  local s = list[n] or {}
  list[n] = s
  s.x, s.y, s.picture, s.frame, s.scale = x, y, pic, frame or 0, scale or 1
  return n
end

function V.setup(px, py, pa, fog)
  view.map = W.map
  view.x, view.y, view.angle = px, py, pa
  view.fog = fog
  local doors, nd = view.doors, 0
  for _, d in ipairs(W.doors) do
    if d.active then
      nd = nd + 1
      local o = doors[nd] or {}
      doors[nd] = o
      o.x, o.y, o.open = d.x, d.y, d.open
    end
  end
  for i = nd + 1, #doors do doors[i] = nil end
  local sp, n = view.sprites, 0
  local t = ticks()
  for _, it in ipairs(W.things) do
    local f = it.kind == "candle" and (t // 8) % 2 or 0
    n = put(sp, n, it.x, it.y, PIC[it.kind], f, 1)
  end
  for _, g in ipairs(W.ghosts) do
    local f
    if g.state == "pop" then f = 3 elseif g.state == "flee" then f = 2 else f = ((t + g.phase) // 20) % 2 end
    n = put(sp, n, g.x, g.y, "SPR_GHOST", f, 1)
  end
  for _, s in ipairs(W.shots) do n = put(sp, n, s.x, s.y, "SPR_CORK_FLY", 0, 1) end
  for i = n + 1, #sp do sp[i] = nil end
  return view
end

function V.cast() return raycast("VIEW", view) end

local function hands()
  local k = math.max(0, W.wax) / 100
  local dim = 0.5 + 0.5 * math.min(1, k * 1.6)
  local bob = math.floor(math.sin(W.P.walk * 0.22) * 6)
  clip(0, 0, 480, SH)
  local ly = (W.raised and 70 or 164) + bob
  local lf = (ticks() // 6) % 3
  if (W.mode == "relight" and W.t < 40) or W.mode == "dark" then lf = 3 end
  img("HUD_LANTERN", 14, ly, {frame = lf, scale = 2, dim = dim})
  if lf ~= 3 then light(62, ly + 56, 54 + 30 * k, 0xFF9A40, {intensity = 0.35 + 0.3 * k}) end
  local gy = 166 - bob // 2 + (W.gun > 6 and 8 or 0)
  img("HUD_GUN", 290, gy, {frame = W.gun > 0 and 1 or 0, scale = 2, dim = dim})
  clip()
end

function V.draw_view(with_hands)
  img("VIEW", 0, 0, {scale = 2})
  if with_hands then hands() end
end

-- ------------------------------------------------------------------ the face in the bar, lit by the flame
function V.face_update(frame_override)
  local P = W.P
  local frame = W.face
  if frame == 0 then
    local g, d = W.nearest_ghost()
    if g and d < 3 then frame = 3
    elseif g and d < 7 then -- he looks at the nearest ghost cork, left or right
      local a = math.deg(math.atan(g.y - P.y, g.x - P.x)) - P.a
      a = (a + 540) % 360 - 180
      frame = a < -20 and 1 or a > 20 and 2 or 0
    end
  end
  spr(0, face_sheet, frame_override or frame, 108, 136, prio(0))
  if ticks() % 2 == 0 then
    local k = math.max(0, W.wax) / 100
    local sway = noise(ticks() * 0.05) * 0.4
    lamp.gain = 0.55 + 0.6 * math.min(1, k * 1.4) + noise(ticks() * 0.11, 3) * 0.08
    if W.mode == "relight" and W.t < 40 then lamp.gain = 0.35 end
    if W.raised then lamp:set(-0.2 + sway, -1, 0.5) else lamp:set(-0.8 + sway, 0.45, 0.7) end
  end
end

function V.face_off() spr_off(0) end

-- ------------------------------------------------------------------ the status bar's words and icons
function V.draw_bar(level)
  local k = math.max(0, W.wax) / 100
  text(lang.tr("bar_wax"), 14, 279, LABEL)
  rect(14, 292, 92, 12, 0x140C06)
  local c = k > 0.5 and 0xF0C050 or k > 0.25 and 0xF08A30 or 0xE04020
  rect(15, 293, math.floor(90 * k + 0.5), 10, c)
  rect(15, 293, math.floor(90 * k + 0.5), 2, 0xFFF0B0)
  for i = 1, W.matches do img("ICO_MATCH", 104 + i * 12, 284, {scale = 2}) end
  img("ICO_CORK", 156, 284, {scale = 2})
  text(tostring(W.corks), 186, 288, SMALL)
  text(lang.tr("bar_gallery", {n = level}), 288, 279, LABEL)
  text(level .. "/5", 288, 290, SMALL)
  if W.has_key then img("ICO_KEY", 322, 284, {scale = 2}) end
  if #W.levers > 0 then
    img("ICO_LEVER", 344, 284, {scale = 2})
    text(W.levers_on .. "/" .. #W.levers, 372, 290, SMALL)
  end
  text(lang.tr("bar_score"), 466, 279, {font = "dos_vga_small", color = 0xB89868, align = "right"})
  text(string.format("%06d", W.score), 466, 290, {font = "dos_vga_body", color = 0xFFE8A0, align = "right"})
end

-- ------------------------------------------------------------------ the map, square by square as the light reveals them
local CS = 8
local MAPC = {["#"] = 0x3A3026, V = 0x8A4630, B = 0x2E5A36, S = 0x2E5A36, R = 0x7A5230, P = 0x9A7448,
              D = 0xA06C36, G = 0x8888A0, H = 0xB04030, L = 0xD04030, M = 0x40C060, E = 0xF0F0E0, X = 0xFFD880}

local function draw_cell(k)
  local x, y = k % 256, k // 256
  local c = W.cell(x, y)
  local col = MAPC[c]
  if not col then col = 0x7A6448 end
  rect(x * CS, y * CS, CS, CS, col)
  if c == "D" or c == "G" or c == "H" then rect(x * CS + 2, y * CS + 2, CS - 4, CS - 4, 0x20140A) end
end

function V.map_new()
  canvas("AMAP", W.w * CS, W.h * CS)
  target("AMAP")
  cls(0x0C0806)
  target()
  W.fresh = {}
  for k in pairs(W.seen) do W.fresh[#W.fresh + 1] = k end
  V.map_level = W.level
end

function V.map_update() -- only the squares seen since the last frame are drawn into it
  if V.map_level ~= W.level then V.map_new() end
  if #W.fresh == 0 then return end
  target("AMAP")
  for _, k in ipairs(W.fresh) do draw_cell(k) end
  for _, lv in ipairs(W.levers) do if W.seen[lv.y * 256 + lv.x] then draw_cell(lv.y * 256 + lv.x) end end
  target()
  W.fresh = {}
end

function V.draw_map()
  V.map_update()
  local mw, mh = W.w * CS, W.h * CS
  local x0, y0 = (480 - mw) // 2, (SH - mh) // 2 + 6
  shade(0, 0, 480, SH)
  rect(x0 - 6, y0 - 22, mw + 12, mh + 28, 0x1A120C)
  box(x0 - 6, y0 - 22, mw + 12, mh + 28, 0xB08850)
  text(lang.tr("map_title", {n = W.level}), x0, y0 - 18, {font = "dos_vga_small", color = 0xE8D8B0})
  text(lang.tr("map_seen", {p = math.floor(100 * W.seen_n / math.max(1, W.open_cells))}), x0 + mw, y0 - 18,
       {font = "dos_vga_small", color = 0xB89868, align = "right"})
  img("AMAP", x0, y0)
  for _, it in ipairs(W.things) do -- what the candle has shown of the things on the floor
    if W.seen[math.floor(it.y) * 256 + math.floor(it.x)] then
      local col = ({key = 0xFFD040, candle = 0xFFF0C0, bottle = 0x60C070, reserva = 0xFF60A0, cork = 0xC89058})[it.kind]
      if col then rect(x0 + math.floor(it.x * CS) - 1, y0 + math.floor(it.y * CS) - 1, 3, 3, col) end
    end
  end
  local a = math.rad(W.P.a)
  local px, py = x0 + W.P.x * CS, y0 + W.P.y * CS
  tri(px + math.cos(a) * 6, py + math.sin(a) * 6, px + math.cos(a + 2.4) * 4, py + math.sin(a + 2.4) * 4,
      px + math.cos(a - 2.4) * 4, py + math.sin(a - 2.4) * 4, 0xFFF080)
end

-- ------------------------------------------------------------------ a message at the top of the view
function V.toast(s, colour)
  local w = textw(s, {font = "dos_vga_body"})
  rect(240 - w // 2 - 10, 10, w + 20, 24, 0x1A120C)
  box(240 - w // 2 - 10, 10, w + 20, 24, 0xB08850)
  text(s, 240, 14, {font = "dos_vga_body", align = "center", color = colour or 0xF0E0B0})
end

return V
