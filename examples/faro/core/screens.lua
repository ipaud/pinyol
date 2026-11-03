-- the screens around the climb: the title (the lighthouse dark in the storm), the story before it, the dawn after it, and the night it is lost.
local H = require("core.hud")
local S = require("core.sound")
local Run = require("core.run")
local lang = require("lang")
local Scr = {}

local rain_far, rain_near
local function rain_init()
  rain_far = swarm(200, {-40, -40, 520, 360})
  rain_near = swarm(80, {-40, -40, 520, 360})
end
local function rain(t, strength)
  if not rain_far then rain_init() end
  for _ = 1, math.floor(4 * strength) do rain_far:add(math.random(-40, 520), -20, -1.4, 5.5, 80) end
  for _ = 1, math.floor(2 * strength) do rain_near:add(math.random(-40, 520), -30, -2.4, 9.5, 50) end
  rain_far:step()
  rain_near:step()
end
local function rain_draw()
  if not rain_far then rain_init() end -- (on the console a frame can be drawn before the first tick)
  rain_far:draw("FX_RAIN_FAR", {alpha = 0.55}) -- far drops half seen through, near ones add their light
  rain_near:draw("FX_RAIN_NEAR", {add = true, alpha = 0.8})
end

-- ------------------------------------------------------------------ title

local T = {t = 0, sel = 1, flash = 0, next = 160}
Scr.title = T
local ITEMS = {"m_start", "m_how", "m_crt"}

function T.enter()
  T.t, T.flash, T.next = 0, 0, 160
  S.music("titulo", 800)
  S.room("outside")
  S.ambient("RAIN")
end

-- returns "start", "how" or nil; the CRT switch is handled here
function T.update(best)
  T.t = T.t + 1
  rain(T.t, 1)
  if T.flash > 0 then T.flash = T.flash - 1 end
  T.next = T.next - 1
  if T.next <= 0 then
    T.next = 380 + (T.t * 53) % 300
    T.flash = 10
    S.play("THUNDER", {delay = 0.6, gain = 0.7})
  end
  if btnp("up") then T.sel = (T.sel - 2) % #ITEMS + 1 S.play("BLIP") end
  if btnp("down") then T.sel = T.sel % #ITEMS + 1 S.play("BLIP") end
  if btnp("a") or btnp("start") then
    S.play("OK")
    local it = ITEMS[T.sel]
    if it == "m_start" then return "start" end
    if it == "m_how" then return "how" end
    if it == "m_crt" then return "crt" end
  end
  return nil
end

function T.draw(best, crt_on)
  local f = T.flash / 10
  if settings().reduce_flashing then f = f * 0.3 end
  img("BG_TITLE", 0, 0, {dim = 0.82 + 0.18 * f})
  -- the lamp is out: only the faintest glow left in its glass
  light(428, 44, 16, 0x605040, {intensity = 0.4 + 0.2 * math.sin(T.t * 0.05)})
  rain_draw()
  text(lang.tr("title1"), 150, 26, {font = H.TITLE, align = "center", color = 0xFFF4D0, gradient = 0xE8A040, outline = 0x1A1020, shadow = 0x000000})
  text(lang.tr("title2"), 150, 64, {font = H.TITLE, align = "center", color = 0xFFF4D0, gradient = 0xE8A040, outline = 0x1A1020, shadow = 0x000000})
  if G.cover then return end -- the cover (tools/cover.py --from): the storm and the title only
  local y0 = 136
  H.panel(30, y0 - 10, 240, 3 * 26 + 16)
  for i, key in ipairs(ITEMS) do
    local label = lang.tr(key, {v = lang.tr(crt_on and "on" or "off")})
    local y = y0 + (i - 1) * 26
    local on = i == T.sel
    if on then light(46, y + 9, 22, 0xFFB050, {intensity = 0.8 + 0.2 * math.sin(T.t * 0.15)}) end
    textbox(label, 62, y, 200, 22, {font = H.BODY, color = on and 0xFFE7A0 or 0xA8B0C8, valign = "middle", fonts = {H.SMALL}})
  end
  local b = best and lang.tr("best", {t = H.time(best)}) or lang.tr("nobest")
  textbox(b, 30, 232, 240, 18, {font = H.SMALL, color = 0xD0D8F0, align = "center", shadow = 0x000000, fonts = {H.SMALL}})
  grad(0, 290, 480, 30, 0x000000, 0x000000, {alpha = 0.6})
  textbox(lang.tr("keys_title"), 10, 298, 460, 18, {font = H.SMALL, color = 0xB0B8D0, align = "center"})
