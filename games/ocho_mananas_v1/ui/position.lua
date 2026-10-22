-- Before the run: where to start, against the left fence, the middle of the street, or the right fence. The choice
-- sets Dani's first line and which way out (R1 on the left, R2 on the right) is nearer. Drawn over the street.
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
  if tapped and py >= 80 and py <= 172 then
    local pick = math.max(1, math.min(#STARTS, math.floor((px - 26) / 144) + 1))
    if pick == sel then return true end
    sel = pick
    return false
  end
  return btnp("a") or btnp("start") or (tapped and py > 260)
end

function position.draw()
  shade(0, 0, 480, 320)
  rect(18, 40, 444, 138, 0x0B0F22)  -- up top, so Dani, standing where he will start, stays in sight
  box(18, 40, 444, 138, 0xFFE048)
  text("ELIGE DÓNDE SALIR", 240, 48, {font = "gba_title", color = 0xFFE048, align = "center"})
  for i, start in ipairs(STARTS) do
    local x = 26 + (i - 1) * 144
    local on = i == sel
    rect(x, 80, 136, 92, on and 0xFFE048 or 0x5A6290)
    rect(x + 3, 83, 130, 86, on and 0x30465A or 0x232A52)
    circ(x + 68, 98, 6, on and 0xFFE048 or 0x87939A, true)
    text(start.name, x + 68, 110, {font = "gba_body", color = 0xF6F2E8, align = "center"})
    if start.side ~= "" then text(start.side, x + 68, 126, {font = "gba_body", color = 0xF6F2E8, align = "center"}) end
    text(start.note, x + 68, 148, {font = "gba_body", color = on and 0xFFE048 or 0x9AA0C8, align = "center"})
  end
  rect(62, 270, 356, 38, 0xD8222E)
  box(62, 270, 356, 38, 0x8C2028)
  text("SALIR AQUÍ", 240, 280, {font = "gba_body", color = 0xF6F2E8, align = "center"})
end

return position
