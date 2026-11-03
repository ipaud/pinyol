-- playtest-gate: win   (tests/playtest_gate.py: the perfect player must light the lamp; ctest runs it)
-- playtest adapter for El Faro de las Ánimas (see docs/playtest.md). The perfect player is the game's own bot (examples/faro/core/bot.lua) pressing
-- buttons: on each floor it calms the wild ánimas that come near with the lantern held high (B), takes as many as the hatch needs to the window and
-- climbs, along jumps that core/route.lua flew beforehand with Estel's own body; in the lantern room it carries fire from a pilot flame to the lamp
-- and steps out of every tentacle's way. The title, the story and the screens between are passed with A, as the bots do by themselves.
local Bot = require("core.bot")
local Play = require("core.play")
local Boss = require("core.boss")
local Run = require("core.run")

PLAYTEST = {
  playing = function() return G.state == "play" or G.state == "boss" end,
  progress = function()
    local k = Run.floor * 100 + Run.freed * 10
    if G.state == "play" and Play.body then k = k + (720 - Play.body.y) / 72 end
    if G.state == "boss" then k = k + Boss.wicks * 3 + (Boss.charged and 1 or 0) end
    if G.state == "ending" then k = k + 1000 end
    return k
  end,
  done = function()
    if G.state == "ending" then return "win" end
    if G.state == "over" then return "lose" end
  end,
  where = function()
    if G.state == "boss" then return "lamp_" .. Boss.wicks end
    return "floor_" .. Run.floor
  end,
  probe = function() return {n_warmth = Run.warmth, n_matches = Run.matches, freed = Run.freed, ticks = Run.ticks} end,
  invariants = function()
    if Run.warmth > 5 or Run.matches > 3 then return "warmth_" .. Run.warmth .. "_matches_" .. Run.matches end
    if Run.freed > 8 then return "freed_" .. Run.freed end
    if G.state == "play" and Play.freed > #Play.animas then return "floor_freed_" .. Play.freed end
  end,
  deaths = function() return 3 - Run.matches end,
  perfect = function(pt)
    if G.state == "play" then return Bot.buttons(Bot.floor(Play), Play.body.ground) end
    if G.state == "boss" then return Bot.buttons(Bot.boss(Boss), Boss.body.ground) end
    if G.state == "title" or G.state == "intro" or G.state == "ending" or G.state == "over" then
      return pt.t % 8 < 2 and {a = true} or {}
    end
    return {}
  end,
}
