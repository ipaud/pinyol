-- screens: the title (logo placeholder, a menu), the "how it works" card and the results. All words through lang; text fitted with textw / textbox.
local K = require("core.const")
local lang = require("lang")
local Bg = require("core.bgfx")
local Spr = require("core.spr")
local Hud = require("core.hud")
local In = require("core.input")
local Snd = require("core.sound")
local U = require("core.util")

local S = {}

local function panel(x, y, w, h)
  rect(x - 4, y - 4, w + 8, h + 8, 0x2A1A3A)
  rect(x, y, w, h, 0xFFF1D0)
  rect(x, y, w, 4, 0xFFFFFF)
  rect(x + 4, y + 4, w - 8, h - 8, 0xF3DDAE)
  rect(x + 8, y + 8, w - 16, h - 16, 0xFFF1D0)
end
S.panel = panel

-- ---------------------------------------------------------------- title

local title = {t = 0, sel = 1}
S.title = title
local ITEMS = {"title_start", "title_how"}

function title.enter() title.t, title.sel = 0, 1 end

function title.update()
  title.t = title.t + 1
  if In.btnp("up") or In.btnp("down") then
    title.sel = title.sel % #ITEMS + 1
    Snd.play("select")
  end
  if In.btnp("a") or In.btnp("start") then
    Snd.play("confirm")
    return title.sel == 1 and "start" or "how"
  end
end

function title.draw()
  local t = title.t
  local cx = t * 1.4
  Bg.scroll(cx, 128)
  Bg.mid(cx, 128)
  Bg.floor(cx, 224)
  -- Poncho on the floor, breathing, now and then looking round
  local f = Spr.seq("poncho", "idle", (t // 45) % 2)
  local cycle = t % 420
  if cycle > 300 then f = Spr.seq("poncho", "idle", (cycle - 300) // 8) end
  if f then Spr.draw("poncho", f, 392, 232) end
  Bg.fore(cx, 128)
  -- the logo: a placeholder in text
  local bob = math.floor(math.sin(t / 30) * 3)
  text(lang.tr("title_name"), 240, 10 + bob, {font = Hud.TITLE, scale = 3, align = "center", color = 0xFFE24A, gradient = 0xFF8A20, outline = 0x3A1A5A,
                                           shadow = 0x1A0A2A, shadow_x = 2, shadow_y = 2})
  text(lang.tr("title_sub"), 240, 80 + bob, {font = Hud.FONT, scale = 1, align = "center", color = 0xFFFFFF, outline = 0x3A1A5A})
  for i, key in ipairs(ITEMS) do
    local y = 128 + (i - 1) * 34
    local on = i == title.sel
    local str = lang.tr(key)
    local w = textw(str, {font = Hud.FONT})
    if on then
      rect(240 - w // 2 - 22, y - 5, w + 44, 28, 0x3A1A5A)
      local bx = 240 - w // 2 - 16 + (t // 10 % 2) * 2
      tri(bx, y + 1, bx, y + 17, bx + 9, y + 9, 0xFFE24A, true)
    end
    text(str, 240, y, {font = Hud.FONT, align = "center", color = on and 0xFFE24A or 0xFFFFFF, outline = 0x2A1A3A})
  end
  local best = stored("best", 0)
  if best > 0 then
    text(lang.tr("title_best", {time = Hud.time_text(best)}), 240, 290, {font = Hud.SMALL, align = "center", color = 0xFFFFFF, outline = 0x2A1A3A})
  end
end

-- ---------------------------------------------------------------- how it works

local how = {}
S.how = how
local LINES = {"how_1", "how_2", "how_3", "how_4", "how_5"}

function how.update()
  if In.btnp("b") or In.btnp("start") or In.btnp("a") then return true end
end

function how.draw(bgfn)
  if bgfn then bgfn() else rect(0, 0, K.W, K.H, 0x2A1A3A) end
  shade(0, 0, K.W, K.H)
  local x, y, w, h = 24, 14, K.W - 48, K.H - 28
  panel(x, y, w, h)
  text(lang.tr("how_title"), K.W // 2, y + 18, {font = Hud.FONT, scale = 1, align = "center", color = 0xC02050})
  -- every paragraph in one font: the biggest of the two in which all of them fit above the "back" line
  local tw, avail, gap = w - 56, h - 40 - 36, 5
  local font = Hud.SMALL
  for _, f in ipairs({Hud.FONT, Hud.SMALL}) do
    local total = 0
    for _, key in ipairs(LINES) do
      local _, th = textw(lang.tr(key), {font = f, width = tw})
      total = total + th + gap
    end
    if total <= avail then font = f break end
  end
  local ly = y + 40
  for _, key in ipairs(LINES) do
    local _, th = text(lang.tr(key), x + 28, ly, {font = font, width = tw, color = 0x3A2A4A})
    ly = ly + th + gap
  end
  text(lang.tr("how_back"), K.W // 2, y + h - 30, {font = Hud.SMALL, align = "center", color = 0x3E6AA8})
end

-- ---------------------------------------------------------------- results

local res = {t = 0}
S.results = res

function res.enter(info)
  res.t, res.info = 0, info
end

function res.update()
  res.t = res.t + 1
  if res.t > 90 and (In.btnp("a") or In.btnp("start")) then return true end
end

function res.draw(bgfn)
  if bgfn then bgfn() end
  shade(0, 0, K.W, K.H)
  local x, y, w, h = 70, 40, K.W - 140, 240
  panel(x, y, w, h)
  local i = res.info
  text(lang.tr("res_title"), K.W // 2, y + 22, {font = Hud.FONT, scale = 2, align = "center", color = 0xC02050})
  local rows = {
    {lang.tr("res_coins"), i.coins .. "/" .. i.total_coins},
    {lang.tr("res_creams"), i.creams .. "/" .. i.total_creams},
    {lang.tr("res_time"), Hud.time_text(i.time)},
    {lang.tr("res_best"), Hud.time_text(i.best)},
  }
  for n, r in ipairs(rows) do
    local yy = y + 74 + (n - 1) * 30
    text(r[1], x + 40, yy, {font = Hud.FONT, color = 0x3A2A4A})
    text(r[2], x + w - 40, yy, {font = Hud.FONT, color = 0x3A2A4A, align = "right"})
  end
  if res.t > 90 and (res.t // 30) % 2 == 0 or U.calm() then
    text(lang.tr("res_next"), K.W // 2, y + h - 34, {font = Hud.SMALL, align = "center", color = 0x3E6AA8})
  end
end

return S
