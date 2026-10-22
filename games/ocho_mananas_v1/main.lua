-- 07:59 · Ocho mañanas: first playable slice of the design plan v1.0 (phases 1-3: one street, Dani, runners,
-- the herd, air and balance, ways out, the rear view with a look back, a cut to the side view, and the first
-- morning from the workshop to breakfast). Plan: 0759_Ocho_Mananas_Plan_Maestro_v1.pdf.
--
-- main.lua is the state machine; the race is race/sim.lua (no camera), views/ project it, ui/ draws over it.
C = require("race.camera")
days = require("data.days")
sim = require("race.sim")
rear = require("views.rear")
side = require("views.side")
hud = require("ui.hud")
screens = require("ui.screens")
story1 = require("story.day1")
actors = require("views.actors")
chant = require("chant.play")
position = require("ui.position")

state = "title"     -- title, scene, practice, chant, position, prep, count, race, close, review, result, notebook
R = nil             -- the race being run (tests read it)
view = "rear"       -- the camera the race is shown through
looking = false     -- the look back is on
save = nil
local timer, look_t, look_ready = 0, 0, true
local banner, banner_t = nil, 0
local latch = {}
local after_scene = nil
local menu_i = 1
tut = nil
last = nil           -- what the last run left for the review and the notebook
local crowd_h = nil
local attract = nil

-- --- saving -------------------------------------------------------------------------------------------------
local function load_save()
  local s = stored("save")
  if type(s) ~= "table" or s.v ~= 1 then s = {v = 1, prologue = false, practice = false, days = {}, opts = {look = "hold"}} end
  s.days = s.days or {}
  s.opts = s.opts or {look = "hold"}
  return s
end
local function write_save() store("save", save) end

-- --- sound: no files, all made here ------------------------------------------------------------------------
local function make_sounds()
  sound("CROWD", {wave = "noise", sustain = 1, decay = 0, lowpass = 0.05, volume = 0.6})
  sound("GOLPE", "hit", 3)
  sound("COHETE", "explosion", 5)
  sound("SALIDA", "powerup", 2)
  sound("BLIP", "blip", 1)
  sound("CASCO", {wave = "noise", sustain = 0.01, decay = 0.07, lowpass = 0.25, volume = 0.7})
  sound("FLASH", {wave = "square", freq = 1800, sustain = 0.02, decay = 0.12, arp = 1.5, arp_time = 0.03, volume = 0.4})
end
flash_t = 0
function sfx_photo() sfx("FLASH", 0.7); flash_t = 10 end
function sfx_hit(what) sfx("GOLPE", what == "toro" and 0.9 or 0.6) end
function sfx_retire() sfx("SALIDA", 0.6) end

local MEL = {"D5", "F#5", "A5", "A5", "G5", "F#5", "E5", "G5", "B5", "A5", "G5", "E5",
             "F#5", "A5", "D6", "C#6", "B5", "A5", "G5", "E5", "C#5", "D5", 0, 0}
