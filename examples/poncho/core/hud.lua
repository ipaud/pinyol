-- hud: hearts, coins, ice creams, the clock and a note at the foot of the screen. Text in the game's own fonts, through lang.
local K = require("core.const")
local lang = require("lang")
local Hero = require("core.hero")
local Items = require("core.items")
local U = require("core.util")
local Deco = require("core.deco")
local Boss = require("core.boss")

local H = {}
H.FONT, H.SMALL, H.TITLE = "snes_body", "snes_small", "snes_title"

-- label(str, x, y, {color, align, font, scale}): text with the game's outline
function H.label(str, x, y, o)
  o = o or {}
  return text(str, x, y, {font = o.font or H.FONT, color = o.color or 0xFFFFFF, outline = o.outline or 0x2A1A3A, align = o.align, scale = o.scale or 1,
                          shadow = o.shadow, gradient = o.gradient, width = o.width})
end

function H.time_text(ticks)
  local sec = ticks // 60
  return string.format("%d:%02d", sec // 60, sec % 60)
end

-- a small dark plate behind a counter, so the numbers read over the busy wall
local function plate(str, x, y)
  local w = textw(str, {font = H.FONT})
  rect(x - 6, y - 4, w + 12, 24, 0x2A1A3A)
end

function H.draw(play)
  Deco.img("TOY_HEARTS", math.max(0, math.min(3, Hero.hearts)), 6, 7)
  local coins, creams, tc, ti = Items.counts()
  -- a coin and an ice cream with their counts
  Deco.img("TOY_HUD", 2, 2, 39)
  plate(coins .. "/" .. tc, 40, 47)
  H.label(coins .. "/" .. tc, 40, 47)
  Deco.img("TOY_HUD", 3, 108, 37)
  plate(creams .. "/" .. ti, 134, 47)
  H.label(creams .. "/" .. ti, 134, 47)
  local tt = H.time_text(play.time)
  rect(K.W - 12 - textw(tt, {font = H.FONT}) - 6, 6, textw(tt, {font = H.FONT}) + 12, 24, 0x2A1A3A)
  H.label(tt, K.W - 12, 10, {align = "right"})
  if Hero.has_scooter then
    Deco.img("TOY_HUD", Hero.s and Hero.s.scooter and 4 or 5, K.W - 72, 22)
  end
  Boss.hud(lang)
  if Hero.costume then -- the costume worn: its colour (and, for the football shirt, the time left of being unbeatable)
    local c = ({barretina = 0xD83A3A, dino = 0x72D84A, boots = 0x2E8A3E, futbol = 0xF4F4F4})[Hero.costume]
    rect(K.W - 118, 34, 30, 30, 0x2A1A3A)
    rect(K.W - 115, 37, 24, 24, c)
    local fut = Hero.s and Hero.s.fut_t or 0
    if fut > 0 then rect(K.W - 118, 66, math.floor(30 * fut / K.FUT_T), 4, 0xFFD43A) end
  end
  if play.toast_t > 0 then
    local a = play.toast_t < 20 and play.toast_t / 20 or 1
    local w = textw(play.toast, {font = H.FONT, width = 400})
    local x = (K.W - w) // 2
    rect(x - 12, 262 + (a < 1 and 8 or 0), w + 24, 34, 0x2A1A3A)
    H.label(play.toast, K.W // 2, 270 + (a < 1 and 8 or 0), {align = "center", width = 400, outline = 0x000000})
  end
end

return H
