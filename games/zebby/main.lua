-- Zebby: Fora de guió. First playable warehouse slice for pinyol@2.
local WORLD_W, FLOOR, STAGE_Y = 720, 136, -44
local FRAGS = {{x = 120, y = 94}, {x = 308, y = 121}, {x = 420, y = 94}}
local cam, tick_count = 0, 0
local pose_kind, pose_start, jump_start = "idle", 0, 0

state = "title"                    -- title, play, escape, retry, won, lost
P = {x = 32, y = 108, vx = 0, vy = 0, ground = true, flat = false, face = 1}
fragments = 0
found = {false, false, false}
remaining = 0
hearts = 3
box_x = 155
invuln = 0
message, message_until = "", 0

local function notify(s)
  message, message_until = s, ticks() + 150
end

local function hero_height()
  return P.flat and 12 or 28
end

local function overlaps(a0, a1, b0, b1)
  return a0 < b1 and b0 < a1
end

local function set_flat(value)
  if P.flat == value then return end
  P.y = P.y + (value and 16 or -16)
  P.vy, P.ground, P.flat = 0, true, value
  pose_kind, pose_start = value and "flatten" or "recover", tick_count
  notify(value and "Zebby está plano: cabe bajo la persiana." or "El rodillo devolvió su forma a Zebby.")
  tone(1, value and "C4" or "G4", {wave = "triangle", vol = 0.23, decay = 0.25})
end

local function reset_run()
  P = {x = 32, y = 108, vx = 0, vy = 0, ground = true, flat = false, face = 1}
  fragments, found, remaining, hearts, box_x, invuln = 0, {false, false, false}, 0, 3, 155, 0
  state, message = "play", ""
  pose_kind, pose_start, jump_start = "idle", tick_count, tick_count
end

function _init()
  reset_run()
  state = "title"
end

local function floor_and_platforms(old_bottom)
  local h = hero_height()
  if P.vy >= 0 then
    for _, plat in ipairs({{100, 146, 104}, {396, 440, 104}}) do
      if overlaps(P.x + 4, P.x + 20, plat[1], plat[2]) and old_bottom <= plat[3] and P.y + h >= plat[3] then
        P.y, P.vy, P.ground = plat[3] - h, 0, true
        return
      end
    end
  end
  if P.y + h >= FLOOR then P.y, P.vy, P.ground = FLOOR - h, 0, true end
end

local function horizontal_block(nx)
  if state ~= "escape" and not P.flat and overlaps(nx + 4, nx + 20, 260, 278) then return true end
  if not P.flat and P.y + hero_height() > FLOOR - 63 and overlaps(nx + 4, nx + 20, box_x - 45, box_x + 27) then return true end
  return false
end

local function move_player()
  local dx = (btn("right") and 1 or 0) - (btn("left") and 1 or 0)
  if (pose_kind == "flatten" or pose_kind == "recover") and tick_count - pose_start < 24 then dx = 0 end
  if dx ~= 0 then P.face = dx end
  local speed = P.flat and 1.3 or (btn("c") and 3.2 or 2.1)
  P.vx = dx * speed
  local nx = math.max(0, math.min(WORLD_W - 24, P.x + P.vx))
  if not horizontal_block(nx) then P.x = nx end
  if btnp("a") and P.ground and not P.flat then
    P.vy, P.ground = -5.2, false
    jump_start = tick_count
    tone(0, "G4", {wave = "square", vol = 0.14, decay = 0.12})
  end
  local old_bottom = P.y + hero_height()
  if not P.ground then
    P.vy = math.min(P.vy + 0.28, 5)
    P.y = P.y + P.vy
    floor_and_platforms(old_bottom)
  elseif P.y + hero_height() < FLOOR then
    local on_platform = false
    for _, plat in ipairs({{100, 146, 104}, {396, 440, 104}}) do
      if overlaps(P.x + 4, P.x + 20, plat[1], plat[2]) and math.abs(P.y + hero_height() - plat[3]) < 2 then on_platform = true end
    end
    if not on_platform then P.ground = false end
  end
