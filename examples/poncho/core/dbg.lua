-- dbg: hooks for tests/poncho.script. Teleports, a trace of the hero, and small physics experiments that press the buttons themselves tick by tick
-- (what the script's own lines cannot do: wait for the moment the hero leaves the ground). They are plain globals under `D`.
local K = require("core.const")
local L = require("core.level")
local In = require("core.input")
local Hero = require("core.hero")
local Foes = require("core.foes")
local Items = require("core.items")
local Cam = require("core.cam")
local Play = require("core.play")
local Fx = require("core.fx")

D = {}
local FLOOR = K.FLOOR * K.TILE

function D.tp(x, y)
  local s = Hero.s
  s.x, s.y, s.vx, s.vy = x, y or FLOOR, 0, 0
  s.ground = y == nil
  s.state, s.inv, s.hurt_t, s.dead_t, s.pw, s.pw_cd, s.face = "play", 0, 0, 0, nil, 0, 1
  Cam.snap(s)
  return true
end
function D.scooter(on) Hero.has_scooter = true Hero.s.scooter = on ~= false return true end
function D.world(i) Play.enter(i) G.state = "play" return true end
function D.boss() local b = require("core.boss").info() return b and {mode = b.mode, hp = b.hp, x = b.x, inv = b.inv} or nil end
-- the hero drops on the head of the boss when it is down: a stomp
function D.stomp_boss()
  local Boss = require("core.boss")
  local b = Boss.info()
  local s = Hero.s
  s.x, s.y, s.vx, s.vy, s.ground, s.inv, s.state = b.x, b.y - b.h - 36, 0, 6, false, 0, "play"
  return true
end
-- the hero cannot be hurt (a long invulnerability) and, when asked, drops on the boss's head each time it is down (once a time)
local armed = false
function D.fight(on)
  armed = false
  G.after_play = on and function()
    local Boss = require("core.boss")
    local b = Boss.info()
    Hero.s.inv = math.max(Hero.s.inv, 5)
    if not b or not Boss.active() then return end
    local down = b.mode == "stun" or b.mode == "tired"
    if not down then armed = false return end
    if b.mt <= 3 then armed = true end
    if armed and b.mt >= 30 and b.inv == 0 then armed = false D.stomp_boss() end
  end or nil
  return true
end
function D.foe_state(kind)
  for _, f in ipairs(Foes.list) do if not kind or f.kind == kind then return {kind = f.kind, mode = f.mode, x = f.x, y = f.y, vy = f.vy, dead = f.dead} end end
end
function D.cherries() local t = {} for _, f in ipairs(Foes.list) do if f.kind == "cherry" then t[#t + 1] = f.vy end end return t end
function D.watch_bee() -- true once a bee has dived
  G.seen_dive = false
  G.after_play = function() for _, f in ipairs(Foes.list) do if f.kind == "bee" and f.mode == "dive" then G.seen_dive = true end end end
  return true
end
-- the stage: stop the beat at tick t (or let it run again), and watch whether a note hopper has left the floor
function D.beat_hold(t) local B = require("core.beat") B.hold = t ~= nil if t then B.t = t end return true end
function D.watch_hop()
  G.hopped = false
  G.after_play = function() for _, f in ipairs(Foes.list) do if f.kind == "note" and f.y < f.base_y - 6 then G.hopped = true end end end
  return true
end
function D.boss_meter() return require("core.boss").meter end
function D.new_crates() L.reset_crates() Play.crates = 0 return true end
function D.tile(c, r) return L.at(c, r) end
function D.foe(kind, dx, range) local s = Hero.s return Foes.spawn(kind, s.x + dx, s.y, range or 8) ~= nil end
function D.costume(kind) Hero.s.state = "play" if kind then Hero.give(kind) else Hero.costume = nil end return true end
function D.hit() return Hero.hurt(Hero.s.x + 40) end
function D.clear() Foes.clear() return true end
function D.bot(on) In.bot = on ~= false return true end
function D.state()
  local s = Hero.s
  return {state = G.state, play = Play.state, x = math.floor(s.x), y = math.floor(s.y), vx = s.vx, vy = s.vy, ground = s.ground, scooter = s.scooter,
          hs = s.state, hearts = Hero.hearts, costume = Hero.costume, pw = s.pw and s.pw.kind, fut = s.fut_t, crates = Play.crates, inv = s.inv, cp = Items.checkpoint and Items.checkpoint.x, time = Play.time, deaths = Play.deaths, cam = math.floor(Cam.x)}
end

-- a trace of the hero each tick of play, from x >= from
local trace, from
function D.trace(on, x0)
  trace, from = on and {} or nil, x0 or 0
  G.after_play = trace and function()
    local s = Hero.s
    if s.x >= from and #trace < 600 then trace[#trace + 1] = {s.x, s.y, s.vx, s.vy} end
  end or nil
  return true
end
function D.dump(every, what) -- what: 1 x, 2 y, 3 vx, 4 vy
  local out = {}
  for i = 1, #trace, every do out[#out + 1] = string.format("%.2f", trace[i][what]) end
  log(table.concat(out, " "))
  return true
end

-- one tick of the hero with these buttons held (a table of names), the rest of the game left alone
local function step(buttons)
  for _, n in ipairs({"left", "right", "up", "down", "a", "b", "c", "start"}) do In.state[n] = buttons[n] == true end
  In.update()
  Hero.update()
  Items.update()
end
local function sim_begin() In.bot = true end
local function sim_end() -- the hero as at the start again (a sim may have let him fall into a pit)
  In.bot = false
  for k in pairs(In.state) do In.state[k] = false end
  In.update()
  Hero.reset(400, FLOOR, false)
  Fx.clear()
end

-- run off a ledge and press jump `late` ticks after the feet left the ground: true when it still jumps (coyote time)
function D.coyote(late)
  sim_begin()
  D.tp(1290)
  local s = Hero.s
  local n = 0
  while s.ground and n < 200 do step({right = true}) n = n + 1 end
  for _ = 1, late do step({right = true}) end
  step({right = true, a = true})
  local jumped = s.vy < 0
  sim_end()
  return jumped
end

-- press jump `early` ticks before landing: true when the jump comes out the moment he lands (the buffer)
function D.buffer(early)
  sim_begin()
  D.tp(400)
  local s = Hero.s
  for _ = 1, 25 do step({a = true}) end -- a good jump, let go on the way up
  local n = 0
  while n < 100 and not (s.vy > 0 and s.y + s.vy * early >= FLOOR - 1) do step({}) n = n + 1 end
  step({a = true})
  n = 0
  while not s.ground and n < 30 do step({}) n = n + 1 end
  step({})
  local jumped = s.vy < 0
  sim_end()
  return jumped
end

-- the height of a jump held to the top, and of a tap
function D.jump_height(hold)
  sim_begin()
  D.tp(400)
  Hero.costume = nil
  local s = Hero.s
  local top = s.y
  for i = 1, 80 do
    step({a = i <= hold})
    if s.y < top then top = s.y end
  end
  sim_end()
  return FLOOR - top
end

-- how far a scooter at speed v glides before it stops, with nothing pressed (px)
function D.glide(v)
  sim_begin()
  D.tp(4700)
  D.scooter(true)
  local s = Hero.s
  s.vx = v
  local x0, n = s.x, 0
  while math.abs(s.vx) > 0.05 and n < 3000 and s.x < 5000 do step({}) n = n + 1 end
  sim_end()
  return s.x - x0, n
end

-- from standstill, hold right on the scooter: ticks until it reaches speed v
function D.scooter_to(v, turbo)
  sim_begin()
  D.tp(4700)
  D.scooter(true)
  local s = Hero.s
  local n = 0
  while math.abs(s.vx) < v and n < 1000 do step({right = true, c = turbo}) n = n + 1 end
  sim_end()
  return n
end


function D.foes_alive()
  local n = 0
  for _, f in ipairs(Foes.list) do if f.dead == 0 then n = n + 1 end end
  return n
end
function D.coins() local c = Items.counts() return c end
return D
