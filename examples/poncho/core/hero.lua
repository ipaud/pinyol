-- hero: Poncho. The feel lives here: speeds that ramp up and down, a jump you can cut, coyote time, a buffered jump, a moment of hang at the top, a faster fall,
-- a scooter that carries its speed. Positions are the soles' (x middle, y soles); the sprite is placed by its anchor, whatever size the art has.
local K = require("core.const")
local L = require("core.level")
local U = require("core.util")
local In = require("core.input")
local Spr = require("core.spr")
local Fx = require("core.fx")
local Snd = require("core.sound")
local Deco = require("core.deco")
local Power = require("core.power")

local H = {}
local HW, BH = K.HALF_W, K.BODY_H
local sign, approach, clamp = U.sign, U.approach, U.clamp

H.costume = nil          -- "barretina", "dino", "boots" or "futbol" (core/power.lua): its strips replace the standing and running ones
H.has_scooter = false
H.hearts = K.HEARTS
H.events = {}            -- what happened this tick, for the achievements and the camera ("land", "jump", "ramp", "bump", "stomp")

local s -- the state, a new table at every start
H.s = nil
Power.init(H)

function H.reset(x, y, keep_scooter)
  local mount = keep_scooter and H.has_scooter and (s and s.scooter) or false
  s = {
    x = x, y = y, vx = 0, vy = 0, face = 1, ground = true, gkind = "solid", gchar = nil,
    coyote = 0, jbuf = 0, jumped = false, jump_t = 99, land_t = 0, drop_t = 0,
    hold = 0, hold_dir = 0, gait = "walk", phase = 0, idle_t = 0, idle_cycle = 0,
    scooter = mount, mode_s = "glide", push_p = 0, drift_t = 0, brake_t = 0, glide_t = 0,
    state = "play", hurt_t = 0, inv = 0, dead_t = 0, win_t = 0, t = 0, air_t = 0, step_f = 0, skid_t = 0, lean = 0,
    c_t = 0, act = false, pw = nil, pw_cd = 0, fut_t = 0, boots_air = false,
  }
  H.costume = nil
  H.s = s
  H.hearts = K.HEARTS
  return s
end

function H.give(kind) Power.give(s, kind) end
function H.attack() return Power.attack(s) end

function H.box() return s.x - HW, s.y - BH, HW * 2, BH end

local function ev(name) H.events[name] = true end

-- ---------------------------------------------------------------- walking and scooter

local function walk_x(dir, run)
  local speed = math.abs(s.vx)
  if dir ~= 0 then
    if dir == s.hold_dir then s.hold = s.hold + 1 else s.hold, s.hold_dir = 0, dir end
  else
    s.hold, s.hold_dir = 0, 0
  end
  if dir == 0 then
    if s.ground then s.vx = approach(s.vx, 0, speed > K.WALK_V + 0.4 and K.FRICTION_RUN or K.FRICTION) else s.vx = approach(s.vx, 0, K.AIR_DRAG) end
    return
  end
  local target = ((run or s.hold >= K.RUN_AFTER) and K.RUN_V or K.WALK_V) * (s.fut_t > 0 and K.FUT_MULT or 1)
  if s.vx * dir < -0.05 then -- turning round: a skid, the body keeps looking the old way until it has slowed
    s.vx = s.vx + dir * (s.ground and K.SKID or K.SKID * 0.55)
    if s.ground and speed > 2.2 then
      s.skid_t = s.skid_t + 1
      if s.skid_t % 3 == 1 then Fx.dust(s.x, s.y, 1, -sign(s.vx), 0.6) end
      if s.skid_t == 1 then Snd.play("skid") end
    end
    if math.abs(s.vx) < 1.2 then s.face = dir end
    return
  end
  s.skid_t = 0
  s.face = dir
  if s.ground and speed < K.START_V then s.vx = dir * K.START_V speed = K.START_V end
  local acc = (not s.ground) and K.AIR_ACCEL or (speed < K.WALK_V and K.ACCEL or K.ACCEL_RUN)
  if speed < target then s.vx = dir * math.min(speed + acc, target)
  elseif speed > target then s.vx = dir * math.max(speed - 0.09, target) end
