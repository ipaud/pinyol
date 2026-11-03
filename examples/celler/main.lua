-- El Celler: a night in the cava cellars of a Penedès village, in first person, the way a 1992 PC raycaster drew it.
-- The ghost corks have come out of their bottles; the night watchman has a candle that burns down, a toy cork gun
-- and five galleries to cross, each locked by a key, before he can get out at dawn.
--   up/down walk, left/right turn (B held: step aside)   A: fire a cork   B: open, pull a lever, push a rack
--   C held: the lantern up (it lights further and scares the ghost corks, and burns faster)   START: the map
-- The console's menu has "Cómo funciona": the view built a column at a time, the rays on the map (explain.lua).
local W, V, B = require("world"), require("view"), require("bot")
local E, D, Snd = require("explain"), require("dawn"), require("sound")
local LV = require("levels")
local lang = require("lang")
local voice = require("voice")

state = "title" -- title | demo | intro | play | clear | dark | dawn | explain (global: tests/celler.script)
G = W           -- the gallery, for the tests and the playtest adapter
AUTO = false    -- the autopilot plays (tests/celler.script plays the whole night with it)

local T, record, new_record = 0, 0, false
local toast_text, toast_t = nil, 0
local show_map = false
local intro_chars, intro_voice = 0, nil
local score_at_start, demo_n = 0, 0
local DEMO_AFTER, DEMO_LENGTH = 600, 2700

local function title_scene() -- the barrel hall of the third gallery, its ghost corks floating, seen turning round
  W.drive(nil)
  W.new_game()
  W.load(3)
  W.P.x, W.P.y, W.P.a = 13.5, 3.5, 200
end

local function toast(s) toast_text, toast_t = s, 170 Snd.play("SFX_TOAST") end

local ACH = {primera_llave = true, taponazo = true, espantar = true, reserva = true, cartografo = true, todos = true,
             una_vela = true, amanecer = true, curioso = true}
local function hook(id)
  if state == "demo" or not ACH[id] then return end
  if achieve(id) then toast(lang.tr("ach_" .. id)) end
end

local function menu()
  menuitem()
  menuitem(lang.tr("how"), function()
    if state ~= "explain" and state ~= "demo" then E.enter(state) state = "explain" end
  end)
end

function _init()
  lang.load()
  Snd.init()
  V.init()
  record = stored("record", 0)
  W.hook, E.hook = hook, hook
  title_scene()
  intro_voice = voice.new({sound = "SFX_BLIP", pitch = 0.9, spread = 3, every = 2, gain = 0.4})
  state, T = "title", 0
  Snd.music(true)
  menu()
end

function _resume() -- Ajustes may have changed the language
  lang.load()
  menu()
end

local function begin_gallery(n)
  W.load(n)
  W.wax = 100 -- a new candle waits at the foot of every stair
  B.reset()
  score_at_start = W.score
  state, T, intro_chars = "intro", 0, 0
  show_map = false
end

local function start()
  W.drive(nil)
  W.new_game()
  begin_gallery(1)
  Snd.music(true, true)
end

local function start_demo()
  demo_n = demo_n + 1
  W.new_game()
  W.load(1 + (demo_n - 1) % 3)
  B.reset()
  state, T = "demo", 0
end

local function any_button()
  for _, b in ipairs({"a", "b", "c", "start", "left", "right", "up", "down"}) do if btnp(b) then return true end end
  return false
end

local function finish_night()
  local tally = {score = W.score, ghosts = W.popped_night or 0, bottles = W.bottles_night or 0, matches = W.matches_used}
  new_record = W.score > record
  if new_record then record = W.score store("record", record) end
  tally.record, tally.new_record = record, new_record
  hook("amanecer")
  if W.matches_used == 0 then hook("una_vela") end
  D.enter(tally)
  state, T = "dawn", 0
  Snd.music(false)
end