end

local function collect()
  for i, f in ipairs(FRAGS) do
    if not found[i] and math.abs(P.x + 12 - f.x) < 13 and math.abs(P.y + hero_height() / 2 - f.y) < 20 then
      found[i], fragments = true, fragments + 1
      tone(0, ({"C5", "E5", "G5"})[i], {wave = "triangle", vol = 0.25, decay = 0.2})
      notify("Fragmento " .. fragments .. "/3 recuperado.")
    end
  end
end

local function hit()
  if invuln > 0 then return end
  hearts, invuln = hearts - 1, 60
  P.x, P.y, P.vx, P.vy, P.ground, P.flat = 488, 108, 0, 0, true, false
  pose_kind, pose_start = "hit", tick_count
  tone(2, "C3", {wave = "noise", vol = 0.3, decay = 0.2})
  if hearts <= 0 then state = "lost" else notify("¡Cuidado con la cámara móvil!") end
end

local function update_play()
  tick_count = tick_count + 1
  if invuln > 0 then invuln = invuln - 1 end
  collect()
  if P.ground and P.x + 20 >= 193 and P.x < 215 then set_flat(P.face > 0) end
  if P.ground and P.x + 20 >= 324 and P.x < 344 then set_flat(P.face < 0) end
  if btnp("b") and math.abs(P.x + 20 - (box_x - 45)) < 17 and box_x < 225 then
    box_x = box_x + 16
    pose_kind, pose_start = "push", tick_count
    tone(1, "A3", {wave = "noise", vol = 0.12, decay = 0.09})
  end
  if state == "play" and btnp("b") and fragments == 3 and P.x >= 647 then
    state, remaining = "escape", 35 * 60
    notify("REC activado. ¡Vuelve a la salida!")
    tone(1, "E5", {wave = "square", vol = 0.24, decay = 0.5})
  end
  move_player()
  if btnp("c") and not P.flat and math.abs(P.vx) > 0 then
    pose_kind, pose_start = "dash", tick_count
  end
  collect()
  if P.x > 503 and P.x < 529 and P.y + hero_height() > 118 and tick_count % 180 < 75 then hit() end
  if state == "escape" then
    remaining = remaining - 1
    if P.x <= 25 then
      state = "won"
      store("progress", {version = 1, p1 = true})
      tone(1, "C5", {wave = "triangle", vol = 0.3, decay = 0.75})
    elseif remaining <= 0 then state = "retry" end
  end
end

function _update()
  if state == "title" then
    if btnp("a") then reset_run() end
  elseif state == "retry" then
    if btnp("a") then
      P.x, P.y, P.vx, P.vy, P.ground, P.flat = 661, 108, 0, 0, true, false
      remaining, state, hearts = 35 * 60, "escape", 3
    end
  elseif state == "lost" then
    if btnp("a") then reset_run() end
  elseif state == "won" then
    if btnp("a") then reset_run() end
  else
    update_play()
  end
end

local function draw_prop(frame, x, y)
  img("PROPS", math.floor((x - cam) * 2), y * 2 + STAGE_Y, {frame = frame, scale = 2})
end

local function draw_native(id, x, height, frame)
  img(id, math.floor((x - cam) * 2), FLOOR * 2 + STAGE_Y - height, {frame = frame or 0})
end

