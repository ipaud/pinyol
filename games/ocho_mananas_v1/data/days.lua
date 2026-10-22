-- The mornings, as data. Distances are street units (about 11 cm: a runner is 16 tall, Estafeta 64 wide here).
-- Only the first morning and the empty-street practice are built in this prototype.
local days = {}

days.practice = {
  id = "practice", title = "Práctica", subtitle = "Estafeta vacía", seed = 7,
  length = 2200, herd = {}, runners = 0, lane = {{0, 0}},
  zones = {},  -- the tutorial places its own way out when the player gets there
  views = {{0, "rear"}},
}

days[1] = {
  id = 1, title = "Mañana 1", date = "7 de julio", subtitle = "La foto", seed = 701,
  street = "ESTAFETA", length = 2700,
  -- the herd's lane: {z, x} keys along the street; the group keeps to it, each animal at its own offset
  lane = {{0, 6}, {600, 4}, {840, 14}, {1100, 14}, {1250, 12}, {1500, -4}, {2400, 7}, {3200, 0}},
  -- Nico on a right-hand balcony: run in front of the group, in its line, with control, and get out in time
  photo = {z0 = 760, z1 = 980, side = 1, at = 870, need = 30, near = 16, far = 45},
  -- a runner who will go down by the left-hand wall: the wall is not a free hiding place
  falls = {{start = 330, x = -25, at = 975, lie = 420}},
  herd = {
    {start = -700, speed = 1.55, members = {
      {"cabestro", -7, 0}, {"toro", 5, -6}, {"toro", -2, -14}, {"toro", 8, -22}, {"toro", -6, -28}, {"cabestro", 1, -40}}},
    {start = -1320, speed = 1.42, members = {{"cabestro", -4, 0}, {"toro", 4, -12}, {"cabestro", -1, -26}}},
  },
  runners = 12,
  zones = {
    {id = "R1", side = -1, z0 = 560, z1 = 700, label = "Portal de la izquierda"},
    {id = "R2", side = 1, z0 = 1420, z1 = 1600, label = "Portal de la derecha"},
    {id = "R3", side = -1, z0 = 2420, z1 = 2620, label = "Salida de final de tramo"},
  },
  -- which camera each part of the street wants; a cut waits for a calm moment
  views = {{0, "rear"}, {1180, "side"}, {2240, "rear"}},
  objective = "Cierra la carrera por una retirada sin quedarte sin aire.",
  challenges = {
    {id = "clean", text = "Sin contactos."},
    {id = "stay", text = "Deja pasar a la manada antes de retirarte."},
    {id = "photo", text = "La foto de Nico: delante del grupo, con control."},
  },
}

return days
