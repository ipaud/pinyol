-- playtest-gate: win   (tests/playtest_gate.py: the perfect player must burst in the last palmera; ctest runs it)
-- playtest adapter for Traca (see docs/playtest.md). The perfect player is the game's own pilot (pilot.lua), the one that plays the title's demo,
-- thinking every tick: it sees every bullet in the swarms and where it will be, tries the 17 ways to hold the arrows a few ticks ahead, takes
-- the safest under its target and lights a traca when nothing is safe. It answers in the console's buttons, turned as the game reads them.
PILOT.every = 1

PLAYTEST = {
  playing = function() return state == "play" end,
  progress = function() return P.stage * 100000 + math.floor(P.sc) * 10 + (P.boss and (2000 - P.boss.hp) // 10 or 0) + (P.bell and 200 - P.bell.hp or 0) end,
  done = function()
    if state == "over" then return "lose" end
    if state == "won" then return "win" end
  end,
  where = function() return "stage_" .. P.stage .. (P.bell and "_bell" or "") .. (P.boss and "_moon" or "") end,
  probe = function() return {score = P.score, n_lives = P.lives, n_bombs = P.bombs, n_power = P.power} end,
  deaths = function() return P.deaths end,
  invariants = function()
    if P.power < 1 or P.power > 4 then return "power_" .. P.power end
    if P.bombs > 5 then return "bombs_" .. P.bombs end
    if P.stage < 1 or P.stage > 5 then return "stage_" .. P.stage end
  end,
  perfect = function() return PILOT.buttons(P) end,
}