local function hero_frame()
  local age = tick_count - pose_start
  if pose_kind == "hit" and age < 24 then return 46 + math.min(5, age // 4) end
  if pose_kind == "flatten" and age < 24 then return 52 + math.min(5, age // 4) end
  if pose_kind == "recover" and age < 24 then return 58 + math.min(5, age // 4) end
  if P.flat then return 57 end
  if pose_kind == "push" and age < 24 then return 18 + math.min(5, age // 4) end
  if not P.ground then return 12 + math.min(5, (tick_count - jump_start) // 4) end
  if btn("c") and math.abs(P.vx) > 0 then
    if pose_kind == "dash" and age < 18 then return 40 + math.min(5, age // 3) end
    return 32 + tick_count // 3 % 8
  end
  if math.abs(P.vx) > 0 then return 24 + tick_count // 5 % 8 end
  return tick_count // 12 % 6
end

local function draw_world()
  cam = math.max(0, math.min(WORLD_W - W, math.floor(P.x - 95)))
  img("WAREHOUSE_A", -cam * 2, 0)
  img("WAREHOUSE_B", 720 - cam * 2, 0)
  for i, f in ipairs(FRAGS) do
    if not found[i] then draw_prop(0, f.x - 16, f.y - 14) end
  end
  draw_native("EXIT_NATIVE", 6, 160, state == "won" and 1 or 0)
  draw_native("BOX_NATIVE", box_x - 45, 127, 0)
  draw_native("PRESS_NATIVE", 180, 170, P.flat and 1 or 0)
  draw_native("ROLLER_NATIVE", 322, 164, P.flat and 1 or 0)
  draw_native("REC_NATIVE", 628, 188, fragments == 3 and 1 or 0)
  if tick_count % 180 < 75 then draw_native("CAMERA_NATIVE", 495, 138, 0) end
  if invuln % 6 < 3 then
    img("ZEBBY_NATIVE", math.floor((P.x - cam + 12) * 2) - 32,
      math.floor((P.y + hero_height()) * 2) + STAGE_Y - 63,
      {frame = hero_frame(), flip_x = P.face < 0})
  end
  draw_native("SHUTTER_NATIVE", 253, 161, (state == "escape" or state == "won") and 1 or 0)
end

local function draw_hud()
  rect(0, 0, 480, 34, 0x0B2D3F)
  text("ZEBBY", 12, 6, 0xF24406, "large_bold")
  text("VIDAS " .. hearts, 115, 8, 0xF4F0E7, "bold")
  text("CLIP " .. fragments .. "/3", 254, 8, 0xF4F0E7, "bold")
  if state == "escape" then text(string.format("%02d s", math.ceil(remaining / 60)), 466, 8, 0xF7C457, "bold", "right") end
  rect(0, 284, 480, 36, 0x0B2D3F)
  local hint
  if message ~= "" and ticks() < message_until then hint = message
  elseif state == "escape" then hint = "VUELVE A LA SALIDA · C PARA CORRER"
  elseif fragments == 3 then hint = "VE A REC · B PARA ACTIVAR"
  elseif P.flat then hint = "FORMA PLANA · PASA BAJO LA PERSIANA"
  else hint = "A SALTAR · B EMPUJAR · C CORRER" end
  text(hint, 240, 293, 0xF4F0E7, "main", "center")
end

function _draw()
  draw_world()
  draw_hud()
  if state == "title" or state == "won" or state == "retry" or state == "lost" then
    rect(62, 72, 356, 184, 0x0B2D3F)
    local heading = state == "title" and "FORA DE GUIÓ" or state == "won" and "¡SECUENCIA RECUPERADA!"
      or state == "retry" and "SE ACABÓ EL TIEMPO" or "SIN VIDAS"
    text(heading, 240, 92, 0xF7C457, "large_bold", "center")
    if state == "title" then
      text("EL MAGATZEM IMPOSSIBLE", 240, 139, 0xF4F0E7, "bold", "center")
      text("3 fragmentos · REC · vuelve", 240, 168, 0xF4F0E7, "main", "center")
    elseif state == "won" then
      text("Primer plano guardado.", 240, 151, 0xF4F0E7, "bold", "center")
    else
      text(state == "retry" and "Reintenta desde REC con tus clips." or "Vuelve a intentarlo.",
        240, 151, 0xF4F0E7, "main", "center")
    end
    text("A · CONTINUAR", 240, 214, 0xF24406, "bold", "center")
  end
end
