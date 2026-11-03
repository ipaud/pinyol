-- playtest adapter for El Celler (docs/playtest.md): how the bots play it, and what a perfect night is.
-- playtest-gate: win   (ctest then fails if the perfect player below ever stops getting out at dawn)
-- The perfect player is bot.lua, the same watchman who plays the title's demo: a breadth first search over the real map
-- (the doors it may open, the gate once it has the key, the lever's gate once it is open), the corks fired at the ghost
-- corks it can see, a candle taken when the light runs low. It presses the buttons; nothing is moved by hand.
local B = require("bot")

PLAYTEST = {
  playing = function() return state == "play" end,
  progress = function() -- galleries crossed, then what the candle has shown of this one, the key and the levers
    return G.level * 1000 + G.seen_n + (G.has_key and 200 or 0) + G.levers_on * 100
  end,
  done = function()
    if state == "dawn" then return "win" end
    if state == "dark" then return "lose" end
  end,
  where = function() return "gallery_" .. G.level end,
  deaths = function() return G.matches_used end,
  probe = function() return {n_wax = G.wax, n_corks = G.corks, n_matches = G.matches, score = G.score} end,
  invariants = function()
    if G.ghosts_popped > G.ghosts_total then return "popped_" .. G.ghosts_popped .. "_of_" .. G.ghosts_total end
    if G.levers_on > rawlen(G.levers) then return "levers_" .. G.levers_on end
    if G.wax > 100 then return "wax_over_100" end
  end,
  perfect = function() return B.think() end,
}