end

-- ------------------------------------------------------------------ the story

local I = {t = 0, line = 1}
Scr.intro = I
function I.enter() I.t, I.line = 0, 1 S.music("torre", 1500) S.room("hall") S.ambient("SEA") end
-- true when it is over
function I.update()
  I.t = I.t + 1
  local full = #lang.tr("intro" .. I.line)
  if btnp("a") or btnp("start") then
    if I.t < full then I.t = full + 1
    else
      I.line, I.t = I.line + 1, 0
      if I.line > 3 then return true end
      S.play("BLIP")
    end
  end
  return false
end
function I.draw()
  img("BG_F1", 0, -400, {dim = 0.35})
  light(150, 260, 70, 0xFFA850, {intensity = 0.6 + 0.05 * math.sin(I.t * 0.3)})
  local s = lang.tr("intro" .. math.min(3, I.line))
  H.panel(40, 70, 400, 120)
  textbox(s, 56, 82, 368, 96, {font = H.BODY, color = 0xF0F0FF, chars = I.t, fonts = {H.SMALL}})
  if I.t > #s then text(lang.tr("skip"), 424, 194, {font = H.SMALL, align = "right", color = 0xFFE0A0}) end
end

-- ------------------------------------------------------------------ the dawn

local D = {t = 0}
Scr.ending = D
function D.enter(stats)
  D.t, D.stats = 0, stats
  S.music("fin", 1500)
  S.room("outside")
  S.ambient("SEA")
end
function D.update()
  D.t = D.t + 1
  return D.t > 600 and (btnp("a") or btnp("start"))
end
function D.draw()
  img("BG_ENDING", 0, 0)
  local ang = 180 + 50 * math.sin(D.t * 0.012)
  light(427, 55, 460, 0xFFF0C0, {cone = {angle = ang, width = 16}, intensity = 0.55})
  light(427, 55, 18, 0xFFFFE0, {intensity = 1})
  local y = 18
  for i = 1, 3 do
    local start = (i - 1) * 150
    if D.t > start then
      local s = lang.tr("end" .. i)
      local _, h = textw(s, {font = H.BODY, width = 300})
      H.panel(14, y - 6, 316, h + 12)
      text(s, 22, y, {font = H.BODY, width = 300, color = 0xFFF6E8, chars = (D.t - start) // 1})
      y = y + h + 16
    end
  end
  if D.t > 450 then
    local st = D.stats
    textbox(lang.tr("end_stats", {t = H.time(st.ticks), n = st.freed, s = st.score}), 14, y, 316, 20, {font = H.SMALL, color = 0xFFE0A0, fonts = {H.SMALL}})
    if st.record then text(lang.tr("new_best"), 22, y + 22, {font = H.BODY, color = 0xFFFFFF, gradient = 0xFFC040}) end
  end
  if D.t > 540 then text(lang.tr("the_end"), 240, 268, {font = H.TITLE, align = "center", color = 0xFFF4D0, gradient = 0xE8A040, outline = 0x1A1020}) end
end

-- ------------------------------------------------------------------ the night is lost

local O = {t = 0}
Scr.over = O
function O.enter() O.t = 0 S.stop() S.ambient("RAIN") end
function O.update() O.t = O.t + 1 return O.t > 120 and (btnp("a") or btnp("start")) end
function O.draw()
  img("BG_TITLE", 0, 0, {dim = 0.35})
  H.panel(60, 110, 360, 90)
  textbox(lang.tr("over"), 70, 118, 340, 40, {font = H.TITLE, align = "center", color = 0xC8D8FF, gradient = 0x6070B0, fonts = {H.BODY}})
  textbox(lang.tr("over2"), 70, 162, 340, 30, {font = H.BODY, align = "center", color = 0xE0E4F0, fonts = {H.SMALL}})
  if O.t > 120 then text(lang.tr("press"), 240, 230, {font = H.SMALL, align = "center", color = 0xFFE0A0}) end
end

return Scr
