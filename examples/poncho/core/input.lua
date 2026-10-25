-- input: the buttons the game reads: the console's, or the little bot's (tests, the title's attract mode)
local In = {}
In.bot = false
In.state = {}
local held, prev = {}, {}
local NAMES = {"left", "right", "up", "down", "a", "b", "c", "start"}

function In.update()
  for _, n in ipairs(NAMES) do
    prev[n] = held[n]
    if In.bot then held[n] = In.state[n] == true else held[n] = btn(n) end
  end
end

function In.btn(n) return held[n] == true end
function In.btnp(n) return held[n] == true and not prev[n] end

return In
