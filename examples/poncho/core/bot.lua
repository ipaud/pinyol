-- bot: a small player that holds the buttons (the title's attract mode, the test script's "play it all the way"): runs right, jumps over walls, gaps and
-- foes it sees coming, rides the scooter when it has it.
local K = require("core.const")
local L = require("core.level")
local Hero = require("core.hero")
local Foes = require("core.foes")
local In = require("core.input")

local B = {}
B.hold_a, B.rest = 0, 0
B.scooter = false -- (the scooter is tried by hand in the test script; the bot walks and runs)

function B.step()
  local s = Hero.s
  local st = In.state
  st.left, st.right, st.up, st.down, st.a, st.b, st.c, st.start = false, false, false, false, false, false, false, false
  if s.state ~= "play" then return end
  st.right = true
  st.c = true
  -- on or off the scooter as asked (once)
  if s.scooter ~= B.scooter and Hero.has_scooter and s.t % 6 == 0 then st.b = true end
  local sp = math.max(2.4, math.abs(s.vx))
  local jump = false
  -- a step too high ahead (ramps rise gently and are walked)
  local prev = s.y
  for d = 6, 24 + sp * 7, 6 do
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
    if f.dead == 0 and dx > 0 and dx < 60 + sp * 10 and f.y > s.y - 120 and f.y - f.h < s.y then jump = true end
  end
  if B.rest > 0 then B.rest = B.rest - 1
  elseif jump and B.hold_a == 0 and (s.ground or s.coyote > 0) then B.hold_a = 30 end
  if B.hold_a > 0 then
    st.a = true
    B.hold_a = B.hold_a - 1
    if B.hold_a == 0 then B.rest = 2 end -- let go for a tick so the next press is a press
  end
end

return B