local BASS = {"D3", 0, 0, "A2", 0, 0, "E3", 0, 0, "A2", 0, 0, "D3", 0, 0, "F#3", 0, 0, "A2", 0, 0, "D3", 0, 0}
local music_on = false
local function tune(t)
  if not music_on or t % 11 ~= 0 then return end
  local i = (t // 11) % #MEL + 1
  if MEL[i] ~= 0 then tone(0, MEL[i], {wave = "square", duty = 0.25, vol = 0.16, decay = 0.18}) end
  if BASS[i] ~= 0 then tone(1, BASS[i], {wave = "triangle", vol = 0.3, decay = 0.4}) end
end
local function music_play(on)
  music_on = on
  if not on then tone(0); tone(1) end
end

local function race_sounds(r)
  local d = r.dani
  local near, nb = 1e9, nil
  for _, b in ipairs(r.bulls) do
    local dz = math.abs(b.z - d.z)
    if dz < near then near, nb = dz, b end
  end
  local k = near < 420 and (1 - near / 420) or 0
  if crowd_h then sfx_set(crowd_h, {gain = 0.12 + 0.45 * k}) end
  if k > 0 then
    -- hooves in the ear of the side they come by: across the street in the rear view, along it in the side view
    local pan = view == "side" and (nb.z - d.z) / 120 or (nb.x - d.x) / 18
    pan = math.max(-0.9, math.min(0.9, pan))
    local t = r.t % 9
    if t == 0 or t == 2 or t == 5 then sfx("CASCO", 0.15 + 0.6 * k, {pan = pan, pitch = 0.8 + t * 0.06}) end
  end
  local step = math.floor(d.phase * 2)
  if step ~= (r.last_step or step) and d.state ~= "down" then tone(3, 900, {wave = "noise", lfsr = 7, decay = 0.02, vol = 0.07}) end
  r.last_step = step
  if d.air < 40 and r.t % 34 == 0 and d.state == "run" then
    tone(2, 520, {wave = "noise", attack = 0.04, decay = 0.18, vol = 0.05 + (40 - d.air) / 500})
  end
end

local function quiet()
  if crowd_h then sfx_stop(crowd_h); crowd_h = nil end
  for v = 1, 3 do tone(v) end
end

-- --- input: the same buttons mean different things in each view; a held one keeps its meaning across a cut ----
local MAP = {
  rear = {left = {-1, 0}, right = {1, 0}, up = {0, 1}, down = {0, -1}},
  side = {up = {-1, 0}, down = {1, 0}, right = {0, 1}, left = {0, -1}},
}
autopilot = nil   -- tests can drive Dani with a function of the race (it returns the same input table)
local function read_input()
  if autopilot then return autopilot(R) end
  local lat, adv = 0, 0
  for b, _ in pairs(MAP.rear) do
    if btn(b) then
      local m = MAP[latch[b] or view][b]
      lat, adv = lat + m[1], adv + m[2]
    else
      latch[b] = nil
    end
  end
  return {lat = math.max(-1, math.min(1, lat)), adv = math.max(-1, math.min(1, adv)),
          push = btn("a"), ease = btn("b"), act = btnp("a")}
end

-- --- views and cuts -----------------------------------------------------------------------------------------
local function enter_view(v)
  view = v
  if v == "rear" then rear.enter(looking) else line_off(); side.enter() end
end

local function wanted_view(r)
  local w = "rear"
  for _, k in ipairs(r.day.views or {}) do if r.dani.z >= k[1] then w = k[2] end end
  return w
end

local function calm(r)
  for _, b in ipairs(r.bulls) do
    local dz = b.z - r.dani.z
    if dz > -140 and dz < 40 then return false end
  end
  return true
end


local function update_view(r)
  local w = wanted_view(r)
  if w ~= view and calm(r) and not looking and r.dani.state == "run" then
    for b, _ in pairs(MAP.rear) do if btn(b) then latch[b] = view end end
    enter_view(w)
  end
end

local function update_look(r)
  if view ~= "rear" or r.dani.state ~= "run" then
    if looking then looking = false; rear.enter(false) end
    return
  end
  local hold = save.opts.look ~= "toggle"
  local want
  if hold then
    if not btn("c") then look_ready = true end
    want = btn("c") and look_ready
  else
    if btnp("c") and look_ready then want = not looking else want = looking end
    if not btn("c") then look_ready = true end
  end
  if want and looking then
    look_t = look_t + 1
    if look_t > 48 then want = false; look_ready = false end  -- 0.8 s at most, then the street ahead again
  end
  if want ~= looking then
    looking = want
    look_t = 0
    if not hold and not want then look_ready = true end
    rear.enter(looking)
  end
end

-- --- starting things ----------------------------------------------------------------------------------------
local start_x = 0   -- where the morning's run starts across the street (chosen after the calls)
local function new_race(day)
  actors.reset_cap()
  R = sim.new(day)
  if day == days[1] then R.dani.x = start_x end
  looking, look_t, look_ready, latch = false, 0, true, {}
  banner, banner_t = nil, 0
  enter_view("rear")
end

local function start_scene(sc, after)
  state, timer = "scene", 0
  screens.scene_start(sc)
  after_scene = after
  music_play(true)
  spr_clear()
  bg(1); bg(2); bg(3); line_off()
end

local function start_prep()
  state, timer = "prep", 0
  new_race(days[1])
  music_play(true)
end

-- the morning's first minutes: the three calls to the saint, then where to start, then the briefing
local function start_position()
  start_x = 0
  new_race(days[1])
  position.reset()
  state, timer = "position", 0
  music_play(false)
end
local function start_chant()
  state, timer = "chant", 0
  music_play(false)
  chant.start(1, start_position)
end

local function start_practice(first)
  new_race(days.practice)
  tut = {step = 1, t = 0, moved = 0, first = first, eased = 0, looked = false, done_t = 0}
  state, timer = "practice", 0
  music_play(false)
  crowd_h = sfx("CROWD", 0.05, {loop = true})
end

local function to_title()
  quiet()
  state, timer, menu_i = "title", 0, 1
  attract = sim.new(days.practice)
  R = attract
  looking = false
  enter_view("rear")
  music_play(true)
end

function _init()
  save = load_save()
  make_sounds()
  rear.init()
  side.init()
  to_title()
end

-- --- the tutorial in the empty street -------------------------------------------------------------------------
local STEPS = {
  "Muévete de lado con izquierda y derecha.",
  "Mantén A para apretar. Gasta aire.",
  "Mantén B para aflojar: recuperas aire sin pararte.",
  "Mantén C para mirar atrás un momento.",
  "Retirada a la izquierda: pégate a la pared en la zona verde y pulsa A.",
}
local function practice_step(inp)
  local d = R.dani
  tut.t = tut.t + 1
  if tut.step == 1 then
    tut.moved = tut.moved + math.abs(d.vx)
    if tut.moved > 40 then tut.step, tut.t = 2, 0 end
  elseif tut.step == 2 then
    if d.air < 82 then tut.step, tut.t = 3, 0 end
  elseif tut.step == 3 then
    if d.effort == "ease" then tut.eased = tut.eased + 1 end
    if tut.eased > 50 and d.air > 90 then tut.step, tut.t = 4, 0 end
  elseif tut.step == 4 then
    if looking then tut.looked = true end
    if tut.looked and not looking then tut.step, tut.t = 5, 0 end
  elseif tut.step == 5 then
    local zn = R.zones[1]
    if not zn or zn.z1 < d.z then
      R.zones[1] = {id = "T", side = -1, z0 = d.z + 120, z1 = d.z + 300, label = "Retirada de práctica"}
    end
  end
end

-- --- the review and the notebook ---------------------------------------------------------------------------
local function judge(r)
  local o = r.over
  local closed = o.result ~= "fallo"
  local passed = r.stats.herd_passed_at ~= nil and r.stats.herd_passed_at <= o.t
  local res = {
    closed = closed, result = o.result, reason = o.reason, zone = o.zone and o.zone.id,
    objective = closed and o.result == "retirada" and not r.stats.air_zero,
    clean = closed and r.stats.contacts == 0,
    stay = closed and passed,
    contacts = r.stats.contacts, air_zero = r.stats.air_zero,
    photo = r.photo and r.photo.taken or false,
  }
  -- the moment it could already be seen: going back from the end, the last stretch in which an animal was
  -- coming up in Dani's line, within reach of the radar
  if not closed and (o.reason == "contacto" or o.reason == "bloqueada" or o.reason == "agotamiento") then
    local rec, wi = r.rec, nil
    local last_i = #rec
    while last_i > 1 and rec[last_i].t > o.t do last_i = last_i - 1 end
    for i = last_i, 1, -1 do
      local s, seen = rec[i], false
      for _, b in ipairs(s.b) do
        if s.dz - b[2] > -22 and s.dz - b[2] < 160 and math.abs(b[1] - s.dx) < 10 then seen = true end
      end
      if seen then wi = i else break end
    end
    if wi and wi < last_i then
      res.warn_i, res.fail_i = wi, last_i
      res.warn_s = (rec[last_i].t - rec[wi].t) / 60
    end
  end
  local note
  if not closed then
    note = ({
      contacto = "Un toro venía por tu carril. El radar lo marcaba: apártate hacia una pared antes de que llegue.",
      bloqueada = "Tenías un corredor delante y el grupo detrás: sin hueco. Cambia de línea antes, con margen.",
      agotamiento = "Te quedaste sin aire justo cuando llegaba la manada. Con B recuperas sin pararte.",
      caida = "Demasiados golpes seguidos. El equilibrio vuelve solo si dejas espacio un momento.",
    })[o.reason] or "La carrera no ha terminado bien."
  elseif o.result == "retirada" and not passed then
    note = "Has salido antes de que llegara la manada. Carrera cerrada; queda pendiente aguantar más."
  elseif o.result == "retirada" then
    note = "Has dejado pasar al grupo y has salido por tu sitio."
  else
    note = "Has llegado al final del tramo sin retirarte. Vale, pero hoy tocaba usar una salida."
  end
  if closed and r.stats.air_zero then note = note .. " En algún momento te quedaste sin aire." end
  res.note = note
  -- the notebook's page is small: one short line
  res.short = (not closed and ({contacto = "Un toro venía por tu carril: apártate antes.", bloqueada = "Sin hueco: cambia de línea con margen.",
                 agotamiento = "Sin aire con la manada encima: usa B.", caida = "Muchos golpes seguidos: deja espacio."})[o.reason])
    or (o.result == "retirada" and not passed and "Saliste antes de que llegara la manada.")
    or (o.result == "retirada" and "Dejaste pasar al grupo y saliste por tu sitio.")
    or "Llegaste al final sin retirarte."
  if res.photo then res.leire = "Hoy has elegido el momento. Ahora falta elegir el sitio."
  elseif r.stats.air_zero then res.leire = "Tenías hueco, pero ya no podías cambiar de ritmo."
  elseif r.stats.contacts == 0 then res.leire = "Hoy has podido esperar."
  else res.leire = "Has rozado a alguien. Mira antes de cambiar de línea." end
  return res
end

local function finish_run()
  last = judge(R)
  last.day = R.day.id
  if R.day.id == 1 then
    local prev = save.days[1] or {}
    save.days[1] = {done = prev.done or last.closed, objective = prev.objective or last.objective,
                    clean = prev.clean or last.clean, stay = prev.stay or last.stay,
                    photo = prev.photo or last.photo, tries = (prev.tries or 0) + 1}
    save.notebook = {zone = last.zone, result = last.result, note = last.short, reason = last.reason}
    write_save()
  end
  state, timer = "review", 0
  quiet()
end

-- --- the loop -------------------------------------------------------------------------------------------------
paused = false
function _update()
  timer = timer + 1
  if flash_t > 0 then flash_t = flash_t - 1 end
  if R then rear.update(R) end
  if banner_t > 0 then banner_t = banner_t - 1 end
  tune(timer)
  if state == "title" then
    local items = screens.title_items(save)
    if btnp("up", 12, 6) then menu_i = (menu_i - 2) % #items + 1; sfx("BLIP", 0.3) end
    if btnp("down", 12, 6) then menu_i = menu_i % #items + 1; sfx("BLIP", 0.3) end
    if btnp("a") and timer > 20 then
      local id = items[menu_i].id
      if id == "day1" then
        if not save.prologue then
          start_scene(story1.prologue, function()
            save.prologue = true; write_save()
            start_scene(story1.practice, function() start_practice(true) end)
          end)
        else
          start_scene(story1.before, start_chant)
        end
      elseif id == "practice" then start_practice(false)
      elseif id == "notebook" then state, timer = "notebook", 0
      elseif id == "look" then save.opts.look = save.opts.look == "hold" and "toggle" or "hold"; write_save()
      end
    end
  elseif state == "scene" then
    if screens.scene_update() then
      music_play(false)
      local f = after_scene
      after_scene = nil
      if f then f() else to_title() end
    end
  elseif state == "practice" then
    if btnp("start") then paused = not paused end
    if paused then
      if btnp("b") then paused = false; to_title() end
      return
    end
    update_look(R)
    local inp = read_input()
    sim.step(R, inp)
    practice_step(inp)
    race_sounds(R)
    if R.over then
      tut.step = 6
      tut.done_t = tut.done_t + 1
      if tut.done_t == 1 then save.practice = true; write_save() end
      if tut.done_t > 100 then
        quiet()
        if tut.first then start_scene(story1.before, start_chant) else to_title() end
      end
    end
  elseif state == "chant" then
    chant.update()
  elseif state == "position" then
    R.dani.x = position.x()  -- Dani stands where he would start
    if timer > 15 and position.update() then
      start_x = position.x()
      R.dani.x = start_x
      state, timer = "prep", 0
      music_play(true)
    end
  elseif state == "prep" then
    if btnp("a") and timer > 20 then
      state, timer = "count", 0
      music_play(false)
      crowd_h = sfx("CROWD", 0.12, {loop = true})
    elseif btnp("b") then to_title() end
  elseif state == "count" then
    if timer % 60 == 0 and timer < 300 then tone(0, "A4", {wave = "square", duty = 0.5, vol = 0.12, decay = 0.08}) end
    if timer == 300 then
      sfx("COHETE", 0.9)
      tone(0, 700, {wave = "sine", slide = 2400, len = 0.4, vol = 0.2, sustain = 1})
    end
    if timer >= 330 then state, timer = "race", 0 end
  elseif state == "race" then
    if btnp("start") then paused = not paused end
    if paused then
      if btnp("b") then paused = false; to_title() end
      return
    end
    update_look(R)
    local inp = read_input()
    sim.step(R, inp)
    update_view(R)
    race_sounds(R)
    if R.over then state, timer = "close", 0; if looking then looking = false; rear.enter(false) end end
  elseif state == "close" then
    sim.step(R, {})
    race_sounds(R)
    if timer > 110 or (timer > 30 and btnp("a")) then finish_run() end
  elseif state == "review" then
    if (timer > 30 and btnp("a")) or timer > 60 * 30 then state, timer = "result", 0 end
  elseif state == "result" then
    if timer > 20 and btnp("a") then
      if last.closed then
        local first = not save.after1
        if first then
          start_scene(story1.after(last), function() save.after1 = true; write_save(); to_title() end)
        else to_title() end
      else
        start_prep(); state, timer = "count", 0; crowd_h = sfx("CROWD", 0.12, {loop = true}); music_play(false)
      end
    elseif timer > 20 and btnp("b") then
      if last.closed then start_prep(); state, timer = "count", 0; crowd_h = sfx("CROWD", 0.12, {loop = true}); music_play(false)
      else to_title() end
    end
  elseif state == "notebook" then
    if btnp("b") or btnp("a") then to_title() end
  end
end

function _draw()
  if state == "chant" then
    chant.draw()
    return
  end
  if state == "scene" then
    screens.scene_draw()
    return
  end
  if state == "review" or state == "result" or state == "notebook" then
    spr_clear()
    bg(1); bg(2); bg(3); line_off()
    backdrop(0x10142C)
    if state == "review" then screens.review(R, last, timer)
    elseif state == "result" then screens.result(R, last, timer)
    else screens.notebook(save) end
    return
  end
  local shake = 0
  if state == "race" or state == "close" then
    for _, b in ipairs(R.bulls) do
      if math.abs(b.z - R.dani.z) < 45 and (timer // 2) % 2 == 0 then shake = 1 end
    end
  end
  if state == "title" then  -- the title picture covers everything: draw nothing under it
    screens.title(save, menu_i, timer)
    return
  end
  if view == "side" then side.draw(R, timer) else rear.draw(R, timer, shake) end
  if state == "race" or state == "close" then dust(R) end
  if flash_t > 0 then  -- the flash whitens the PPU floor, and a burst over the pictures drawn on top of it
    fade("light", ALL, flash_t + 4)
    img("FLASH", 360 - 64 * 5, 130 - 64 * 5, {scale = 5, alpha = math.min(1, flash_t / 5)})
  elseif flash_was then fx_off() end
  flash_was = flash_t > 0
  if state == "race" or state == "close" then fallen_marks(R) end
  if state == "position" then
    position.draw()
    return
  end
  if state == "prep" then
    screens.prep(R.day, timer)
    return
  end
  local opts = {banner = banner_t > 0 and banner or nil, warn = view == "rear", prompt_y = view == "side" and 96 or (state == "practice" and 204 or 250)}
  if state == "count" then
    local s = math.min(timer // 60, 5)
    opts.clock = s < 5 and string.format("07:59:%02d", 55 + s) or "08:00:00"
  end
  if state == "practice" then opts.radar = false; opts.street = "PRÁCTICA" end
  if state ~= "close" then hud.draw(R, opts) end
  if looking and view == "rear" then screens.look_frame(state == "practice" and 218 or 286) end
  if state == "count" then screens.countdown(timer) end
  if state == "practice" then screens.tutorial(STEPS[tut.step], tut, R) end
  if state == "close" then screens.close(R) end
  if paused then screens.pause() end
end

-- dust kicked up by the herd, on the overlay at their hooves (a few puffs: each particle costs the console ~50 us)
local particles = require("particles")
local fx = particles.new()
function dust(r)
  if timer % 10 == 0 then  -- the animals bring their own dust: only a few light puffs from the street
    for _, b in ipairs(r.bulls) do
      local x, y
      if view == "side" then
        local sx = side.x(r.dani, b.x, b.z)
        if sx > 0 and sx < 240 then x, y = (sx - 40) * 2, side.y(b.x) * 2 end
      elseif math.abs(b.z - r.dani.z) < 160 then
        x, y = rear.screen(b.x, rear.back and b.z or b.z - 14, 0)
      end
      if x then
        fx:burst(x, y - 2, 1, {speed = 0.8, angle = -90, spread = 120, gravity = -0.02, drag = 0.04, life = 20,
                               size = 3, size_end = 1, colours = {0xD8C8A8, 0xB0A090, 0x807080}, shape = "circle"})
      end
    end
  end
  fx:update()
  fx:draw()
end

-- a runner down ahead: a red mark over him, so the obstacle is read in time even when he is small
function fallen_marks(r)
  for _, ru in ipairs(r.runners) do
    if (ru.state == "down" or ru.state == "trip") and ru.z > r.dani.z - 10 and ru.z - r.dani.z < 320 then
      local x, y
      if view == "side" then
        local sx = side.x(r.dani, ru.x, ru.z)
        if sx > 0 and sx < 240 then x, y = sx * 2, side.y(ru.x) * 2 - 30 end
      elseif not looking then
        x, y = rear.screen(ru.x, ru.z, 10)
      end
      if x and y > 34 then
        local blink = ru.state == "trip" and (timer // 6) % 2 == 0
        if not blink then
          tri(x - 7, y - 14, x + 7, y - 14, x, y - 2, 0xFF4030)
          rect(x - 1, y - 12, 2, 5, 0xFFFFFF)
          rect(x - 1, y - 6, 2, 2, 0xFFFFFF)
        end
      end
    end
  end
end

-- for the tests: straight into a morning's race, skipping the screens before it
function go_race(id)
  new_race(days[id or 1])
  state, timer = "race", 0
end
function set_timer(v) timer = v end  -- tests: jump within a screen that plays by itself (the review)
function mute_music() music_play(false) end  -- tests: the title's tune off, to hear the chant on its own
