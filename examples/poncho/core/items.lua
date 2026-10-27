-- items: what lies about the playroom and does something when touched: coins, ice creams (a heart back), springs, the toy keyboard (a friend: it keeps your place
-- and plays a tune), the scooter, the end flag. Drawn from code for now.
local K = require("core.const")
local M = require("core.map")
local U = require("core.util")
local Hero = require("core.hero")
local Fx = require("core.fx")
local Snd = require("core.sound")
local L = require("core.level")
local Boss = require("core.boss")
local Beat = require("core.beat")

local Deco = require("core.deco")
local I = {}
local coins = swarm(256, {-1000, -1000, 8000, 1000}) -- every coin on the screen is one command, all turning together
I.list = {}
I.events = {}   -- this tick: coin, icecream, spring, keyboard, scooter, goal
I.checkpoint = nil

local WIDE = {peel = 110, puddle = 110, seesaw = 90, drum = 70}

-- the keyboard's arpeggio: ticks after touching, note, key (0..7)
local TUNE = {{0, "C5", 0}, {7, "E5", 2}, {14, "G5", 4}, {21, "C6", 7}, {30, "G5", 4}, {37, "C6", 7}}

-- the list is kept sorted by x: a tick only looks at the items next to the hero, and a frame only at the ones on the screen (a level has hundreds of coins)
local function first_from(x)
  local lo, hi = 1, #I.list + 1
  while lo < hi do
    local mid = (lo + hi) // 2
    if I.list[mid].x < x then lo = mid + 1 else hi = mid end
  end
  return lo
end

