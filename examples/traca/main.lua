-- Traca: a vertical shoot-'em-up the way the 1985 cabinets were built, with the monitor stood on its end. The game
-- is drawn on a 160x240 canvas standing up and shown turned a quarter round and twice as big, so the console is held
-- on its side (its left edge down) and the arrows are read turned too. A firework rocket climbs the sky of a village's
-- fiesta night to burst as the last palmera: paper lanterns, bats, fair balloons and drunk rockets spitting sparks
-- (the bullets, hundreds of them, in swarms) get in its way, and the fair's cardboard moon waits at the top.
--   arrows (turned): move   A: fire (held)   B: slowly   C: a traca (clears the sky)
-- Files: play.lua (the game), foes.lua, boss.lua, stages.lua, sky.lua (the background), pilot.lua (the machine that
-- plays: the title's demo and the playtest's perfect player), finale.lua, explain.lua ("Cómo funciona"), tunes.lua.
local lang = require("lang")
VW, VH = 160, 240 -- the standing canvas (global: the other files and the test)
P = require("play")
PILOT = require("pilot")
local S, E, M = require("sky"), require("explain"), require("tunes")

state = "title" -- title | play | demo | over | won | how (global: tests/traca.script)
local T, high, new_record = 0, 0, false
local toast_text, toast_t = nil, 0
local demos = 0
local DEMO_AFTER, DEMO_LENGTH = 600, 2400 -- ticks of title before the machine plays by itself, and for how long
local TURN = {angle = 90, scale = 2}      -- the canvas turned a quarter round, its top on the console's right edge
FONT_T, FONT_B, FONT_S = "arcade_80s_title", "arcade_80s_body", "arcade_80s_small"

function calm() return settings().reduce_flashing end -- the player wants no flashing (global: every file asks)

local function toast(s) toast_text, toast_t = s, 170 end

function earn(id) -- an achievement (global: play.lua, explain.lua); never in the title's demo
  if state == "demo" then return end
  if achieve(id) then toast(lang.tr("ach_" .. id)) M.sfx("SFX_TOAST") end
end

function extra_life() toast(lang.tr("extra")) M.sfx("SFX_TOAST") end

function enter_how() -- the console's menu item (global: tests/traca.script)
  if state == "how" then return end
  E.enter(state)
  state = "how"
  earn("curioso")
end

local function menu()
  menuitem()
  menuitem(lang.tr("how"), enter_how)
end

function _init()
  lang.load()
  show(0) -- no world of tiles: everything is drawn on the standing canvas
  canvas("V", VW, VH)
  canvas("SNAP", VW, VH)
  high = stored("high", 0)
  M.init()
  P.init()
  S.init()
  menu()
  M.play("fiesta")
end

function _resume() -- the menu closed: Ajustes may have changed the language or the flashing
  lang.load()
  menu()
end

local function start()
  P.ai = false
  P.new_game(1)
  state, new_record, T = "play", false, 0
  M.sfx("SFX_START")
  M.play("fiesta")
end

local function start_demo()
  demos = demos + 1
  P.new_game(1 + (demos - 1) % 4)
  P.ai = true
  state, T = "demo", 0
end

local function any_button()
  for _, b in ipairs({"a", "b", "c", "start", "left", "right", "up", "down"}) do if btnp(b) then return true end end
  return false
end

local function finish(won) -- the game's end: the record kept
  state, T = won and "won" or "over", 0
  if P.score > high then high, new_record = P.score, true store("high", high) end
  M.play(won and nil or "over")
end

function _update()
  T = T + 1
  if toast_t > 0 then toast_t = toast_t - 1 end
  M.update()
  if state == "how" then
    if E.update() then state = E.back end
    return
  end
  S.update(P)
  if state == "title" then
    P.idle()
    S.title_tick(T)
    if btnp("a") or btnp("start") then start() elseif T > DEMO_AFTER then start_demo() end
  elseif state == "demo" then
    P.update()
    if any_button() or T > DEMO_LENGTH or P.mode == "over" or P.mode == "won" then
      P.ai, state, T = false, "title", 0
      P.idle_reset()
      M.play("fiesta")
    end
  elseif state == "play" then
    P.update()
    if P.mode == "over" then finish(false) elseif P.mode == "won" then finish(true) end
  elseif state == "over" or state == "won" then
    P.idle()
    if T > 120 and (btnp("a") or btnp("start")) then
      state, T = "title", 0
      P.idle_reset()
      M.play("fiesta")
    end
  end
end

-- ------------------------------------------------------------------ drawing: on the standing canvas, then turned

local function say(s, y, col, font, scale)
  text(s, VW // 2, y, {font = font or FONT_B, align = "center", color = col, scale = scale, shadow = 0x0A0818})
end

local function blink() return calm() or (T // 30) % 2 == 0 end

local function draw_title()
  S.draw_title(T)
  local k = math.sin(T / 40) * 1.5
  text("TRACA", VW // 2, 34 + k, {font = FONT_T, scale = 3, align = "center", color = 0xFFF0A0, gradient = 0xFF7020,
                                   outline = 0x5A1028, shadow = 0x0A0818, spacing = 1})
  say(lang.tr("subtitle"), 66, 0xFFB0D0, FONT_S)
  textbox(lang.tr("turn"), 14, 100, VW - 28, 22, {font = FONT_S, align = "center", color = 0xA0C8FF, shadow = 0x0A0818})
  if blink() then say(lang.tr("press"), 128, 0xFFFFFF) end
  say(lang.tr("high") .. " " .. string.format("%06d", high), 146, 0xFFD848, FONT_S)
  say(lang.tr("controls"), 230, 0xC0B8E0, FONT_S)
end

local function draw_toast()
  if toast_t <= 0 or not toast_text then return end
  local w, h = textw(toast_text, {font = FONT_S, width = VW - 24})
  rect(VW // 2 - w // 2 - 5, 206, w + 10, h + 6, 0x140E30)
  box(VW // 2 - w // 2 - 5, 206, w + 10, h + 6, 0xFFD848)
  text(toast_text, VW // 2, 209, {font = FONT_S, align = "center", color = 0xFFFFFF, width = VW - 24})
end

local function draw_end()
  local won = state == "won"
  rect(12, 70, VW - 24, 96, 0x140E30)
  box(12, 70, VW - 24, 96, won and 0xFFD848 or 0xFF5070)
  say(lang.tr(won and "won" or "over"), 82, won and 0xFFF0A0 or 0xFF6080, FONT_T)
  if won then textbox(lang.tr("won_sub"), 20, 98, VW - 40, 22, {font = FONT_S, align = "center", color = 0xFFB0D0}) end
  say(string.format("%06d", P.score), 124, 0xFFFFFF, FONT_T)
  if new_record then say(lang.tr("new_record"), 140, 0xFFD848, FONT_S) end
  if T > 120 and blink() then say(lang.tr("press"), 152, 0xC0B8E0, FONT_S) end
end

function _draw()
  target("V")
  if state == "how" then
    E.draw()
  elseif state == "title" then
    draw_title()
  else
    P.draw()
    if state == "demo" and blink() then say(lang.tr("demo"), 120, 0xFFFFFF) end
    if state == "over" or state == "won" then draw_end() end
  end
  draw_toast()
  target()
  img("V", 240 - VW, 160 - VH, TURN) -- 160x240 shown 320x480 and turned: it fills the 480x320 screen
end

