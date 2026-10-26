-- world 1, the giant playroom: 192 x 14 tiles of 32 px (6144 x 448 px). Written with the builders of core/map.lua.
return function(k)
local floor, gap, blocks, shelf, ramp, rampdown, obj, coins, arc, foe, boss = k.floor, k.gap, k.blocks, k.shelf, k.ramp, k.rampdown, k.obj, k.coins, k.arc, k.foe, k.boss
local FR, COLS = k.FR, k.COLS
floor(0, COLS - 1)

-- 1. the start: room to walk, run and jump
coins(8, 1, 5, 1, 0)
blocks(15, 1, 2, "T")
arc(14, 1, 5, 1.4)
-- 2. steps up and down, a shelf with the first ice cream, a toy car
blocks(20, 1, 2) blocks(22, 2, 3) blocks(25, 1, 2)
shelf(28, 33, 3)
coins(29, 4, 4, 1, 0)
obj("icecream", 31, 5)
foe("car", 36, 0, {range = 5})
-- costume 1: the barretina (red cap, headbutt), then the toy car it can beat
obj("cos_barretina", 18, 0)
-- 3. a gap that asks for a jump, a spring to a high shelf, a ball
blocks(38, 1, 2, "T")
gap(41, 44)
arc(40, 2, 6, 2)
obj("spring", 48, 0)
shelf(45, 52, 5)
coins(46, 6, 5, 1, 0)
obj("icecream", 51, 6)
foe("ball", 53, 0, {range = 4})
-- 4. the toy keyboard (checkpoint, a friend), the scooter, a long flat run and a ramp over a gap
obj("keyboard", 57, 0)
obj("scooter", 62, 0)
blocks(66, 1, 2, "K")  -- crates: a headbutt, a stomp or the scooter at speed breaks them
coins(64, 1, 6, 1, 0)
ramp(70, 2)
gap(74, 78)
arc(74, 3, 5, 1.2)
-- 5. toy boxes to climb, a paper plane, a spring
coins(82, 1, 3, 1, 0)
obj("cos_dino", 85, 0)  -- costume 2: the dinosaur onesie (fire, ground pound)
foe("ball", 90, 0, {range = 3})
blocks(88, 1, 2, "T") blocks(90, 2, 2, "T")
shelf(93, 99, 3)
blocks(95, 1, 2, "K", FR - 3)
foe("plane", 97, 4, {range = 6})
coins(94, 4, 5, 1, 0)
obj("spring", 101, 0)
shelf(103, 108, 5)
obj("icecream", 105, 6)
coins(107, 6, 3, 1, 0)
-- 6. a wide gap with floating toys, then wind-up robots
gap(112, 118)
shelf(113, 114, 2) shelf(116, 117, 2)
coins(113, 3, 2, 3, 0)
obj("cos_boots", 120, 0)  -- costume 3: green boots (a splash jump in the air), for the secret shelf above the robots
shelf(125, 131, 6)
arc(125, 7, 7, 0.8)
obj("icecream", 128, 7)
foe("robot", 124, 0, {range = 5})
foe("robot", 129, 0, {range = 5})
-- 7. the second toy keyboard, a hill of blocks
obj("keyboard", 134, 0)
blocks(139, 1, 6, "T") blocks(140, 1, 4, "W", FR - 1) blocks(141, 1, 2, "T", FR - 2)
foe("car", 146, 0, {range = 6})
foe("plane", 148, 3, {range = 6})
-- 8. the long run: a ramp up to a shelf in the air, robots and balls along the floor
coins(152, 1, 5, 1, 0)
blocks(150, 1, 2, "K")
obj("cos_futbol", 155, 0)  -- costume 4: the football shirt (a dash, invulnerable for 5 s)
ramp(158, 2)
shelf(164, 171, 4)
coins(165, 5, 5, 1, 0)
foe("ball", 168, 0, {range = 3})
-- 9. the last screen (cols 177-191) is the arena of Capitan Cuerda, a giant wind-up robot; the flag is shut until he is beaten
obj("keyboard", 174, 0)
obj("flag", 188, 0, {locked = true})
boss("cuerda", 186)
k.start(3)
end
