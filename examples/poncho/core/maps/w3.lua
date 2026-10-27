-- world 3, the chalk park: 240 x 14 tiles (7680 x 448 px), longer than the market. Its new verbs: hopscotch tiles ('H': the first step cracks one, the second makes it vanish,
-- chalk dust), puddles (they slow him down unless he wears the rain boots), a seesaw that throws him high, swings that swing (moving platforms), a rainbow of chalk ramps for
-- the scooter. Two keyboards on picnic blankets (checkpoints), the four costumes, and the park's toys in readable groups: pigeons (they stop to peck), balls (bouncers),
-- snails (slow, a stomp sends them into the shell), kites (a sine path above).
-- The last screen (cols 214-239) is left empty for a boss to come: kit.boss would go there; the flag is open.
return function(k)
local gap, blocks, shelf, ramp, rampdown, obj, coins, arc, foe, hop, swing = k.gap, k.blocks, k.shelf, k.ramp, k.rampdown, k.obj, k.coins, k.arc, k.foe, k.hop, k.swing
local FR = k.FR

-- 1. the gate: room to run, a first pigeon that stops to peck, crates to hop up
coins(8, 1, 5, 1, 0)
foe("pigeon", 15, 0, {range = 4})
blocks(19, 1, 2, "T") blocks(21, 2, 2, "T")
arc(19, 3, 5, 1.2)
-- 2. hopscotch over the pond: single squares, each lets you land once (a second landing and it is gone)
gap(25, 38)
hop(26, 0) hop(28, 0) hop(30, 0) hop(32, 0) hop(34, 0) hop(36, 0)
coins(26, 2, 6, 2, 0)
-- 3. the rain boots, then two puddles with a snail between them
obj("cos_boots", 41, 0)
obj("puddle", 47, 0, {w = 128})
foe("snail", 52, 0, {range = 2})
obj("puddle", 57, 0, {w = 128})
coins(46, 1, 12, 1, 0)
-- 4. the seesaw: up to a shelf of coins and a lollipop, and a drop to the other side
obj("seesaw", 66, 0)
shelf(68, 78, 7)
coins(69, 8, 9, 1, 0)
obj("icecream", 74, 8)
blocks(82, 1, 3, "K")
-- 5. the first keyboard (a picnic blanket) and the cap
obj("keyboard", 87, 0)
obj("cos_barretina", 91, 0)
foe("ball", 96, 0, {range = 3})
foe("ball", 99, 0, {range = 3, phase = 0})
-- 6. swings over a pit
gap(104, 121)
swing(108, 0, 1.5, 200, 0) swing(113, 0, 1.5, 200, 2.1) swing(118, 0, 1.5, 200, 4.2)
arc(106, 3, 15, 1.4)
-- 7. kites over a group of pigeons
obj("cos_dino", 129, 0)
foe("pigeon", 134, 0, {range = 3}) foe("pigeon", 138, 0, {range = 3})
foe("plane", 136, 5, {range = 5}) foe("plane", 142, 5, {range = 5})
coins(131, 1, 10, 1, 0)
-- 8. the rainbow of chalk: the scooter, then ramps up and over two gaps
obj("scooter", 148, 0)
ramp(154, 2)
gap(158, 162)
arc(158, 3, 5, 1.2)
coins(164, 1, 4, 1, 0)
ramp(170, 3)
gap(176, 180)
arc(176, 4, 5, 1.4)
-- 9. the second keyboard and a high secret: a second seesaw to a shelf with the football shirt
obj("keyboard", 186, 0)
obj("seesaw", 190, 0)
shelf(194, 203, 7)
obj("cos_futbol", 198, 8)
coins(194, 8, 4, 2, 0)
blocks(184, 1, 2, "K")
-- 10. the last hopscotch: stairs of squares, puddle, snails and balls; then the flag
hop(206, 1) hop(208, 2) hop(210, 1)
obj("puddle", 212, 0, {w = 96})
foe("snail", 217, 0, {range = 2})
foe("ball", 221, 0, {range = 3})
foe("pigeon", 226, 0, {range = 3})
blocks(231, 1, 2, "W")
obj("flag", 236, 0)
coins(214, 1, 8, 1, 0)
k.start(3)
end
