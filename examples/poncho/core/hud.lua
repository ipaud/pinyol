-- hud: hearts, coins, ice creams, the clock and a note at the foot of the screen. Text in the game's own fonts, through lang.
local K = require("core.const")
local lang = require("lang")
local Hero = require("core.hero")
local Items = require("core.items")
local U = require("core.util")
local Deco = require("core.deco")
local Boss = require("core.boss")
local W = require("core.worlds")
local Beat = require("core.beat")

local H = {}
H.FONT, H.SMALL, H.TITLE = "snes_body", "snes_small", "snes_title"

-- label(str, x, y, {color, align, font, scale}): text with the game's outline
local lo = {}
function H.label(str, x, y, o)
  o = o or lo
  local opts = H.opts
  opts.font, opts.color, opts.outline, opts.align, opts.scale = o.font or H.FONT, o.color or 0xFFFFFF, o.outline or 0x2A1A3A, o.align, o.scale or 1
  opts.shadow, opts.gradient, opts.width = o.shadow, o.gradient, o.width
  return text(str, x, y, opts)
end
H.opts = {}

-- the width of a text in the HUD's font, worked out once per text (a frame asks for the same few)
local widths = {}
local function width(str)
  local w = widths[str]
  if not w then w = textw(str, {font = H.FONT}) widths[str] = w end
  return w
end

-- "3/66" and the like: put together again only when the numbers change
local pair_a, pair_b, pair_s = {}, {}, {}
local function pair(slot, a, b)
  if pair_a[slot] ~= a or pair_b[slot] ~= b then pair_a[slot], pair_b[slot], pair_s[slot] = a, b, a .. "/" .. b end
  return pair_s[slot]
end

function H.time_text(ticks)
  local sec = ticks // 60
  return string.format("%d:%02d", sec // 60, sec % 60)
end

-- a small dark plate behind a counter, so the numbers read over the busy wall
local function plate(str, x, y)
  rect(x - 6, y - 4, width(str) + 12, 24, 0x2A1A3A)
end

function H.draw(play)
  Deco.img("TOY_HEARTS", math.max(0, math.min(3, Hero.hearts)), 6, 7)
  local coins, creams, tc, ti = Items.counts()
  -- a coin and an ice cream with their counts
  Deco.img("TOY_HUD", 2, 2, 39)
  local cs = pair(1, coins, tc)
  plate(cs, 40, 47)
  H.label(cs, 40, 47)
  Deco.img("TOY_HUD", 3, 108, 37)
  local is = pair(2, creams, ti)
  plate(is, 134, 47)
  H.label(is, 134, 47)
  local tt = H.time_text(play.time)
  rect(K.W - 12 - width(tt) - 6, 6, width(tt) + 12, 24, 0x2A1A3A)
  H.label(tt, K.W - 12, 10, {align = "right"})
  if Hero.has_scooter then
    Deco.img("TOY_HUD", Hero.s and Hero.s.scooter and 4 or 5, K.W - 72, 22)
  end
  Boss.hud(lang)
  if W.theme.beat then -- the beat: a dot that swells on every beat of the stage
    circ(K.W // 2, 306, 4 + math.floor(Beat.pulse() * 6), 0xFFE070, true)
  end
  if Hero.costume then -- the costume worn: its colour (and, for the football shirt, the time left of being unbeatable)
    local c = ({barretina = 0xD83A3A, dino = 0x72D84A, boots = 0x2E8A3E, futbol = 0xF4F4F4})[Hero.costume]
    rect(K.W - 118, 34, 30, 30, 0x2A1A3A)
    rect(K.W - 115, 37, 24, 24, c)
    local fut = Hero.s and Hero.s.fut_t or 0
    if fut > 0 then rect(K.W - 118, 66, math.floor(30 * fut / K.FUT_T), 4, 0xFFD43A) end
  end
  if play.toast_t > 0 then
    local up = Boss.rhythm_round() and -150 or 0 -- (in a rhythm round the keys are at the foot of the screen: the note goes higher)
    local a = play.toast_t < 20 and play.toast_t / 20 or 1
    local w = textw(play.toast, {font = H.FONT, width = 400})
    local x = (K.W - w) // 2
    rect(x - 12, 262 + up + (a < 1 and 8 or 0), w + 24, 34, 0x2A1A3A)
    H.label(play.toast, K.W // 2, 270 + up + (a < 1 and 8 or 0), {align = "center", width = 400, outline = 0x000000})
  end
end

return H
