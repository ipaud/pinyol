-- Each era owns its rules and rendering identity; the world state stays in world.lua.
local Era = {}
Era.list = {
  {id = "8bit", name = "8-BIT", run = 1.25, jump = -4.1, gravity = 0.24,
   sky = 0x17233A, deep = 0x283A50, ground = 0x82936A, light = 0xE8D69A, ink = 0x101820},
  {id = "gb", name = "GAME BOY", run = 1.65, jump = -4.45, gravity = 0.23,
   sky = 0xE9E9C1, deep = 0xA9B878, ground = 0x66845A, light = 0xE9E9C1, ink = 0x253C34},
  {id = "16bit", name = "16-BIT", run = 1.5, jump = -4.2, gravity = 0.23,
   sky = 0x243B56, deep = 0x314E68, ground = 0x916C55, light = 0xE9BD76, ink = 0x172431},
  {id = "arcade", name = "ARCADE", run = 1.8, jump = -4.3, gravity = 0.22,
   sky = 0x281F3A, deep = 0x4C3157, ground = 0xBA5948, light = 0xFFD27A, ink = 0x171321},
}
Era.index = { ["8bit"] = 1, gb = 2, ["16bit"] = 3, arcade = 4 }
function Era.allowed(world, index) return index == 3 or world.unlock[index] == true end
function Era.next(world, current, direction)
  for step = 1, #Era.list do
    local index = (current - 1 + direction * step) % #Era.list + 1
    if Era.allowed(world, index) then return index end
  end
  return current
end
return Era
