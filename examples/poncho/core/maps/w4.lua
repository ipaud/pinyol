-- world 4, the keyboard stage: 232 x 14 tiles (7424 x 448 px). The toy keyboard as a concert stage, all of it rhythm and friendly: a floor of piano keys ('P': each white key
-- sinks and plays a note, higher as you go), black keys ('B', solid blocks), drum pads that bounce harder on the beat (120 bpm = 30 ticks, core/beat.lua), a spotlight
-- zone where a sweeping beam freezes the toys it touches, a long glissando of ramps for the scooter, two keyboards (checkpoints) and the costumes. The last screen
-- (cols 217-231) is the arena of el Gran Silencio, with two low shelves to stand on; the flag opens when he is beaten.
return function(k)
local gap, blocks, shelf, ramp, rampdown, obj, coins, arc, foe, piano, black, spot = k.gap, k.blocks, k.shelf, k.ramp, k.rampdown, k.obj, k.coins, k.arc, k.foe, k.piano, k.black, k.spot
local FR = k.FR

-- 1. the wings: bare boards to run on, then the keyboard begins and the notes climb
coins(8, 1, 5, 1, 0)
piano(12, 44)
foe("note", 22, 0, {range = 2})
coins(14, 1, 12, 1, 0)
obj("cos_dino", 40, 0)
-- 2. black keys to hop over, a drum pad up to a shelf, a cable that slides
black(48, 1, 2) black(54, 2, 1) black(58, 1, 2)
piano(46, 66)
obj("drum", 62, 0)
shelf(63, 70, 5)
coins(64, 6, 6, 1, 0)
obj("icecream", 67, 6)
foe("cable", 72, 0, {range = 4})
-- 3. the first keyboard
obj("keyboard", 78, 0)
-- 4. the spotlight: the beam sweeps the zone, speakers and notes freeze where it falls
spot(84, 112)
piano(82, 118)
foe("speaker", 90, 0, {})
foe("note", 96, 0, {range = 2})
foe("note", 98, 0, {range = 2, phase = 0})
foe("speaker", 106, 0, {})
foe("bubble", 100, 3, {range = 5})
coins(86, 1, 10, 2, 0)
obj("cos_futbol", 116, 0)
-- 5. a pit of drum pads: on the beat they throw you across
gap(122, 142)
black(126, 1, 1, FR + 1)
obj("drum", 126, 0)
black(132, 1, 1, FR + 1)
obj("drum", 132, 0)
black(138, 1, 1, FR + 1)
obj("drum", 138, 0)
arc(124, 3, 19, 2.2)
-- 6. bubbles and a cable after the pit
piano(143, 160)
foe("cable", 150, 0, {range = 4})
foe("bubble", 154, 3, {range = 5})
obj("cos_barretina", 162, 0)
blocks(166, 1, 2, "K")
-- 7. the glissando: the scooter, then ramps up and down along the keys
obj("scooter", 170, 0)
piano(168, 196)
ramp(174, 3)
rampdown(180, 3)
ramp(192, 2)
gap(196, 200)
arc(196, 3, 6, 1.4)
coins(176, 5, 8, 1, 0)
foe("bubble", 188, 3, {range = 6})
-- 8. the second keyboard and the boots, speakers either side of the way to the arena
piano(201, 216)
obj("keyboard", 204, 0)
obj("cos_boots", 208, 0)
foe("speaker", 211, 0, {})
foe("note", 214, 0, {range = 2})
-- 9. the arena of el Gran Silencio (cols 217-231): two low shelves out of the pull's reach; the flag is shut until he is beaten
shelf(219, 222, 2)
shelf(223, 225, 2)
obj("flag", 229, 0, {locked = true})
k.boss("silencio", 228)
k.start(3)
end