-- an item with a running timer (a pressed spring, the keyboard's tune) is ticked from this short list wherever it lies
local function busy(it)
  if not it.busy then it.busy = true I.busy[#I.busy + 1] = it end
end

function I.init()
  I.list, I.checkpoint, I.events, I.busy, I.flags, I.tick = {}, nil, {}, {}, {}, 0
  I.coins, I.creams, I.total_c, I.total_i = 0, 0, 0, 0
  for i, o in ipairs(M.objs) do
    local it = {cos = o.kind:sub(1, 4) == "cos_", w = o.w or 96, locked = o.locked, kind = o.kind, x = o.x, y = o.y, i = i, t0 = (i * 7) % 60, t = (i * 7) % 60, taken = false, press = 0, on = false, tune = nil}
    I.list[i] = it
    if it.kind == "coin" then I.total_c = I.total_c + 1 elseif it.kind == "icecream" then I.total_i = I.total_i + 1
    elseif it.kind == "flag" then I.flags[#I.flags + 1] = it end
  end
  table.sort(I.list, function(a, b) if a.x ~= b.x then return a.x < b.x end return a.i < b.i end)
end

-- the costumes lost with a death lie there again
function I.reset_costumes() for _, it in ipairs(I.list) do if it.kind:sub(1, 4) == "cos_" then it.taken = false end end end

function I.counts() return I.coins, I.creams, I.total_c, I.total_i end

-- one tick of the timers of the busy items
local function run_timers()
  local list, n = I.busy, #I.busy
  for j = n, 1, -1 do
    local it = list[j]
    if it.press > 0 then it.press = it.press - 1 end
    if it.tune then -- the keyboard's tune, a note at a time
      it.tune.t = it.tune.t + 1
      for _, n in ipairs(TUNE) do
        if n[1] == it.tune.t then Snd.note(n[2], 0.35) it.key = n[3] it.key_t = 10 it.bounce = 8 end
      end
      if it.tune.t > 60 then it.tune = nil end
    end
    if it.key_t and it.key_t > 0 then it.key_t = it.key_t - 1 if it.key_t == 0 then it.key = nil end end
    if it.bounce and it.bounce > 0 then it.bounce = it.bounce - 1 end
    if it.press == 0 and not it.tune and not (it.key_t and it.key_t > 0) and not (it.bounce and it.bounce > 0) then
      it.busy = false
      list[j] = list[#list]
      list[#list] = nil
    end
  end
end

function I.update()
  I.events = {}
  local s = Hero.s
  if s.state == "win" then return end
  local alive = s.state ~= "dead"
  I.tick = I.tick + 1
  run_timers()
  for _, it in ipairs(I.flags) do
    if it.locked and Boss.beaten() then it.locked = false end -- the boss is down: the flag is open
  end
  local list = I.list
  for idx = first_from(s.x - 110), #list do
    local it = list[idx]
    if it.x - s.x > 110 then break end
    if alive and math.abs(it.x - s.x) < (WIDE[it.kind] or 60) then
      local k = it.kind
      local dx = math.abs(it.x - s.x)
      if k == "coin" and not it.taken and dx < 26 and it.y > s.y - K.BODY_H - 12 and it.y < s.y + 12 then
        it.taken = true
        I.coins = I.coins + 1
        I.events.coin = true
        Fx.sparkle(it.x, it.y, 0xFFE060, 6)
        Snd.play("coin", 0.7)
      elseif k == "icecream" and not it.taken and dx < 30 and it.y > s.y - K.BODY_H - 30 and it.y < s.y + 20 then
        it.taken = true
        I.creams = I.creams + 1
        I.events.icecream = true
        Hero.hearts = math.min(K.HEARTS, Hero.hearts + 1)
        Fx.sparkle(it.x, it.y - 20, 0xFF9AD0, 10)
        Snd.play("cream")
      elseif k == "spring" and s.vy >= 0 and dx < 26 and s.y > it.y - 26 and s.y < it.y + 4 then
        it.press = 14 busy(it)
        Hero.bounce(K.SPRING_V + (require("core.input").btn("a") and 2.4 or 0), true)
        I.events.spring = true
        Snd.play("spring")
        Fx.dust(it.x, it.y, 4, 0, 2)
      elseif k == "keyboard" and dx < 50 and s.y > it.y - 70 and s.y < it.y + 12 then
        if not it.on then
          it.on = true
          it.tune = {t = 0} busy(it)
          I.events.keyboard = true
          Fx.sparkle(it.x, it.y - 30, 0x80E0FF, 10)
        end
        I.checkpoint = {x = it.x, y = it.y}
      elseif k == "scooter" and not it.taken and dx < 40 and s.y > it.y - 60 and s.y < it.y + 12 then
        it.taken = true
        Hero.has_scooter = true
        s.scooter = true
        I.events.scooter = true
        Fx.sparkle(it.x, it.y - 20, 0x60C0FF, 12)
        Snd.play("scooter")
      elseif it.cos and not it.taken and dx < 36 and s.y > it.y - 80 and s.y < it.y + 16 then
        it.taken = true
        Hero.give(k:sub(5))
        I.events.costume = k:sub(5)
        Fx.sparkle(it.x, it.y - 30, 0xFFFFFF, 10)
      elseif k == "awning" and s.vy >= 0 and dx < 44 and s.y >= it.y - 6 and s.y - s.vy <= it.y + 4 and s.y < it.y + 22 then
        it.press = 14 busy(it) -- a bouncy awning: a trampoline you can also walk under
        s.y = it.y
        Hero.bounce(K.SPRING_V * 1.2 + (require("core.input").btn("a") and 2.4 or 0), false)
        I.events.spring = true
        Snd.play("boing")
      elseif k == "seesaw" and s.vy >= 0 and dx < 70 and s.y >= it.y - 14 and s.y - s.vy <= it.y + 4 and s.y < it.y + 24 then
        it.press = 22 busy(it) -- a seesaw: the far end is thrown down and Poncho goes up, high
        s.y = it.y
        Hero.bounce(K.SEESAW_V + (require("core.input").btn("a") and 1.5 or 0), false)
        I.events.spring = true
        I.events.seesaw = true
        Snd.play("spring")
        Fx.dust(it.x + 50, it.y, 5, 1, 2)
      elseif k == "drum" and s.vy >= 0 and dx < 40 and s.y >= it.y - 8 and s.y - s.vy <= it.y + 4 and s.y < it.y + 22 then
        it.press = 14 busy(it) -- a drum pad: a big bounce when he lands on the beat, a small one off it
        s.y = it.y
        local on = Beat.near(5)
        Hero.bounce(on and K.SPRING_V * 1.22 or 13.5, false)
        I.events.spring = true
        if on then I.events.drum_beat = true Fx.ring(it.x, it.y - 4, 8, 40, 0xFFE070, 12) end
        Snd.play("boing")
        tone(2, on and "C4" or "G3", {wave = "noise", vol = 0.3, decay = 0.12, sustain = 0})
      elseif k == "puddle" and s.ground and dx < it.w / 2 + 10 and s.y > it.y - 10 then
        if Hero.costume == "boots" then -- rain boots: a splash, and no slowing
          if I.tick % 9 == 0 and math.abs(s.vx) > 1 then Fx.ring(s.x, s.y - 2, 6, 26, 0x8CD8FF, 10) end
          I.events.splash = true
        else
          s.vx = s.vx * 0.93 -- wading: it slows him
          if I.tick % 12 == 0 and math.abs(s.vx) > 0.8 then Fx.dust(s.x, s.y, 1, 0, 1) end
          I.events.wade = true
        end
      elseif k == "peel" and s.ground and dx < it.w / 2 and s.y > it.y - 10 then
        s.slip = 3 -- a banana peel patch: no grip
        I.events.slip = true
      elseif k == "flag" and not it.locked and dx < 36 and s.y > it.y - 150 and s.y < it.y + 16 then
        I.events.goal = true
      end
    end
  end
end

-- ---------------------------------------------------------------- drawing (world pixels, under camera()): one packed picture each (core/deco.lua)

local function icecream(it)
  local lolli = Deco.id("TOY_CREAM") ~= "TOY_CREAM" -- the market's lollipop: anchored at its middle, in one of three kinds
  Deco.img("TOY_CREAM", lolli and (it.x // 32) % math.max(1, Deco.count(Deco.id("TOY_CREAM"))) or 0, math.floor(it.x), math.floor(it.y - (lolli and 34 or 22) + math.sin(it.t / 18) * 4))
end

local function spring(it)
  Deco.img("TOY_SPRING", it.press > 7 and 2 or (it.press > 0 and 1 or 0), math.floor(it.x), math.floor(it.y))
end

local function keyboard(it)
  local x, y = math.floor(it.x), math.floor(it.y)
  local b = (it.bounce and it.bounce > 0) and -math.floor(math.sin(it.bounce / 8 * math.pi) * 4) or 0
  y = y + b
  local fr = 0
  if it.on then fr = 2 + (it.t // 6) % 4 elseif (it.t % 150) > 144 then fr = 1 end
  Deco.img("TOY_KEYBOARD", fr, x, y)
  if it.on and Deco.id("TOY_KEYBOARD") == "TOY_KEYBOARD" then -- notes floating up (the market's keyboard plays its own)
    Deco.img("TOY_NOTE", (it.t // 10) % 2, x + 30, y - 36 - (it.t % 40) // 2)
  end
end

local function scooter(it)
  local x, y = math.floor(it.x), math.floor(it.y + math.sin(it.t / 16) * 3)
  Deco.img("TOY_SCOOTER", 0, x, y)
  if (it.t // 20) % 3 == 0 then Deco.img("TOY_SPARK", 0, x + 14, y - 74) end
end

local flook = {}
local function flag(it)
  flook.dim = it.locked and 0.45 or nil
  Deco.img("TOY_FLAG", math.floor(it.t * 6 / (8 * 6.2832)) % math.max(1, Deco.count(Deco.id("TOY_FLAG"))), math.floor(it.x), math.floor(it.y), flook)
end

-- a bouncy awning (stripes, code-drawn until the art has it) and a banana-peel patch (a flat yellow shape)
local function awning(it)
  local x, y = math.floor(it.x), math.floor(it.y)
  if Deco.has("FT_PAD") then -- the bounce pad: taut, pressed, squashed
    Deco.img("FT_PAD", it.press > 8 and 1 or (it.press > 0 and 2 or 0), x, y + 22)
    return
  end
  local sag = it.press > 0 and 6 or 0
  rect(x - 56, y + sag, 112, 7, 0xE04040)
  rect(x - 56 + 28, y + sag, 28, 7, 0xFFF4E0)
  rect(x - 56 + 84, y + sag, 28, 7, 0xFFF4E0)
  rect(x - 56, y + 7 + sag, 112, 3, 0xA02828)
  rect(x - 3, y + 10, 6, (K.FLOOR * 32 - y) - 10, 0x8A5A2C)
end

-- a seesaw (a plank on a trestle, tilting when it throws) and a puddle (a flat pool), code-drawn until CI_SEESAW / CI_PUDDLE exist
local function seesaw(it)
  local x, y = math.floor(it.x), math.floor(it.y)
  if Deco.has("CI_SEESAW") then Deco.img("CI_SEESAW", it.press > 0 and 1 or 0, x, y) return end -- left_down, right_down
  local tilt = it.press > 0 and 14 or 0
  tri(x - 12, y, x + 12, y, x, y - 24, 0x8A5A2C)
  poly({x - 64, y - 20 + tilt, x + 64, y - 20 - tilt, x + 64, y - 12 - tilt, x - 64, y - 12 + tilt}, 0xFF6A8A, true)
end

local function puddle(it)
  local x, y = math.floor(it.x), math.floor(it.y)
  if Deco.has("CI_PUDDLE") then -- calm, ripple_0, ripple_1: the picture repeated along the puddle
    local fr = (it.t // 14) % 3
    for dx = -it.w // 2 + 34, it.w // 2 - 20, 60 do Deco.img("CI_PUDDLE", fr, x + dx, y) end
    return
  end
  rect(x - it.w // 2, y - 6, it.w, 6, 0x5A9AD8)
  rect(x - it.w // 2 + 10, y - 6, it.w // 3, 2, 0xB8E4FF)
end

-- a drum pad: a flat drum that swells on the beat (code-drawn until KI_DRUM exists)
local function drum(it)
  local x, y = math.floor(it.x), math.floor(it.y)
  if Deco.has("KT_PAD") then -- the drum skin: taut, pressed on a hit and for a moment on every beat, squashed after
    Deco.img("KT_PAD", it.press > 8 and 1 or (it.press > 0 and 2 or (Beat.pulse() > 0.6 and 1 or 0)), x, y)
    return
  end
  local g = math.floor(Beat.pulse() * 4) + (it.press > 0 and -3 or 0)
  rect(x - 28 - g, y - 12 - g, 56 + 2 * g, 12 + g, 0xE04A6A)
  rect(x - 28 - g, y - 12 - g, 56 + 2 * g, 4, 0xFFD0DC)
end

local function peel(it)
  local x, y = math.floor(it.x), math.floor(it.y)
  if Deco.has("FI_PEEL") then
    for dx = -it.w // 2 + 25, it.w // 2 - 20, 46 do Deco.img("FI_PEEL", 0, x + dx, y) end
    return
  end
  rect(x - it.w // 2, y - 5, it.w, 5, 0xF2D43A)
  rect(x - it.w // 2 + 8, y - 8, it.w - 16, 3, 0xFFF080)
end

-- the carts on the pit and the swings (the platforms of core/level.lua: a handful, only the ones on the screen are drawn)
local function carts(cam_x)
  for _, p in ipairs(L.plats) do
    if p.x > cam_x - 120 and p.x < cam_x + K.W + 60 then
      local x, y = math.floor(p.x), math.floor(p.y)
      if p.kind == "swing" then
        if Deco.has("CI_SWING") then Deco.img("CI_SWING", 0, x + p.w // 2, y + 6) else
          line(x + 10, y, x + 18, y - 190, 0xB8B8C8) line(x + p.w - 10, y, x + p.w - 18, y - 190, 0xB8B8C8)
          rect(x, y, p.w, 8, 0xE0804A)
        end
      elseif Deco.has("FT_CART") then Deco.img("FT_CART", 0, x + p.w // 2, y + 39) else
        rect(x, y, p.w, 5, 0xB07A3E)
        rect(x + 4, y + 5, p.w - 8, 16, 0x8A5A2C)
        circ(x + 14, y + 24, 8, 0x30303A, true) circ(x + p.w - 14, y + 24, 8, 0x30303A, true)
      end
    end
  end
end

-- a costume to find: a little coloured box with a star over it, bobbing (placeholder art, drawn by code: three commands)
local COS = {barretina = 0xD83A3A, dino = 0x72D84A, boots = 0x2E8A3E, futbol = 0xF4F4F4}
local function costume(it)
  local x, y = math.floor(it.x), math.floor(it.y - 30 + math.sin(it.t / 15) * 5)
  rect(x - 17, y - 17, 34, 34, 0x2A1A3A)
  rect(x - 14, y - 14, 28, 28, COS[it.kind:sub(5)])
  if it.kind == "cos_futbol" then rect(x - 14, y - 6, 28, 6, 0x2E8A3E) end
  Deco.img("TOY_STAR", 0, x, y)
end

function I.draw(cam_x)
  coins:clear()
  local it_t = ticks()
  local list = I.list
  for idx = first_from(cam_x - 90), #list do
    local it = list[idx]
    local dx = it.x - cam_x
    if dx >= K.W + 90 then break end
    if dx > -90 and not it.taken then
      local k = it.kind
      it.t = I.tick + it.t0
      if k == "coin" then coins:add(it.x, it.y + math.sin(it.t / 20 + it.i) * 3)
      elseif k == "icecream" then icecream(it)
      elseif k == "spring" then spring(it)
      elseif k == "keyboard" then keyboard(it)
      elseif k == "scooter" then scooter(it)
      elseif k == "flag" then flag(it)
      elseif k == "awning" then awning(it)
      elseif k == "peel" then peel(it)
      elseif k == "seesaw" then seesaw(it)
      elseif k == "drum" then drum(it)
      elseif k == "puddle" then puddle(it)
      elseif it.cos then costume(it) end
    end
  end
  carts(cam_x)
  local cid = Deco.id("TOY_COIN")
  coins:draw(cid, (it_t // 4) % math.max(1, Deco.count(cid)))
end

return I
