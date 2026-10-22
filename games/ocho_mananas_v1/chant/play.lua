-- The three calls to the saint before the encierro (07:55, 07:57, 07:59), played on the touch screen: a numbered
-- circle for each beat with a ring closing on it, two more beats shown ahead as a dotted route, and from the third
-- morning some beats are gestures (follow a curve, go and come back along it, circle until the lights fill).
-- Dani and Leire react in their corners. The melody is an original guide, not the official chant (chant/song.lua).
-- chant.start(day, on_done): on_done({score = , misses = }) when the third call ends (or B skips them).
local CHART = require("chant.chart")
local SONG = require("chant.song")
local frame = require("ui.frame")
local chant = {}

local BG, DANI = "CH_BG_CROWD", "CH_DANI"
local TIMES = {"07:55", "07:57", "07:59"}
local WINDOWS = {13, 10, 7}
local LENGTH = {4, 5, 6}
local BEATS = {{112,170},{198,213},{288,165},{365,205},{244,145},{145,230},{322,135},{104,112},{220,194},{370,145}}
local COLORS = {0xF4C84D,0x58D4C3,0xFF705D,0xD77DEB}

-- state, public for the tests (chant.s)
local S = {state = "intro", day = 1, phase = 1, idx = 1, score = 0, misses = 0, tick = 0, phase_tick = 0,
           feedback_tick = 0, feedback_kind = "", reaction = 0, reaction_kind = 0, gesture = nil, hit_fx = nil}
chant.s = S
local on_done

local function phase_length(p)
  return LENGTH[p] + (S.day >= 6 and 1 or 0) + (S.day >= 8 and 1 or 0)
