-- explain: "Cómo funciona", from the console's menu, over whatever was on (the title, a game, its end): the game
-- waits as it was. Four pages, drawn on the same standing canvas as the game, so they read the same way round:
--   1 the monitor stood up: the frame the game had on the screen, turning between how it is drawn and how it is sent
--   2 the arrows turned: press them and see which of the console's buttons is which of the rocket's directions
--   3 bullets in swarms: a live spiral, and how many there are
--   4 what turning costs, and why the canvas is 160x240
-- A: next page   B: back to the game
local lang = require("lang")
local E = {}

local PAGES = 4
local page, t = 1, 0
local demo = swarm(400, {10, 30, VW - 10, 122})

function E.enter(back)
  E.back, page, t = back, 1, 0
  target("SNAP") -- the frame that was on the screen, kept to turn it
  img("V", 0, 0)
  target()
  demo:clear()
end

function E.update() -- true when the player is done
  t = t + 1
  if btnp("a") then page, t = page % PAGES + 1, 0 demo:clear() end
  if page == 3 and t % 5 == 0 then
    local a = t / 20
    demo:add(80, 78, math.cos(a) * 0.7, math.sin(a) * 0.7)
    demo:add(80, 78, math.cos(a + math.pi) * 0.7, math.sin(a + math.pi) * 0.7)
    demo:add(80, 78, math.cos(a + math.pi / 2) * 0.5, math.sin(a + math.pi / 2) * 0.5)
  end
  demo:step()
  return btnp("b") or btnp("start")
end

local function body(key, vars)
  textbox(lang.tr(key, vars), 8, 136, VW - 16, 88, {font = FONT_S, color = 0xE8E0FF, valign = "top"})
end

local function monitor() -- the frame turning: a quarter round and back, resting at each end
  local k = (t % 300) / 300
  local turn = k < 0.3 and 0 or k < 0.5 and (k - 0.3) / 0.2 or k < 0.8 and 1 or 1 - (k - 0.8) / 0.2
  local e = turn * turn * (3 - 2 * turn)
  box(32, 28, 96, 96, 0x403878)
  img("SNAP", 80 - 32, 76 - 48, {scale = 0.4, angle = 90 * e})
  local cap = e < 0.5 and "how_drawn" or "how_sent"
  textbox(lang.tr(cap), 6, 126, VW - 12, 9, {font = FONT_S, align = "center", color = 0xFFD848})
end

local NAMES = {{"right", "how_up", 80, 36}, {"left", "how_down", 80, 104}, {"up", "how_left", 36, 70}, {"down", "how_right", 124, 70}}

local function arrows() -- the console's cross, as it sits with the console on its side, lit while held
  rect(72, 40, 16, 60, 0x2A2050) rect(50, 62, 60, 16, 0x2A2050)
  local said = nil
  for _, n in ipairs(NAMES) do
    local on = btn(n[1])
    local x, y = n[3], n[4]
    local w = textw(lang.tr("btn_" .. n[1]), FONT_S)
    rect(x - w // 2 - 3, y - 5, w + 6, 11, on and 0xFFD848 or 0x403878)
    text(lang.tr("btn_" .. n[1]), x, y - 3, {font = FONT_S, align = "center", color = on and 0x1A1028 or 0xE8E0FF})
    if on then said = n end
  end
  img("SPR_ROCKET", 76, 63, (t // 3) % 3)
  if said then
    textbox(lang.tr("how_press", {b = lang.tr("btn_" .. said[1]), d = lang.tr(said[2])}), 6, 114, VW - 12, 20,
            {font = FONT_S, align = "center", color = 0xFFD848})
  end
end

function E.draw()
  rect(0, 0, VW, VH, 0x100C28)
  for y = 0, VH - 1, 4 do rect(0, y, VW, 1, 0x141032) end -- the glass's lines
  text(lang.tr("how_title"), VW // 2, 6, {font = FONT_B, align = "center", color = 0xFFF0A0, shadow = 0x0A0818})
  textbox(lang.tr("how_p" .. page), 6, 18, VW - 12, 10, {font = FONT_S, align = "center", color = 0xFFB0D0})
  if page == 1 then
    monitor()
    body("how_1")
  elseif page == 2 then
    arrows()
    body("how_2")
  elseif page == 3 then
    box(8, 28, VW - 16, 96, 0x403878)
    demo:draw("B_ORB")
    circ(80, 78, 2, 0xFFFFFF)
    textbox(lang.tr("how_live", {n = #demo + #P.orbs + #P.sparks + #P.bigs + #P.confs}), 6, 126, VW - 12, 9,
            {font = FONT_S, align = "center", color = 0xFFD848})
    body("how_3")
  else
    box(8, 28, VW - 16, 96, 0x403878)
    rect(18, 40, 20, 30, 0x58E0F8) -- the canvas, 160x240, inside the one it would take at full size, 320x480
    box(18, 40, 40, 60, 0xFF5070)
    textbox("160x240", 64, 40, 80, 9, {font = FONT_S, color = 0x58E0F8})
    textbox("320x480", 64, 92, 80, 9, {font = FONT_S, color = 0xFF5070})
    textbox(lang.tr("how_px"), 64, 52, 84, 38, {font = FONT_S, color = 0xE8E0FF})
    body("how_4")
  end
  textbox(lang.tr("how_keys", {p = page, n = PAGES}), 4, 226, VW - 8, 10, {font = FONT_S, align = "center", color = 0xC0B8E0})
end

return E
