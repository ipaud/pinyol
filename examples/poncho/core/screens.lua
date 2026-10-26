-- screens: the title (logo placeholder, a menu), the "how it works" card and the results. All words through lang; text fitted with textw / textbox.
local K = require("core.const")
local lang = require("lang")
local Bg = require("core.bgfx")
local Deco = require("core.deco")
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
  -- the logo (a picture of the word, from the image model) and the subtitle in the player's language
  local bob = math.floor(math.sin(t / 30) * 3)
  Deco.img("UI_LOGO_" .. lang.code:upper(), 0, 240, 2 + bob)
  local ly = 180 + bob
  rect(150, ly, 180, 76, 0x2A1A3A) rect(150, ly, 180, 3, 0xFFD43A)
  for i, key in ipairs(ITEMS) do
    local y = 192 + (i - 1) * 34
    local on = i == title.sel
    local str = lang.tr(key)
    local w = textw(str, {font = Hud.FONT})
    if on then
      rect(240 - w // 2 - 22, y - 5, w + 44, 28, 0x5A2E8A)
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

local how = {page = 1}
S.how = how
local PAGES = {"move", "scooter", "costumes"}
local LINES = 4 -- lines to a page: how_<page>_1 .. how_<page>_4, at the body font

function how.update()
  if In.btnp("right") then how.page = how.page % #PAGES + 1 Snd.play("select") end
  if In.btnp("left") then how.page = (how.page - 2) % #PAGES + 1 Snd.play("select") end
  if In.btnp("b") or In.btnp("start") then how.page = 1 return true end
  if In.btnp("a") then
    if how.page >= #PAGES then how.page = 1 return true end
    how.page = how.page + 1
    Snd.play("select")
  end
end

function how.draw(bgfn)
  if bgfn then bgfn() else rect(0, 0, K.W, K.H, 0x2A1A3A) end
  shade(0, 0, K.W, K.H)
  local x, y, w, h = 20, 12, K.W - 40, K.H - 24
  panel(x, y, w, h)
  local key = PAGES[how.page]
  text(lang.tr("how_" .. key), K.W // 2, y + 16, {font = Hud.FONT, scale = 1, align = "center", color = 0xC02050})
  local ly = y + 44
  for i = 1, LINES do
    local str = lang.tr("how_" .. key .. "_" .. i)
    textbox(str, x + 26, ly, w - 52, 46, {font = Hud.FONT, fonts = {Hud.FONT, Hud.SMALL}, color = 0x3A2A4A, valign = "middle"})
    ly = ly + 48
  end
  text(lang.tr("how_page", {n = how.page, m = #PAGES}), K.W // 2, y + h - 26, {font = Hud.SMALL, align = "center", color = 0x3E6AA8})
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
