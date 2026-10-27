-- worlds: the themes of the game's worlds and the player's progress. The contract with the art: everything a world draws is named here; an asset that is not in the
-- game's data (data/deco.lua, data/deco2.lua) is replaced by its stand-in (a world-1 picture, tinted by `mul`), so a world plays before its art arrives.
--
--   defs[i] = {id, name_key, ready, cols, music, bgcolor, boss,
--     far  = {def = "data.xx_slices", fallback = "data.far_slices", speed, y, ycam, mul}      the wall: a picture cut in 160 px columns (tools/slice_pic.py), 1 of 2 wide layers
--     case = {...the same, dim}                                                                the second wide layer (or none)
--     mid  = {speed, period, dim, mul, list = {{x, "FM_G_APPLE", "BG_G_BALL"}, ...}}            cut-out giants behind the floor: x in the layer, asset, stand-in
--     fore = {period, speed, list = {{x, asset, y, stand-in}, ...}}                            foreground pieces in front of everything
--     tiles = "FT", tilemul = nil,  alias = {TOY_COIN = "FI_COIN", ...}                        tile strips FT_TILES, FT_FLOOR2/4/8, FT_FLOORCOL, FT_BODY1/2/4/8, FT_SHELF2/4/8, FT_TBOX2/4/8
--     foes = {apple = "FE_APPLE", ...}                                                         (core/foes.lua picks the pictures; frames 0..n-3 loop, the last two are the beaten toy)
--   }
-- World 2's assets are FM_* (backgrounds), FT_* (tiles), FE_* (foes: FE_APPLE walker, FE_BANANA slider, FE_BEE flyer, FE_CHERRY bouncer), FI_* (items).
local M = require("core.map")
local K = require("core.const")
local Deco = require("core.deco")
local W = {}

W.defs = {
  {id = "playroom", name_key = "world_1", ready = true, cols = 192, music = "playroom", bgcolor = 0xE8C9A0, boss = "cuerda", tiles = "BG",
   far = {def = "data.far_slices", speed = 0.09, y = -14, ycam = 0.05},
   case = {def = "data.case_slices", speed = 0.27, y = 250, ycam = 0.9, dim = 0.9},
   mid = {speed = 0.62, period = 3000, dim = 0.88, list = {
     {80, "BG_G_TEDDY"}, {330, "BG_G_TOWER"}, {500, "BG_G_ROCKET"}, {690, "BG_G_DUCK"}, {900, "BG_G_BALL"}, {1070, "BG_G_CASTLE"}, {1300, "BG_G_RINGS"},
     {1480, "BG_G_BUNNY"}, {1740, "BG_G_DRUM"}, {1900, "BG_G_HORSE"}, {2150, "BG_G_DINO"}, {2400, "BG_G_TRAIN"}, {2560, "BG_G_ROCKET"}, {2780, "BG_G_TEDDY"}}},
   fore = {speed = 1.5, period = 3300, list = {
     {300, "BG_FORE_CRAYON_R", 282}, {900, "BG_FORE_BLOCKS", 272}, {1500, "BG_FORE_CRAYON_G", 286}, {2000, "BG_FORE_BALL", 280},
     {2500, "BG_FORE_BRICKS", 288}, {2900, "BG_FORE_CRAYON_B", 288}}},
   alias = {}},
  {id = "market", name_key = "world_2", ready = true, cols = 204, music = "market", bgcolor = 0xF3CF7B, boss = "sandia", tiles = "FT",
   far = {def = "data.fm_far_slices", speed = 0.09, y = 0, ycam = 0.05, fill = 0xF3CF7B},
   mid = {speed = 0.62, period = 3000, dim = 0.94, list = {
     {80, "FM_STALL_1"}, {330, "FM_LAMP"}, {520, "FM_STALL_2"}, {800, "FM_FOUNTAIN"}, {980, "FM_CRATEPYR"}, {1150, "FM_STALL_3"}, {1420, "FM_PARASOL"},
     {1560, "FM_BARRELS"}, {1750, "FM_STALL_4"}, {2020, "FM_CART"}, {2200, "FM_SIGN"}, {2350, "FM_STALL_5"}, {2620, "FM_WHEELBARROW"}, {2760, "FM_CRATEPEAR"},
     {2900, "FM_SACKS"},
     {250, "FM_BUNTING", nil, {top = 0, sx = 0.6}}, {1050, "FM_LANTERNS", nil, {top = 0}}, {1500, "FM_BUNTING", nil, {top = 0, sx = 0.6}},
     {2150, "FM_LANTERNS", nil, {top = 0}}, {2650, "FM_BUNTING", nil, {top = 0, sx = 0.6}}}},
   fore = {speed = 1.5, period = 3300, list = {
     {250, "FM_FORE_CABBAGE", 262}, {800, "FM_FORE_CAT", 250}, {1300, "FM_FORE_BASKET", 270}, {1800, "FM_FORE_CAN", 262}, {2300, "FM_FORE_SACK", 258},
     {2800, "FM_FORE_CARROTS", 250}}},
   alias = {TOY_COIN = "FI_COIN", TOY_CREAM = "FI_LOLLI", TOY_FLAG = "FI_FLAG", TOY_KEYBOARD = "FI_KEYBOARD", TOY_SPRING = "FT_PAD"}},
  -- world 3, the chalk park: CM_* backgrounds, CT_* tiles, CE_* toys, CI_* items (data/deco3.lua, data/cm_far_slices.lua, data/world3_assets.md). The art has no hopscotch square
  -- of its own: the chalk boxes t2 (circle) and t6 (plain) are the square and the cracked one. A picture the data lacks is replaced by the market's, tinted.
  {id = "chalk", name_key = "world_3", ready = true, cols = 240, music = "chalk", bgcolor = 0x676279, tiles = "CT", tilemul = 0xC8E0D0,
   frames = {H = 2, h = 6}, fb_frames = {H = 4, h = 5},
   far = {def = "data.cm_far_slices", fallback = "data.fm_far_slices", speed = 0.09, y = 0, ycam = 0.05, fill = 0x676279, mul = 0xB8E8C8},
   mid = {speed = 0.62, period = 3000, dim = 0.94, mul = 0xC8E8D8, list = {
     {80, "CM_SLIDE", "FM_STALL_1"}, {330, "CM_TREE", "FM_LAMP"}, {560, "CM_SWINGS", "FM_STALL_2"}, {820, "CM_FOUNTAIN", "FM_FOUNTAIN"}, {1010, "CM_BENCH", "FM_CRATEPYR"},
     {1200, "CM_TREE", "FM_STALL_3"}, {1450, "CM_SANDBOX", "FM_PARASOL"}, {1560, "CM_LAMP", "FM_LAMP"}, {1830, "CM_SLIDE", "FM_STALL_4"}, {2080, "CM_TREE", "FM_CART"},
     {2260, "CM_BENCH", "FM_SIGN"}, {2430, "CM_SEESAW", "FM_STALL_5"}, {2680, "CM_CHALKHOUSE", "FM_WHEELBARROW"}, {2820, "CM_CHALKBOW", "FM_CRATEPEAR"},
     {1320, "CM_CHALKSUN", "FM_SACKS"}}},
   fore = {speed = 1.5, period = 3300, list = {
     {250, "CM_FORE_LEAVES", 262, "FM_FORE_CABBAGE"}, {800, "CM_FORE_CHALKBOX", 252, "FM_FORE_CAT"}, {1300, "CM_FORE_BALL", 262, "FM_FORE_BASKET"},
     {1800, "CM_FORE_HOOP", 246, "FM_FORE_CAN"}, {2300, "CM_FORE_BOTTLE", 258, "FM_FORE_SACK"}, {2800, "CM_FORE_SCOOTER", 258, "FM_FORE_CARROTS"}}},
   alias = {TOY_COIN = "CI_COIN", TOY_CREAM = "CI_LOLLI", TOY_FLAG = "CI_FLAG", TOY_KEYBOARD = "CI_KEYBOARD", TOY_SPRING = "CT_PAD", FT_PAD = "CT_PAD", FT_CART = "CT_CART",
            TOY_BALL = "CE_BALL", TOY_PLANE = "CE_KITE"}},
  {id = "stage", name_key = "world_4", ready = false, cols = 192},
}

