-- The calls to the saint before the encierro (07:55, 07:57, 07:59), played on the touch screen. Each call is the whole
-- chant, sung by the crowd (chant/song.lua) as Pau wrote it (chant/chart.lua). The circles to touch lie along the
-- melody: their height follows the pitch, they run along two rows as the phrases do. The first mornings ask only for
-- the notes that carry each phrase; later ones for more and more of them, for following the long notes with a
-- finger, going and coming back along them, and circling on the last one.
-- Dani and Leire react in their corners.
-- chant.start(day, on_done): on_done({score = , misses = }) when the third call ends (or B skips them).
local CHART = require("chant.chart")
local SONG = require("chant.song")
local frame = require("ui.frame")
local chant = {}

local BG, DANI = "CH_BG_CROWD", "CH_DANI"
local TIMES = {"07:55", "07:57", "07:59"}
local COLORS = {0xF4C84D, 0x58D4C3, 0xFF705D, 0xD77DEB}

-- state, public for the tests (chant.s)
local S = {call_prev = "", state = "intro", day = 1, phase = 1, idx = 1, score = 0, misses = 0, tick = 0, phase_tick = 0,
           feedback_tick = 0, feedback_kind = "", reaction = 0, reaction_kind = 0, gesture = nil, hit_fx = nil,
           targets = {}, hits = 0, call_hits = 0, call_total = 0}
chant.s = S
local on_done

-- where note n lies on the screen in this call: two rows, the pitch lifts it. The second call swaps the rows and the
-- third mirrors them, so each call is its own picture.
local function note_xy(n)
  local m = CHART.PITCH[n]
  local x, y
  if n <= 8 then
    x = 60 + (n - 1) / 7 * 360
    y = 128 - (m - 69) / 7 * 50
  else
    x = 420 - (n - 9) / 8 * 360
    y = 205 - (m - 69) / 7 * 45
  end
  if S.phase == 2 then y = 270 - y end        -- rows swapped (128..78 and 205..160 become 142..192 and 65..110)
  if S.phase == 3 then x = 480 - x end
  return math.floor(x), math.floor(y)
end

local function current() return S.targets[S.idx] end

-- a target with its place and the shape of what it asks
local function make_target(t)
  local x, y = note_xy(t.n)
  local out = {n = t.n, x = x, y = y, k = t.kind, due = t.due, span = t.span, gap = t.gap}
  out.r = t.kind == "tap" and math.floor(44 - CHART.level(S.day, S.phase) * 12) or 44
  if t.kind == "slide" or t.kind == "reverse" then
    -- the finger follows the circle along a curve that leads on towards the next note
    local nx, ny = note_xy(math.min(CHART.N, t.n + 1))
    if nx == x and ny == y then nx, ny = x + 60, y end
    local ex = math.max(70, math.min(410, x + (nx - x) * 3.2))
    local ey = math.max(84, math.min(205, y + (ny - y) * 3.2))
    out.ex, out.ey = ex, ey
    out.bend = ((t.n % 2 == 0) and 1 or -1) * 26
  end
  return out
end

local function track_point(t, u)
  local dx, dy = t.ex - t.x, t.ey - t.y
  local length = math.max(1, math.sqrt(dx * dx + dy * dy))
  local cx = (t.x + t.ex) * 0.5 - (dy / length) * t.bend
  local cy = (t.y + t.ey) * 0.5 + (dx / length) * t.bend
  local v = 1 - u
  return math.floor(v * v * t.x + 2 * v * u * cx + u * u * t.ex), math.floor(v * v * t.y + 2 * v * u * cy + u * u * t.ey)
end

local function load_targets()
  S.targets = {}
  for i, t in ipairs(CHART.targets(S.day, S.phase)) do S.targets[i] = make_target(t) end
  S.idx, S.call_hits, S.call_total = 1, 0, #S.targets
end

