-- Test helpers: autopilots that play a morning the way a player would. Loaded only by test scripts.
local pilot = {}

local function steer(r, want)
  local d = r.dani.x - want
  return d > 1 and -1 or d < -1 and 1 or 0
end

local function herd_back(r)  -- how far behind Dani the nearest animal of the first group is (or a big number)
  local back = 1e9
  for _, b in ipairs(r.bulls) do
    local k = r.dani.z - b.z
    if b.group == 1 and k > -20 then back = math.min(back, k) end
  end
  return back
end

-- Nico's photo: into the herd's line before his balcony, let it come close, push to stay in front, then cut left
-- across the street, wait for the herd to pass, and leave by the right-hand way out (R2).
function pilot.photo(r)
  local d, ph = r.dani, r.photo
  local inp = {lat = 0, adv = 0}
  local back = herd_back(r)
  if not ph.taken then
    if d.z > 600 then inp.lat = steer(r, 14) end
    if d.z > 760 then
      if back > 40 then inp.ease = true elseif back < 32 then inp.push = true end
    end
  elseif not r.stats.herd_passed_at then
    inp.push = d.air > 5
    inp.lat = steer(r, -12)
  else
    inp.lat = steer(r, d.z > 1300 and 26 or -12)
    inp.act = r.can_retire ~= nil and r.can_retire.id == "R2"
  end
  return inp
end

-- Hiding against the right-hand wall while the herd goes by in the middle-right: it brushes.
function pilot.right_wall(r)
  return {lat = steer(r, 29), adv = 0, act = r.can_retire ~= nil and r.can_retire.id == "R2"}
end

-- Against the left wall: the runners crowd there, and one goes down by it.
function pilot.left_wall(r)
  return {lat = steer(r, -27), adv = 0}
end

-- Reading the street: the gap between the crowded left wall and the herd's line, then out on the right (R2).
function pilot.gap(r)
  local d = r.dani
  local want = r.stats.herd_passed_at and d.z > 1300 and 26 or -12
  return {lat = steer(r, want), adv = 0, act = r.can_retire ~= nil and r.can_retire.id == "R2"}
end

return pilot
