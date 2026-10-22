-- The screens around the race, drawn at 480x320: title, scenes, the briefing, the countdown, the practice's steps,
-- the close, the schematic review, the result and the notebook.
local screens = {}

local NAVY, INK, WHITE, GOLD = 0x141B3A, 0x0B0F22, 0xF6F2E8, 0xFFE048
local RED, TEAL, TEAL_L, MUTED = 0xD8222E, 0x28967A, 0x96ECC8, 0x9AA0C8

local function card(x, y, w, h, edge)
  rect(x, y, w, h, INK)
  box(x, y, w, h, edge or 0x5A6290)
  box(x + 2, y + 2, w - 4, h - 4, 0x232A52)
end

local function check(x, y, ok, label, colour)
  rect(x, y + 2, 14, 14, ok and TEAL or 0x2A3058)
  box(x, y + 2, 14, 14, ok and TEAL_L or 0x5A6290)
  if ok then
    line(x + 3, y + 9, x + 6, y + 12, WHITE)
    line(x + 6, y + 12, x + 11, y + 5, WHITE)
  end
  text(label, x + 22, y, {font = "gba_body", color = colour or WHITE})
end

-- --- title ---------------------------------------------------------------------------------------------------
function screens.title_items(save)
  local items = {{id = "day1", text = save.days[1] and save.days[1].done and "Mañana 1 · 7 de julio  (repetir)" or "Mañana 1 · 7 de julio"},
                 {id = "practice", text = "Práctica · calle vacía"}}
  if save.notebook then items[#items + 1] = {id = "notebook", text = "Cuaderno"} end
  items[#items + 1] = {id = "look", text = "Mirada atrás: " .. (save.opts.look == "toggle" and "alternar" or "mantener C")}
  return items
end

function screens.title(save, sel, t)
  shade(0, 0, 480, 320)
  text("07:59", 240, 40, {font = "gba_title", scale = 4, align = "center", color = WHITE, gradient = 0xF6C890,
                          outline = INK, shadow = 0x000000, shadow_x = 2, shadow_y = 2})
  text("OCHO MAÑANAS", 240, 118, {font = "gba_title", scale = 2, align = "center", color = GOLD, gradient = 0xF08040,
                                   outline = INK})
  text("Un juego de encierros", 240, 164, {font = "gba_small", scale = 2, align = "center", color = MUTED})
  local items = screens.title_items(save)
  local y = 196
  for i, it in ipairs(items) do
    local on = i == sel
    if on then
      rect(110, y - 2, 260, 24, 0x2A3466)
      tri(118, y + 4, 118, y + 16, 126, y + 10, GOLD)
    end
    text(it.text, 240, y, {font = "gba_body", align = "center", color = on and WHITE or MUTED})
    y = y + 25
  end
  text("Prototipo · v0.1 · Pinyol", 8, 304, {font = "gba_small", scale = 2, color = 0x6A70A0})
  if save.days[1] and save.days[1].done then
    text("Mañana 1 completada", 472, 304, {font = "gba_small", scale = 2, color = TEAL_L, align = "right"})
  end
end

-- --- scenes: who says what, one line at a time ----------------------------------------------------------------
local sc = nil
function screens.scene_start(scene)
  sc = {scene = scene, i = 1, chars = 0, t = 0}
end

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
  rect(0, 0, 480, 26, 0x0B0F22)
  text(sc.scene.place, 12, 4, {font = "gba_small", scale = 2, color = MUTED})
  local line_ = sc.scene.lines[math.min(sc.i, #sc.scene.lines)]
  if line_.pic then
    local w, h = imgsize(line_.pic)
    local k = w <= 120 and 3 or 1  -- the old pictures are tiny and shown at 3x, the new prints at their size
    local x, y = 240 - w * k // 2, (k == 1 and 124 or 112) - h * k // 2
    rect(x - 8, y - 8, w * k + 16, h * k + 16, 0xF0E8D8)
    img(line_.pic, x, y, {scale = k})
  end
  rect(16, 222, 448, 86, 0x0B0F22)
  box(16, 222, 448, 86, 0x5A6290)
  local who = line_[1]
  if who ~= "" then
    local col = ({Dani = GOLD, Leire = TEAL_L, Ana = 0xF0A0B8, Nico = 0xA0C8F0, ["Julián"] = 0xE0C090})[who] or WHITE
    plate(26, 212, textw(who, "gba_body") + 20, 22, 0x2A3466)
    text(who, 36, 213, {font = "gba_body", color = col})
  end
  text(line_[2], 30, 240, {font = "gba_body", color = who == "" and MUTED or WHITE, width = 420,
                          chars = math.floor(sc.chars)})
  if sc.chars >= #line_[2] and (sc.t // 20) % 2 == 0 then tri(446, 292, 456, 292, 451, 298, GOLD) end
  text("A: seguir   B: saltar", 464, 304 - 18, {font = "gba_small", scale = 2, color = 0x6A70A0, align = "right"})
end

-- --- briefing before the run ----------------------------------------------------------------------------------
function screens.prep(day, t)
  shade(0, 0, 480, 320)
  card(28, 14, 424, 294, GOLD)
  text(string.upper(day.title .. " · " .. day.date), 240, 22, {font = "gba_title", align = "center", color = GOLD})
  text("«" .. day.subtitle .. "» · Tramo: " .. (day.street or ""), 240, 50, {font = "gba_small", scale = 2, align = "center", color = MUTED})
  text("Objetivo", 48, 72, {font = "gba_body", color = GOLD})
  text(day.objective, 48, 90, {font = "gba_body", color = WHITE, width = 390})
  text("Retos opcionales", 48, 128, {font = "gba_body", color = GOLD})
  for i, c in ipairs(day.challenges) do text("· " .. c.text, 56, 128 + i * 18, {font = "gba_body", color = WHITE}) end
  -- the street's map: the ways out are known before running
  local x0, x1, y = 70, 410, 232
  rect(x0, y - 6, x1 - x0, 12, 0x2A3058)
  for _, zn in ipairs(day.zones) do
    local a = x0 + zn.z0 / day.length * (x1 - x0)
    local b = x0 + zn.z1 / day.length * (x1 - x0)
    rect(math.floor(a), zn.side < 0 and y - 12 or y + 6, math.floor(b - a), 6, TEAL)
    text(zn.id, math.floor((a + b) / 2), zn.side < 0 and y - 26 or y + 13, {font = "gba_small", scale = 2, align = "center", color = TEAL_L})
  end
  tri(x0 - 12, y - 6, x0 - 12, y + 6, x0 - 4, y, GOLD)
  text("inicio", x0 - 22, y + 13, {font = "gba_small", scale = 2, color = MUTED})
  text("fin", x1 + 6, y - 6, {font = "gba_small", scale = 2, color = MUTED})
  if day.photo then  -- Nico's balcony on the map
    local px = x0 + day.photo.at / day.length * (x1 - x0)
    rect(math.floor(px) - 5, day.photo.side < 0 and y - 13 or y + 7, 10, 7, 0xC8C8D8)
    circ(math.floor(px), day.photo.side < 0 and y - 10 or y + 10, 2, INK)
  end
  text("A apretar · B aflojar · C mirar atrás", 240, 262, {font = "gba_small", scale = 2, align = "center", color = WHITE})
  if (t // 25) % 2 == 0 then text("A: a la calle   B: volver", 240, 280, {font = "gba_body", align = "center", color = GOLD}) end
end

function screens.countdown(t)
  local s = t // 60
  if s < 5 then
    text(tostring(5 - s), 240, 110, {font = "gba_title", scale = 4, align = "center", color = WHITE, outline = INK,
                                     shadow = 0x000000})
  elseif t < 330 then
    text("¡COHETE!", 240, 110, {font = "gba_title", scale = 3, align = "center", color = GOLD, gradient = 0xF06030,
                                outline = INK, shake = 1})
  end
end

function screens.look_frame()
  rect(0, 29, 480, 3, 0xF0A040)
  rect(0, 316, 480, 4, 0xF0A040)
  rect(0, 29, 3, 291, 0xF0A040)
  rect(477, 29, 3, 291, 0xF0A040)
  plate(186, 286, 108, 22, 0x7A4010)
  text("MIRANDO ATRÁS", 240, 289, {font = "gba_small", scale = 2, align = "center", color = WHITE})
end

function screens.tutorial(step, tut, r)
  local s = step or "¡Bien! Así se cierra una carrera."
  local w = 440
  rect(20, 252, w, 52, 0x0B0F22)
  box(20, 252, w, 52, TEAL)
  plate(30, 243, 70, 20, 0x1C5E50)
  text("Leire", 40, 244, {font = "gba_small", scale = 2, color = TEAL_L})
  text(s, 34, 264, {font = "gba_body", color = WHITE, width = w - 28})
  text(math.min(tut.step, 5) .. "/5", 448, 254, {font = "gba_small", scale = 2, color = MUTED, align = "right"})
end

local CLOSE = {
  retirada = {"RETIRADA", TEAL}, fin = {"FIN DE TRAMO", TEAL},
  contacto = {"CONTACTO", RED}, bloqueada = {"SIN HUECO", RED}, agotamiento = {"SIN AIRE", RED}, caida = {"AL SUELO", RED},
}
function screens.close(r)
  local o = r.over
  local k = o.result == "fallo" and o.reason or o.result
  local c = CLOSE[k] or {"FIN", WHITE}
  rect(0, 120, 480, 64, 0x0B0F22)
  rect(0, 120, 480, 3, c[2])
  rect(0, 181, 480, 3, c[2])
  text(c[1], 240, 132, {font = "gba_title", scale = 2, align = "center", color = WHITE, outline = INK})
end

function screens.pause()
  shade(0, 0, 480, 320)
  card(140, 110, 200, 90, GOLD)
  text("PAUSA", 240, 124, {font = "gba_title", align = "center", color = GOLD})
  text("START: seguir", 240, 154, {font = "gba_body", align = "center", color = WHITE})
  text("B: abandonar", 240, 174, {font = "gba_body", align = "center", color = MUTED})
end

-- --- the review: the last seconds seen from above, a schematic (not a camera Dani carries) ----------------------
function screens.review(r, res, t)
  local rec = r.rec
  text("REVISIÓN", 20, 10, {font = "gba_title", color = GOLD})
  text("Los últimos segundos, desde arriba", 460, 16, {font = "gba_small", scale = 2, align = "right", color = MUTED})
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
      local w = textw(msg, "gba_body") + 20
      rect(240 - w // 2, 52, w, 24, 0x7A2430)
      text(msg, 240, 54, {font = "gba_body", align = "center", color = WHITE})
    end
  end
  local dx, dy = math.floor(X(s.dz)), math.floor(Y(s.dx))
  for k = math.max(1, i - 6), i do
    if rec[k].ph then
      circ(dx, dy, 16, GOLD, false)
      text("FOTO", dx, dy - 34, {font = "gba_body", align = "center", color = GOLD})
    end
  end
  circ(dx, dy, 6, INK)
  circ(dx, dy, 5, s.st == "down" and RED or GOLD)
  tri(dx + 7, dy - 4, dx + 7, dy + 4, dx + 12, dy, GOLD)
  text("sentido de la carrera >", x1, cy + half + 14, {font = "gba_small", scale = 2, align = "right", color = MUTED})
  local secs = (s.t - rec[n].t) / 60
  text(string.format("%.1f s", secs), x0, cy + half + 14, {font = "gba_small", scale = 2, color = MUTED})
  card(20, 240, 440, 66, res.closed and TEAL or RED)
  text(res.note, 34, 250, {font = "gba_body", color = WHITE, width = 412})
  if t > 30 then text("A: seguir", 452, 290, {font = "gba_small", scale = 2, color = GOLD, align = "right"}) end
end

function screens.result(r, res, t)
  card(28, 18, 424, 284, res.closed and TEAL or RED)
  local day = r.day
  text(string.upper(day.title .. " · " .. day.date), 240, 30, {font = "gba_title", align = "center", color = GOLD})
  local head = res.closed and (res.result == "retirada" and "Carrera cerrada por una retirada" or "Carrera cerrada al final del tramo")
               or "La carrera no ha terminado bien"
  text(head, 240, 62, {font = "gba_body", align = "center", color = res.closed and TEAL_L or 0xFF9080})
  check(56, 100, res.objective, "Objetivo: retirada sin quedarte sin aire")
  check(56, 128, res.clean, "Sin contactos")
  check(56, 156, res.stay, "Dejar pasar a la manada antes de salir")
  check(56, 184, res.photo, "La foto de Nico")
  text("Contactos: " .. res.contacts .. (res.air_zero and " · te quedaste sin aire" or ""), 56, 216,
       {font = "gba_small", scale = 2, color = MUTED})
  if res.closed then
    text("A: seguir   B: repetir la mañana", 240, 270, {font = "gba_body", align = "center", color = GOLD})
  else
    text("A: reintentar   B: menú", 240, 270, {font = "gba_body", align = "center", color = GOLD})
    text("El reintento empieza en la cuenta atrás y no repite escenas.", 240, 246, {font = "gba_small", scale = 2, align = "center", color = MUTED})
  end
end

function screens.notebook(save)
  card(28, 18, 424, 284, GOLD)
  text("CUADERNO DE DANI", 240, 30, {font = "gba_title", align = "center", color = GOLD})
  local nb = save.notebook or {}
  local labels = {R1 = "Portal de la izquierda (temprano)", R2 = "Portal de la derecha", R3 = "Salida del final"}
  text("7 de julio · Estafeta", 52, 74, {font = "gba_body", color = MUTED})
  text("Entrada: inicio del tramo", 52, 104, {font = "gba_body", color = WHITE})
  text("Salida: " .. (nb.zone and labels[nb.zone] or nb.result == "fin" and "final del tramo" or "ninguna"), 52, 130,
       {font = "gba_body", color = WHITE})
  text("Foto de Nico: " .. (save.days[1] and save.days[1].photo and "conseguida" or "todavía no"), 52, 150,
       {font = "gba_body", color = WHITE})
  text("Observación", 52, 180, {font = "gba_body", color = GOLD})
  text(nb.note or "", 52, 200, {font = "gba_body", color = WHITE, width = 380})
  text("A o B: volver", 240, 278, {font = "gba_small", scale = 2, align = "center", color = MUTED})
end

return screens
