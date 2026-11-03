-- world: one gallery of the cellar and what happens in it. The map raycast draws, the doors sliding in it, the levers,
-- the things on the floor, the ghost corks and the corks in flight, the candle burning down. Everything is in squares
-- (x, y floats, 0..w and 0..h; a square's centre is .5); angles in degrees, 0 east, 90 south (raycast's).
-- Input comes through W.btn / W.btnp, so the demo and the tests can drive the game with the same buttons a player has.
local LV = require("levels")
local Snd = require("sound")
local W = {}

local WALL = {["#"] = true, V = true, B = true, S = true, R = true, P = true, D = true, G = true, H = true,
              L = true, M = true, E = true, X = true}
local DOOR = {D = true, G = true, H = true, S = true}
local THING = {k = "key", c = "candle", a = "bottle", r = "reserva", s = "cork", b = "barrel", g = "demijohn"}
local BLOCKS = {barrel = true, demijohn = true}
W.WALL = WALL

W.SPEED, W.BACK, W.TURN, W.R = 0.066, 0.045, 3.2, 0.22
W.WAX_TICK = 100 / (60 * 200)       -- a candle lasts three minutes and a bit
W.RAISED = 2.5                      -- the lantern held up burns that much faster
W.BLOW = 15                         -- what a ghost cork's breath takes from the candle
W.CANDLE = 45
W.GHOST_SPEED, W.FLEE_SPEED = 0.024, 0.04
W.SHOT_SPEED = 0.3

