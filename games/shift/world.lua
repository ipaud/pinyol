-- One persistent world. Era interpretations alter visibility, collision, and interaction.
local World = {}
function World.new()
  return {unlock = {[3] = true}, switch = false, guardian_hp = 3, wall_broken = false,
          checkpoint = 34, exit_open = false, nodes = {false, false, false}}
end
function World.visible(world, id, era)
  if id == "machine" then return era ~= 1 end
  if id == "microplatform" then return era == 2 end
  if id == "switch" then return era == 3 end
  if id == "guardian" then return world.guardian_hp > 0 end
  if id == "wall" then return not world.wall_broken end
  return true
end
function World.solid(world, id, era)
  if id == "machine" then return era ~= 1 end
  if id == "microplatform" then return era == 2 end
  if id == "wall" then return not world.wall_broken end
  if id == "door" then return not world.exit_open end
  if id == "guardian" then return world.guardian_hp > 0 and era ~= 4 end
  return false
end
function World.activate(world, id)
  if id == "switch" and not world.switch then
    world.switch, world.exit_open, world.nodes[2] = true, true, true
    return true
  end
  return false
end
return World
