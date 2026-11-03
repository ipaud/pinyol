-- El Faro de las Ánimas: a stormy night on a cape of the Catalan coast, the lighthouse lamp gone out. Estel, the keeper's daughter, climbs the tower
-- floor by floor with her grandfather's lantern: the ánimas of drowned fishermen, wild and cold to the touch, calm in the lantern held high and follow
-- her to the window, where they go out to sea; at the top, the Octopus of the Storm has put the great lamp out. Made the way a PlayStation or a
-- Saturn made its 2D games (docs/art.md, "PlayStation and Saturn 2D"): every picture painted in up to 256 colours at the screen's own 480x320, light
-- and transparency on what moves, quads that turn and bend, ADPCM sounds and MIDI songs in one reverb room.
--   ‹ › walk   A jump   B (held) raise the lantern   (the console's menu: "Cómo funciona")
local lang = require("lang")
local transition = require("transition")
local C = require("core.const")
local Run = require("core.run")
local Play = require("core.play")
local Boss = require("core.boss")
local Bot = require("core.bot")
local H = require("core.hud")
local S = require("core.sound")
local Scr = require("core.screens")
local X = require("core.explain")
local L = require("core.levels")

G = {state = "title", t = 0, bot = false} -- (global: the test script and tests/playtest/faro.lua read it)
local best = nil
local crt_on = false
local idle, demos = 0, 0

local function earn(id)
  if G.state == "demo" then return end
  if achieve(id) then H.toast(lang.tr("ach_" .. id)) end
end

local function apply_crt()
  if crt_on then crt({scan = 0.28}) else crt(false) end
end
X.crt_on = function() return crt_on end
X.toggle_crt = function()
  crt_on = not crt_on
  store("crt", crt_on)
  apply_crt()
end

local function menu()
  menuitem()
  menuitem(lang.tr("m_how"), function()
    if G.state == "explain" or G.state == "demo" or G.state == "wait" then return end
    G.back = G.state
    X.enter(G.state)
    G.state = "explain"
  end)
end

-- the buttons, as the floors and the lamp room read them
local function buttons()
  return {dx = (btn("right") and 1 or 0) - (btn("left") and 1 or 0), jump = btnp("a") or btnp("up"), hold = btn("a") or btn("up"),
          lift = btn("b") or btn("c")}
end
Play.input = function(P) if G.bot then return Bot.floor(P) end return buttons() end
Boss.input = function(B) if G.bot then return Bot.boss(B) end return buttons() end

Play.hook = function(id)
  if id == "free" and Run.freed >= 1 then earn("primera") end
  if id == "wet" then Run.wet = true end
  if id == "warm" then earn("abrigada") end
  if id == "floor_done" and Play.n == 2 and not Run.wet then earn("seca") end
  if id == "hatch" then H.toast(lang.tr("hatch")) end
end
Boss.hook = function(id)
  if id == "lamp" then
    earn("faro")
    if Run.ticks < 5 * 60 * 60 then earn("alba") end
    if Run.freed >= 8 then earn("todas") end
  end
  if id == "wick" then H.toast(lang.tr("wicks", {n = Boss.wicks})) end
end

local function to_title()
  G.state, G.bot, idle = "title", false, 0
  Scr.title.enter()
end

local function to_floor(n)
  Run.floor = n
  Run.wet = false
  if n <= L.count then
    Play.enter(n)
    G.state = G.state == "demo" and "demo" or "play"
  else
    Boss.enter()
    G.state = "boss"
  end
end

local function next_floor()
  transition.go("blocks", 0.9, {on_mid = function() to_floor(Run.floor + 1) end})
end

function _init()
  show(0) -- no 240x160 world: every picture at the screen's own 480x320
  lang.load()
  best = stored("best", nil)
  crt_on = stored("crt", false) and true or false
  apply_crt()
  menu()
  to_title()
end

function _resume()
  lang.load()
  menu()
  apply_crt()
end

local function any_button()
  for _, b in ipairs({"a", "b", "c", "start", "left", "right", "up", "down"}) do if btnp(b) then return true end end
  return false
end

local function start_demo()
  demos = demos + 1
  Run.new()
  G.state, G.bot, G.demo_t = "demo", true, 0
  Play.enter(1 + demos % 3)
  Run.floor = Play.n
end

local function finish()
  local record = not best or Run.ticks < best
  if record then best = Run.ticks store("best", best) end
  Scr.ending.enter({ticks = Run.ticks, freed = Run.freed, score = Run.score, record = record})
  G.state = "ending"
end

function _update()
  G.t = G.t + 1
  S.update()
  H.update()
  transition.update()
  local st = G.state
  if st == "title" then
    idle = idle + 1
    local pick = Scr.title.update(best)
    if pick then idle = 0 end
    if pick == "start" then
      Run.new()
      G.state = "intro"
      Scr.intro.enter()
    elseif pick == "how" then
      G.back = "title"
      X.enter("title")
      G.state = "explain"
    elseif pick == "crt" then X.toggle_crt()
    elseif idle > 900 then start_demo() end
  elseif st == "intro" then
    if Scr.intro.update() then transition.go("blocks", 0.9, {on_mid = function() to_floor(1) end}) G.state = "wait" end
  elseif st == "demo" then
    G.demo_t = G.demo_t + 1
    Play.update()
    if any_button() or G.demo_t > 1800 or Play.state ~= "play" then to_title() end
  elseif st == "play" then
    Play.update()
    if Play.state == "clear" then G.state = "wait" next_floor()
    elseif Play.state == "over" then G.state = "over" Scr.over.enter() end
  elseif st == "boss" then
    Boss.update()
    if Boss.state == "won" then finish()
    elseif Boss.state == "over" then G.state = "over" Scr.over.enter() end
  elseif st == "ending" then
    if Scr.ending.update() then to_title() end
  elseif st == "over" then
    if Scr.over.update() then to_title() end
  elseif st == "explain" then
    if X.update() then G.state = G.back or "title" end
  end
end

local function hud_play()
  local lv = Play.lv
  local label = lv.quota > 0 and lang.tr("animas", {n = math.min(Play.freed, lv.quota), q = lv.quota}) or nil
  H.draw({oil = Play.oil, drained = Play.drained, t = Play.t, label = label})
  if Play.card > 0 and Play.state == "play" then H.card(lang.tr(lv.id), lang.tr(lv.hint), Play.card / 150) end
  if Play.state == "frozen" then
    H.panel(90, 130, 300, 56)
    textbox(lang.tr("frozen"), 100, 136, 280, 22, {font = H.BODY, align = "center", color = 0xC8E0FF})
    local left = Run.matches - 1
    if left > 0 then textbox(lang.tr(left == 1 and "match_last" or "matches_left", {n = left}), 100, 160, 280, 20, {font = H.SMALL, align = "center", color = 0xFFE0A0}) end
  end
end

local function hud_boss()
  H.draw({oil = Boss.oil, drained = Boss.drained, t = Boss.t, label = lang.tr("wicks", {n = Boss.wicks})})
  if Boss.state == "intro" or Boss.t < 260 then H.card(lang.tr("f5"), lang.tr("hint_f5"), 1) end
  if Boss.charged and Boss.state == "fight" then textbox(lang.tr("charged"), 270, 34, 204, 18, {font = H.SMALL, align = "right", color = 0xFFE0A0, shadow = 0x000000}) end
  if Boss.state == "frozen" then
    H.panel(90, 130, 300, 40)
    textbox(lang.tr("frozen"), 100, 136, 280, 26, {font = H.BODY, align = "center", color = 0xC8E0FF})
  end
end

function _draw()
  local st = G.state
  if st == "wait" then st = Run.floor <= L.count and (Play.lv and "play" or "intro") or "boss" end
  if st == "title" then Scr.title.draw(best, crt_on)
  elseif st == "intro" then Scr.intro.draw()
  elseif st == "play" or st == "demo" then
    Play.draw_world()
    hud_play()
    if st == "demo" and (G.t // 40) % 2 == 0 then textbox(lang.tr("demo"), 100, 300, 280, 18, {font = H.SMALL, align = "center", color = 0xFFFFFF}) end
  elseif st == "boss" then
    Boss.draw_world()
    hud_boss()
  elseif st == "ending" then Scr.ending.draw()
  elseif st == "over" then Scr.over.draw()
  elseif st == "explain" then X.draw()
  end
  transition.draw()
end

-- ------------------------------------------------------------------ for the test script and the playtest
function dbg_floor(n) Run.new() G.bot = false to_floor(n) return true end
function dbg_bot(on) G.bot = on ~= false return true end
function dbg_state()
  return {state = G.state, floor = Run.floor, play = Play.state, boss = Boss.state, freed = Run.freed, warmth = Run.warmth, matches = Run.matches}
end
function dbg_ending() Run.ticks = 4 * 3600 + 1234 Run.freed, Run.score = 6, 1450 finish() return true end
function dbg_over() G.state = "over" Scr.over.enter() return true end