local function count_night() -- what the gallery left behind, added to the night's tally when its stairs are taken
  W.popped_night = (W.popped_night or 0) + W.ghosts_popped
  local left = 0
  for _, it in ipairs(W.things) do if it.kind == "bottle" or it.kind == "reserva" then left = left + 1 end end
  W.bottles_night = (W.bottles_night or 0) + W.bottles_total - left
end

local function update_play()
  if W.btnp("start") then show_map = not show_map end
  W.update()
  if W.mode == "clear" then
    W.score = W.score + 300 + math.floor(W.wax) * 5
    count_night()
    state, T = "clear", 0
  elseif W.mode == "out" then
    W.score = W.score + 1000 + math.floor(W.wax) * 10
    count_night()
    finish_night()
  elseif W.mode == "dark" then
    state, T = "dark", 0
    Snd.music(false)
  end
end

function _update()
  T = T + 1
  if toast_t > 0 then toast_t = toast_t - 1 end
  Snd.update()
  if state == "explain" then
    if E.update() then state = E.back end
    return
  end
  if state == "title" then
    W.P.a = (W.P.a + 0.35) % 360
    if btnp("a") or btnp("start") then start() elseif T > DEMO_AFTER then start_demo() end
  elseif state == "demo" then
    W.drive(B.think())
    W.update()
    if any_button() or T > DEMO_LENGTH or W.mode ~= "play" then
      title_scene()
      state, T = "title", 0
    end
  elseif state == "intro" then
    intro_chars = intro_chars + 1
    do
      local s = lang.tr(LV[W.level].name .. "_hint")
      local ch = s:sub(intro_chars, intro_chars)
      if ch ~= "" then intro_voice:say(ch) end
    end
    if (T > 25 and (btnp("a") or btnp("b") or btnp("start"))) or T > 420 or (AUTO and T > 40) then state, T = "play", 0 end
  elseif state == "play" then
    if AUTO then W.drive(B.think()) end
    update_play()
  elseif state == "clear" then
    if (T > 60 and (btnp("a") or btnp("start"))) or T > 240 or (AUTO and T > 90) then begin_gallery(W.level + 1) end
  elseif state == "dark" then
    if T > 60 and (btnp("a") or (AUTO and T > 90)) then -- the gallery again, with a new box of matches
      W.score = score_at_start
      begin_gallery(W.level)
      W.wax, W.matches = 100, 3
      Snd.music(true, true)
    elseif T > 60 and btnp("b") then
      title_scene() state, T = "title", 0 Snd.music(true)
    end
  elseif state == "dawn" then
    if D.update(btnp("a") or btnp("start")) then
      title_scene() state, T = "title", 0 Snd.music(true)
    end
  end
end

-- ------------------------------------------------------------------ drawing
local TITLE = {font = "dos_vga_title", align = "center", color = 0xFFD880, gradient = 0xC06020, outline = 0x200C04, scale = 2}
local BODY = {font = "dos_vga_body", align = "center", color = 0xF0E0B0}

