-- SHIFT: same world state, four sets of rules. Drawn from native Pinyol primitives for Cirera.
local Era = require("era")
local World = require("world")
local Audio = require("audio")
local juice = require("juice")
local particles = require("particles")

local W, H, FLOOR, LEVEL_W = 240, 160, 140, 1380
local ACCEL, FRICTION, MAX_FALL = 0.16, 0.78, 4.4
local fx = particles.new()
world, player, era, state, sync = {}, {}, 3, "boot", 100
local camera_x, render_x, render_y, timer, shift_lock, debug = 0, 0, 0, 0, 0, false
local message, message_t, swipe_x = "", 0, nil

local function overlap(ax, ay, aw, ah, bx, by, bw, bh)
  return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah
end
local function rect_hit(x, y, w, h, bx, by, bw, bh) return overlap(x, y, w, h, bx, by, bw, bh) end
local function say(s, ticks) message, message_t = s, ticks or 140 end
local function checkpoint(x)
  world.checkpoint = x
  world.nodes[1] = true
  sync = math.min(100, sync + 25)
  say("CHECKPOINT // SYNC +25", 130)
  sfx("NODE")
end
local function fresh()
  world, era, sync = World.new(), 3, 100
  player = {x = 34, y = FLOOR - 16, vx = 0, vy = 0, w = 12, h = 16, face = 1,
            ground = false, coyote = 0, attack = 0, heavy = 0, hurt = 0, charge = 0}
  P, WORLD = player, world
  camera_x, timer, shift_lock, state = 0, 0, 0, "play"
  say("MOVE  ·  A JUMP  ·  C SHIFT", 200)
end

local function solid_rects()
  -- Shared floor. Era-specific objects add/remove collision, never duplicate world state.
  if World.solid(world, "machine", era) then
    if rect_hit(player.x, player.y, player.w, player.h, 220, 82, 62, 58) then return 220, 82, 62, 58 end
  end
  if World.solid(world, "door", era) and rect_hit(player.x, player.y, player.w, player.h, 684, 70, 12, 70) then
    return 684, 70, 12, 70
  end
  if World.solid(world, "wall", era) and rect_hit(player.x, player.y, player.w, player.h, 1020, 76, 34, 64) then
    return 1020, 76, 34, 64
  end
  if World.solid(world, "guardian", era) and rect_hit(player.x, player.y, player.w, player.h, 832, 100, 32, 40) then
    return 832, 100, 32, 40
  end
end
local function platform_at(x, y, old_bottom)
  local gap = (x >= 394 and x < 650) or (x >= 735 and x < 830)
  if not gap and y >= FLOOR and old_bottom <= FLOOR then return FLOOR end
  if not World.solid(world, "microplatform", era) then return nil end
  local tops = {{410, 118, 35}, {458, 96, 35}, {506, 74, 36}, {554, 86, 42}, {604, 112, 34},
                {748, 118, 40}, {792, 98, 40}}
  for _, p in ipairs(tops) do
    if x + player.w > p[1] and x < p[1] + p[3] and y >= p[2] and old_bottom <= p[2] then return p[2] end
  end
  return nil