end
local function beat_xy(n)
  local p = BEATS[((n + (S.day - 1) * 3 - 1) % #BEATS) + 1]
  return p[1], p[2]
end
local function gesture_type(n)
  local day, phase = S.day, S.phase
  local count = phase_length(phase)
  if day <= 2 then return "tap" end
  if day == 3 and phase == 3 and n == count then return "slide" end
  if day == 4 and phase >= 2 and n == count then return "reverse" end
  if day == 5 and phase == 2 and n == count then return "slide" end
  if day == 5 and phase == 3 and n == count then return "spin" end
  if day == 6 and phase == 2 and n == count then return "reverse" end
  if day == 6 and phase == 3 and n == count then return "spin" end
  if day == 7 and phase == 1 and n == count then return "slide" end
  if day == 7 and phase == 2 and n == count then return "reverse" end
  if day == 7 and phase == 3 and n == count then return "spin" end
  if day == 8 and phase == 1 and n == count then return "reverse" end
  if day == 8 and phase == 2 and n == count then return "slide" end
  if day == 8 and phase == 3 and n == count then return "spin" end
  return "tap"
end
local function target_for(n)
  local x, y = beat_xy(n)
  local k = gesture_type(n)
  return {x = x, y = y, k = k, i = n, r = k == "tap" and math.max(30, 44 - (S.day - 1) * 1.3) or 44}
end
local function track_end(t)
  local dx = t.x < 240 and 125 or -125
  local dy = t.y < 150 and 68 or -55
  return math.max(100, math.min(380, t.x + dx)), math.max(84, math.min(221, t.y + dy))
end
local function track_point(t, u)
  local tx, ty = track_end(t)
  local dx, dy = tx - t.x, ty - t.y
  local length = math.max(1, math.sqrt(dx * dx + dy * dy))
  local bend = (((t.i or S.idx) + S.day) % 2 == 0 and 1 or -1) * (22 + math.min(S.day, 8) * 2)
  local cx = (t.x + tx) * 0.5 - (dy / length) * bend
  local cy = (t.y + ty) * 0.5 + (dx / length) * bend
  local v = 1 - u
  return math.floor(v * v * t.x + 2 * v * u * cx + u * u * tx), math.floor(v * v * t.y + 2 * v * u * cy + u * u * ty)
end
local function spin_required()
  return math.pi * 2 * (0.85 + math.max(0, S.day - 5) * 0.22)
end
local function hit_window()
  return math.max(5, WINDOWS[S.phase] - (S.day - 1) * 0.75)
end
local function hit_area(x, y)
  local target = target_for(S.idx)
  local dx, dy = x - target.x, y - target.y
  return dx * dx + dy * dy <= target.r * target.r
end
local function play_chime(ok)
  tone(0, ok and "G4" or "C3", {wave = ok and "triangle" or "noise", vol = ok and 0.24 or 0.13, decay = 0.09})
end

local function next_phase()
  SONG.stop()
  if S.phase < 3 then
    S.phase = S.phase + 1
    S.idx, S.phase_tick, S.feedback_tick, S.feedback_kind, S.reaction, S.reaction_kind = 1, 0, 0, "", 0, 0
    SONG.start()
  else
    local f = on_done
    on_done = nil
    if f then f({score = S.score, misses = S.misses}) end
  end
end
local function take_hit(bonus, rating)
  local target = target_for(S.idx)
  S.hit_fx = {x = target.x, y = target.y, age = 24, kind = "hit", rating = rating or "BIEN"}
  S.score = S.score + 100 + (bonus or 0)
  S.feedback_tick, S.feedback_kind, S.reaction, S.reaction_kind = 24, "¡A tiempo!", 24, 4
  play_chime(true)
  tone(1, S.phase == 3 and "D5" or "A4", {wave = "triangle", vol = 0.12, decay = 0.14})
  S.idx = S.idx + 1
  if S.idx > phase_length(S.phase) then S.feedback_tick = 54 end
end
local function take_miss()
  local target = target_for(S.idx)
  S.hit_fx = {x = target.x, y = target.y, age = 24, kind = "miss", rating = "TARDE"}
  S.misses = S.misses + 1
  S.feedback_tick, S.feedback_kind = 50, "¡Ay! Se me fue la letra"
  S.reaction, S.reaction_kind = 50, ((S.misses - 1) % 3) + 1 -- confusion, complaint, scarf drop
  play_chime(false)
  S.idx = S.idx + 1
  if S.idx > phase_length(S.phase) then S.feedback_tick = 60 end
end

function chant.start(day, done)
  S.state, S.day, S.phase, S.idx, S.score, S.misses = "intro", day or 1, 1, 1, 0, 0
  S.tick, S.phase_tick, S.feedback_tick, S.feedback_kind, S.reaction, S.reaction_kind = 0, 0, 0, "", 0, 0
  S.gesture, S.hit_fx = nil, nil
  on_done = done
  spr_clear(); bg(1); bg(2); bg(3); line_off()
end

function chant.update()
  S.tick = S.tick + 1
  if S.hit_fx then S.hit_fx.age = S.hit_fx.age - 1; if S.hit_fx.age <= 0 then S.hit_fx = nil end end
  local px, py, down, tapped, released = pen()
  local action = btnp("a") or btnp("start") or (tapped and true) or false
  if S.state == "intro" then
    if btnp("b") then  -- skip the calls (a morning played again)
      local f = on_done
      on_done = nil
      if f then f({score = 0, misses = 0}) end
    elseif action then S.state, S.phase_tick = "play", 0; SONG.start() end
    return
  end
  S.phase_tick = S.phase_tick + 1
  if S.feedback_tick > 0 then S.feedback_tick = S.feedback_tick - 1 end
  if S.reaction > 0 then S.reaction = S.reaction - 1 end

  local count = phase_length(S.phase)
  local window = hit_window()
  SONG.update(S.phase_tick, S.phase, S.day, count)
  local due = CHART.onset_tick(S.idx, S.phase, S.day)
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
      elseif phase_tick > g.started + finish + window + 10 then take_miss(); S.gesture = nil end
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
      elseif phase_tick > g.started + 120 then take_miss(); S.gesture = nil end
    end
  elseif action and S.idx <= count and hit_area(px, py) then
    local delta = math.abs(phase_tick - due)
    if delta <= window then
      local target = target_for(S.idx)
      if target.k == "tap" then
        take_hit(0, delta <= math.max(2, math.floor(window * 0.3)) and "PERFECTO" or "BIEN")
      elseif target.k == "slide" or target.k == "reverse" then
        local tx, ty = track_end(target)
        S.gesture = {k = target.k, x = target.x, y = target.y, tx = tx, ty = ty, i = target.i, started = phase_tick,
                     duration = math.max(20, 34 - (S.day - 3) * 2), progress = 0, off = 0}
        tone(0, "A4", {wave = "triangle", vol = 0.16, decay = 0.07})
      elseif target.k == "spin" then
        S.gesture = {k = "spin", x = target.x, y = target.y, started = phase_tick,
                     angle = math.atan(py - target.y, px - target.x), turns = 0, required = spin_required()}
        tone(0, "A4", {wave = "triangle", vol = 0.16, decay = 0.07})
      end
    elseif phase_tick > due + window then take_miss() end
  end
  if not S.gesture and S.idx <= count and S.phase_tick > due + window then take_miss() end
  if S.idx > count and S.feedback_tick == 0 then next_phase() end
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

local function draw_intro()
  img(BG, 0, 0)
  crowd_motion()
  local pose = (S.tick % 48 < 24) and 1 or 0
  img("CH_LEIRE", 79, 157, {frame = math.floor((S.tick % 48) / 8), scale = 0.82})
  img(DANI, 193, 151, {frame = pose, scale = 1})
  draw_header("ANTES DEL ENCIERRO")
  text(TIMES[1], 240, 105, {font = "jersey_body", scale = 2, color = 0xFFF1D1, align = "center", outline = 0x15253D})
  draw_button("ACERCARSE AL SANTO")
  if (S.tick // 25) % 2 == 0 then tx("B: saltar", 240, 52, 0xF3CC6A, "jersey_small", "center") end
end

local function draw_gestures(target, colour)
  local bx, by = target.x, target.y
  if target.k == "slide" or target.k == "reverse" then
    local tx_, ty = track_end(target)
    if target.k == "slide" then
      img("CH_OSU_GESTURES", bx - 31, by - 28, {frame = 3, scale = 0.56})
    else
      img("CH_OSU_GESTURES", bx - 17, by - 34, {frame = 1, scale = 0.44})
    end
    draw_track(target, colour)
    circ(tx_, ty, 12, colour, false)
    line(tx_ - 7, ty - 4, tx_, ty, colour); line(tx_ - 7, ty + 4, tx_, ty, colour)
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
  local count = phase_length(S.phase)
  local target = S.idx <= count and target_for(S.idx) or nil
  local bx, by = target and target.x or 240, target and target.y or 160
  local due = CHART.onset_tick(S.idx, S.phase, S.day)
  local open = math.abs(S.phase_tick - due) <= hit_window()
  local colour = COLORS[(math.floor((S.idx - 1) / 4) % #COLORS) + 1]
  -- Show the next two beats as a dotted, numbered route through the crowd.
  local px0, py0 = bx, by
  for j = S.idx + 1, math.min(S.idx + 2, count) do
    local future = target_for(j)
    route_link(px0, py0, future.x, future.y, j)
    img("CH_OSU_NUMBERS", future.x - 19, future.y - 19, {frame = (j - 1) % 5, scale = 0.48})
    px0, py0 = future.x, future.y
  end
  if target then
    local approach = math.max(0, math.min(1, (S.phase_tick - (due - 28)) / 28))
    img("CH_OSU_RINGS", bx - 48, by - 48, {frame = approach < 0.34 and 0 or (approach < 0.68 and 1 or 2), scale = 1})
    draw_gestures(target, colour)
    img("CH_OSU_NUMBERS", bx - 32, by - 32, {frame = (S.idx - 1) % 5, scale = 0.80})
    if open then circ(bx, by, 3, 0xFFFFFF, true) end
  end
  draw_hit()
end

function chant.draw()
  if S.state == "intro" then draw_intro() else draw_play() end
end

return chant
