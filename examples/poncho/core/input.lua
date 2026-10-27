-- input: the buttons the game reads: the console's, or the little bot's (tests, the title's attract mode)
local In = {}
In.bot = false
In.state = {}
local held, prev = {}, {}
local NAMES = {"left", "right", "up", "down", "a", "b", "c", "start"}

-- touch: a tap this tick (the screen's own 480x320 pixels), for the menus
In.tapped, In.tx, In.ty = false, 0, 0
function In.tap_in(x, y, w, h) return In.tapped and In.tx >= x and In.tx < x + w and In.ty >= y and In.ty < y + h end

function In.update()
  local px, py, down, tapped = pen()
  In.tapped, In.tx, In.ty = tapped == true and not In.bot, px or 0, py or 0
  for _, n in ipairs(NAMES) do
    prev[n] = held[n]
    if In.bot then held[n] = In.state[n] == true else held[n] = btn(n) end
  end
end

function In.btn(n) return held[n] == true end
function In.btnp(n) return held[n] == true and not prev[n] end

return In
