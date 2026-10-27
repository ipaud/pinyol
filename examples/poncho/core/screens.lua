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
local W = require("core.worlds")

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
local function items() -- with a saved game the menu also offers to continue (the world select)
  if W.any_progress() then return {"title_continue", "title_start", "title_how"} end
  return ITEMS
end
local PICK = {title_continue = "continue", title_start = "start", title_how = "how"}

function title.enter() title.t, title.sel = 0, 1 end

function title.update()
  title.t = title.t + 1
  local its = items()
  if In.btnp("up") then title.sel = (title.sel - 2) % #its + 1 Snd.play("select") end
  if In.btnp("down") then title.sel = title.sel % #its + 1 Snd.play("select") end
  for i = 1, #its do -- a tap on an item picks it
    if In.tap_in(150, 192 + (i - 1) * 34 - 6, 180, 32) then title.sel = i Snd.play("confirm") return PICK[its[i]] end
  end
  if In.btnp("a") or In.btnp("start") then
    Snd.play("confirm")
    return PICK[its[title.sel] or "title_start"]
  end
end

function title.back() -- the scene behind the title and the world select
  local t = title.t
  local cx = t * 1.4
  Bg.scroll(cx, 128)
  Bg.mid(cx, 128)
  Bg.floor(cx, 224)
end

