-- Entrehilos: primera pantalla jugable. Arte a resolución de pantalla (480x320).
local SPEED = 2.2
local RIVER_LEFT, RIVER_RIGHT = 213, 267
local BRIDGE_TOP, BRIDGE_BOTTOM = 214, 251
local THREADS = {0xFF9477, 0xF7C766, 0x65BCC0}
local THREAD_NAMES = {"CORAL", "ORO", "TURQUESA"}

state = "title"                    -- title, play, stitch
room = "river"                     -- river, farbank
player = {x = 72, y = 211}          -- esquina superior izquierda; pies en y + 38
bridge_done = false
stitches = {false, false, false}
selected = 1
thread_index = 1
stitch_feedback = ""
message = ""
message_until = 0

local function near_bridge()
  return room == "river" and player.x + 15 >= 173 and player.x + 15 <= 213
    and player.y + 38 >= 193 and player.y + 38 <= 271
end

local function bridge_passable(x, y)
  local cx, feet = x + 15, y + 38
  if room ~= "river" or cx < RIVER_LEFT or cx > RIVER_RIGHT then return true end
  return bridge_done and feet >= BRIDGE_TOP and feet <= BRIDGE_BOTTOM
end

local function move(dx, dy)
  local nx = math.max(0, math.min(450, player.x + dx * SPEED))
  local ny = math.max(180, math.min(242, player.y + dy * SPEED))
  if bridge_passable(nx, player.y) then player.x = nx end
  if bridge_passable(player.x, ny) then player.y = ny end
end

function _init()
  bridge_done = stored("bridge_done", false)
  stitches = {false, false, false}
  selected, thread_index, stitch_feedback = 1, 1, ""
  room, state, message, message_until = "river", "title", "", 0
  player = {x = 72, y = 211}
end

function _update()
  if state == "title" then
    if btnp("a") then state = "play" end
    return
  end

  if state == "stitch" then
    if btnp("left") then selected = math.max(1, selected - 1) end
    if btnp("right") then selected = math.min(3, selected + 1) end
    if btnp("up") then thread_index = (thread_index + 1) % 3 + 1 end
    if btnp("down") then thread_index = thread_index % 3 + 1 end
    if btnp("b") then state = "play" end
    if btnp("a") and not stitches[selected] then
      if thread_index ~= selected then
        stitch_feedback = "Ese color no encaja en el dibujo."
        return
      end
      stitch_feedback = ""
      stitches[selected] = true
      tone(0, ({"C5", "E5", "G5"})[selected], {wave = "triangle", vol = 0.24, decay = 0.16})
      if stitches[1] and stitches[2] and stitches[3] then
        bridge_done, state, message = true, "play", "¡Puente terminado! Cruza el río."
        message_until = ticks() + 180
        store("bridge_done", true)
        tone(1, "C4", {wave = "triangle", vol = 0.3, decay = 0.7})
      else
        for i = 1, 3 do if not stitches[i] then selected = i; break end end
      end
    end
    return
  end

  if btnp("a") and near_bridge() and not bridge_done then
    state, selected, thread_index, stitch_feedback, message = "stitch", 1, 1, "", ""
    return
  end
  local dx = (btn("right") and 1 or 0) - (btn("left") and 1 or 0)
  local dy = (btn("down") and 1 or 0) - (btn("up") and 1 or 0)
  move(dx, dy)

  if room == "river" and bridge_done and player.x >= 449 then
    room, player.x, message = "farbank", 9, "El camino continúa entre hilos."
    message_until = ticks() + 180
  elseif room == "farbank" and player.x <= 1 then
    room, player.x, message = "river", 444, "Tu puente sigue aquí."
    message_until = ticks() + 180
  end
end

local function stitch_mark(x, y, colour)
  line(x - 8, y - 8, x + 8, y + 8, colour)
  line(x + 8, y - 8, x - 8, y + 8, colour)
  line(x - 7, y - 8, x + 9, y + 8, colour)
  line(x + 9, y - 8, x - 7, y + 8, colour)
end

function _draw()
  img(room == "river" and "BG_RIVER" or "BG_FARBANK", 0, 0)
  if room == "river" and bridge_done then img("BRIDGE", 196, 203) end
  img("HERO", math.floor(player.x), math.floor(player.y))

  rect(0, 0, 480, 32, 0x0B3F45)
  text("ENTREHILOS", 15, 6, 0xF5EBD4, "bold")
  text(room == "river" and "01 · EL RÍO" or "02 · LA OTRA ORILLA", 465, 6, 0xF5EBD4, "bold", "right")

  if state == "title" then
    rect(48, 67, 384, 180, 0x0B3F45)
    text("UN MUNDO POR BORDAR", 240, 91, 0xF7C766, "large_bold", "center")
    text("Cada puntada abre un camino.", 240, 142, 0xF5EBD4, "bold", "center")
    text("A · EMPEZAR", 240, 199, 0xFF836E, "bold", "center")
    return
  end

  if state == "stitch" then
    rect(43, 45, 394, 240, 0x0B3F45)
    text("BORDA EL PUENTE", 240, 71, 0xF7C766, "large_bold", "center")
    text("Elige un hueco. Da una puntada.", 240, 111, 0xF5EBD4, "bold", "center")
    for i = 1, 3 do
      local x = 144 + (i - 1) * 96
      rect(x - 30, 151, 60, 62, selected == i and 0x1C7375 or 0x154F55)
      if stitches[i] then stitch_mark(x, 182, THREADS[i])
      else
        rect(x - 8, 160, 16, 5, THREADS[i])
        text("+", x, 174, THREADS[i], "large_bold", "center")
      end
    end
    text("HILO: " .. THREAD_NAMES[thread_index], 240, 218, THREADS[thread_index], "bold", "center")
    if stitch_feedback ~= "" then
      text(stitch_feedback, 240, 247, 0xF5EBD4, "main", "center")
    else
      text("IZQ/DER HUECO   ARR/ABA HILO", 240, 239, 0xF5EBD4, "main", "center")
      text("A COSER   B SALIR", 240, 259, 0xF5EBD4, "main", "center")
    end
    return
  end

  rect(0, 288, 480, 32, 0x0B3F45)
  if message ~= "" and ticks() < message_until then text(message, 240, 294, 0xF5EBD4, "bold", "center")
  elseif near_bridge() and not bridge_done then
    text("A · BORDAR PUENTE", 240, 294, 0xF7C766, "bold", "center")
  elseif room == "river" then
    text("MUÉVETE CON LA CRUCETA · ACÉRCATE AL RÍO", 240, 294, 0xF5EBD4, "main", "center")
  else
    text("HAS CRUZADO · VUELVE PARA VER TU PUENTE", 240, 294, 0xF5EBD4, "main", "center")
  end
end
