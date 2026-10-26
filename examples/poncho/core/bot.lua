-- bot: a small player that holds the buttons (the title's attract mode, the test script's "play it all the way"): runs right, jumps over walls, gaps and
-- foes it sees coming, rides the scooter when it has it.
local K = require("core.const")
local L = require("core.level")
local Hero = require("core.hero")
local Foes = require("core.foes")
local In = require("core.input")

local B = {}
B.hold_a, B.rest, B.tap, B.cool = 0, 0, 0, 0
B.scooter = false -- (the scooter is tried by hand in the test script; the bot walks and runs)

function B.step()
  local s = Hero.s
  local st = In.state
  st.left, st.right, st.up, st.down, st.a, st.b, st.c, st.start = false, false, false, false, false, false, false, false
  if s.state ~= "play" then return end
  st.right = true
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
  if B.rest > 0 then B.rest = B.rest - 1
  elseif jump and B.hold_a == 0 and (s.ground or s.coyote > 0) and B.tap == 0 and not s.pw then B.hold_a = 30 end
  if B.hold_a > 0 then
    st.a = true
    B.hold_a = B.hold_a - 1
    if B.hold_a == 0 then B.rest = 2 end -- let go for a tick so the next press is a press
  end
end

return B