end

local function scooter_x(dir, down, turbo)
  local v = s.vx
  local av, sv = math.abs(v), sign(v)
  if not s.ground then -- carries its speed in the air; a little steering
    if dir ~= 0 and (sv == dir or av < 0.3) and av < K.S_TOP then s.vx = v + dir * 0.05 end
    s.vx = approach(s.vx, 0, 0.004)
    if dir ~= 0 and av < 0.5 then s.face = dir end
    s.mode_s = "air"
    return
  end
  if down and av > 0.3 then -- brake
    s.vx = approach(v, 0, K.S_BRAKE)
    s.brake_t, s.drift_t, s.mode_s = s.brake_t + 1, 0, "brake"
    if s.brake_t % 3 == 1 and av > 1.5 then Fx.dust(s.x - sv * 18, s.y, 1, -sv, 0.8) end
    return
  end
  s.brake_t = 0
  if dir ~= 0 and sv ~= 0 and sv ~= dir and av > K.S_DRIFT_V then -- changing direction at speed: a drift
    s.vx = approach(v, 0, K.S_DRIFT)
    s.drift_t, s.mode_s = s.drift_t + 1, "drift"
    if s.drift_t % 2 == 1 then Fx.dust(s.x - sv * 14, s.y, 1, -sv, 1.4) end
    if s.drift_t == 1 then Snd.play("skid", 0.6) end
    return
  end
  s.drift_t = 0
  if dir ~= 0 then
    if sv ~= 0 and sv ~= dir then -- slow enough: turn on the spot
      s.vx = approach(v, 0, 0.2)
      if math.abs(s.vx) < 0.6 then s.face = dir end
      s.mode_s = "glide"
      return
    end
    s.face = dir
    s.mode_s = "push"
    s.push_p = s.push_p + (0.1 + av * 0.028) * (turbo and 1.35 or 1)
    local f = math.floor(s.push_p) % 8
    local acc = K.S_PUSH + ((f >= 1 and f <= 3) and K.S_PULSE * (turbo and K.S_TURBO or 1) or 0)
    local limit = turbo and K.S_TOP_TURBO or K.S_TOP
    if av < limit then s.vx = dir * math.min(av + acc, limit) else s.vx = dir * math.max(av - K.S_OVER, limit) end
    return
  end
  s.mode_s = "glide"
  s.vx = approach(v, 0, K.S_ROLL)
end

-- ---------------------------------------------------------------- one tick

local function land(hard)
  s.ground, s.jumped, s.air_t = true, false, 0
  s.coyote = K.COYOTE
  if hard then
    s.land_t = 9
    Fx.dust(s.x, s.y, 5, 0, 2.2)
    Snd.play("land", 0.8)
    ev("land_hard")
  else
    Snd.play("land", 0.35)
  end
end

local function do_jump(boost)
  local v = K.JUMP_V + math.min(math.abs(s.vx), 8.8) * 0.055 + (boost or 0)
  s.vy, s.ground, s.jumped, s.jump_t, s.jbuf, s.coyote, s.land_t = -v, false, true, 0, 0, 0, 0
  Fx.dust(s.x, s.y, 3, -sign(s.vx), 1.5)
  Snd.play("jump", 1, {pitch_var = 1})
  ev("jump")
end

function H.bounce(v, held) -- a spring or a stomp throws the body up
  s.vy, s.ground, s.jumped, s.jump_t, s.coyote = -v, false, held and true or false, 0, 0
  s.land_t = 0
end

