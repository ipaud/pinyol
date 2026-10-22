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

-- Any morning: run at the base pace, keep out of the herd's lane, and take the first way out that comes up (or the last when
-- `which == "last"`), against its wall, pressing A inside it. Closes every morning with a retreat.
function pilot.retire(which)
  return function(r)
    local d = r.dani
    local zn
    for _, z in ipairs(r.zones) do
      if z.z1 >= d.z and (which ~= "last" or z == r.zones[#r.zones]) then zn = z break end
    end
    if not zn then return {lat = 0, adv = 0} end
    local want = d.z > zn.z0 - 180 and zn.side * 27 or 0
    -- before the way out: hold the side the herd is not on
    if want == 0 then
      local lane = require("race.sim").lane_at(r, d.z + 120)
      want = lane > 0 and -18 or 18
    end
    local inp = {lat = steer(r, want), adv = 0}
    inp.act = r.can_retire ~= nil and r.can_retire.id == zn.id
    return inp
  end
end

-- A player who reads the radar: keeps to the wall away from the nearest animal behind him while it is close, and otherwise
-- heads for the way out he wants (`which` "first" or "last").
function pilot.smart(which)
  return function(r)
    local d = r.dani
    local zn
    for _, z in ipairs(r.zones) do
      if z.z1 >= d.z and (which ~= "last" or z == r.zones[#r.zones]) then zn = z break end
    end
    local near
    for _, b in ipairs(r.bulls) do
      local back = d.z - b.z
      if back > -15 and back < 130 and (not near or back < d.z - near.z) then near = b end
    end
    local want
    if near then want = near.x > d.x and -27 or 27
    elseif zn then want = d.z > zn.z0 - 160 and zn.side * 27 or 0
    else want = 0 end
    local inp = {lat = steer(r, want), adv = 0}
    if zn and r.can_retire and r.can_retire.id == zn.id and not near then inp.act = true end
    return inp
  end
end

return pilot
