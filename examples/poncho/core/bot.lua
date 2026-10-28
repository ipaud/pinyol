-- bot: a small player that holds the buttons (the title's attract mode, the test script's "play it all the way"): runs right, jumps over walls, gaps and
-- foes it sees coming, rides the scooter when it has it.
local K = require("core.const")
local L = require("core.level")
local Hero = require("core.hero")
local Foes = require("core.foes")
local In = require("core.input")
local Boss = require("core.boss")
local Items = require("core.items")

local B = {}
B.hold_a, B.rest, B.tap, B.cool = 0, 0, 0, 0
B.scooter = false -- (the scooter is tried by hand in the test script; the bot walks and runs)

local KEYS = {"left", "a", "b", "right"}
B.sloppy = false -- a deliberately imperfect player: it misses one rhythm note in three, presses the others a few ticks off, and does not dodge every attack
local JIT = {0, -3, 4, -6, 2}
local incident, last_mode = 0, nil
local function dodges() -- every second attack is not dodged by a sloppy bot
  return not B.sloppy or incident % 2 == 1
end

-- el Gran Silencio: wait at the far end of the arena (out of the inhale's pull), hop the breath's waves, and in the rhythm round press each key on the beat
local function silencio(s, bi, st)
  if bi.mode == "rhythm" then
    local lane, dt, idx = Boss.next_note()
    if lane and B.sloppy then
      if idx % 3 == 0 then lane = nil end -- a missed note
      if lane and dt == JIT[idx % 5 + 1] then st[KEYS[lane]] = true end
    elseif lane and dt == 0 then st[KEYS[lane]] = true end
    return
  end
  if bi.mode ~= last_mode then
    last_mode = bi.mode
    if bi.mode == "wave" then incident = incident + 1 end
  end
  local tx = L.W - K.W + 40
  if s.x > tx + 10 then st.left = true elseif s.x < tx - 10 then st.right = true end
  for _, w in ipairs(Boss.waves()) do
    if not w.gone and math.abs(w.x - s.x) < 90 and s.ground and dodges() then B.hold_a = 22 end
  end
  if B.hold_a > 0 then st.a = true B.hold_a = B.hold_a - 1 end
end

-- Capitan Cuerda, Mama Sandia and Dona Paloma: stay on the far side and hop (or run from) what they throw; when the boss is down, run to it and jump on its head
local function boss_ai(s, bi, st)
  local x0, x1 = L.W - K.W, L.W
  if bi.mode ~= last_mode then
    last_mode = bi.mode
    if bi.mode == "charge" or bi.mode == "roll" or bi.mode == "rise" or bi.mode == "spit" then incident = incident + 1 end
  end
  local vuln = bi.mode == "stun" or bi.mode == "tired"
  local dx = bi.x - s.x
  if vuln then
    if math.abs(dx) > 30 then st[dx > 0 and "right" or "left"] = true end
    if s.ground and math.abs(dx) < 105 and B.hold_a == 0 then B.hold_a = 30 end
    if not s.ground and math.abs(dx) > 12 then st[dx > 0 and "right" or "left"] = true end
  elseif bi.mode == "rise" or bi.mode == "swoop" then -- she marks where he is when she dives: keep running, to the side with more room, so he is far from it when she lands
    if bi.mode == "rise" and bi.mt <= 1 then B.run_dir = (s.x < (x0 + x1) / 2) and 1 or -1 end
    if dodges() then
      local d = B.run_dir or 1
      if (d > 0 and s.x > x1 - 40) or (d < 0 and s.x < x0 + 40) then d = -d B.run_dir = d end
      st[d > 0 and "right" or "left"] = true st.c = true
    end
  else
    local tx = (s.x < bi.x) and x0 + 60 or x1 - 60 -- the far end of the side he is on (never across the boss)
    if s.x > tx + 10 then st.left = true elseif s.x < tx - 10 then st.right = true end
    for _, sd in ipairs(bi.seeds or {}) do -- a seed in the air near him: hop it
      if math.abs(sd.x - s.x) < 90 and sd.y < s.y and s.ground and dodges() and B.hold_a == 0 then B.hold_a = 24 end
    end
    local near = math.abs(dx) < 140
    if s.ground and near and (bi.mode == "charge" or bi.mode == "roll" or bi.mode == "walk") and dodges() and B.hold_a == 0 then B.hold_a = 28 end
    if not s.ground and near and bi.mode == "walk" then st.left, st.right = false, false st[dx > 0 and "right" or "left"] = true end -- over the walker and on
  end
  if B.hold_a > 0 then st.a = true B.hold_a = B.hold_a - 1 end
end

function B.step()
  local s = Hero.s
  local st = In.state
  st.left, st.right, st.up, st.down, st.a, st.b, st.c, st.start = false, false, false, false, false, false, false, false
  if s.state ~= "play" and not Hero.frozen then return end
  local bi = Boss.info()
  if bi and bi.id == "silencio" and Boss.active() then silencio(s, bi, st) return end
  if bi and Boss.active() and bi.mode ~= "wait" and bi.mode ~= "dying" then boss_ai(s, bi, st) return end
  st.right = true
  for _, f in ipairs(Items.flags) do -- past an open flag (a jump over it): turn back to it
    if not f.locked and s.x > f.x + 20 then st.right, st.left = false, true end
  end
  -- costumed: tap C (3 ticks) at a crate or a toy ahead (the power); otherwise hold C to run. Uncostumed: hold C
  if Hero.costume then
    -- how far ahead the ground is flat (a crate is not a step: the headbutt breaks it)
    local flat = 400
    for d = 20, 400, 20 do
      local gy = L.ground(s.x + d, s.y - 40, s.y + 70, 24)
      if not gy or (gy < s.y - 20 and L.at((s.x + d) // 32, gy // 32) ~= "K") then flat = d - 20 break end
    end
    local act = false
    for d = 24, 90, 6 do
      if L.at((s.x + d) // 32, (s.y - 20) // 32) == "K" and Hero.costume == "barretina" and flat >= 200 then act = true end
    end
    for _, f in ipairs(Foes.list) do
      local dx = f.x - s.x
      if f.dead == 0 and dx > 20 and dx < 130 and math.abs(f.y - s.y) < 90 and s.ground and flat >= 300 then act = true end
    end
    -- a tap: let go for two ticks, press for three, let go for seven; running (C held) the rest of the time
    if B.tap > 0 then
      B.tap = B.tap - 1
      st.c = B.tap >= 8 and B.tap <= 10
    elseif act and s.pw_cd == 0 and not s.pw then
      B.tap = 12
      st.c = false
    else st.c = true end
  else
    st.c = true
    B.tap = 0
  end
  -- after a power's burst of speed, ease off before a step or a gap (a jump at that speed overshoots)
  if s.ground and not s.pw and s.vx > 4.7 and not s.scooter then
    for d = 20, 260, 20 do
      local gy = L.ground(s.x + d, s.y - 40, s.y + 70, 24)
      if not gy or gy < s.y - 20 then st.right = false break end
    end
  end
  -- on or off the scooter as asked (once)
  if s.scooter ~= B.scooter and Hero.has_scooter and s.t % 6 == 0 then st.b = true end
  local sp = math.max(2.4, math.abs(s.vx))
  local jump = false
  -- a step too high ahead (ramps rise gently and are walked)
  local prev = s.y
  for d = 6, 24 + math.min(sp, 4.5) * 7, 6 do
    local gy = L.ground(s.x + d, prev - 44, prev + 10, 16)
    if gy and gy < prev - 14 then jump = true break end
    if gy then prev = gy end
  end
  -- the edge: no ground a step ahead
  if s.ground then
    local ax = s.x + sp * 2 + 12
    if not L.ground(ax, s.y - 20, s.y + 40, 8) then jump = true end
  end
  -- a foe ahead and about at my height
  for _, f in ipairs(Foes.list) do
    local dx = f.x - s.x
    if f.dead == 0 and dx > 0 and dx < 60 + sp * 10 and f.y > s.y - 120 and f.y - f.h < s.y then
      local safe = true -- (a jump at a toy must not carry him into a gap)
      for d = 20, 80 + sp * 30, 20 do if not L.ground(s.x + d, s.y - 40, s.y + 70, 24) then safe = false end end
      if safe then jump = true end
    end
  end
  -- a sound ring coming along the floor: hop it
  for _, r in ipairs(Foes.rings) do
    local d = (r.x - s.x) * r.dir
    if d < 0 and d > -110 and s.ground and math.abs(r.x - s.x) < 110 then jump = true end
  end
  if B.rest > 0 then B.rest = B.rest - 1
  elseif jump and B.hold_a == 0 and (s.ground or s.coyote > 0) and B.tap == 0 and not s.pw then B.hold_a = 30 end
  if B.hold_a > 0 then
    st.a = true
    B.hold_a = B.hold_a - 1
    if B.hold_a == 0 then B.rest = 2 end -- let go for a tick so the next press is a press
  end
end

return B