local function move_x()
  local nx = s.x + s.vx
  if s.scooter and math.abs(s.vx) > 4.5 then -- the scooter at speed breaks crates
    local d = sign(s.vx)
    local xa, xb = s.x + d * HW, nx + d * (HW + 4)
    local n = L.break_crates(math.min(xa, xb), s.y - 50, math.max(xa, xb), s.y - 4)
    if n > 0 then
      H.events.crate = (H.events.crate or 0) + n
      for i = 1, math.min(2, #L.broke_at) do Fx.debris(L.broke_at[i][1], L.broke_at[i][2]) end
      Snd.play("crate")
      s.vx = s.vx * 0.85
    end
  end
  if s.vx > 0 and L.wall_x(nx, s.y, HW, BH, 1) then
    nx = math.floor((nx + HW) / K.TILE) * K.TILE - HW - 0.01
    if s.scooter and s.vx > 4.5 then ev("bump") s.vx = -s.vx * K.S_BOUNCE Snd.play("bump") Fx.dust(nx + HW, s.y - 20, 4, -1, 1.5)
    else s.vx = 0 end
  elseif s.vx < 0 and L.wall_x(nx, s.y, HW, BH, -1) then
    nx = (math.floor((nx - HW) / K.TILE) + 1) * K.TILE + HW + 0.01
    if s.scooter and s.vx < -4.5 then ev("bump") s.vx = -s.vx * K.S_BOUNCE Snd.play("bump") Fx.dust(nx - HW, s.y - 20, 4, 1, 1.5)
    else s.vx = 0 end
  end
  s.x = nx
end

-- the highest ground under the soles going from y0 to y1: the middle, and (for flat ground only) a foot to each side
local function ground3(y0, y1, tol)
  local drop = s.drop_t > 0
  local gy, kind, ch = L.ground(s.x, y0, y1, tol, drop)
  for _, dx in ipairs({-9, 9}) do
    local y2, k2, c2 = L.ground(s.x + dx, y0, y1, tol, drop)
    if y2 and k2 ~= "slope" and (not gy or y2 < gy) then gy, kind, ch = y2, k2, c2 end
  end
  return gy, kind, ch
end

local function move_y()
  local was = s.ground
  if was and s.vy >= 0 then -- stick to the ground: ramps up and down, small steps
    local gy, kind, ch = ground3(s.y - 14, s.y + 14, 16)
    if gy then
      s.y, s.vy, s.gkind, s.gchar = gy, 0, kind, ch
      return
    end
    -- the ground is gone: off a ledge (coyote time) or off the top of a ramp (launched)
    s.ground = false
    s.coyote = K.COYOTE
    if s.gkind == "slope" and s.gchar then
      local up = (s.gchar == "a" or s.gchar == "b") and 1 or -1
      if sign(s.vx) == up and math.abs(s.vx) > 2.5 then
        s.vy = -math.min(math.abs(s.vx) * K.RAMP_LAUNCH, 7)
        s.coyote = 0
        ev("ramp") Snd.play("ramp", 0.5)
        if math.abs(s.vx) > 4.5 then ev("ramp_fast") end
      end
    end
    s.gkind = nil
  end
  -- in the air
  local ny = s.y + s.vy
  if s.vy >= 0 then
    local gy, kind, ch = ground3(s.y, ny, 16)
    if gy then
      local impact = s.vy
      s.y, s.vy, s.gkind, s.gchar = gy, 0, kind, ch
      land(impact > K.LAND_HARD)
      return
    end
    s.y = ny
  else
    s.y = ny
    local head = s.y - BH
    local l, m, r = L.ceiling(s.x, head, HW)
    if l or m or r then
      if l and not r and not m then s.x = s.x + 5 -- a corner: slide round it
      elseif r and not l and not m then s.x = s.x - 5
      else
        s.y = (math.floor(head / K.TILE) + 1) * K.TILE + BH
        s.vy = 0
        ev("bonk")
      end
    end
  end
end

local function control(dir, down)
  local run = In.btn("c")
  if In.btnp("a") then s.jbuf = K.BUFFER elseif s.jbuf > 0 then s.jbuf = s.jbuf - 1 end
  if s.ground then s.coyote = K.COYOTE elseif s.coyote > 0 then s.coyote = s.coyote - 1 end
  if s.drop_t > 0 then s.drop_t = s.drop_t - 1 end

  if s.scooter then scooter_x(dir, down, run) else walk_x(dir, run) end

  -- jump: buffered, with coyote time; down + jump on a shelf drops through it
  if s.jbuf > 0 then
    if s.ground and s.gkind == "shelf" and down then
      s.drop_t, s.ground, s.jbuf, s.y, s.coyote = 14, false, 0, s.y + 2, 0
    elseif s.ground or s.coyote > 0 then
      do_jump(s.scooter and 0.5 or 0)
    end
  end
  if s.jump_t < 99 then s.jump_t = s.jump_t + 1 end
  -- a short press, a short jump
  if s.jumped and s.vy < -K.CUT_V and not In.btn("a") then s.vy = -K.CUT_V end

  -- gravity: a moment of hang at the top, heavier on the way down, faster still with DOWN held
  if not s.ground then
    s.air_t = s.air_t + 1
    local g = K.GRAV
    if s.vy > 0 then
      g = g * K.FALL_G
      if down and not s.scooter then g = g * K.FAST_G / K.FALL_G end
    elseif math.abs(s.vy) < K.HANG_V and In.btn("a") then
      g = g * K.HANG_G
    end
    s.vy = math.min(s.vy + g, (down and not s.scooter) and K.FAST_FALL or K.MAX_FALL)
  end
end

-- the little animation clocks, and the sounds that go with them
local STRIDE = {walk = 8.5, run = 11.5}
local function clocks()
  local av = math.abs(s.vx)
  if s.scooter or not s.ground then
    s.gait = av > 3.2 and "run" or "walk"
  else
    local was = s.gait
    if s.gait == "walk" and av > 3.3 then s.gait = "run" elseif s.gait == "run" and av < 2.6 then s.gait = "walk" end
    if was ~= s.gait then -- the same point in the cycle in the other gait
      local nw, nr = Spr.n("poncho", "walk"), Spr.n("poncho", "run")
      if nw > 0 and nr > 0 then
        local from, to = was == "walk" and nw or nr, s.gait == "walk" and nw or nr
        s.phase = (s.phase % from) / from * to
      end
    end
    if av > 0.15 then s.phase = s.phase + av / STRIDE[s.gait] end
    -- a footstep each time a foot lands (twice a cycle)
    local n = Spr.n("poncho", s.gait)
    if n > 0 and av > 0.5 then
      local f = math.floor(s.phase) % n
      if f ~= s.step_f and (f == 0 or f == n // 2) then Snd.play("step", 0.5 + av * 0.05, {pitch_var = 3, max = 2}) end
      s.step_f = f
    end
  end
  if s.land_t > 0 then s.land_t = s.land_t - 1 end
  if s.ground and av < 0.15 and not s.scooter then s.idle_t = s.idle_t + 1 else s.idle_t = 0 end
  s.glide_t = s.glide_t + 1
end

function H.update()
  H.events = {}
  s.t = s.t + 1
  if s.inv > 0 then s.inv = s.inv - 1 end
  local st = s.state
  if st == "dead" then
    s.dead_t = s.dead_t + 1
    s.vy = s.vy + K.GRAV
    s.y = s.y + s.vy
    s.x = s.x + s.vx
    s.vx = s.vx * 0.98
    return
  elseif st == "win" then
    s.win_t = s.win_t + 1
    s.vx = approach(s.vx, 0, 0.12)
    s.x = s.x + s.vx
    s.ground = true
    local gy = ground3(s.y - 14, s.y + 14, 16)
    if gy then s.y = gy end
    return
  end
  local dir = (In.btn("right") and 1 or 0) - (In.btn("left") and 1 or 0)
  local down = In.btn("down")
  if st == "hurt" then
    s.hurt_t = s.hurt_t - 1
    if s.hurt_t <= 0 then s.state = "play" end
    dir = 0
    s.jbuf = 0
    if s.ground then s.vx = approach(s.vx, 0, 0.2) end
    if not s.ground then
      s.vy = math.min(s.vy + K.GRAV, K.MAX_FALL)
      s.air_t = s.air_t + 1
    end
    move_x() move_y() clocks()
    return
  end
  if In.btnp("b") and H.has_scooter then -- B: on or off the scooter
    s.scooter = not s.scooter
    Snd.play("scooter", 0.5)
    Fx.dust(s.x, s.y, 3, 0, 1.5)
    ev("mount")
  end
  s.act = false -- a tap of C is the costume's power; holding it runs
  if In.btn("c") then s.c_t = s.c_t + 1
  else
    if s.c_t > 0 and s.c_t <= K.TAP then s.act = true end
    s.c_t = 0
  end
  control(dir, down)
  Power.update(s, down)
  move_x()
  move_y()
  clocks()
  s.lean = approach(s.lean, clamp(s.vx / 8, -1, 1), 0.08)
  if s.y > L.H + 90 then H.die("pit") end
end

-- ---------------------------------------------------------------- harm

function H.hurt(from_x)
  if s.inv > 0 or s.state ~= "play" then return false end
  if H.costume then -- a hit costs the costume, not a heart
    Power.lose(s)
    Snd.play("hurt")
    ev("hurt")
    local away = (s.x < from_x) and -1 or 1
    s.state, s.hurt_t, s.inv = "hurt", K.HURT_T, K.INVULN
    s.vx, s.vy, s.ground, s.jumped, s.face = away * 3.4, -6.2, false, false, -away
    return true
  end
  H.hearts = H.hearts - 1
  Snd.play("hurt")
  ev("hurt")
  if H.hearts <= 0 then H.die("foe") return true end
  local away = (s.x < from_x) and -1 or 1
  s.state, s.hurt_t, s.inv = "hurt", K.HURT_T, K.INVULN
  s.vx, s.vy, s.ground, s.jumped, s.face = away * 3.4, -6.2, false, false, -away
  s.scooter = false -- a hit throws him off the scooter
  return true
end

function H.die(how)
  if s.state == "dead" then return end
  s.state, s.dead_t, s.ground = "dead", 0, false
  Snd.play("die")
  ev("die")
  if how == "pit" then s.vy, s.vx = 0, 0 else s.vy, s.vx = -9, s.vx * 0.3 end
  s.how_died = how
end

function H.win()
  if s.state == "win" then return end
  s.state, s.win_t = "win", 0
  s.scooter = false
end

-- ---------------------------------------------------------------- the picture

local function seq(sheet, prefix, i) return Spr.seq(sheet, prefix, i) end

-- sheet, frame for what the body is doing now
function H.pose()
  local av = math.abs(s.vx)
  local st = s.state
  local sh = "poncho"
  if st == "win" then return sh, seq(sh, "win", s.win_t / 7) end
  if st == "dead" then
    local n = Spr.n(sh, "die")
    return sh, seq(sh, "die", math.min(n - 1, s.dead_t // 9))
  end
  if st == "hurt" then return sh, seq(sh, "hurt", s.hurt_t > K.HURT_T - 8 and 0 or 1) end
  if s.scooter then
    sh = "poncho_scooter"
    if not s.ground then
      local f = s.jump_t < 3 and 0 or (s.vy < -2 and 1 or (s.vy < 2 and 2 or 3))
      return sh, seq(sh, "scooter_jump", f)
    end
    local m = s.mode_s
    if m == "brake" then return sh, seq(sh, "scooter_brake", s.brake_t // 4) end
    if m == "drift" then return sh, seq(sh, "scooter_drift", s.drift_t // 5) end
    if m == "push" then return sh, seq(sh, "scooter_push", s.push_p) end
    return sh, seq(sh, "scooter_glide", av > 0.3 and s.glide_t / 9 or 0)
  end
  if H.costume then
    local cs, n = "poncho_" .. H.costume, nil
    local pw = s.pw
    if pw then
      local k = pw.kind
      if k == "dash" then return cs, seq(cs, H.costume == "futbol" and "dash" or "headbutt", pw.t * 6 / pw.len) end
      if k == "fire" then return cs, seq(cs, "fire", pw.t // 6 % 3) end
      if k == "pound" then return cs, seq(cs, "stomp", 0) end
      if k == "shock" then return cs, seq(cs, "stomp", pw.t < 6 and 1 or 2) end
      if k == "splash" then return cs, seq(cs, "splash", pw.t * 6 / pw.len) end
    end
    if not s.ground then return cs, seq(cs, "run", 2) end
    if av > 0.15 then
      local g = Spr.n("poncho", s.gait)
      return cs, seq(cs, "run", (s.phase % g) / g * Spr.n(cs, "run"))
    end
    return cs, seq(cs, "idle", s.idle_t // 14 % Spr.n(cs, "idle"))
  end
  if not s.ground then
    local f
    if s.jump_t < 3 then f = "jump_0"
    elseif s.vy < -2.2 then f = "jump_1"
    elseif s.vy < 2 then f = "jump_2"
    elseif s.vy < 6.5 then f = "jump_3"
    else f = "fall_0" end
    return sh, Spr.has(sh, f) and f or seq(sh, "jump", 0)
  end
  if s.land_t > 0 and av < 1.8 then return sh, seq(sh, "land", 2 - (s.land_t - 1) // 3) end
  if av > 0.15 then
    local prefix = s.gait
    return sh, seq(sh, prefix, s.phase)
  end
  -- standing: breathing, then after three seconds a look around and a blink (the whole idle strip once), again every few seconds
  local n = Spr.n(sh, "idle")
  if s.idle_t < 180 then
    return sh, seq(sh, "idle", (s.idle_t // 45) % 2)
  end
  local k = ((s.idle_t - 180) // 8)
  if k < n then return sh, seq(sh, "idle", k) end
  if s.idle_t > 180 + 8 * n + 150 then s.idle_t = 170 end
  return sh, seq(sh, "idle", (s.idle_t // 45) % 2)
end

function H.draw(cam_x, cam_y)
  local sh, frame = H.pose()
  if not frame then return end
  -- hurt and invulnerable: blink (a steady see-through for a player who wants fewer flashes)
  local alpha = nil
  if s.inv > 0 and s.state == "play" and s.fut_t <= 0 then
    if U.calm() then alpha = 0.6 elseif (s.inv // 6) % 2 == 0 then alpha = 0.35 end
  end
  -- a soft shadow on the ground
  if s.ground then
    Deco.img("TOY_SHADOW", math.abs(s.vx) > 3 and 1 or 0, math.floor(s.x), math.floor(s.y))
  end
  Spr.draw(sh, frame, math.floor(s.x), math.floor(s.y), {flip = s.face < 0, alpha = alpha})
  -- the powers' effects, by code: at most five commands
  local pw, f = s.pw, s.face
  local x, y = math.floor(s.x), math.floor(s.y)
  if H.costume and pw and pw.kind == "fire" and pw.t >= 5 and pw.t <= 34 then -- a tongue of flame, flickering
    local fl = pw.t % 4 * 3
    local x0 = x + f * 52
    tri(x0, y - 52, x0 + f * (88 + fl), y - 40 - fl // 2, x0, y - 30, 0xFF8A20)
    tri(x0, y - 48, x0 + f * (62 + fl), y - 41, x0, y - 34, 0xFFD43A)
  elseif H.costume == "barretina" and pw and pw.kind == "dash" then -- speed lines behind the head
    line(x - f * 30, y - 60, x - f * 70, y - 60, 0xFFFFFF) line(x - f * 26, y - 40, x - f * 64, y - 40, 0xFFFFFF)
  end
  if s.fut_t > 0 then -- sparkles circling him
    local a = s.t * 0.2
    for i = 0, 2 do
      local b = a + i * 2.094
      Deco.img("TOY_SPARK", 0, x + math.floor(math.cos(b) * 34), y - 46 + math.floor(math.sin(b) * 36))
    end
  end
end

return H
