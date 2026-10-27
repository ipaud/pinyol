-- playtest-gate: win   (tests/playtest_gate.py: the perfect player must reach level 21, the adapter's "win" for a game with no end; ctest runs it)
-- playtest adapter for Pozo (see docs/playtest.md). The perfect claw knows what the game knows: the enemy nearest the rim is the one to shoot (d is the depth: 1 at the far
-- end, 0 at the rim), a garra already on the rim runs at the claw lane by lane and must be shot first, the zapper clears a crowded well once, and at the end of a level the claw
-- waits in a lane with no spike (it dives down that lane, and a spike there kills it).
local W = require("well")

local function lane_of(f)
  if f.flip and f.flip.t >= 0.5 then return f.flip.to end
  return f.lane
end

local function round(me_lane, to) -- how many lanes and which way, the short way round a closed well
  local d = to - me_lane
  if W.closed then
    d = (d + W.n // 2) % W.n - W.n // 2
    if d == 0 and to ~= me_lane then d = W.n // 2 end
  end
  return d
end

PLAYTEST = {
  playing = function() return state == "play" end,
  progress = function() return G.level end,
  done = function()
    if state == "over" then return "lose" end
    if G.level >= 21 then return "win" end
  end,
  where = function() return "level_" .. G.level end,
  probe = function() return {score = G.score, n_lives = G.lives} end,
  perfect = function(pt)
    local me = G.me
    local out = {a = true}
    local rim, near, close = nil, nil, 0
    for _, f in ipairs(G.foes) do
      if f.kind ~= "pua" then
        if f.rim then
          if not rim or math.abs(round(me.lane, lane_of(f))) < math.abs(round(me.lane, lane_of(rim))) then rim = f end
        elseif not near or f.d < near.d then near = f end
        if f.d < 0.3 then close = close + 1 end
      end
    end
    -- the zapper: once a level, when the well is crowded close to the rim
    if G.zaps == 0 and close >= 3 and pt.t % 7 == 0 then out.b = true end
    local want = rim and lane_of(rim) or (near and lane_of(near))
    if not want and #G.queue == 0 then -- nothing to shoot and nothing more coming: wait where the dive is safe
      local best, bd = nil, 99
      for k = 1, W.n do
        if not G.spikes[k] then
          local d = math.abs(round(me.lane, k))
          if d < bd then best, bd = k, d end
        end
      end
      want = best
    end
    if want and want ~= me.lane then
      local d = round(me.lane, want)
      if pt.t % 2 == 0 then out[d > 0 and "right" or "left"] = true end -- one lane a press: let go between presses
    end
    return out
  end,
}