local function spin_required() return math.pi * 2 * (0.85 + CHART.level(S.day, S.phase) * 0.7) end
local function hit_window() return CHART.window(S.day, S.phase, current()) end
local function hit_area(x, y)
  local t = current()
  local dx, dy = x - t.x, y - t.y
  return dx * dx + dy * dy <= t.r * t.r
end

-- the hits and misses are sound effects: the four synth voices are the choir's
local sounds_made = false
local function make_sounds()
  if sounds_made then return end
  sounds_made = true
  sound("CH_OK", {wave = "triangle", freq = 784, sustain = 0.01, decay = 0.14, volume = 0.5})
  sound("CH_PERFECT", {wave = "triangle", freq = 1175, sustain = 0.02, decay = 0.2, arp = 1.5, arp_time = 0.05, volume = 0.5})
  sound("CH_MISS", {wave = "noise", sustain = 0.01, decay = 0.1, lowpass = 0.25, volume = 0.55})
  sound("CH_GRAB", {wave = "triangle", freq = 660, sustain = 0.01, decay = 0.08, volume = 0.4})
end
local function play_chime(ok, perfect)
  sfx(ok and (perfect and "CH_PERFECT" or "CH_OK") or "CH_MISS", ok and 0.7 or 0.6)
end

local function finish_all()
  local f = on_done
  on_done = nil
  if f then f({score = S.score, misses = S.misses}) end
end

-- a call has ended: the next one waits for a touch, after the third the morning goes on
local function next_phase()
  SONG.stop()
  S.call_prev = S.call_hits .. " de " .. S.call_total
  if S.phase < 3 then
    S.phase = S.phase + 1
    S.phase_tick, S.feedback_tick, S.feedback_kind, S.reaction, S.reaction_kind = 0, 0, "", 0, 0
    S.gesture = nil
    load_targets()
    S.state = "intro"
  else
    finish_all()
  end
end

local function advance()
  S.idx = S.idx + 1
end

local function take_hit(bonus, rating)
  local t = current()
  S.hit_fx = {x = t.x, y = t.y, age = 24, kind = "hit", rating = rating or "BIEN"}
  S.score = S.score + 100 + (bonus or 0)
  S.hits, S.call_hits = S.hits + 1, S.call_hits + 1
  S.feedback_tick, S.feedback_kind, S.reaction, S.reaction_kind = 24, "¡A tiempo!", 24, 4
  play_chime(true, rating == "PERFECTO")
  advance()
end

local function take_miss()
  local t = current()
  S.hit_fx = {x = t.x, y = t.y, age = 24, kind = "miss", rating = "TARDE"}
  S.misses = S.misses + 1
  S.feedback_tick, S.feedback_kind = 50, "¡Ay! Se me fue la letra"
  S.reaction, S.reaction_kind = 50, ((S.misses - 1) % 3) + 1 -- confusion, complaint, scarf drop
  play_chime(false)
  advance()
end

-- the circle to hit now (x, y, kind) and when it is due: for tests that play the calls
function chant.target() local t = current(); return t.x, t.y, t.k end
function chant.due() local t = current(); return t and t.due or 0 end

-- where a perfect finger would be this tick: x, y, down, tapped, released (nil when the calls are not on). For tests.
function chant.finger()
  if S.state == "intro" then return 240, 285, false, true, false end
  local g, t = S.gesture, current()
  if g and (g.k == "slide" or g.k == "reverse") then
    local raw = math.min(g.k == "reverse" and 2 or 1, (S.phase_tick - g.started) / g.duration)
    local u = g.k == "reverse" and (raw <= 1 and raw or 2 - raw) or raw
    local x, y = track_point(g, u)
    return x, y, true, false, raw >= (g.k == "reverse" and 2 or 1)
  elseif g and g.k == "spin" then
    local a = (S.phase_tick - g.started) * 0.6
    return g.x + math.cos(a) * 30, g.y + math.sin(a) * 30, true, false, g.cleared == true
  elseif t then
    return t.x, t.y, false, true, false
  end
end

