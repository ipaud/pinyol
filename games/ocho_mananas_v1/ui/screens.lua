-- The screens around the race, drawn at 480x320: title, scenes, the briefing, the countdown, the practice's steps,
-- the close, the schematic review, the result and the notebook.
local frame = require("ui.frame")
local screens = {}

local NAVY, INK, WHITE, GOLD = 0x141B3A, 0x0B0F22, 0xF6F2E8, 0xFFE048
local RED, TEAL, TEAL_L, MUTED = 0xD8222E, 0x28967A, 0x96ECC8, 0x9AA0C8

local function card(x, y, w, h, look)
  frame.panel(look or "navy", x, y, w, h)
end

local function check(x, y, ok, label, colour)
  frame.icon(ok and "CHECK" or "CROSS", x - 4, y - 8, 28)
  text(label, x + 28, y, {font = "jersey_small", color = colour or WHITE})
end

-- --- title ---------------------------------------------------------------------------------------------------
local DATES = {"7 de julio", "8 de julio", "9 de julio", "10 de julio", "11 de julio", "12 de julio", "13 de julio", "14 de julio"}
function screens.title_items(save, sel_day)
  local d = sel_day or 1
  local suffix = (save.days[dk(d)] and save.days[dk(d)].done) and "  (repetir)" or ""
  local items = {{id = "day", text = "Mañana " .. d .. " · " .. DATES[d] .. suffix, pick = save.next > 1}}
  items[#items + 1] = {id = "practice", text = "Práctica · calle vacía"}
  if save.notes and next(save.notes) then items[#items + 1] = {id = "notebook", text = "Cuaderno"} end
  items[#items + 1] = {id = "look", text = "Mirada atrás: " .. (save.opts.look == "toggle" and "alternar" or "mantener C")}
  return items
end

function screens.title(save, sel, t)
  img("TITLE_ART", 0, 0)
  img("LOGO", 40, 2 + math.floor(math.sin(t / 40) * 2))
  local items = screens.title_items(save, sel_day)
  local h = 22 + #items * 22
  card(100, 312 - h, 280, h)
  local y = 312 - h + 12
  for i, it in ipairs(items) do
    local on = i == sel
    if on then frame.icon("SELECT", 112 + math.floor(math.sin(t / 8) * 2), y - 8, 26) end
    text(it.text, 250, y, {font = "jersey_small", align = "center", color = on and GOLD or WHITE})
    if it.pick and on then  -- the morning can be changed: arrows at both sides
      if sel_day > 1 then tri(134, y + 4, 140, y - 1, 140, y + 9, GOLD) end
      if sel_day < math.min(8, save.next) then tri(366, y + 4, 360, y - 1, 360, y + 9, GOLD) end
    end
    y = y + 22
  end
  if save.days[dk(1)] and save.days[dk(1)].done then
    frame.icon("CHECK", 440, 280, 30)
  end
end

-- --- scenes: who says what, one line at a time ----------------------------------------------------------------
local sc = nil
function screens.scene_start(scene)
  sc = {scene = scene, i = 1, chars = 0, t = 0}
end

-- for the tests: show line i of the scene, all of it
function screens.scene_goto(i) sc.i, sc.chars = math.min(i, #sc.scene.lines), 999 end
function screens.scene_lines() return #sc.scene.lines end

function screens.scene_update()
  sc.t = sc.t + 1
  local line_ = sc.scene.lines[sc.i]
  if not line_ then return true end
  sc.chars = sc.chars + 1.2
  if btnp("b") then return true end
  if btnp("a") and sc.t > 10 then
    if sc.chars < #line_[2] then sc.chars = 999
    else
      sc.i, sc.chars = sc.i + 1, 0
      sfx("BLIP", 0.2)
      if sc.i > #sc.scene.lines then return true end
    end
  end
  return false
end

function screens.scene_draw()
  local bgpic = sc.scene.bg or "PIC_TALLER"
  cls(0x10142C)
  local bw = imgsize(bgpic)
  img(bgpic, 0, 0, {scale = bw <= 240 and 2 or 1})  -- the old pictures are 240x160, the new ones 480x320
  frame.panel("ink", -8, -10, 496, 36)
  text(sc.scene.place, 12, 4, {font = "jersey_small", color = MUTED})
  local line_ = sc.scene.lines[math.min(sc.i, #sc.scene.lines)]
  if line_.pic then
    local w, h = imgsize(line_.pic)
    local k = w <= 120 and 3 or math.min(1, 170 / h)  -- the old pictures are tiny and shown at 3x, the prints at their size or smaller
    local x, y = 240 - math.floor(w * k / 2), (w <= 120 and 112 or 122) - math.floor(h * k / 2)
    rect(x - 8, y - 8, math.floor(w * k) + 16, math.floor(h * k) + 16, 0xF0E8D8)
    img(line_.pic, x, y, {scale = k})
  end
  frame.panel("navy", 8, 216, 464, 100)
  local who = line_[1]
  if who ~= "" then
    frame.panel("gold", 22, 202, textw(who, "jersey_small") + 28, 26)
    text(who, 36, 207, {font = "jersey_small", color = 0x3A2410})
  end
  text(line_[2], 30, 238, {font = "jersey_small", color = who == "" and MUTED or WHITE, width = 420,
                          chars = math.floor(sc.chars)})
  if sc.chars >= #line_[2] and (sc.t // 20) % 2 == 0 then tri(446, 296, 456, 296, 451, 302, GOLD) end
  text("A: seguir   B: saltar", 458, 290, {font = "jersey_small", color = 0x6A70A0, align = "right"})
end

-- --- briefing before the run ----------------------------------------------------------------------------------
function screens.prep(day, t, variants, variant)
  shade(0, 0, 480, 320)
  card(20, 8, 440, 304, "navy")
  text(string.upper(day.title .. " · " .. day.date), 240, 20, {font = "jersey_body", align = "center", color = GOLD})
  text("«" .. day.subtitle .. "» · " .. (day.street or ""), 240, 46, {font = "jersey_small", align = "center", color = MUTED})
  text("Objetivo", 48, 66, {font = "jersey_small", color = GOLD})
  text(day.objective, 48, 82, {font = "jersey_small", color = WHITE, width = 390})
  local y = 104
  if variants then  -- the stretch to run: picked with left and right, every one known
    text("Tramo", 48, y + 4, {font = "jersey_small", color = GOLD})
    local x = 108
    for i, v in ipairs(variants) do
      local on = i == variant
      rect(x, y, 160, 24, on and GOLD or 0x5A6290)
      rect(x + 2, y + 2, 156, 20, on and 0xF6E8B0 or 0x232A52)
      text(v.name, x + 80, y + 5, {font = "jersey_small", color = on and 0x3A2410 or WHITE, align = "center"})
      x = x + 170
    end
    text("izq/der · " .. (variants[variant].note or ""), 108, y + 30, {font = "jersey_small", color = MUTED})
    y = y + 50
  else
    y = y + 6
  end
  text("Retos opcionales", 48, y, {font = "jersey_small", color = GOLD})
  for i, c in ipairs(day.challenges) do text("· " .. c.text, 56, y + i * 17, {font = "jersey_small", color = WHITE}) end
  -- the street's map: the ways out are known before running
  local x0, x1, my = 70, 410, 250
  rect(x0, my - 6, x1 - x0, 12, 0x2A3058)
  for _, zn in ipairs(day.zones) do
    local a = x0 + zn.z0 / day.length * (x1 - x0)
    local b = x0 + zn.z1 / day.length * (x1 - x0)
    rect(math.floor(a), zn.side < 0 and my - 12 or my + 6, math.floor(b - a), 6, TEAL)
    text(zn.id, math.floor((a + b) / 2), zn.side < 0 and my - 26 or my + 13, {font = "jersey_small", align = "center", color = TEAL_L})
  end
  tri(x0 - 12, my - 6, x0 - 12, my + 6, x0 - 4, my, GOLD)
  text("inicio", x0 - 22, my + 13, {font = "jersey_small", color = MUTED})
  text("fin", x1 + 6, my - 6, {font = "jersey_small", color = MUTED})
  if day.photo then  -- Nico's balcony on the map
    local px = x0 + day.photo.at / day.length * (x1 - x0)
    rect(math.floor(px) - 5, day.photo.side < 0 and my - 13 or my + 7, 10, 7, 0xC8C8D8)
    circ(math.floor(px), day.photo.side < 0 and my - 10 or my + 10, 2, INK)
  end
  if (t // 25) % 2 == 0 then text("A: a la calle   B: volver", 240, 286, {font = "jersey_small", align = "center", color = GOLD}) end
end

function screens.countdown(t)
  local s = t // 60
  if s < 5 then
    local pulse = 1 - (t % 60) / 60  -- the number is struck on the second and fades slowly
    frame.panel("navy", 200, 88, 80, 84)
    text(tostring(5 - s), 240, 96, {font = "jersey_title", scale = 2, align = "center", color = pulse > 0.5 and WHITE or 0xD8D2C0,
                                    outline = INK})
  elseif t < 330 then
    frame.panel("red", 100, 96, 280, 76)
    text("¡COHETE!", 240, 118, {font = "jersey_title", scale = 1, align = "center", color = GOLD, outline = INK, shake = 1})
  end
end

function screens.look_frame(plate_y)
  rect(0, 29, 480, 3, 0xF0A040)
  rect(0, 316, 480, 4, 0xF0A040)
  rect(0, 29, 3, 291, 0xF0A040)
  rect(477, 29, 3, 291, 0xF0A040)
  frame.panel("gold", 184, plate_y - 4, 112, 26)
  text("MIRANDO ATRÁS", 240, plate_y + 1, {font = "jersey_small", align = "center", color = 0x3A2410})
end

function screens.tutorial(step, tut, r)
  local s = step or "¡Bien! Así se cierra una carrera."
  local w = 440
  frame.panel("navy", 20, 242, w, 70)
  frame.panel("teal", 30, 228, 64, 28)
  text("Leire", 62, 235, {font = "jersey_small", color = WHITE, align = "center"})
  text(s, 34, 262, {font = "jersey_small", color = WHITE, width = w - 28})
  text(math.min(tut.step, 5) .. "/5", 446, 248, {font = "jersey_small", color = 0xC8D0E8, align = "right"})
end

local CLOSE = {
  retirada = {"RETIRADA", TEAL}, fin = {"FIN DE TRAMO", TEAL},
  contacto = {"CONTACTO", RED}, bloqueada = {"SIN HUECO", RED}, agotamiento = {"SIN AIRE", RED}, caida = {"AL SUELO", RED},
}
function screens.close(r)
  local o = r.over
  local k = o.result == "fallo" and o.reason or o.result
  local c = CLOSE[k] or {"FIN", WHITE}
  frame.panel(c[2] == TEAL and "teal" or "red", -10, 112, 500, 80)
  text(c[1], 240, 134, {font = "jersey_body", scale = 2, align = "center", color = WHITE, outline = INK})
end

function screens.pause()
  shade(0, 0, 480, 320)
  card(130, 100, 220, 110, "gold")
  text("PAUSA", 240, 118, {font = "jersey_body", align = "center", color = 0x3A2410})
  text("START: seguir", 240, 154, {font = "jersey_small", align = "center", color = 0x3A2410})
  text("B: abandonar", 240, 176, {font = "jersey_small", align = "center", color = 0x6A3A20})
end

-- --- the review: the last seconds seen from above, a schematic (not a camera Dani carries) ----------------------
function screens.review(r, res, t)
  local rec = r.rec
  text("REVISIÓN", 20, 10, {font = "jersey_body", color = GOLD})
  text("Los últimos segundos, desde arriba", 460, 16, {font = "jersey_small", align = "right", color = MUTED})
  local n = #rec
  if n == 0 then return end
  local first = math.max(1, n - 140)
  local span = n - first + 1
  local pos = (t // 3) % (span + 40)
  local wi = res.warn_i and res.warn_i >= first and res.warn_i - first or nil
  local hold = false
  if wi and pos >= wi then   -- stop a moment where it could already be seen
    if pos < wi + 20 then pos, hold = wi, true else pos = pos - 20 end
  end
  local i = math.min(n, first + pos)
  local s = rec[i]
  local x0, x1, cy, half = 20, 460, 140, 64
  local zc = s.dz
  local function X(z) return x0 + (z - (zc - 170)) / 300 * (x1 - x0) end
  local function Y(x) return cy + x / 32 * half end
  frame.panel("ink", x0 - 10, cy - half - 20, x1 - x0 + 20, half * 2 + 40)
  rect(x0, cy - half - 6, x1 - x0, half * 2 + 12, 0x5E5670)
  rect(x0, cy - half - 10, x1 - x0, 4, 0xC8A070)
  rect(x0, cy + half + 6, x1 - x0, 4, 0xC8A070)
  for z = math.floor((zc - 170) / 30) * 30, zc + 130, 30 do
    local x = X(z)
    if x > x0 and x < x1 then line(x, cy - half - 6, x, cy + half + 6, 0x6E6680) end
  end
  for _, zn in ipairs(r.zones) do
    local a, b = math.max(x0, X(zn.z0)), math.min(x1, X(zn.z1))
    if b > a then rect(math.floor(a), zn.side < 0 and cy - half - 10 or cy + half + 6, math.floor(b - a), 4, TEAL_L) end
  end
  for _, p in ipairs(s.ru) do
    local x = X(p[2])
    if x > x0 and x < x1 then
      if p[3] then rect(math.floor(x) - 6, math.floor(Y(p[1])) - 3, 12, 6, 0xFF9080)
      else circ(math.floor(x), math.floor(Y(p[1])), 4, WHITE) end
    end
  end
  for _, p in ipairs(s.b) do
    local x = X(p[2])
    if x > x0 + 10 and x < x1 then
      local yy = math.floor(Y(p[1]))
      rect(math.floor(x) - 14, yy - 5, 16, 10, p[3] and 0x241A20 or 0xE4D4B6)
      line(math.floor(x) + 2, yy - 5, math.floor(x) + 6, yy - 8, 0xEEE0B8)
      line(math.floor(x) + 2, yy + 4, math.floor(x) + 6, yy + 7, 0xEEE0B8)
    end
  end
  if wi and i >= first + wi then
    for _, p in ipairs(s.b) do
      if s.dz - p[2] > -22 and s.dz - p[2] < 160 and math.abs(p[1] - s.dx) < 10 then
        local bx, by = math.floor(X(p[2])) - 6, math.floor(Y(p[1]))
        if bx > x0 and bx < x1 then
          circ(bx, by, 13, 0xFF5040, false)
          circ(bx, by, 14, 0xFF5040, false)
        end
      end
    end
    if hold or i == first + wi then
      local msg = string.format("Aquí ya venía por tu carril: %.1f s antes", res.warn_s)
      local w = textw(msg, "jersey_small") + 20
      rect(240 - w // 2, 52, w, 24, 0x7A2430)
      text(msg, 240, 54, {font = "jersey_small", align = "center", color = WHITE})
    end
  end
  local dx, dy = math.floor(X(s.dz)), math.floor(Y(s.dx))
  for k = math.max(1, i - 6), i do
    if rec[k].ph then
      circ(dx, dy, 16, GOLD, false)
      text("FOTO", dx, dy - 34, {font = "jersey_small", align = "center", color = GOLD})
    end
  end
  circ(dx, dy, 6, INK)
  circ(dx, dy, 5, s.st == "down" and RED or GOLD)
  tri(dx + 7, dy - 4, dx + 7, dy + 4, dx + 12, dy, GOLD)
  text("sentido de la carrera >", x1, cy + half + 14, {font = "jersey_small", align = "right", color = MUTED})
  local secs = (s.t - rec[n].t) / 60
  text(string.format("%.1f s", secs), x0, cy + half + 14, {font = "jersey_small", color = MUTED})
  card(20, 238, 440, 72, res.closed and "teal" or "red")
  text(res.note, 34, 250, {font = "jersey_small", color = WHITE, width = 412})
  if t > 30 then text("A: seguir", 452, 290, {font = "jersey_small", color = GOLD, align = "right"}) end
end

function screens.result(r, res, t)
  card(24, 12, 432, 296, res.closed and "teal" or "red")
  local day = r.day
  text(string.upper(day.title .. " · " .. day.date), 240, 24, {font = "jersey_body", align = "center", color = GOLD})
  local head = res.closed and (res.result == "retirada" and "Carrera cerrada por una retirada" or "Carrera cerrada al final del tramo")
               or "La carrera no ha terminado bien"
  text(head, 240, 56, {font = "jersey_small", align = "center", color = WHITE, shadow = INK})
  local y = 92
  check(56, y, res.objective, "Objetivo: retirada sin quedarte sin aire")
  for _, c in ipairs(day.challenges or {}) do
    y = y + 28
    check(56, y, res.ch[c.id], c.text)
  end
  text("Contactos: " .. res.contacts .. (res.air_zero and " · te quedaste sin aire" or ""), 56, y + 32,
       {font = "jersey_small", color = WHITE, shadow = INK})
  if res.closed then
    text("A: seguir   B: repetir la mañana", 240, 270, {font = "jersey_small", align = "center", color = GOLD})
  else
    text("A: reintentar   B: menú", 240, 270, {font = "jersey_small", align = "center", color = GOLD})
    text("El reintento empieza en la cuenta atrás y no repite escenas.", 240, 246, {font = "jersey_small", align = "center", color = WHITE, shadow = INK})
  end
end

function screens.notebook(save, page)
  img("NOTEBOOK", 0, 0)
  text("CUADERNO DE DANI", 240, 4, {font = "jersey_body", align = "center", color = GOLD, outline = INK})
  local d = page or 1
  local nb = save.notes[dk(d)] or {}
  local labels = {R1 = "la primera", R2 = "la segunda", R3 = "la tercera"}
  local INKC, SOFT = 0x2A1E18, 0x6A4A38
  local x, w = 256, 176
  text("Mañana " .. d .. " · " .. DATES[d]:gsub(" de julio", " jul"), x, 118, {font = "jersey_small", color = SOFT})
  text("Entrada: inicio del tramo", x, 134, {font = "jersey_small", color = INKC, width = w})
  text("Salida: " .. (nb.zone and labels[nb.zone] or nb.result == "fin" and "final del tramo" or "ninguna"), x, 150,
       {font = "jersey_small", color = INKC, width = w})
  local day = save.days[dk(d)] or {}
  local got = day.photo
  if d == 1 or d == 8 then
    frame.icon(got and "CHECK" or "CROSS", x - 4, 164, 24)
    text(got and "Foto de Nico: sí" or "Foto de Nico: no", x + 22, 170, {font = "jersey_small", color = INKC})
  end
  local done = 0
  for _ in pairs(day.ch or {}) do done = done + 1 end
  local won = 0
  for _, ok in pairs(day.ch or {}) do if ok then won = won + 1 end end
  if done > 0 then text("Retos: " .. won .. " de " .. done, x, 190, {font = "jersey_small", color = INKC}) end
  text(nb.note and #nb.note < 90 and nb.note or "", x, 214, {font = "jersey_small", color = INKC, width = w})
  text("‹ " .. d .. " / " .. math.max(1, (function() local n = 0; for k = 1, 8 do if save.notes[dk(k)] then n = k end end return n end)()) .. " ›", 240, 276,
       {font = "jersey_small", color = 0xF6F2E8, align = "center", outline = INK})
  text("A o B: volver", 240, 292, {font = "jersey_small", color = 0xF6F2E8, align = "center", outline = INK})
end

-- the end of the campaign: which of the three endings, with the picture that went into the sleeve
local END_PIC = {secuencia = "PIC_TIRA", foto = "PIC_NICO_OK", otra = "PIC_NICO"}
function screens.finale(save, t)
  local st = require("story.days")
  local e = save.ending or "secuencia"
  img("NOTEBOOK", 0, 0)
  frame.panel("navy", 20, 24, 440, 232)
  text("14 DE JULIO", 240, 34, {font = "jersey_small", color = MUTED, align = "center"})
  text(st.TITLES[e], 240, 54, {font = "jersey_body", color = GOLD, align = "center"})
  local w, h = imgsize(END_PIC[e])
  local k = math.min(0.62, 150 / h, 240 / w)
  local px, py = 40, 92
  rect(px - 6, py - 6, math.floor(w * k) + 12, math.floor(h * k) + 12, 0xF0E8D8)
  img(END_PIC[e], px, py, {scale = k})
  local tx = px + math.floor(w * k) + 24
  local tw = 440 - tx  -- up to the panel's inner edge
  text(st.NOTES[e], tx, 100, {font = "jersey_small", color = WHITE, width = tw})
  text("Ocho mañanas. Una carrera tuya.", tx, 170, {font = "jersey_small", color = 0xC8D0E8, width = tw})
  local good = 0
  for d = 1, 8 do for _, ok in pairs((save.days[dk(d)] or {}).ch or {}) do if ok then good = good + 1 end end end
  text("Retos cumplidos: " .. good, tx, 218, {font = "jersey_small", color = GOLD})
  if t > 30 and (t // 25) % 2 == 0 then text("A: volver al título", 240, 238, {font = "jersey_small", color = GOLD, align = "center"}) end
end

return screens