-- ------------------------------------------------------------------ input (a player, the demo or a test's autopilot)
local held, prev = nil, {}
function W.drive(t) held = t end -- a table of held buttons, or nil: the real buttons
function W.btn(b) if held then return held[b] == true end return btn(b) end
function W.btnp(b) if held then return held[b] == true and not prev[b] end return btnp(b) end
local function end_input()
  if held then for _, b in ipairs({"up", "down", "left", "right", "a", "b", "c", "start"}) do prev[b] = held[b] end end
end

-- ------------------------------------------------------------------ the map
local function key(x, y) return y * 256 + x end

function W.cell(x, y) -- the character of a square (outside: rock)
  local row = W.map[y + 1]
  if not row or x < 0 or x >= W.w then return "#" end
  return row:sub(x + 1, x + 1)
end

local function set_cell(x, y, c)
  local row = W.map[y + 1]
  W.map[y + 1] = row:sub(1, x) .. c .. row:sub(x + 2)
end

function W.door_at(x, y) return W.doors_by[key(x, y)] end

function W.solid(x, y) -- can a body stand in this square?
  if W.blocked[key(x, y)] then return true end
  local c = W.cell(x, y)
  if not WALL[c] then return false end
  local d = W.doors_by[key(x, y)]
  return not (d and d.active and d.open >= 0.9)
end

local function free(x, y) -- a point of a body
  return not W.solid(math.floor(x), math.floor(y))
end

function W.load(n)
  local lv = LV[n]
  W.level, W.def = n, lv
  W.map, W.doors, W.doors_by, W.levers, W.things, W.ghosts, W.shots, W.blocked = {}, {}, {}, {}, {}, {}, {}, {}
  W.ghosts_total, W.ghosts_popped, W.bottles_total = 0, 0, 0
  W.has_key, W.key_total = false, 0
  for y, row in ipairs(lv.map) do
    local out = {}
    for x = 1, #row do
      local c = row:sub(x, x)
      local cx, cy = x - 1, y - 1
      if c == "@" then
        W.P = {x = cx + 0.5, y = cy + 0.5, a = lv.angle, hurt = 0, walk = 0}
        c = "."
      elseif c == "t" then
        W.ghosts[#W.ghosts + 1] = {x = cx + 0.5, y = cy + 0.5, hx = cx + 0.5, hy = cy + 0.5, state = "float", t = 0,
                                   phase = (#W.ghosts * 37) % 120}
        W.ghosts_total = W.ghosts_total + 1
        c = "."
      elseif THING[c] then
        local k = THING[c]
        W.things[#W.things + 1] = {kind = k, x = cx + 0.5, y = cy + 0.5}
        if BLOCKS[k] then W.blocked[key(cx, cy)] = true end
        if k == "key" then W.key_total = W.key_total + 1 end
        if k == "bottle" or k == "reserva" then W.bottles_total = W.bottles_total + 1 end
        c = "."
      end
      if DOOR[c] then
        local d = {x = cx, y = cy, kind = c, open = 0, opening = false, active = c ~= "S"}
        W.doors[#W.doors + 1] = d
        W.doors_by[key(cx, cy)] = d
      elseif c == "L" then
        W.levers[#W.levers + 1] = {x = cx, y = cy, on = false}
      end
      out[#out + 1] = c
    end
    W.map[y] = table.concat(out)
  end
  W.h, W.w = #W.map, #W.map[1]
  W.grid = grid(W.w, W.h)
  for y = 0, W.h - 1 do
    for x = 0, W.w - 1 do W.grid:set(x, y, W.solid(x, y) and 0 or 1) end
  end
  W.seen, W.seen_n, W.fresh = {}, 0, {}
  W.open_cells = 0
  for y = 0, W.h - 1 do for x = 0, W.w - 1 do if not WALL[W.cell(x, y)] then W.open_cells = W.open_cells + 1 end end end
  W.pcell, W.field, W.flee_field = nil, nil, nil
  W.raised, W.mode, W.t = false, "play", 0
  W.levers_on, W.mapped, W.blown = 0, false, 0
  W.face, W.face_t = 0, 0
  W.gun, W.cool = 0, 0
  W.msg, W.msg_t = nil, 0
end

-- a new night: what the watchman carries from gallery to gallery
function W.new_game()
  W.wax, W.matches, W.corks, W.score = 100, 3, 6, 0
  W.matches_used, W.reserva, W.all_ghosts_once, W.mapped_once = 0, false, false, false
  W.hook = W.hook or function() end
end

local function say(key, args) W.msg, W.msg_args, W.msg_t = key, args, 150 end
W.say = say

-- ------------------------------------------------------------------ doors, levers, the way out
local function open_door(d, snd)
  if d.opening or d.open >= 1 then return end
  d.opening, d.active = true, true
  Snd.play(snd or "SFX_DOOR")
end

local function levers_done() return W.levers_on >= #W.levers end

local function try_door(d) -- pushed or used: opens if it may
  if d.opening then return end
  if d.kind == "D" then open_door(d)
  elseif d.kind == "G" then
    if W.has_key then open_door(d, "SFX_GATE") else
      if W.msg ~= "locked" then Snd.play("SFX_LOCKED") end
      say("locked")
    end
  elseif d.kind == "H" then
    if W.msg ~= "need_lever" then Snd.play("SFX_LOCKED") end
    say("need_lever")
  elseif d.kind == "S" then
    open_door(d, "SFX_SECRET")
    say("secret")
  end
end

local function pull(lv)
  if lv.on then return end
  lv.on = true
  set_cell(lv.x, lv.y, "M")
  W.levers_on = W.levers_on + 1
  Snd.play("SFX_LEVER")
  W.score = W.score + 50
  if levers_done() then
    for _, d in ipairs(W.doors) do if d.kind == "H" then open_door(d, "SFX_GATE") end end
    say("gates_open")
  else
    say("levers", {n = W.levers_on, of = #W.levers})
  end
end

local function bump(cx, cy) -- the watchman walks into a square he cannot enter
  local c = W.cell(cx, cy)
  local d = W.doors_by[key(cx, cy)]
  if d and d.kind ~= "S" then try_door(d)
  elseif c == "E" then W.mode = "clear" W.t = 0 Snd.play("SFX_STAIRS")
  elseif c == "X" then W.mode = "out" W.t = 0 Snd.play("SFX_OUT")
  end
end

function W.ahead(dist) -- the square straight ahead
  local a = math.rad(W.P.a)
  return math.floor(W.P.x + math.cos(a) * (dist or 0.8)), math.floor(W.P.y + math.sin(a) * (dist or 0.8))
end

local function use()
  local cx, cy = W.ahead(0.8)
  local c = W.cell(cx, cy)
  local d = W.doors_by[key(cx, cy)]
  if d then try_door(d) return end
  if c == "L" then for _, lv in ipairs(W.levers) do if lv.x == cx and lv.y == cy then pull(lv) end end return end
  if c == "M" then say("lever_done") return end
  if c == "E" or c == "X" then bump(cx, cy) return end
end

local function step_doors()
  for _, d in ipairs(W.doors) do
    if d.opening and d.open < 1 then
      d.open = math.min(1, d.open + (d.kind == "S" and 1 / 70 or 1 / 32))
      if d.open >= 0.9 then W.grid:set(d.x, d.y, 1) end
    end
  end
end

-- ------------------------------------------------------------------ moving
local function move(dx, dy)
  local P, r = W.P, W.R
  local nx = P.x + dx
  local sx = dx > 0 and r or -r
  if dx ~= 0 then
    if free(nx + sx, P.y - r) and free(nx + sx, P.y + r) then P.x = nx
    else bump(math.floor(nx + sx), math.floor(P.y)) end
  end
  local ny = P.y + dy
  local sy = dy > 0 and r or -r
  if dy ~= 0 then
    if free(P.x - r, ny + sy) and free(P.x + r, ny + sy) then P.y = ny
    else bump(math.floor(P.x), math.floor(ny + sy)) end
  end
end

local function walk()
  local P = W.P
  local fwd = (W.btn("up") and 1 or 0) - (W.btn("down") and 1 or 0)
  local side = (W.btn("right") and 1 or 0) - (W.btn("left") and 1 or 0)
  local a = math.rad(P.a)
  if W.btn("b") and side ~= 0 then -- B held: a step aside
    move(-math.sin(a) * side * 0.05, math.cos(a) * side * 0.05)
  else -- turning starts slow and gathers speed: a tap turns a little (aiming), a held button turns fast
    P.turn = side ~= 0 and (P.turn or 0) + 1 or 0
    P.a = (P.a + side * (1.2 + (W.TURN - 1.2) * math.min(1, P.turn / 14))) % 360
  end
  if fwd ~= 0 then
    local sp = fwd > 0 and W.SPEED or -W.BACK
    move(math.cos(a) * sp, math.sin(a) * sp)
    P.walk = P.walk + 1
  end
end

-- ------------------------------------------------------------------ the light and what it reveals
function W.fog() -- how far the candle lights, in squares
  local k = (math.max(0, W.wax) / 100) ^ 0.6
  local f = (2.2 + 8.5 * k) * (W.def.fog or 1)
  if W.raised then f = f + 3.5 end
  local fl = noise(ticks() * 0.09) * (W.wax < 25 and 0.8 or 0.3)
  return math.max(1.4, f + fl)
end

local function reveal() -- the squares in the candle's reach, for the map (shadowcasting: walls stop the light)
  local cx, cy = math.floor(W.P.x), math.floor(W.P.y)
  local fov = W.grid:fov(cx, cy, math.floor(W.fog() + 0.5))
  local x0, x1 = math.max(0, cx - 12), math.min(W.w - 1, cx + 12)
  local y0, y1 = math.max(0, cy - 12), math.min(W.h - 1, cy + 12)
  for y = y0, y1 do
    for x = x0, x1 do
      local k = key(x, y)
      if not W.seen[k] and fov:get(x, y) > 0 then
        W.seen[k] = true
        W.fresh[#W.fresh + 1] = k
        if not WALL[W.cell(x, y)] then W.seen_n = W.seen_n + 1 end
      end
    end
  end
  if W.seen_n >= W.open_cells and not W.mapped then
    W.mapped = true
    W.hook("cartografo")
  end
end

local function fields() -- the way to the watchman from every square, and the way away from him: one search for every ghost
  local cx, cy = math.floor(W.P.x), math.floor(W.P.y)
  if W.pcell == key(cx, cy) then return end
  W.pcell = key(cx, cy)
  W.field = W.grid:distances(cx, cy)
  W.flee_field = nil
  reveal()
end

local function flee_field()
  if not W.flee_field then
    local f = W.grid:distances(math.floor(W.P.x), math.floor(W.P.y))
    f:scale(-1.2)
    W.flee_field = W.grid:rescan(f) -- away from him, and round corners to hide, not into a wall
  end
  return W.flee_field
end

-- ------------------------------------------------------------------ ghost corks
local function ghost_step(g, dx, dy, speed)
  local d = math.sqrt(dx * dx + dy * dy)
  if d < 1e-4 then return end
  local nx, ny = g.x + dx / d * speed, g.y + dy / d * speed
  if free(nx, g.y) then g.x = nx end
  if free(g.x, ny) then g.y = ny end
end

local function follow(g, field, speed)
  local cx, cy = math.floor(g.x), math.floor(g.y)
  local dx, dy = field:descend(cx, cy)
  local tx, ty = cx + dx + 0.5, cy + dy + 0.5 -- the next square's middle (its own, when none is better)
  ghost_step(g, tx - g.x, ty - g.y, speed)
end

local function sees(g)
  return W.grid:sees(math.floor(g.x), math.floor(g.y), math.floor(W.P.x), math.floor(W.P.y))
end

local function update_ghost(g, i)
  g.t = g.t + 1
  local P = W.P
  local dx, dy = P.x - g.x, P.y - g.y
  local d = math.sqrt(dx * dx + dy * dy)
  if g.state == "pop" then return g.t > 24 end
  if (g.t + i * 3) % 10 == 0 then g.sees = d < 7 and sees(g) end
  if g.state == "float" then
    ghost_step(g, g.hx - g.x, g.hy - g.y, 0.008)
    if g.sees and d < 6.5 then g.state, g.t = "chase", 0 end
  elseif g.state == "chase" then
    if g.sees then ghost_step(g, dx, dy, W.GHOST_SPEED) elseif W.field then follow(g, W.field, W.GHOST_SPEED) end
    if d > 9 then g.state, g.t = "float", 0 end
  elseif g.state == "flee" then
    follow(g, flee_field(), W.FLEE_SPEED)
    if g.t > g.until_t then g.state, g.t = "chase", 0 end
  end
  if g.state ~= "flee" and W.raised and g.sees and d < 6 then
    g.state, g.t, g.until_t = "flee", 0, 120
    W.hook("espantar")
  end
  if g.state ~= "flee" and d < 0.42 and P.hurt == 0 then -- it blows on the candle
    W.wax = W.wax - W.BLOW
    P.hurt = 60
    W.face, W.face_t = 4, 50
    g.state, g.t, g.until_t = "flee", 0, 150
    Snd.play("SFX_BLOW")
    W.blown = 12
  end
  return false
end

local function pop(g)
  g.state, g.t = "pop", 0
  W.ghosts_popped = W.ghosts_popped + 1
  W.score = W.score + 100
  W.things[#W.things + 1] = {kind = "cork", x = g.x, y = g.y}
  Snd.play("SFX_BUBBLES")
  W.hook("taponazo")
  if W.ghosts_popped == W.ghosts_total then W.hook("todos") end
end

-- ------------------------------------------------------------------ corks in flight
local function shoot()
  if W.cool > 0 then return end
  if W.corks <= 0 then
    Snd.play("SFX_CLICK")
    say("no_corks")
    W.cool = 20
    return
  end
  W.corks = W.corks - 1
  local a = math.rad(W.P.a)
  W.shots[#W.shots + 1] = {x = W.P.x + math.cos(a) * 0.3, y = W.P.y + math.sin(a) * 0.3, dx = math.cos(a), dy = math.sin(a), life = 90}
  W.gun, W.cool = 10, 16
  Snd.play("SFX_POP")
end

local function update_shots()
  for i = #W.shots, 1, -1 do
    local s = W.shots[i]
    local gone = false
    for _ = 1, 3 do -- small steps: a cork never jumps over a ghost or through a door
      local nx, ny = s.x + s.dx * W.SHOT_SPEED / 3, s.y + s.dy * W.SHOT_SPEED / 3
      for _, g in ipairs(W.ghosts) do
        if g.state ~= "pop" and (g.x - nx) ^ 2 + (g.y - ny) ^ 2 < 0.38 * 0.38 then pop(g) gone = true break end
      end
      if gone then break end
      if not free(nx, ny) then -- it hits a wall and falls: picked up again later
        W.things[#W.things + 1] = {kind = "cork", x = s.x - s.dx * 0.15, y = s.y - s.dy * 0.15}
        Snd.play("SFX_THUD")
        gone = true
        break
      end
      s.x, s.y = nx, ny
    end
    s.life = s.life - 1
    if gone or s.life <= 0 then table.remove(W.shots, i) end
  end
end

-- ------------------------------------------------------------------ things on the floor
local function take()
  local P = W.P
  for i = #W.things, 1, -1 do
    local it = W.things[i]
    if not BLOCKS[it.kind] and (it.x - P.x) ^ 2 + (it.y - P.y) ^ 2 < 0.45 * 0.45 then
      local k = it.kind
      if k == "key" then W.has_key = true W.score = W.score + 200 Snd.play("SFX_KEY") say("got_key") W.face, W.face_t = 5, 60 W.hook("primera_llave")
      elseif k == "candle" then W.wax = math.min(100, W.wax + W.CANDLE) Snd.play("SFX_CANDLE") say("got_candle")
      elseif k == "bottle" then W.score = W.score + 250 Snd.play("SFX_BOTTLE") say("got_bottle")
      elseif k == "reserva" then W.score = W.score + 2000 W.reserva = true Snd.play("SFX_BOTTLE") say("got_reserva") W.face, W.face_t = 5, 90 W.hook("reserva")
      elseif k == "cork" then W.corks = W.corks + 1 Snd.play("SFX_CLICK")
      end
      table.remove(W.things, i)
    end
  end
end

-- ------------------------------------------------------------------ a tick
function W.update()
  W.t = W.t + 1
  if W.msg_t > 0 then W.msg_t = W.msg_t - 1 if W.msg_t == 0 then W.msg = nil end end
  if W.mode == "relight" then
    if W.t == 40 then Snd.play("SFX_MATCH") end
    if W.t >= 90 then W.mode, W.t = "play", 0 end
    end_input()
    return
  end
  if W.mode ~= "play" then end_input() return end
  local P = W.P
  W.raised = W.btn("c")
  walk()
  if W.btnp("a") then shoot() end
  if W.btnp("b") then use() end
  step_doors()
  fields()
  update_shots()
  for i = #W.ghosts, 1, -1 do if update_ghost(W.ghosts[i], i) then table.remove(W.ghosts, i) end end
  take()
  if P.hurt > 0 then P.hurt = P.hurt - 1 end
  if W.cool > 0 then W.cool = W.cool - 1 end
  if W.gun > 0 then W.gun = W.gun - 1 end
  if W.blown and W.blown > 0 then W.blown = W.blown - 1 end
  if W.face_t > 0 then W.face_t = W.face_t - 1 if W.face_t == 0 then W.face = 0 end end
  W.wax = W.wax - W.WAX_TICK * (W.raised and W.RAISED or 1)
  if W.wax <= 0 then
    W.wax = 0
    if W.matches > 0 then -- a match from the box: the candle lit again
      W.matches, W.matches_used = W.matches - 1, W.matches_used + 1
      W.wax = 55
      W.mode, W.t = "relight", 0
    else
      W.mode, W.t = "dark", 0
    end
  end
  end_input()
end

-- the ghost nearest in front of the watchman, for the face's eyes and the demo
function W.nearest_ghost()
  local best, bd = nil, 99
  for _, g in ipairs(W.ghosts) do
    if g.state ~= "pop" then
      local d = (g.x - W.P.x) ^ 2 + (g.y - W.P.y) ^ 2
      if d < bd then best, bd = g, d end
    end
  end
  return best, math.sqrt(bd)
end

return W
