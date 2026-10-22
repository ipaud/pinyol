-- Before the run: where to start, against the left fence, the middle of the street, or the right fence. The choice
-- sets Dani's first line and which way out (R1 on the left, R2 on the right) is nearer. Drawn over the street.
local frame = require("ui.frame")
local position = {}

local STARTS = {
  {x = -22, name = "VALLADO", side = "IZQUIERDO", note = "SALIDA R1"},
  {x = 0,   name = "CENTRO",  side = "",          note = "NEUTRO"},
  {x = 22,  name = "VALLADO", side = "DERECHO",   note = "SALIDA R2"},
}
local sel = 2

function position.reset() sel = 2 end
function position.x() return STARTS[sel].x end

-- true when the choice is made
function position.update()
  local px, py, _, tapped = pen()
  if btnp("left") or btnp("up") then sel = math.max(1, sel - 1)
  elseif btnp("right") or btnp("down") then sel = math.min(#STARTS, sel + 1) end
  if tapped and py >= 76 and py <= 172 then
    local pick = math.max(1, math.min(#STARTS, math.floor((px - 26) / 144) + 1))
    if pick == sel then return true end
    sel = pick
    return false
  end
  return btnp("a") or btnp("start") or (tapped and py > 260)
end

function position.draw()
  frame.panel("navy", 14, 34, 452, 148)  -- up top, so Dani, standing where he will start, stays in sight
  text("ELIGE DÓNDE SALIR", 240, 42, {font = "jersey_body", color = 0xFFE048, align = "center"})
  for i, start in ipairs(STARTS) do
    local x = 26 + (i - 1) * 144
    local on = i == sel
    frame.panel(on and "gold" or "ink", x, 76, 136, 96)
    local c = on and 0x3A2410 or 0xF6F2E8
    frame.icon(i == 1 and "LEFT" or (i == 3 and "RIGHT" or "RUN"), x + 48, 80, 40)
    text(start.name .. (start.side ~= "" and (" " .. start.side) or ""), x + 68, 122, {font = "jersey_small", color = c, align = "center"})
    text(start.note, x + 68, 142, {font = "jersey_small", color = on and 0x8C2028 or 0x9AA0C8, align = "center"})
  end
  frame.panel("red", 62, 266, 356, 44)
  frame.icon("A", 74, 267, 40)
  text("SALIR AQUÍ", 250, 278, {font = "jersey_body", color = 0xF6F2E8, align = "center"})
end

return position