local function draw_title()
  grad(0, 0, 480, 150, 0x000000, 0x000000, {alpha = 0.55})
  text(lang.tr("title"), 240, 30, TITLE)
  text(lang.tr("subtitle"), 240, 104, {font = "dos_vga_body", align = "center", color = 0xF0D8A0, outline = 0x140A04})
  if (T // 30) % 2 == 0 then text(lang.tr("press"), 240, 200, {font = "dos_vga_body", align = "center", color = 0xFFFFFF, outline = 0x140A04}) end
  rect(0, 272, 480, 48, 0x140C06)
  text(lang.tr("record", {n = string.format("%06d", record)}), 240, 276, {font = "dos_vga_small", scale = 2, align = "center", color = 0xC8A878})
  textbox(lang.tr("controls"), 12, 298, 456, 20, {font = "dos_vga_small", color = 0xB89868, align = "center", valign = "top"})
end

local function draw_intro()
  shade(0, 0, 480, 272)
  local n = W.level
  local title = lang.tr("gallery", {n = n}) .. " · " .. lang.tr(LV[n].name)
  local hint = lang.tr(LV[n].name .. "_hint")
  local x, y, w = 40, 52, 400
  local _, hh = textw(hint, {font = "dos_vga_body", width = w - 32})
  rect(x, y, w, hh + 78, 0x1A100A)
  box(x, y, w, hh + 78, 0xD8A860)
  box(x + 3, y + 3, w - 6, hh + 72, 0x5A3A20)
  text(title, 240, y + 14, {font = "dos_vga_body", align = "center", color = 0xFFD880, scale = 1})
  text(hint, x + 16, y + 44, {font = "dos_vga_body", color = 0xF0E0B0, width = w - 32, chars = intro_chars})
  if T > 25 then text(lang.tr("press_go"), 240, y + hh + 58, {font = "dos_vga_small", align = "center", color = 0xB89868}) end
end

local function draw_card(title_key, lines, colour)
  shade(0, 0, 480, 272)
  local x, y, w = 70, 70, 340
  rect(x, y, w, 40 + #lines * 20 + 24, 0x1A100A)
  box(x, y, w, 40 + #lines * 20 + 24, colour)
  text(lang.tr(title_key, {n = W.level}), 240, y + 12, {font = "dos_vga_body", align = "center", color = colour})
  for i, s in ipairs(lines) do text(s, 240, y + 22 + i * 20, BODY) end
  if T > 60 then text(lang.tr(state == "dark" and "press_retry" or "press_go"), 240, y + 46 + #lines * 20, {font = "dos_vga_small", align = "center", color = 0xB89868}) end
end

local function draw_game()
  local P = W.P
  V.setup(P.x, P.y, P.a, state == "title" and 10 or W.fog())
  V.cast()
  local playing = state ~= "title"
  V.draw_view(playing)
  if state == "title" then return end
  if W.blown and W.blown > 0 and not settings().reduce_flashing then shade(0, 0, 480, 272) end -- the breath: one dimming, never a strobe
  if W.mode == "relight" then
    if W.t < 40 then rect(0, 0, 480, 272, 0x000000) end
    V.toast(lang.tr("relight", {n = W.matches}), 0xFFB060)
  end
  V.face_update()
  V.draw_bar(W.level)
  if show_map and state == "play" then V.draw_map() end
  if W.msg and W.mode == "play" then V.toast(lang.tr("msg_" .. W.msg, W.msg_args)) end
end

function _draw()
  if state == "explain" then V.face_off() E.draw() return end
  if state == "dawn" then show(0) V.face_off() D.draw() return end
  show(state == "title" and 0 or ALL)
  draw_game()
  if state == "title" then draw_title()
  elseif state == "demo" then
    if (T // 30) % 2 == 0 then text(lang.tr("demo"), 240, 40, {font = "dos_vga_body", align = "center", color = 0xFFFFFF}) end
  elseif state == "intro" then draw_intro()
  elseif state == "clear" then
    draw_card("clear", {lang.tr("clear_wax", {n = math.floor(W.wax)}), lang.tr("clear_ghosts", {n = W.ghosts_popped, of = W.ghosts_total}),
                        lang.tr("clear_score", {n = string.format("%06d", W.score)})}, 0xFFD880)
  elseif state == "dark" then
    draw_card("dark", {lang.tr("dark_1"), lang.tr("dark_2")}, 0xE06040)
  end
  if toast_t > 0 and toast_text then
    local w = textw(toast_text, {font = "dos_vga_body"})
    rect(240 - w // 2 - 10, 236, w + 20, 26, 0x2A1A0C)
    box(240 - w // 2 - 10, 236, w + 20, 26, 0xFFD880)
    text(toast_text, 240, 240, {font = "dos_vga_body", align = "center", color = 0xFFE8A0})
  end
end