W.cur, W.theme = 1, W.defs[1]

local function try(name) local ok, v = pcall(require, name) if ok and type(v) == "table" then return v end end

-- the wide layers' definitions (the world's own, else the stand-in with its tint)
local function layer(l)
  if not l then return nil end
  local def = try(l.def)
  local o = {speed = l.speed, y = l.y, ycam = l.ycam, dim = l.dim, mul = l.mul, fill = l.fill}
  if def then o.def, o.mul = def, nil else o.def = try(l.fallback or l.def) end
  o.mul = o.mul
  return o
end

-- loads world i's level and theme (the map, the alias table of the pictures, the wide layers)
function W.load(i)
  local d = W.defs[i]
  W.cur, W.theme = i, d
  M.load(i)
  Deco.alias = d.alias or {}
  W.far, W.case = layer(d.far), layer(d.case)
  W.tile_prefix = (d.tiles and Deco.has(d.tiles .. "_TILES")) and d.tiles or "BG"
  W.tile_mul = (W.tile_prefix == "BG" and d.tiles ~= "BG") and d.tilemul or nil
  W.tile_frames = (W.tile_prefix == d.tiles) and d.frames or d.fb_frames
  return d
end

-- ---------------------------------------------------------------- progress (saved: which worlds are done, the best time of each)
function W.progress() return stored("progress", {}) end
function W.done(i) return W.progress()["w" .. i] ~= nil end
function W.best(i) return W.progress()["w" .. i] end
function W.finish(i, time)
  local p = W.progress()
  local best = p["w" .. i]
  if not best or time < best then p["w" .. i] = time store("progress", p) end
end
function W.any_progress() return next(W.progress()) ~= nil end
function W.unlocked(i) return W.defs[i].ready and (i == 1 or W.done(i - 1)) end
function W.next_ready(i) local n = W.defs[i + 1] return n and n.ready and W.unlocked(i + 1) and i + 1 or nil end

return W