end
local function move_player()
  local p = player
  if p.hurt > 0 then p.hurt = p.hurt - 1 end
  if p.attack > 0 then p.attack = p.attack - 1 end
  if p.heavy > 0 then p.heavy = p.heavy - 1 end
  local left, right = btn("left"), btn("right")
  if left ~= right then
    p.vx = math.max(-Era.list[era].run, math.min(Era.list[era].run, p.vx + (left and -ACCEL or ACCEL)))
    p.face = left and -1 or 1
  else
    p.vx = p.vx * FRICTION
    if math.abs(p.vx) < 0.04 then p.vx = 0 end
  end
  p.coyote = p.ground and 7 or math.max(0, p.coyote - 1)
  if btnb("a") and p.coyote > 0 then
    p.vy, p.ground, p.coyote = Era.list[era].jump, false, 0
    sfx("JUMP", 0.5, {pitch = era == 2 and 1.15 or 1})
  end
  if not btn("a") and p.vy < -1.7 then p.vy = -1.7 end
  p.vy = math.min(MAX_FALL, p.vy + Era.list[era].gravity)
  local oldx = p.x
  p.x = math.max(0, math.min(LEVEL_W - 18, p.x + p.vx))
  local bx, by, bw, bh = solid_rects()
  if bx then
    if p.vx > 0 then p.x = bx - p.w else p.x = bx + bw end
    p.vx = 0
  end
  local old_bottom = p.y + p.h
  p.y = p.y + p.vy
  p.ground = false
  local top = platform_at(p.x + p.w / 2, p.y + p.h, old_bottom)
  if top then p.y, p.vy, p.ground = top - p.h, 0, true end
  if p.y > H + 30 then
    p.x, p.y, p.vx, p.vy = world.checkpoint, FLOOR - p.h, 0, 0
    sync = math.max(35, sync - 12)
    say("REBOOT // LAST CHECKPOINT", 100)
  end
  if math.floor(oldx / 100) < 1 and p.x >= 100 then checkpoint(96) end
end

local function change_era(index, free)
  if index == era or not Era.allowed(world, index) or shift_lock > 0 then return false end
  local cost = math.abs(index - era) == 1 and 10 or 18
  if not free and sync < cost then say("SYNC LOW // FIND A NODE", 80); return false end
  local was = era
  era = index
  -- If a newly solid interpretation overlaps NODI, reject it. No surprise crushing.
  local bx, by, bw, bh = solid_rects()
  if bx then era = was; say("NO SAFE FOOTING", 55); return false end
  if not free then sync = sync - cost end
  Audio.shift(was, era)
  return true
end

local function shift_input()
  if btnp("c") then change_era(Era.next(world, era, 1)) end
  local tx, ty, down, tapped, released = pen()
  if down and not swipe_x then swipe_x = tx end
  if released and swipe_x then
    local delta = tx - swipe_x
    if math.abs(delta) > 24 then change_era(Era.next(world, era, delta < 0 and 1 or -1)) end
    swipe_x = nil
  end
  if tapped and ty < 30 and tx >= 158 and tx < 430 then
    local index = math.floor((tx - 158) / 68) + 1
    change_era(index)
  end
end

local function interact()
  local p = player
  if btnp("b") and math.abs(p.x - 586) < 34 and math.abs(p.y - 82) < 44 and era == 3 then
    if World.activate(world, "switch") then
      checkpoint(620)
      say("ROUTE RESTORED", 180)
      sfx("NODE")
    end
  end
  if era == 4 then
    if btn("b") then p.charge = math.min(90, p.charge + 1) end
    if btnr("b") then
      local heavy = p.charge >= 18
      local damage = heavy and 2 or 1
      p.charge, p.attack, p.heavy = 0, heavy and 20 or 12, heavy and 20 or 0
      local front = p.x + (p.face > 0 and p.w or -34)
      if world.guardian_hp > 0 and rect_hit(front, p.y + 1, 34, 20, 832, 100, 32, 40) then
        world.guardian_hp = math.max(0, world.guardian_hp - damage)
        world.nodes[3] = world.guardian_hp == 0
        sync = math.min(100, sync + 6)
        juice.freeze(heavy and 7 or 3); juice.shake(heavy and 5 or 3)
        fx:burst(848 - camera_x, 108, heavy and 14 or 9, {speed = heavy and 3.4 or 2.6,
                                                       life = 11, size = 2,
                                                       colours = {Era.list[4].light, 0xFFF5D0, 0xEF725A}})
        sfx("HIT", 0.7, {pitch = heavy and 0.7 or (0.8 + world.guardian_hp * 0.1)})
        if world.guardian_hp == 0 then say("THREAT CLEARED // SYNC +6", 150) end
      elseif not world.wall_broken and rect_hit(front, p.y + 2, 34, 22, 1020, 76, 34, 64) then
        if world.guardian_hp > 0 then
          say("THREAT FIRST", 90)
        else
          world.wall_broken, world.nodes[3] = true, true
          sync = math.min(100, sync + 12)
          fx:burst(1036 - camera_x, 104, 16, {speed = 2.8, life = 15, size = 2,
                                             colours = {0xFFD27A, 0xD95F4C, 0xFFF5D0}})
          juice.freeze(4); juice.shake(4); sfx("HIT", 0.9)
          say("BARRIER REMOVED", 110)
        end
      end
    end
  end
  if p.x > 1270 and world.wall_broken and world.guardian_hp == 0 then state = "ending"; timer = 0 end
