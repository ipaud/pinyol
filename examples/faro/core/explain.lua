-- "Cómo funciona", from the console's menu or the title: the tricks of a 32-bit console that this lighthouse is made of, each shown with the game's
-- own pictures. 1) light that adds up: an ánima drawn the PlayStation's four ways of meeting what is under it; 2) quads: the gear turning on its
-- two triangles, a tentacle bending along its spine, the 4x4 dither on and off; 3) water over the whole screen (distort with screen = true) and the
-- glass of a tube (crt); 4) the sound: ADPCM, MIDI on a bank, one reverb room.
local H = require("core.hud")
local E = require("core.estel")
local S = require("core.sound")
local lang = require("lang")
local X = {}

local PAGES = {"luz", "quad", "agua", "son"}
X.page, X.t, X.dither, X.crt, X.room = 1, 0, true, false, true

function X.enter(from)
  X.from, X.page, X.t = from, 1, 0
  X.crt_before = X.crt_on and X.crt_on() or false
  achieve("curiosa")
end

-- true when the player is done
function X.update()
  X.t = X.t + 1
  if btnp("b") or btnp("start") then
    if not X.room then X.room = true S.room(S.current_room() or "hall", true) end
    return true
  end
  if btnp("right") then X.page = X.page % #PAGES + 1 S.play("BLIP") end
  if btnp("left") then X.page = (X.page - 2) % #PAGES + 1 S.play("BLIP") end
  if btnp("a") then
    local pg = PAGES[X.page]
    if pg == "quad" then X.dither = not X.dither end
    if pg == "agua" and X.toggle_crt then X.toggle_crt() end
    if pg == "son" then
      X.room = not X.room
      if X.room then reverb("hall", 0.45, {music = 0.35, ambient = 0.2}) else reverb() end
      S.play("CALM")
      S.play("FREE", {delay = 0.5})
    end
  end
  return false
end

local function body(key, y)
  local s = lang.tr(key)
  local _, h = textw(s, {font = H.SMALL, width = 440})
  H.panel(10, y - 6, 460, h + 12)
  text(s, 20, y, {font = H.SMALL, width = 440, color = 0xE8ECF8})
  return y + h + 12
end

local function title(key)
  textbox(lang.tr(key), 10, 6, 460, 40, {font = H.TITLE, align = "center", color = 0xFFF0C8, gradient = 0xE09030, outline = 0x101018, fonts = {H.BODY}})
end

local function luz()
  img("BG_F1", 0, -360, {dim = 0.7})
  title("ex_luz_t")
  local y = body("ex_luz", 50)
  local modes = {{}, {alpha = 0.5}, {add = true}, {sub = true}, {quarter = true}}
  local f = (X.t // 9) % 5
  for i, m in ipairs(modes) do
    local x = 4 + (i - 1) * 92
    m.frame = f
    img("SPR_ANIMA", x, 172, m)
    textbox(lang.tr("ex_luz_l" .. i), x, 280, 112, 18, {font = H.SMALL, align = "center", color = 0xFFE0A0, shadow = 0x000000})
  end
end

local function quad_page()
  img("BG_F3", 0, -300, {dim = 0.6})
  title("ex_quad_t")
  local y = body("ex_quad", 50)
  -- the gear on four corners, and its two triangles
  local cx, cy, r = 120, 220, 60
  local a = math.rad(X.t * 1.2)
  local p = {}
  for i = 0, 3 do
    local t = a + math.pi * 1.25 + i * math.pi / 2
    p[#p + 1] = cx + math.cos(t) * r * 1.414
    p[#p + 1] = cy + math.sin(t) * r * 1.414
  end
  local opts = {lights = {0xFFE0A0, 0x9070C0, 0x302040, 0xA06040}, dither = X.dither}
  quad("TEX_GEAR", p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], opts)
  line(p[1], p[2], p[3], p[4], 0x60FFFF) line(p[3], p[4], p[5], p[6], 0x60FFFF)
  line(p[5], p[6], p[7], p[8], 0x60FFFF) line(p[7], p[8], p[1], p[2], 0x60FFFF)
  line(p[1], p[2], p[5], p[6], 0xFF60A0)
  -- a tentacle: four quads along a bending spine
  local base, h = 300, 150
  local pts = {}
  for i = 0, 4 do
    local k = i / 4
    pts[i] = {340 + math.sin(X.t * 0.06 + k * 2.2) * 34 * k * k, base - h * k, 1 - 0.6 * k}
  end
  for i = 0, 3 do
    local q, c = pts[i], pts[i + 1]
    local wa, wc = 22 * q[3], 22 * c[3]
    local v0, v1 = 128 - 32 * i, 128 - 32 * (i + 1)
    quad("TEX_TENTACLE", c[1] - wc, c[2], c[1] + wc, c[2], q[1] + wa, q[2], q[1] - wa, q[2],
         {uv = {0, v1, 47, v1, 47, v0, 0, v0}, lights = {0xC0B0E0, 0xC0B0E0, 0x504070, 0x504070}, dither = X.dither})
  end
  for i = 0, 4 do circ(pts[i][1], pts[i][2], 2, 0x60FFFF, true) end
  grad(240, 150, 60, 140, 0xFFD080, 0x200818, {dither = X.dither})
  textbox(lang.tr("ex_dither", {v = lang.tr(X.dither and "on" or "off")}), 200, 280, 140, 18, {font = H.SMALL, align = "center", color = 0xFFE0A0, shadow = 0x000000})
end

local function agua()
  img("BG_F2", 0, -400, {dim = 0.75})
  title("ex_agua_t")
  body("ex_agua", 50)
  local wy = 160
  local b = {x = 400, y = 158, dir = -1, vx = 0, vy = 0, ground = true}
  local st = {t = X.t, walked = 0, hurt = 0, lift = (X.t // 120) % 2 == 1}
  E.reflect(b, st, 0, wy)
  E.draw(b, st, 0)
  E.light(b, st, 0, st.lift and 104 or 56)
  distort(0, wy, 480, 120, {screen = true, kind = "water", amp = 3, period = 16, speed = 0.4})
  textbox("crt: " .. lang.tr(X.crt_on and X.crt_on() and "on" or "off"), 340, 282, 130, 18, {font = H.SMALL, align = "right", color = 0xFFE0A0, shadow = 0x000000})
end

local function son()
  img("BG_LAMP", 0, -330, {dim = 0.5})
  title("ex_son_t")
  local y = body("ex_son", 50)
  -- the bell's echoes as rings, when the room is on
  local k = (X.t % 120) / 120
  for i = 0, (X.room and 4 or 0) do
    local r = 10 + (k + i * 0.2) % 1 * 90
    circ(240, 230, r, 0x504030 + 0x101008 * (4 - i), false)
  end
  light(240, 230, 26, 0xFFC060, {intensity = 0.8})
  textbox(lang.tr("ex_room", {v = lang.tr(X.room and "room_hall" or "room_none")}), 140, 270, 200, 20, {font = H.SMALL, align = "center", color = 0xFFE0A0})
end

function X.draw()
  local pg = PAGES[X.page]
  if pg == "luz" then luz() elseif pg == "quad" then quad_page() elseif pg == "agua" then agua() else son() end
  rect(0, 300, 480, 20, 0x080810)
  for i = 1, #PAGES do circ(424 + (i - 1) * 14, 310, 3, i == X.page and 0xFFE0A0 or 0x404860, true) end
  textbox(lang.tr("ex_back"), 10, 302, 380, 16, {font = H.SMALL, color = 0xA0A8C8})
end

return X
