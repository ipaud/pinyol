-- play: one run of the level: the hero, the things, the foes, the camera, the checkpoint, the respawn and the end.
local K = require("core.const")
local L = require("core.level")
local M = require("core.map")
local Hero = require("core.hero")
local Items = require("core.items")
local Foes = require("core.foes")
local Cam = require("core.cam")
local Fx = require("core.fx")
local Tiles = require("core.tiles")
local Bg = require("core.bgfx")
local Snd = require("core.sound")
local Ach = require("core.ach")
local Hud = require("core.hud")
local Music = require("core.music")
local Power = require("core.power")
local Beat = require("core.beat")
local Keys = require("core.keys")
local W = require("core.worlds")
local Boss = require("core.boss")
local lang = require("lang")
local transition = require("transition")

local P = {}
P.state = "run"       -- "run" | "goal"
P.time, P.deaths = 0, 0
P.toast, P.toast_t = "", 0
P.stats = {stomps = 0}
P.crates = 0

local START_X, START_Y = 0, K.FLOOR * K.TILE
P.world = 1

function P.say(text, ticks) P.toast, P.toast_t = text, ticks or 170 end
Ach.on_new = function(text) P.say(text, 200) end

function P.enter(world)
  P.world = world or 1
  W.load(P.world)
  L.reload()
  Cam.reload()
  START_X = M.start_c * K.TILE + 16
  Items.init()
  Foes.init()
  Fx.clear()
  Power.reset_run()
  P.crates = 0
  Boss.reset(M.boss)
  Beat.reset()
  Keys.clear()
  Hero.bounds = nil
  Hero.has_scooter = false
  Hero.reset(START_X, START_Y)
  Cam.snap(Hero.s)
  Cam.shake = 0
  P.state, P.time, P.deaths, P.toast_t, P.stats.stomps = "run", 0, 0, 0, 0
  P.end_t = 0
  Music.start(W.theme.music)
end

function P.respawn()
  local cp = Items.checkpoint
  Foes.init()
  Fx.clear()
  Boss.retry()
  Items.reset_costumes()
  Hero.reset(cp and cp.x or START_X, cp and cp.y or START_Y, true)
  Cam.snap(Hero.s)
end

local function events()
  local he, ie, fe = Hero.events, Items.events, Foes.events
  if ie.keyboard then Ach.earn("keyboard") P.say(lang.tr("toast_keyboard")) end
  if ie.scooter then Ach.earn("scooter") P.say(lang.tr("toast_scooter"), 260) end
  if ie.icecream then P.say(lang.tr("toast_cream"), 120) end
  if ie.costume then P.say(lang.tr("toast_" .. ie.costume), 260) end
  if next(Power.worn) then Ach.earn("costume") end
  if Power.count_worn() >= #Power.KINDS then Ach.earn("wardrobe") end
  if he.costume_lost then P.say(lang.tr("toast_lost"), 120) end
  if he.crate then
    P.crates = P.crates + he.crate
    if P.crates >= 5 then Ach.earn("crates") end
  end
  if he.pound then Cam.kick(10) end
  if fe.stomp then Ach.earn("stomp") end
  local rd = Boss.events.round
  if rd and rd.perfect == 4 then Ach.earn("ritmo") end
  if Boss.events.round_start then P.say(lang.tr("toast_rhythm"), 150) end
  if he.land_ch == "H" or he.land_ch == "h" then
    if L.hop(he.land_x, he.land_y) then Fx.dust(he.land_x, he.land_y, 4, 0, 1.4) end
  end
  if L.vanished then Fx.dust(L.vanished[1], L.vanished[2], 6, 0, 2.2) L.vanished = nil end
  if fe.curl then Ach.earn("curl") end
  if Boss.events.start then P.say(lang.tr(Boss.name()), 150) end
  if Boss.events.beaten then Ach.earn(({"boss1", "boss2", "boss2", "silencio"})[P.world] or "boss1") P.say(lang.tr("toast_boss_down"), 220) end
  if he.ramp_fast then Ach.earn("ramp") end
  if he.land_hard then Cam.kick(4) end
  if he.bump or he.hurt then Cam.kick(10) end
  if fe.hurt then Cam.kick(10) end
end

function P.update()
  Fx.update()
  Beat.update()
  Music.update()
  transition.update()
  if P.toast_t > 0 then P.toast_t = P.toast_t - 1 end
  local s = Hero.s
  if P.state == "goal" then
    P.end_t = P.end_t + 1
    Hero.update()
    Cam.update(s)
    if P.end_t % 25 == 1 then Fx.confetti(s.x, s.y - 120, 12) end
    return P.end_t > 200 and "done" or nil
  end
  if s.state ~= "dead" then P.time = P.time + 1 end
  L.update_plats()
  Hero.update()
  Items.update()
  Foes.update()
  Boss.update()
  if W.theme.piano then Keys.track(Hero.s) Keys.update() end
  events()
  Cam.update(s)
  if s.state == "dead" and not transition.active() then
    local wait = s.how_died == "pit" and 20 or 70
    if s.dead_t > wait then
      P.deaths = P.deaths + 1
      local sx, sy = s.x - Cam.x, math.max(40, math.min(280, s.y - Cam.y - 30))
      if s.how_died == "pit" then sx, sy = math.max(40, math.min(440, sx)), 160 end
      transition.go("iris", 0.9, {cx = math.floor(sx), cy = math.floor(sy), on_mid = P.respawn})
    end
  end
  if Items.events.goal and s.state == "play" then
    Hero.win()
    Music.stop()
    P.state, P.end_t = "goal", 0
    Snd.play("win")
    Ach.earn(({"playroom", "market", "chalk", "silencio"})[P.world] or "playroom")
    Fx.confetti(s.x, s.y - 120, 30)
  end
  return nil
end

function P.draw()
  local cx, cy = Cam.view()
  Bg.scroll(cx, cy)
  Bg.mid(cx, cy)
  camera(cx, cy)
  Tiles.draw(cx, cy)
  if W.theme.piano then Keys.draw() end
  local bx = Foes.beam()
  if bx and M.spot and cx < M.spot.x1 and cx + K.W > M.spot.x0 then -- the spotlight's beam, added to the light
    grad(math.floor(bx) - 40, cy, 80, K.FLOOR * 32 - cy, 0x181030, 0x686030, {add = true})
  end
  Items.draw(cx)
  Foes.draw(cx)
  Boss.draw(cx)
  Hero.draw()
  Fx.draw()
  camera()
  Bg.fore(cx, cy)
  Hud.draw(P)
  transition.draw()
end

return P