end

local function unlocks()
  if player.x > 165 and not world.unlock[1] then
    world.unlock[1] = true; say("8-BIT ONLINE // C TO SHIFT", 220); sync = 100; sfx("NODE")
  end
  if player.x > 350 and not world.unlock[2] then
    world.unlock[2] = true; say("GAME BOY ONLINE // SMALL PLATFORMS", 220); sync = 100; sfx("NODE")
  end
  if player.x > 735 and not world.unlock[4] then
    world.unlock[4] = true; say("ARCADE MODE // B ATTACK", 220); sync = 100; sfx("NODE")
  end
  if player.x > 1160 and not world.nodes[3] and world.guardian_hp == 0 then world.nodes[3] = true end
end

local function update()
  timer = timer + 1
  fx:update()
  if message_t > 0 then message_t = message_t - 1 end
  if shift_lock > 0 then shift_lock = shift_lock - 1 end
  if state == "boot" then
    if timer == 15 then say("BOOTING...", 48) end
    if timer == 68 then say("VIDEO MODE NOT FOUND", 58) end
    if timer == 132 then say("TRYING 1991... FAILED", 70) end
    if timer > 210 then fresh() end
    return
  elseif state == "ending" then
    if timer > 300 and btnp("a") then fresh() end
    return
  end
  shift_input()
  local frozen = juice.update()
  if not frozen then
    move_player()
    unlocks()
    interact()
    if world.switch and player.x > 700 and not world.nodes[2] then checkpoint(700) end
    if player.x > 1080 and world.guardian_hp == 0 and world.checkpoint < 1080 then checkpoint(1080) end
  end
  if sync <= 0 then
    local target = Era.next(world, era, timer % 2 == 0 and 1 or -1)
    change_era(target, true)
    sync, shift_lock = 42, 80
    say("DESYNC // RECOVERING", 100)
    fx:burst(120, 78, 12, {speed = 2.2, life = 18, size = 2,
                           colours = {Era.list[era].light, 0xFFFFFF, Era.list[3].deep}})
  elseif not frozen and timer % 6 == 0 and sync < 100 then
    sync = math.min(100, sync + 1)
  end
  Audio.tick(era, not frozen)
end

-- Pinyol shapes/text use 480x320; scene coordinates are 240x160.
local function pixel_rect(x, y, w, h, col)
  rect(math.floor(x * 2), math.floor(y * 2), math.ceil(w * 2), math.ceil(h * 2), col)
end
local function pixel_line(x1, y1, x2, y2, col) line(x1 * 2, y1 * 2, x2 * 2, y2 * 2, col) end
local function pixel_circ(x, y, radius, col) circ(x * 2, y * 2, math.max(1, radius * 2), col) end
local function world_rect(x, y, w, h, col) pixel_rect(x - render_x, y - render_y, w, h, col) end
local function world_line(x1, y1, x2, y2, col)
  pixel_line(x1 - render_x, y1 - render_y, x2 - render_x, y2 - render_y, col)
