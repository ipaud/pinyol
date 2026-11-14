-- Digestión: una escena jugable corta para probar el puzle y el tono.
local ITEMS = {
  {name = "BIRRA", clue = "Líquido. Sospechosamente familiar.", route = "ESTÓMAGO", color = 0xC86143},
  {name = "FACTURA", clue = "Papel que nadie quiere tragar.", route = "ARCHIVO", color = 0xD9CDB5},
  {name = "PIZZA", clue = "Comida, aunque Stanley diga otra cosa.", route = "ESTÓMAGO", color = 0xE8A957},
}

state, processed, misery, route = "title", 0, 0, "ESTÓMAGO"
yuri_x, stanley_seen = 62, false
local note, note_ticks = "", 0

local function reset()
  state, processed, misery, route = "play", 0, 0, "ESTÓMAGO"
  yuri_x, stanley_seen = 62, false
  note, note_ticks = "Llega al panel y clasifica la cinta.", 180
end

local function say(message)
  note, note_ticks = message, 150
end

function _init()
  show(0)
  backdrop(0x17252A)
end

function _update()
  if state == "title" or state == "won" then
    if btnp("a") or btnp("start") then reset() end
    return
  end
  if state == "stanley" then
    if btnp("a") then state = "play"; say("Yuri: La pizza sigue siendo comida.") end
    return
  end

  if note_ticks > 0 then note_ticks = note_ticks - 1 end
  local dx = (btn("right") and 1 or 0) - (btn("left") and 1 or 0)
  yuri_x = math.max(38, math.min(382, yuri_x + dx * 2.6))
  if btnp("up") then route = "ESTÓMAGO" end
  if btnp("down") then route = "ARCHIVO" end
  if not btnp("a") then return end
  if yuri_x < 360 then say("Acércate a la palanca de la derecha."); return end

  local item = ITEMS[processed + 1]
  if route ~= item.route then
    misery = misery + 1
    say("Ruta incorrecta. Vuelve a intentarlo.")
    tone(2, 180, {wave = "square", vol = 0.22, decay = 0.14})
    return
  end
  processed = processed + 1
  tone(2, 750, {wave = "triangle", vol = 0.25, decay = 0.18})
  if processed == 2 then
    stanley_seen, state = true, "stanley"
  elseif processed == #ITEMS then
    state = "won"
  else
    say("Bien. Siguiente objeto.")
  end
end

local function scene()
  img("BG_DIGESTION", 0, 0)
  if processed < #ITEMS then
    img("OBJ_ITEMS", 232, 157, {frame = processed})
  end
  img("SPR_YURI", yuri_x - 36, 128)
  rect(0, 0, 480, 50, 0x101E24)
  rect(0, 230, 480, 90, 0x14262A)
end

local function hud()
  text("MICROMISERIAS  /  DIGESTIÓN", 16, 9, {font = "bold", color = 0xE5DDBD})
  text(processed .. "/3", 444, 9, 0xE5DDBD, "bold", "right")
  text("MISERIA " .. misery, 16, 30, 0xE2A573, "main")
  local item = ITEMS[processed + 1]
  if item then text(item.clue, 22, 236, 0xE5DDBD, "main") end
  text((route == "ESTÓMAGO" and "> " or "  ") .. "ARRIBA: ESTÓMAGO", 22, 260,
       route == "ESTÓMAGO" and 0xF4E7A5 or 0x788D85, "bold")
  text((route == "ARCHIVO" and "> " or "  ") .. "ABAJO: ARCHIVO", 252, 260,
       route == "ARCHIVO" and 0xF4E7A5 or 0x788D85, "bold")
  if note_ticks > 0 then
    rect(12, 281, 456, 27, 0x584330)
    text(note, 20, 286, 0xFFF2CE, "main")
  else
    text("IZQ/DER: MOVER   A: CLASIFICAR", 22, 283, 0xABB9B7, "main")
  end
end

function _draw()
  if state == "title" then
    img("BG_DIGESTION", 0, 0)
    shade(0, 0, 480, 320)
    img("SPR_YURI", 45, 144)
    img("SPR_STANLEY", 358, 136)
    text("MICROMISERIAS", 240, 73, {font = "large_bold", align = "center", color = 0xDBE6BF,
                                   shadow = 0x07191A, scale = 2})
    text("DIGESTIÓN", 240, 128, {font = "bold", align = "center", color = 0xE2A573, scale = 2})
    text("Tres objetos.", 240, 177, 0xE7DCC2, "main", "center")
    text("Dos destinos.", 240, 198, 0xE7DCC2, "main", "center")
    text("Pésima ayuda.", 240, 219, 0xE7DCC2, "main", "center")
    text("A  EMPEZAR", 240, 270, 0xD8E9CD, "bold", "center")
    return
  end
  scene()
  if state == "stanley" then
    rect(35, 42, 410, 244, 0x132327)
    box(35, 42, 410, 244, 0xD6B184)
    img("SPR_STANLEY", 73, 111)
    text("STANLEY", 180, 75, 0x91E1B3, "bold")
    text("La pizza va al archivo.", 180, 111, 0xE4E4CB, "main")
    text("Mi teoría es impecable.", 180, 137, 0xE4E4CB, "main")
    text("Yuri desconfía.", 180, 176, 0xD9A77B, "main")
    text("A  CONTINUAR", 180, 241, 0xE8D39F, "bold")
  elseif state == "won" then
    rect(42, 67, 396, 196, 0x14262A)
    box(42, 67, 396, 196, 0xC6A576)
    text("TURNO TERMINADO", 240, 92, {font = "bold", align = "center", color = 0xDDEABC, scale = 2})
    text("3 objetos clasificados", 240, 148, 0xE5DDBD, "main", "center")
    text("Miserias acumuladas: " .. misery, 240, 174, 0xE2A573, "main", "center")
    text("Yuri: Mañana ya me preocuparé.", 240, 203, 0xE5DDBD, "main", "center")
    text("A  REPETIR", 240, 238, 0xC3D5C3, "bold", "center")
  else
    hud()
  end
end
