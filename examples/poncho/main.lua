-- Poncho (working title: Poncho y el Patinete Loco): a side-scrolling platformer for a 3-year-old hero, 16-bit look. This is the first level, "the giant playroom".
--   The world is 240x160 only for the far wall (a bitmap layer scrolled line by line); everything else (tiles, Poncho, toys, text) is drawn at the screen's own
--   480x320 with img / shapes, as Taller does, so the strips can be as big as the art wants. The level is 192 x 14 tiles of 32 px (6144 x 448 px).
--   Controls: arrows move, A jumps (let go early for a short hop), C runs, B gets on or off the scooter once found, DOWN brakes / falls faster / drops through shelves.
--   core/hero.lua is the feel; core/map.lua is the level; core/foes.lua, items.lua the toys; bgfx.lua and tiles.lua the picture.
local lang = require("lang")
local K = require("core.const")
local In = require("core.input")
local Snd = require("core.sound")
local Spr = require("core.spr")
local Bg = require("core.bgfx")
local Tiles = require("core.tiles")
local Play = require("core.play")
local Scr = require("core.screens")
local Items = require("core.items")
local Bot = require("core.bot")

G = {state = "title", t = 0, back = "title"}

local function open_how() -- the console's menu item: also on the title, before any level; it gives the game back as it was
  if G.state == "explain" then return end
  G.back, G.state = G.state, "explain"
end

local function set_menu()
  menuitem()
  menuitem(lang.tr("how_item"), open_how)
end

local function to_title()
  require("core.music").stop()
  G.state = "title"
  In.bot = false
  Scr.title.enter()
end

function _init()
  lang.load()
  Snd.init()
  Tiles.init()
  Bg.init()
  Spr.preload({"poncho", "poncho_scooter"})
  set_menu()
  Play.enter()
  to_title()
end

function _resume()
  lang.load()
  set_menu()
end

local function finish()
  local best = stored("best", 0)
  local t = Play.time
  if best == 0 or t < best then best = t store("best", t) end
  local coins, creams, tc, ti = Items.counts()
  Scr.results.enter({coins = coins, creams = creams, total_coins = tc, total_creams = ti, time = t, best = best})
  G.state = "results"
end

function _update()
  G.t = G.t + 1
  if In.bot then Bot.step() end
  In.update()
  local st = G.state
  if st == "title" then
    local pick = Scr.title.update()
    if pick == "start" then Play.enter() G.state = "play"
    elseif pick == "how" then open_how() end
  elseif st == "play" then
    if Play.update() == "done" then finish() end
    if G.after_play then G.after_play() end
  elseif st == "explain" then
    if Scr.how.update() then G.state = G.back end
  elseif st == "results" then
    if Scr.results.update() then to_title() end
  end
end

function _draw()
  local st = G.state
  if st == "explain" then
    Scr.how.draw(G.back == "title" and Scr.title.draw or (G.back == "results" and Scr.results.draw or Play.draw))
  elseif st == "title" then Scr.title.draw()
  elseif st == "results" then Scr.results.draw(Play.draw)
  else Play.draw() end
end

HOW = open_how -- (global: tests/poncho.script)
require("core.dbg") -- the test script's hooks: teleports, traces and little physics experiments