end
local function world_circ(x, y, radius, col) pixel_circ(x - render_x, y - render_y, radius, col) end
local function draw_backdrop(pal)
  pixel_rect(0, 0, W, H, pal.sky)
  if era == 1 then
    for x = -((camera_x // 20) % 32), W, 32 do
      pixel_rect(x, 30, 14, 22 + (x * 7 % 22), pal.deep)
      pixel_rect(x + 5, 34, 3, 3, pal.light)
    end
  elseif era == 2 then
    -- Four-tone handheld view; border marks this as a distinct hardware mode.
    pixel_rect(0, 0, W, 10, pal.ink); pixel_rect(0, 150, W, 10, pal.ink)
    for x = 8, W, 40 do pixel_rect(x - (camera_x // 3) % 40, 44, 16, 2, pal.light) end
  else
    for x = -((camera_x // 3) % 72), W, 72 do
      pixel_line(x, 50, x + 22, 32, pal.deep); pixel_line(x + 22, 32, x + 46, 51, pal.deep)
      pixel_line(x + 46, 51, x + 70, 35, pal.deep)
    end
    -- Circuit landscape and warm apertures, fixed palette per era.
    for x = -((camera_x // 2) % 80), W, 80 do
      pixel_rect(x + 11, 62 + (x % 13), 2, 18, pal.deep)
      pixel_rect(x + 5, 78 + (x % 13), 16, 2, pal.deep)
      pixel_circ(x + 13, 78 + (x % 13), 2, pal.light)
    end
  end
end
local function draw_floor(pal)
  world_rect(0, FLOOR, 394, H - FLOOR, pal.ink)
  world_rect(650, FLOOR, 85, H - FLOOR, pal.ink)
  world_rect(830, FLOOR, LEVEL_W - 830, H - FLOOR, pal.ink)
  for x = -((camera_x // 8) % 16), W, 16 do
    world_rect(x, FLOOR, 14, 3, pal.ground)
    if era == 3 or era == 4 then
      world_line(x + 2, FLOOR + 8, x + 13, FLOOR + 8, pal.deep)
      world_line(x + 5, FLOOR + 12, x + 5, FLOOR + 19, pal.deep)
    end
  end
  -- Shared landmarks: identical world coordinates, different visual readings.
  if World.visible(world, "machine", era) then
    if era == 1 then
      world_rect(220, 96, 62, 44, pal.deep); world_rect(228, 88, 46, 8, pal.light)
    elseif era == 2 then
      world_rect(220, 86, 62, 54, pal.ink); world_rect(224, 90, 54, 4, pal.light)
      for i = 0, 3 do world_rect(226 + i * 13, 100, 5, 36, pal.ground) end
    else
      world_rect(220, 92, 62, 48, pal.deep); world_rect(214, 84, 74, 9, pal.ground)
      world_rect(228, 103, 46, 28, pal.ink); world_rect(235, 96, 8, 5, pal.light)
      for i = 0, 4 do world_line(222 + i * 13, 88, 222 + i * 13, 80 - (i % 2) * 5, pal.light) end
    end
  end
  if World.visible(world, "microplatform", era) then
    local platforms = {{410,118,35},{458,96,35},{506,74,36},{554,86,42},{604,112,34},
                       {748,118,40},{792,98,40}}
    for _, p in ipairs(platforms) do
      world_rect(p[1], p[2], p[3], 5, pal.light)
      world_rect(p[1] + 3, p[2] + 5, p[3] - 6, 3, pal.deep)
      world_line(p[1], p[2], p[1] + p[3] - 1, p[2], pal.ink)
    end
  end
  if World.visible(world, "switch", era) then
    world_rect(570, 92, 29, 7, pal.deep); world_rect(580, 70, 8, 22, pal.light)
    world_circ(584, 68, 4, world.switch and 0x9CE8A2 or pal.ground)
  elseif era == 1 then
    world_rect(568, 132, 54, 8, pal.deep)
  end
  if World.solid(world, "door", era) then
    world_rect(684, 70, 12, 70, pal.deep)
    for y = 75, 132, 12 do world_rect(687, y, 6, 4, pal.light) end
  elseif world.switch then
    world_line(690, 72, 690, 136, pal.light)
  end
  if World.visible(world, "guardian", era) then
    if era == 4 then
      world_rect(832, 100, 32, 40, pal.deep); world_rect(827, 93, 42, 12, pal.light)
      world_rect(836, 107, 8, 7, 0xFFFFFF); world_rect(851, 107, 8, 7, 0xFFFFFF)
      world_rect(832, 121, 32, 7, pal.ground)
      for i = 1, 3 do world_rect(836 + i * 7, 86, 4, 3, i <= world.guardian_hp and 0xFF8B62 or pal.ink) end
    elseif era == 1 then
      world_rect(836, 118, 24, 22, pal.deep)
    else
      world_rect(836, 115, 24, 25, pal.ink); world_rect(841, 120, 5, 4, pal.light)
      world_rect(850, 120, 5, 4, pal.light)
    end
  end
  if World.visible(world, "wall", era) then
    if era == 4 then
      world_rect(1020, 76, 34, 64, pal.deep)
      for y = 82, 132, 12 do world_rect(1024, y, 26, 4, pal.ground) end
    else
      world_rect(1020, 76, 34, 64, pal.deep)
      world_rect(1024, 80, 26, 3, pal.light)
    end
  end
  if world.wall_broken then
    world_rect(1020, 132, 34, 8, pal.deep)
    world_rect(1015, 126, 8, 8, pal.ground); world_rect(1044, 130, 9, 6, pal.ground)
  end
  world_rect(1290, 86, 5, 54, pal.light)
  world_rect(1283, 84, 19, 4, pal.light)
end

local function draw_player(pal)
  local p, x, y = player, math.floor(player.x - render_x), math.floor(player.y - render_y)
  local blink = p.hurt > 0 and p.hurt % 6 < 3
  if blink then return end
  if era == 1 then
    pixel_rect(x + 2, y + 4, 9, 9, pal.light); pixel_rect(x + 4, y + 1, 5, 4, pal.ground)
    pixel_rect(x + (p.face > 0 and 8 or 4), y + 6, 2, 2, pal.ink)
    pixel_rect(x + 2, y + 13, 3, 3, pal.deep); pixel_rect(x + 8, y + 13, 3, 3, pal.deep)
  elseif era == 2 then
    pixel_rect(x + 2, y + 3, 9, 11, pal.ink); pixel_rect(x + 4, y + 1, 5, 4, pal.light)
    pixel_rect(x + (p.face > 0 and 8 or 4), y + 7, 2, 2, pal.light)
    pixel_rect(x + 1, y + 13, 4, 3, pal.deep); pixel_rect(x + 8, y + 13, 4, 3, pal.deep)
  elseif era == 4 then
    pixel_rect(x, y + 4, 14, 10, pal.deep); pixel_rect(x + 2, y + 1, 10, 6, pal.light)
    pixel_rect(x + (p.face > 0 and 8 or 3), y + 3, 3, 2, 0xFFFFFF)
    pixel_rect(x + 1, y + 13, 5, 3, pal.ground); pixel_rect(x + 9, y + 13, 5, 3, pal.ground)
    if p.attack > 0 then
      local reach = p.heavy > 0 and 18 or 10
      pixel_line(x + 7, y + 8, x + 7 + p.face * reach, y + 8, 0xFFF5D0)
    end
  else
    -- NODI: compact seed shape, twin feet and asymmetric antenna.
    pixel_circ(x + 6, y + 8, 6, pal.light); pixel_rect(x + 3, y + 6, 8, 7, pal.light)
    pixel_line(x + 8, y + 3, x + 11, y, pal.ground); pixel_circ(x + 11, y, 1, pal.light)
    pixel_rect(x + (p.face > 0 and 8 or 4), y + 6, 2, 2, pal.ink)
    pixel_line(x + 4, y + 13, x + 3, y + 15, pal.ink); pixel_line(x + 9, y + 13, x + 10, y + 15, pal.ink)
    if p.attack > 0 then pixel_line(x + 7, y + 8, x + 14 + p.face * 7, y + 8, pal.light) end
  end
end

local function draw_hud()
  local current = Era.list[era]
  rect(0, 0, 480, 30, 0x111923)
  text("SHIFT", 12, 8, {font = "bold", color = current.light, outline = current.ink})
  for i in ipairs(Era.list) do
    local x = 158 + (i - 1) * 68
    if world.unlock[i] then
      rect(x, 7, 61, 17, i == era and current.ground or 0x293642)
      text(i == 2 and "GB" or (i == 1 and "8-BIT" or (i == 3 and "16" or "ARC")), x + 30, 9,
           {font = "bold", align = "center", color = i == era and current.ink or 0xAAB4B5})
    else
      text("--", x + 30, 9, {font = "bold", align = "center", color = 0x59646A})
    end
  end
  text("SYNC", 14, 286, {font = "bold", color = 0xFFF4D6, outline = 0x172431})
  rect(82, 287, 200, 13, 0x172431)
  rect(84, 289, math.floor(196 * sync / 100), 9, sync < 25 and 0xE46758 or current.light)
  text(string.format("%d", sync), 294, 286, {font = "bold", color = 0xFFF4D6, outline = 0x172431})
  if message_t > 0 and message ~= "" then
    rect(92, 44, 296, 27, 0x111923)
    text(message, 240, 51, {font = "bold", align = "center", color = current.light})
  end
  if debug then
    text(string.format("X %.0f  Y %.0f  E%d  HP%d  T%d", player.x, player.y, era, world.guardian_hp, timer),
         8, 306, {font = "main", color = 0xFFFFFF})
  end
end

local function draw()
  if state == "boot" then
    rect(0, 0, 480, 320, 0x101820)
    text("SHIFT", 240, 100, {font = "large_bold", scale = 2, align = "center", color = 0xE9BD76})
    text(message, 240, 146, {font = "main", align = "center", color = 0xD7D0B3})
    return
  elseif state == "ending" then
    rect(0, 0, 480, 320, 0x101820)
    text("SECTOR STABILIZED", 240, 68, {font = "bold", align = "center", color = 0xE9BD76})
    text("11 MODES REMAINING", 240, 92, {font = "main", align = "center", color = 0xD7D0B3})
    text("SHIFT", 240, 120, {font = "large_bold", align = "center", color = 0xFFFFFF})
    text("SAME WORLD. DIFFERENT RULES.", 240, 144, {font = "main", align = "center", color = 0xE9BD76})
    return
  end
  camera_x = math.max(0, math.min(LEVEL_W - W, player.x - 104))
  local shake_x, shake_y = juice.offset()
  render_x, render_y = camera_x + shake_x, shake_y
  mosaic(1, 1)
  local pal = Era.list[era]
  draw_backdrop(pal); draw_floor(pal); draw_player(pal)
  camera()
  draw_hud()
  fx:draw()
  if Audio.shift_t > 0 then
    if era == 1 then mosaic(2 + Audio.shift_t // 4, 2 + Audio.shift_t // 4)
    elseif era == 2 then haze(0, H, 1, Audio.shift_t, 9)
    elseif era == 3 then haze(34, 114, 1, Audio.shift_t, 11)
    else
      for i = 1, 3 do pixel_line(0, (Audio.shift_t * 7 + i * 19) % H, W, (Audio.shift_t * 7 + i * 19) % H, pal.light) end
    end
  end
end

function _init()
  Audio.init()
  reverb("studio_small", 0.16, {music = 0.1})
  fresh()
  state, timer = "boot", 0
  if stored("skip_boot", false) then fresh() end
end
function _update()
  if btnp("start") then debug = not debug end
  update()
end
function _draw() draw() end

-- Test/debug surface: persistent world entities remain inspectable and editable.
P, WORLD = player, world
WORLD_MODEL, ERA_DEFS = World, Era