-- Jump to call p of the morning, already sung from its start: for tests that look at each call
function chant.goto_call(p)
  SONG.stop()
  S.phase, S.state, S.phase_tick, S.gesture = p, "play", 0, nil
  S.feedback_tick, S.feedback_kind, S.reaction, S.reaction_kind = 0, "", 0, 0
  load_targets()
  SONG.start()
end

function chant.start(day, done)
  make_sounds()
  S.state, S.day, S.phase, S.score, S.misses, S.hits = "intro", day or 1, 1, 0, 0, 0
  S.tick, S.phase_tick, S.feedback_tick, S.feedback_kind, S.reaction, S.reaction_kind = 0, 0, 0, "", 0, 0
  S.gesture, S.hit_fx = nil, nil
  load_targets()
  on_done = done
  spr_clear(); bg(1); bg(2); bg(3); line_off()
end

function chant.update()
  S.tick = S.tick + 1
  if S.hit_fx then S.hit_fx.age = S.hit_fx.age - 1; if S.hit_fx.age <= 0 then S.hit_fx = nil end end
  local px, py, down, tapped, released = pen()
  local action = btnp("a") or btnp("start") or (tapped and true) or false
  if S.state == "intro" then
    if btnp("b") then finish_all()  -- skip the calls (a morning played again)
    elseif action and S.tick > 12 then S.state, S.phase_tick = "play", 0; SONG.start() end
    return
  end
  S.phase_tick = S.phase_tick + 1
  if S.feedback_tick > 0 then S.feedback_tick = S.feedback_tick - 1 end
  if S.reaction > 0 then S.reaction = S.reaction - 1 end

  SONG.update(S.phase_tick, S.phase, S.day)
  local t = current()
  local g, phase_tick = S.gesture, S.phase_tick
  if g then
    if g.k == "slide" or g.k == "reverse" then
      local duration = g.duration
      local raw = math.max(0, math.min(g.k == "reverse" and 2 or 1, (phase_tick - g.started) / duration))
      local u = g.k == "reverse" and (raw <= 1 and raw or 2 - raw) or raw
      local ex, ey = track_point(g, u)
      if down or released then
        local dx, dy = px - ex, py - ey
        if dx * dx + dy * dy <= 54 * 54 then g.progress = math.max(g.progress, raw)
        else g.off = g.off + 1 end
      end
      local finish = duration * (g.k == "reverse" and 2 or 1)
      if released then
        if g.progress >= (g.k == "reverse" and 1.75 or 0.88) and g.off < 14 then
          take_hit(g.off == 0 and 25 or 0, g.off == 0 and "PERFECTO" or "BIEN")
        else take_miss() end
        S.gesture = nil
      elseif phase_tick > g.started + finish + 14 then take_miss(); S.gesture = nil end
    elseif g.k == "spin" then
      if down or released then
        local dx, dy = px - g.x, py - g.y
        local radius = math.sqrt(dx * dx + dy * dy)
        if radius >= 13 and radius <= 62 then
          local angle = math.atan(dy, dx)
          local da = (angle - g.angle + math.pi) % (2 * math.pi) - math.pi
          g.turns = g.turns + math.abs(da)
          g.angle = angle
        end
      end
      if g.turns >= g.required then g.cleared = true end
      if released then
        if g.cleared then take_hit(math.min(100, math.floor((g.turns - g.required) / (math.pi * 2) * 50)), "PERFECTO")
        else take_miss() end
        S.gesture = nil
      elseif phase_tick > g.started + 150 then take_miss(); S.gesture = nil end
    end
  elseif t and action and hit_area(px, py) then
    local window = hit_window()
    local delta = math.abs(phase_tick - t.due)
    if delta <= window then
      if t.k == "tap" then
        take_hit(0, delta <= math.max(2, math.floor(window * 0.3)) and "PERFECTO" or "BIEN")
      elseif t.k == "slide" or t.k == "reverse" then
        S.gesture = {k = t.k, x = t.x, y = t.y, ex = t.ex, ey = t.ey, bend = t.bend, started = phase_tick,
                     duration = math.max(20, t.k == "reverse" and t.span // 2 or t.span), progress = 0, off = 0}
        sfx("CH_GRAB", 0.6)
      elseif t.k == "spin" then
        S.gesture = {k = "spin", x = t.x, y = t.y, started = phase_tick,
                     angle = math.atan(py - t.y, px - t.x), turns = 0, required = spin_required()}
        sfx("CH_GRAB", 0.6)
      end
    end
  end
  t = current()  -- a hit or a miss above moved on: judge the next one against the clock
  if not S.gesture and t and S.phase_tick > t.due + hit_window() then take_miss() end
  -- the call is over when the chant has finished ringing and nothing is left to touch
  if not S.gesture and not current() and S.phase_tick > CHART.last_tick(S.day) + 20 and S.feedback_tick == 0 then
    next_phase()
  end
end

-- --- drawing -----------------------------------------------------------------------------------------------------
local function tx(s, x, y, color, font, align)
  text(s, x, y, {font = font or "jersey_small", color = color or 0xFFF4D8, align = align or "left"})
end
local function crowd_motion(in_play)
  -- Individually animated singers sit within the packed foreground mass; fixed frames keep identities stable.
  local people = in_play and {{91,224,0},{145,214,4},{326,223,1},{376,215,6}}
    or {{34,226,0},{83,215,4},{395,220,1},{446,230,6}}
  for i, p in ipairs(people) do
    local bob = math.floor(math.sin((S.tick + i * 7) / 8) * 2)
    img("CH_CROWD", p[1], p[2] + bob, {frame = p[3], scale = 0.55})
  end
end
local function draw_header(kicker)
  frame.panel("navy", -8, -10, 496, 50)
  tx(kicker, 16, 8, 0xF3CC6A)
  tx("DIA " .. S.day .. "/8", 464, 8, 0xFFFFFF, "jersey_small", "right")
end
local function draw_button(label)
  frame.panel("red", 62, 266, 356, 44)
  tx(label, 240, 278, 0xFFF2D2, "jersey_body", "center")
end
local function route_link(x1, y1, x2, y2, n)
  -- A bold red/cream guide keeps the path legible over the photograph-like crowd.
  line(x1, y1, x2, y2, 0x142334)
  local dx, dy = x2 - x1, y2 - y1
  for i = 1, 5 do
    local u = i / 6
    img("CH_ROUTE_BEAD", math.floor(x1 + dx * u - 8), math.floor(y1 + dy * u - 8),
      {frame = (math.floor(S.tick / 5) + i + n) % 4, scale = 0.8})
  end
end
local function draw_track(t, color)
  local px, py = track_point(t, 0)
  for i = 1, 12 do
    local x, y = track_point(t, i / 12)
    line(px, py, x, y, 0x14253D)
    line(px, py, x, y, color)
    if i % 2 == 0 then circ(x, y, 2, 0xFFF2D2, true) end
    px, py = x, y
  end
end

-- how hard the call is, 1 to 5 pips
local function pips(x, y)
  local lit = 1 + math.floor(CHART.level(S.day, S.phase) * 4 + 0.001)
  for i = 1, 5 do circ(x + (i - 3) * 18, y, 5, i <= lit and 0xFFE048 or 0x4A4F70, true) end
end

local function draw_intro()
  img(BG, 0, 0)
  crowd_motion()
  local pose = (S.tick % 48 < 24) and 1 or 0
  img("CH_LEIRE", 79, 157, {frame = math.floor((S.tick % 48) / 8), scale = 0.82})
  img(DANI, 193, 151, {frame = pose, scale = 1})
  draw_header(S.phase == 1 and "ANTES DEL ENCIERRO" or ("LLAMADA " .. S.phase .. " DE 3"))
  frame.panel("navy", 150, 52, 180, 84)
  text(TIMES[S.phase], 240, 60, {font = "jersey_title", scale = 1, color = 0xFFF1D1, align = "center", outline = 0x15253D})
  pips(240, 120)
  if S.phase > 1 then tx(S.call_prev .. " aciertos", 240, 150, 0xFFF2D2, "jersey_small", "center") end
  draw_button(S.phase == 1 and "ACERCARSE AL SANTO" or "CANTAR")
  if S.phase == 1 and (S.tick // 25) % 2 == 0 then tx("B: saltar", 240, 246, 0xF3CC6A, "jersey_small", "center") end
end

local function draw_gestures(target, colour)
  local bx, by = target.x, target.y
  if target.k == "slide" or target.k == "reverse" then
    if target.k == "slide" then
      img("CH_OSU_GESTURES", bx - 31, by - 28, {frame = 3, scale = 0.56})
    else
      img("CH_OSU_GESTURES", bx - 17, by - 34, {frame = 1, scale = 0.44})
    end
    draw_track(target, colour)
    circ(target.ex, target.ey, 12, colour, false)
    line(target.ex - 7, target.ey - 4, target.ex, target.ey, colour); line(target.ex - 7, target.ey + 4, target.ex, target.ey, colour)
    if target.k == "reverse" then
      circ(bx, by, 9, 0xFFF0C9, false)
      line(bx + 5, by - 4, bx, by, 0xFFF0C9); line(bx + 5, by + 4, bx, by, 0xFFF0C9)
    end
    local g = S.gesture
    if g and (g.k == "slide" or g.k == "reverse") then
      local raw = math.max(0, math.min(g.k == "reverse" and 2 or 1, (S.phase_tick - g.started) / g.duration))
      local u = g.k == "reverse" and (raw <= 1 and raw or 2 - raw) or raw
      local ox, oy = track_point(g, u)
      img("CH_SLIDER_BEAD", ox - 16, oy - 16, {frame = math.floor(S.tick / 5) % 4, scale = 1.25})
    end
  elseif target.k == "spin" then
    circ(bx, by, 49, colour, false)
    img("CH_OSU_GESTURES", bx - 34, by - 31, {frame = 2, scale = 0.62})
    local g = S.gesture
    local amount = g and g.k == "spin" and g.turns or 0
    for j = 1, 12 do
      local a = (j / 12) * math.pi * 2 - math.pi / 2
      local c = amount >= spin_required() * j / 12 and 0xFFF0C2 or colour
      circ(math.floor(bx + math.cos(a) * 44), math.floor(by + math.sin(a) * 44), 3, c, true)
    end
    local a = g and g.k == "spin" and g.angle or -math.pi / 2
    img("CH_OSU_GESTURES", bx + math.cos(a) * 44 - 14, by + math.sin(a) * 44 - 12, {frame = 4, scale = 0.28})
  end
end

local function draw_hit()
  local fx = S.hit_fx
  if not fx then return end
  local frame = math.max(0, math.min(7, math.floor((24 - fx.age) / 3)))
  if fx.kind == "hit" then
    img("CH_OSU_HIT", fx.x - 42, fx.y - 42, {scale = 0.88})
    -- The grade sits in a stable, fully visible lane above the beat field.
    tx(fx.rating, 240, 49, 0x122339, "jersey_small", "center")
    tx(fx.rating, 240, 47, fx.rating == "PERFECTO" and 0xFFF0BD or 0x73E3D1, "jersey_small", "center")
    if frame >= 1 and frame <= 5 then
      local radius = 13 + frame * 3
      circ(fx.x, fx.y, radius, frame % 2 == 0 and 0xD73532 or 0xFFF2D2, false)
      for k = 0, 7 do
        local a = k * math.pi / 4 - math.pi / 2
        line(fx.x + math.cos(a) * (radius + 2), fx.y + math.sin(a) * (radius + 2),
             fx.x + math.cos(a) * (radius + 7), fx.y + math.sin(a) * (radius + 7), k % 2 == 0 and 0xF4C84D or 0xFFF2D2)
      end
    end
    if frame >= 2 and frame <= 5 then tx("100", fx.x, fx.y - 5, 0x14253D, "jersey_small", "center") end
  else
    img("CH_OSU_MISS", fx.x - 32, fx.y - 32, {scale = 0.80})
    tx("TARDE", 240, 49, 0x17233D, "jersey_small", "center")
    tx("TARDE", 240, 47, 0xFF7061, "jersey_small", "center")
    img("CH_MISS_FX", fx.x - 24, fx.y - 24, {frame = math.min(3, math.floor(frame / 2)), scale = 1.1})
  end
end

local function draw_play()
  local reaction, rk = S.reaction, S.reaction_kind
  -- Keep the crowd and the saint as the main image; dim it only enough for the beat rings.
  img(BG, 0, 0, {dim = 0.42})
  crowd_motion(true)
  frame.panel("navy", -8, -10, 496, 50)
  text(TIMES[S.phase], 14, 6, {font = "jersey_body", color = 0xF3CC6A})
  tx("DIA " .. S.day .. "/8", 466, 9, 0xFFFFFF, "jersey_small", "right")
  for i = 1, 3 do
    circ(219 + i * 21, 20, 4, i < S.phase and 0xD9B54E or (i == S.phase and 0xF0D071 or 0x6B625D), true)
  end
  -- Compact busts sit over the crowd and change pose with each hit or mistake.
  frame.panel(reaction > 0 and "gold" or "ink", 6, 218, 78, 96)
  frame.panel(reaction > 25 and "red" or (reaction > 0 and "teal" or "ink"), 396, 218, 78, 96)
  local dp = 0
  if reaction > 25 then dp = rk == 1 and 4 or (rk == 2 and 5 or 6)
  elseif reaction > 0 and rk == 4 then dp = 2
  elseif S.tick % 44 < 22 then dp = 1 end
  local lp = reaction > 25 and 5 or (reaction > 0 and 2 or math.floor((S.tick % 36) / 6))
  img("CH_DANI_PORTRAIT", 12, 229, {frame = dp, scale = 0.78})
  img("CH_LEIRE_PORTRAIT", 407, 229, {frame = lp, scale = 0.78})
  local target = current()
  local bx, by = target and target.x or 240, target and target.y or 160
  local due = target and target.due or 0
  local open = target and math.abs(S.phase_tick - due) <= hit_window()
  local colour = COLORS[S.phase]
  -- The notes still to sing as a faint trail, and the next two as a dotted, numbered route through the crowd.
  if target then
    local px0, py0 = bx, by
    for j = S.idx + 1, math.min(S.idx + 2, #S.targets) do
      local future = S.targets[j]
      route_link(px0, py0, future.x, future.y, j)
      img("CH_OSU_NUMBERS", future.x - 19, future.y - 19, {frame = (j - 1) % 5, scale = 0.48})
      px0, py0 = future.x, future.y
    end
    local approach = math.max(0, math.min(1, (S.phase_tick - (due - 28)) / 28))
    img("CH_OSU_RINGS", bx - 48, by - 48, {frame = approach < 0.34 and 0 or (approach < 0.68 and 1 or 2), scale = 1})
    draw_gestures(target, colour)
    img("CH_OSU_NUMBERS", bx - 32, by - 32, {frame = (S.idx - 1) % 5, scale = 0.80})
    if open then circ(bx, by, 3, 0xFFFFFF, true) end
  end
  -- the line being sung, small, between the two busts
  local line_i
  for i, ph in ipairs(CHART.PHRASES) do
    if S.phase_tick >= CHART.due(ph[1], S.day) - 20 then line_i = i end
  end
  if line_i and S.phase_tick < CHART.last_tick(S.day) + 20 then
    frame.panel("navy", 96, 280, 288, 36)
    tx(CHART.LYRICS[line_i], 240, 291, 0xFFF4D8, "jersey_small", "center")
  end
  draw_hit()
end

function chant.draw()
  if S.state == "intro" then draw_intro() else draw_play() end
end

return chant
