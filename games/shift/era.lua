-- Each era owns its rules and rendering identity; the world state stays in world.lua.
local Era = {}
Era.list = {
  {id = "8bit", name = "8-BIT", run = 1.25, jump = -4.1, gravity = 0.24,
   sky = 0x111820, deep = 0xD7473C, ground = 0xF19476, light = 0xF2E8CE, ink = 0x111820},
  {id = "gb", name = "GAME BOY", run = 1.65, jump = -4.45, gravity = 0.23,
   sky = 0xE9E9C1, deep = 0x8AA66B, ground = 0x506E50, light = 0xE9E9C1, ink = 0x253C34},
  {id = "16bit", name = "16-BIT", run = 1.5, jump = -4.2, gravity = 0.23,
   sky = 0x4B9FD1, deep = 0x315A73, ground = 0x5D9C58, light = 0xF4D181, ink = 0x172431},
  {id = "arcade", name = "ARCADE", run = 1.8, jump = -4.3, gravity = 0.22,
   sky = 0x171A3A, deep = 0x59447D, ground = 0xE14B47, light = 0xFFD43B, ink = 0x111426},
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
