-- A player that plays whole mornings by itself through the real state machine: skips the scenes, taps the calls when due,
-- takes the start and the briefing, runs the race with a pilot and goes through the result. Used by tests/campana.script.
--   BOT.play(d, {variant = 2, exit = "last"})   start morning d; BOT.done is true when the title is back
local bot = {}
local PILOT = require("tests.pilot")
local AP = require("tests.autoplay")

local real_btnp = btnp
local press, seen_race, picked
bot.log = {}

btnp = function(k, ...)
  if press == k then return true end
  return real_btnp(k, ...)
end

function bot.play(d, opt)
  opt = opt or {}
  bot.opt, bot.done, bot.day, seen_race, bot.states = opt, false, d, false, {}
  picked = false
  AP.install()
  go_morning(d)
end

local last_state, pick_at
local every = 0
function bot.step()
  if bot.done or not bot.day then press = nil; return end
  press = nil
  every = every + 1
  if state ~= last_state then
    last_state = state
    bot.states[#bot.states + 1] = state
    pick_at = nil
    if state == "race" then autopilot = PILOT.smart(bot.opt.exit or "first") end
    if state == "title" and #bot.states > 3 then bot.done = true; AP.remove(); autopilot = nil end
  end
  if state == "prep" and bot.opt.variant and bot.opt.variant > 1 and not picked and get_timer() > 12 then
    press = "right"; picked = true  -- pick the stretch, once the briefing takes keys
  end
  if state == "prep" then bot.variant = variant end
  if every % 12 == 0 then
    if state == "scene" then press = "b"
    elseif state == "position" or state == "prep" then press = "a"
    elseif state == "review" or state == "result" or state == "finale" then press = "a" end
  end
end

return bot