function title.draw()
  local t = title.t
  local cx = t * 1.4
  title.back()
  -- Poncho on the floor, breathing, now and then looking round
  local f = Spr.seq("poncho", "idle", (t // 45) % 2)
  local cycle = t % 420
  if cycle > 300 then f = Spr.seq("poncho", "idle", (cycle - 300) // 8) end
  if f then Spr.draw("poncho", f, 392, 232) end
  Bg.fore(cx, 128)
  -- the logo (a picture of the word, from the image model) and the subtitle in the player's language
  local bob = math.floor(math.sin(t / 30) * 3)
  Deco.img("UI_LOGO_" .. lang.code:upper(), 0, 240, 2 + bob)
  text(lang.tr("touch_hint"), 240, 300, {font = Hud.SMALL, align = "center", color = 0xFFFFFF, outline = 0x2A1A3A})
  local ly = 180 + bob
  local its = items()
  rect(150, ly, 180, 8 + #its * 34, 0x2A1A3A) rect(150, ly, 180, 3, 0xFFD43A)
  for i, key in ipairs(its) do
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
  if In.btnp("a") or In.tapped then
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

-- ---------------------------------------------------------------- the world select: four cards, a world is open when the one before it is done

local sel = {i = 1}
S.select = sel
local ACCENT = {0xE8A040, 0xA8D060, 0xE8E8E8, 0x7070D0}

function sel.enter(i)
  sel.i = i or 1
  if not i then for w = #W.defs, 1, -1 do if W.unlocked(w) then sel.i = w break end end end -- the furthest one open
end

function sel.update()
  local n = #W.defs
  local i = sel.i
  if In.btnp("left") then i = (i - 2) % n + 1 end
  if In.btnp("right") then i = i % n + 1 end
  if In.btnp("up") or In.btnp("down") then i = (i + 1) % n + 1 end
  if i ~= sel.i then sel.i = i Snd.play("select") end
  if In.btnp("b") then return "back" end
  for w = 1, #W.defs do -- a tap on a card: the first tap picks it, a tap on the picked one plays it
    if In.tap_in(28 + ((w - 1) % 2) * 226, 52 + ((w - 1) // 2) * 124, 198, 108) then
      if sel.i == w and W.unlocked(w) then Snd.play("confirm") return w end
      sel.i = w Snd.play("select")
    end
  end
  if In.btnp("a") or In.btnp("start") then
    if W.unlocked(sel.i) then Snd.play("confirm") return sel.i end
    Snd.play("select")
  end
end

local function card(i, on)
  local d = W.defs[i]
  local x, y, w, h = 28 + ((i - 1) % 2) * 226, 52 + ((i - 1) // 2) * 124, 198, 108
  local open = W.unlocked(i)
  rect(x - 5, y - 5, w + 10, h + 10, on and 0xFFD43A or 0x2A1A3A)
  rect(x, y, w, h, open and 0xFFF1D0 or 0xB8AE98)
  rect(x, y, w, 30, ACCENT[i])
  textbox(lang.tr(d.name_key), x + 8, y + 2, w - 16, 26, {font = Hud.FONT, fonts = {Hud.FONT, Hud.SMALL}, color = 0x2A1A3A, valign = "middle", align = "center"})
  local status, col
  if not d.ready then status, col = lang.tr("select_soon"), 0x6A5A7A
  elseif not open then status, col = lang.tr("select_locked"), 0x6A5A7A
  elseif W.done(i) then status, col = lang.tr("select_done", {time = Hud.time_text(W.best(i))}), 0x2E7A3E
  else status, col = lang.tr("select_new"), 0xC02050 end
  textbox(status, x + 10, y + 46, w - 20, 50, {font = Hud.FONT, fonts = {Hud.FONT, Hud.SMALL}, color = col, valign = "middle", align = "center"})
end

function sel.draw(bgfn)
  if bgfn then bgfn() end
  shade(0, 0, K.W, K.H)
  text(lang.tr("select_title"), K.W // 2, 14, {font = Hud.FONT, scale = 1, align = "center", color = 0xFFE24A, outline = 0x2A1A3A})
  for i = 1, #W.defs do card(i, i == sel.i) end
  text(lang.tr("select_help"), K.W // 2, 296, {font = Hud.SMALL, align = "center", color = 0xFFFFFF, outline = 0x2A1A3A})
end

-- ---------------------------------------------------------------- the credits: a roll of text going up, and at the end the toy keyboard, his friend, playing

local cre = {t = 0}
S.credits = cre
-- {key, style}: "h" a heading, "t" a line of text; each takes one row of ROW pixels (a long line takes two)
local ROLL = {{"credits_title", "h"}, {"credits_1", "t"}, {"", "t"}, {"credits_h_worlds", "h"}, {"world_1", "t"}, {"world_2", "t"}, {"world_3", "t"}, {"world_4", "t"}, {"", "t"},
              {"credits_h_bosses", "h"}, {"boss_cuerda", "t"}, {"boss_sandia", "t"}, {"boss_paloma", "t"}, {"boss_silencio", "t"}, {"", "t"},
              {"credits_h_made", "h"}, {"credits_made", "t"}, {"credits_art", "t"}, {"", "t"}, {"credits_2", "t"}, {"", "t"}, {"credits_h_thanks", "h"}, {"credits_3", "t"}}
local ROW, SPEED = 34, 0.55
local STOP = (#ROLL - 1) * ROW + K.H + 20 - 165       -- how far it scrolls: the last row stops at y = 165
local END_T = math.floor(STOP / SPEED)               -- when that is

function cre.enter() cre.t = 0 end
function cre.update()
  cre.t = cre.t + 1
  if (In.btnp("a") or In.btnp("start") or In.tapped) and cre.t > 60 then
    if cre.t < END_T then cre.t = END_T else return true end -- the first press goes to the end, the next leaves
  end
  if cre.t > END_T + 600 then return true end
end

function cre.draw(bgfn)
  if bgfn then bgfn() end
  rect(0, 0, K.W, K.H, 0x1A1230)
  local scroll = math.min(cre.t, END_T) * SPEED
  for i, r in ipairs(ROLL) do
    local y = K.H + 20 + (i - 1) * ROW - scroll
    if y > -40 and y < K.H + 10 and r[1] ~= "" then
      if r[2] == "h" then
        text(lang.tr(r[1]), K.W // 2, y, {font = Hud.FONT, align = "center", color = 0xFFD43A, outline = 0x2A1A3A, slide = true})
      else
        text(lang.tr(r[1]), K.W // 2, y, {font = Hud.SMALL, align = "center", color = 0xFFFFFF, outline = 0x2A1A3A, width = 420, slide = true})
      end
    end
  end
  rect(0, 0, K.W, 34, 0x1A1230) -- (the rows go up under a bar)
  -- the end: the keyboard, his friend, playing, with a note rising
  local k = math.max(0, math.min(1, (cre.t - END_T + 60) / 60))
  if k > 0 then
    local fr = 2 + (cre.t // 6) % 4
    Deco.img("TOY_KEYBOARD", fr, K.W // 2, 300 + math.floor((1 - k) * 80))
    if cre.t > END_T then
      text(lang.tr("credits_next"), K.W // 2, 12, {font = Hud.SMALL, align = "center", color = 0x9FB8FF, outline = 0x2A1A3A})
    end
  end
end

-- ---------------------------------------------------------------- results

local res = {t = 0}
S.results = res

function res.enter(info)
  res.t, res.info = 0, info
end

function res.update()
  res.t = res.t + 1
  if res.t <= (res.info.final and 45 or 90) then return end
  if In.btnp("a") or In.btnp("start") or In.tapped then return res.info.final and "credits" or (res.info.next and "next" or "worlds") end
  if In.btnp("b") then return "worlds" end
end

function res.draw(bgfn)
  if bgfn then bgfn() end
  shade(0, 0, K.W, K.H)
  local x, y, w, h = 70, 40, K.W - 140, 240
  panel(x, y, w, h)
  local i = res.info
  text(lang.tr(i.final and "res_title_final" or "res_title"), K.W // 2, y + 22, {font = Hud.FONT, scale = 2, align = "center", color = 0xC02050})
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
  if res.info.final or (res.t > 90 and (res.t // 30) % 2 == 0) or U.calm() then -- (the last world's prompt is there at once)
    text(lang.tr(res.info.final and "credits_next" or (res.info.next and "res_next_world" or "res_worlds")), K.W // 2, y + h - 40, {font = Hud.SMALL, align = "center", color = 0x3E6AA8})
    if res.info.next and not res.info.final then text(lang.tr("res_worlds_b"), K.W // 2, y + h - 22, {font = Hud.SMALL, align = "center", color = 0x3E6AA8}) end
  end
end

return S
