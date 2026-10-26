-- world 2, the living fruit market: 204 x 14 tiles (6528 x 448 px). Its own rhythm: fruit-crate steps ('T' crates, 'K' ones that break), conveyor belts (a moving floor),
-- a bouncy awning, a banana-peel patch, a rolling melon, a pit with a cart, three keyboards (checkpoints), the four costumes and a secret shelf, and the market's
-- own toys: the apple (it curls into a ball when stomped), the banana (it slides), the bee (a sine path and a dive), cherries in pairs (they bounce out of step).
-- The last screen (cols 189-203) is the arena of Mama Sandia, a giant watermelon.
return function(k)
local gap, blocks, shelf, ramp, obj, coins, arc, foe, boss, conveyor, cart = k.gap, k.blocks, k.shelf, k.ramp, k.obj, k.coins, k.arc, k.foe, k.boss, k.conveyor, k.cart
local FR = k.FR

-- 1. the stalls open: room to run, a first apple, fruit-crate steps
coins(8, 1, 5, 1, 0)
foe("apple", 14, 0, {range = 4})
blocks(18, 1, 2, "T") blocks(20, 2, 2, "T") blocks(22, 1, 2, "T")
arc(18, 3, 6, 1.2)
-- 2. a conveyor against him, cherries in pairs behind it
conveyor(26, 33, -1)
coins(27, 1, 6, 1, 0)
foe("cherry", 38, 0, {range = 3})
foe("cherry", 39, 0, {range = 3, phase = -9})
-- 3. the first keyboard, and the cap
obj("keyboard", 43, 0)
obj("cos_barretina", 46, 0)
blocks(52, 1, 2, "K") blocks(52, 1, 2, "K", FR - 1)
coins(54, 2, 4, 1, 0)
-- 4. the scooter and a banana that slides
obj("scooter", 58, 0)
foe("banana", 63, 0, {range = 5})
coins(60, 1, 6, 1, 0)
-- 5. the bouncy awning up to a high shelf of fruit, a peel patch under it
obj("awning", 72, 2)
obj("peel", 78, 0, {w = 96})
shelf(74, 83, 6)
coins(75, 7, 7, 1, 0)
obj("icecream", 79, 7)
-- 6. a melon rolls along a long flat
foe("melon", 90, 0, {range = 9})
coins(86, 1, 4, 1, 0)
-- 7. a pit with a cart that rolls across it
gap(100, 104)
cart(99, 102, 0, 1.0)
-- 8. the second keyboard and the onesie
obj("keyboard", 110, 0)
obj("cos_dino", 113, 0)
foe("bee", 118, 4, {range = 6})
foe("bee", 124, 5, {range = 5})
-- 9. a conveyor with him, crates, an apple pair
conveyor(130, 135, 1)
coins(129, 1, 8, 1, 0)
blocks(140, 1, 3, "T")
foe("apple", 145, 0, {range = 4})
foe("apple", 149, 0, {range = 4})
-- 10. boots and the secret shelf over a melon
obj("cos_boots", 154, 0)
shelf(158, 166, 6)
arc(158, 7, 9, 0.8)
obj("icecream", 162, 7)
foe("melon", 162, 0, {range = 6})
-- 11. a ramp over a wide gap (the scooter), the football shirt, crates to break
ramp(170, 2)
gap(174, 179)
arc(174, 3, 6, 1.2)
obj("cos_futbol", 182, 0)
blocks(184, 1, 2, "K")
foe("cherry", 180, 0, {range = 2})
foe("cherry", 181, 0, {range = 2, phase = -9})
-- 12. the third keyboard before the arena; the last screen is Mama Sandia's; the flag is shut until she is beaten
obj("keyboard", 186, 0)
obj("flag", 200, 0, {locked = true})
boss("sandia", 198)
k.start(3)
end
