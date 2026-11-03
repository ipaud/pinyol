-- the four floors of the lighthouse, each a painted room 480x720 seen through a 480x320 camera that follows Estel up.
-- A platform is {x, y, w, kind}: y is its top, where feet stand; every platform is one-way (jumped through from below, stood on from above).
-- kind: "wood", "stone", "iron" (drawn from the plank pictures), "barrel" (a barrel bobbing on the cistern's water), "none" (painted in the room).
-- anima: {x, y, ax, ay}: where it floats and how far it wanders. window: where the ánimas go out to sea. hatch: the way up, on the platform under it.
-- hazards: gears {x, y, r} that turn (quad), water from row `water` down, wind (the gallery outside).
local L = {}

L[1] = {
  id = "f1", bg = "BG_F1", music = "torre", quota = 1, start = {x = 70, y = 660},
  lamps = {{40, 300}, {432, 398}}, windows = {{420, 160}},
  plat = {
    {0, 660, 480, "none"},
    {40, 604, 100, "wood"}, {170, 548, 110, "wood"}, {300, 492, 110, "wood"}, {180, 436, 100, "wood"},
    {40, 380, 120, "stone"}, {180, 324, 110, "wood"}, {310, 268, 160, "stone"}, {190, 212, 100, "wood"},
    {40, 156, 130, "wood"}, {170, 104, 130, "wood"},
  },
  animas = {{x = 260, y = 360, ax = 70, ay = 16}},
  oil = {{70, 380}},
  window = {x = 368, y = 64, w = 104, h = 200}, wplat = 8,
  hatch = {x = 205, y = 40, w = 60, plat = 11},
  hint = "hint_f1",
}

L[2] = {
  id = "f2", bg = "BG_F2", music = "torre", quota = 2, start = {x = 420, y = 528}, water = 560,
  lamps = {{440, 300}}, windows = {{66, 170}},
  plat = {
    {330, 528, 150, "none"},
    {236, 548, 64, "barrel"}, {130, 548, 64, "barrel"},
    {14, 516, 104, "stone"}, {120, 460, 100, "wood"}, {240, 404, 100, "wood"}, {360, 348, 110, "stone"},
    {230, 296, 110, "wood"}, {14, 248, 190, "stone"}, {176, 196, 100, "wood"}, {300, 140, 110, "wood"},
    {190, 90, 110, "iron"},
  },
  animas = {{x = 190, y = 420, ax = 70, ay = 14}, {x = 330, y = 250, ax = 60, ay = 20}},
  oil = {{400, 348}},
  window = {x = 14, y = 80, w = 110, h = 180}, wplat = 9,
  hatch = {x = 218, y = 30, w = 60, plat = 12},
  hint = "hint_f2",
}

L[3] = {
  id = "f3", bg = "BG_F3", music = "maquina", quota = 2, start = {x = 60, y = 560},
  lamps = {{44, 282}}, windows = {{404, 160}},
  plat = {
    {0, 560, 480, "none"},
    {150, 504, 210, "none"}, {20, 448, 120, "iron"}, {160, 392, 100, "iron"}, {280, 336, 130, "iron"},
    {170, 280, 100, "iron"}, {20, 224, 130, "iron"}, {300, 262, 170, "stone"}, {170, 168, 100, "iron"},
    {30, 112, 120, "wood"},
  },
  gears = {{x = 420, y = 424, r = 26, speed = 1.6}, {x = 100, y = 300, r = 24, speed = -2.2}, {x = 250, y = 126, r = 22, speed = 2.8}},
  animas = {{x = 110, y = 400, ax = 60, ay = 14}, {x = 260, y = 232, ax = 80, ay = 18}, {x = 400, y = 214, ax = 40, ay = 30}},
  oil = {{390, 336}},
  window = {x = 330, y = 56, w = 144, h = 210}, wplat = 8,
  hatch = {x = 60, y = 52, w = 60, plat = 10},
  hint = "hint_f3",
}

L[4] = {
  id = "f4", bg = "BG_F4", music = "tormenta", quota = 0, start = {x = 420, y = 660}, outside = true, sea = 700,
  lamps = {}, windows = {},
  plat = {
    {300, 660, 180, "stone"},
    {398, 604, 58, "none"}, {398, 548, 58, "none"}, {398, 492, 58, "none"}, {398, 436, 58, "none"},
    {300, 384, 70, "iron"}, {222, 336, 74, "iron"}, {240, 296, 240, "none"},
  },
  animas = {{x = 150, y = 560, ax = 60, ay = 30, drift = true}, {x = 120, y = 360, ax = 50, ay = 30, drift = true}},
  oil = {{330, 384}},
  hatch = {x = 400, y = 222, w = 70, plat = 8, door = true},
  hint = "hint_f4",
}

L.count = 4
return L
