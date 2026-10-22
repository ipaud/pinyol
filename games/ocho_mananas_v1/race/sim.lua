-- The race itself: one street, Dani, the runners and the herd, in street units. No camera here: the rear and
-- the side views both project this same state, so nothing jumps when the shot changes.
--
--   r = sim.new(day)            a fresh run of that morning (the same seed: the same morning every time)
--   sim.step(r, input)          one tick; input = {lat, adv, push, ease, act}
--   r.over                      nil while running; then {result = "retirada" | "fin" | "fallo", reason, zone}
local sim = {}

-- Starting values for the first prototype (plan, p. 8): to be tuned after playing it.
sim.BASE, sim.PUSH, sim.EASE = 0.90, 1.28, 0.62    -- units a tick
sim.AIR_PUSH, sim.AIR_BASE, sim.AIR_EASE = -18 / 60, 9 / 60, 16 / 60
sim.HIT, sim.BAL_BACK, sim.BAL_WAIT = 25, 15 / 60, 36
sim.WALL = 29                                          -- how close to a wall a runner's middle can be

local function clamp(v, a, b) return v < a and a or v > b and b or v end
local function approach(v, target, step) return v < target and math.min(target, v + step) or math.max(target, v - step) end

function sim.lane_at(r, z)
  local keys = r.day.lane
  if z <= keys[1][1] then return keys[1][2] end
  for i = 2, #keys do
    local a, b = keys[i - 1], keys[i]
    if z <= b[1] then return a[2] + (b[2] - a[2]) * (z - a[1]) / (b[1] - a[1]) end
  end
  return keys[#keys][2]
end

local function log_event(r, kind, text, extra)
  local e = {t = r.t, z = r.dani.z, kind = kind, text = text}
  for k, v in pairs(extra or {}) do e[k] = v end
  r.events[#r.events + 1] = e
  return e
end

function sim.new(day, opts)
  opts = opts or {}
  math.randomseed(day.seed)
  local r = {
    day = day, t = 0, length = day.length, zones = {}, events = {}, rec = {}, over = nil,
    dani = {x = 0, z = 0, v = sim.BASE, vx = 0, air = 100, bal = 100, cool = 999, stumble = 0, phase = 0,
            state = "run", effort = "base", exhausted = false, retire_t = 0, down_t = 0},
    stats = {contacts = 0, air_zero = false, min_air = 100, herd_passed_at = nil, pushes = 0, sharp = 0},
    runners = {}, bulls = {}, can_retire = nil, nearest_bull = nil,
  }
  for i, z in ipairs(day.zones) do
    r.zones[i] = {id = z.id, side = z.side, z0 = z.z0, z1 = z.z1, label = z.label}
  end
  for g, group in ipairs(day.herd) do
    for k, m in ipairs(group.members) do
      local z = group.start + m[3]
      r.bulls[#r.bulls + 1] = {kind = m[1], ox = m[2], z = z, x = sim.lane_at(r, z) + m[2],
                               v = group.speed * (0.985 + 0.03 * math.random()), group = g,
                               phase = math.random(), brushed = false, passed = false}
    end
  end
  for i = 1, day.runners or 0 do
    local z = i <= 3 and -20 - i * 18 or 20 + (i - 3) * (520 / math.max(1, (day.runners or 0) - 3)) + math.random(-8, 8)
    local x = math.random(-24, 24)
    r.runners[i] = {x = x, z = z, tx = x, v0 = 0.80 + math.random() * 0.24, v = 0.9, lean = 0, pending = nil,
                    var = (i - 1) % 4, phase = math.random(), state = "run", bump = 0, next_move = math.random(120, 360),
                    retire = (i % 3 == 0)}
  end
  -- runners who will fall: they run by a wall, stumble where the day says (shoulders first, as everyone), and lie there
  for _, f in ipairs(day.falls or {}) do
    r.runners[#r.runners + 1] = {x = f.x, z = f.start, tx = f.x, v0 = 0.9, v = 0.9, lean = 0, var = 3, phase = 0.3,
                                 state = "run", bump = 0, next_move = 1e9, retire = false,
                                 fall = {at = f.at, lie = f.lie, t = 0}}
  end
  if day.photo then r.photo = {t = 0, taken = false, at = nil, live = false, best = nil, z = nil} end
  return r
end

-- How the run ends.
local function finish(r, result, reason, zone)
  if r.over then return end
  r.over = {result = result, reason = reason, zone = zone, t = r.t, z = r.dani.z}
  if result == "fallo" then
    r.dani.state = "down"
    log_event(r, "fail", reason)
  else
    log_event(r, "end", result, {zone = zone and zone.id})
  end
end

local function contact(r, what)
  local d = r.dani
  d.bal = d.bal - sim.HIT
  d.cool = 0
  d.stumble = 24
  r.stats.contacts = r.stats.contacts + 1
  log_event(r, "contact", what)
  if sfx_hit then sfx_hit(what) end
  if d.bal <= 0 then
    d.bal = 0
    finish(r, "fallo", "caida")
  end
end

local function step_dani(r, inp)
  local d = r.dani
  if d.state == "retire" then
    d.retire_t = d.retire_t + 1
    d.x = approach(d.x, d.retire_side * 34, 0.5)
    d.v = approach(d.v, 0.45, 0.03)
    d.z = d.z + d.v
    d.phase = d.phase + d.v / 22
    if d.retire_t >= 46 then finish(r, "retirada", nil, d.retire_zone) end
    return
  end
  if d.state == "down" then
    d.v = approach(d.v, 0, 0.06)
    d.z = d.z + d.v
    d.down_t = d.down_t + 1
    return
  end
  -- effort: A pushes (and spends air), B eases off (and gets it back), nothing keeps the base pace
  local target = sim.BASE
  local effort = "base"
  if inp.push and not d.exhausted then target, effort = sim.PUSH, "push"
  elseif inp.ease then target, effort = sim.EASE, "ease" end
  target = target + (inp.adv or 0) * 0.08
  if d.exhausted then target = math.min(target, 0.66) end
  if d.stumble > 0 then target = target * 0.7; d.stumble = d.stumble - 1 end
  d.v = d.v + clamp(target - d.v, -0.012, 0.02)
  if effort == "push" and d.effort ~= "push" then r.stats.pushes = r.stats.pushes + 1 end
  d.effort = effort
  local da = effort == "push" and sim.AIR_PUSH or effort == "ease" and sim.AIR_EASE or sim.AIR_BASE
  d.air = clamp(d.air + da, 0, 100)
  if d.air <= 0 and not d.exhausted then
    d.exhausted = true
    r.stats.air_zero = true
    log_event(r, "exhausted", "sin aire")
  elseif d.exhausted and d.air >= 20 then
    d.exhausted = false
  end
  r.stats.min_air = math.min(r.stats.min_air, d.air)
  -- across the street
  local want = (inp.lat or 0) * 0.62
  local before = d.vx
  d.vx = d.vx + clamp(want - d.vx, -0.09, 0.09)
  if math.abs(d.vx - before) > 0.08 and math.abs(want) > 0.5 and before * want < 0 then r.stats.sharp = r.stats.sharp + 1 end
  d.x = clamp(d.x + d.vx, -sim.WALL, sim.WALL)
  d.z = d.z + d.v
  d.phase = d.phase + d.v / 22
  d.cool = d.cool + 1
  if d.cool > sim.BAL_WAIT then d.bal = math.min(100, d.bal + sim.BAL_BACK) end
  -- a way out: close to its wall, inside it, and a new press of A (holding A to push never does it)
  r.can_retire = nil
  for _, zn in ipairs(r.zones) do
    if d.z >= zn.z0 and d.z <= zn.z1 and d.x * zn.side >= 20 then r.can_retire = zn end
  end
  if r.can_retire and inp.act then
    d.state, d.retire_side, d.retire_zone, d.retire_t = "retire", r.can_retire.side, r.can_retire, 0
    log_event(r, "retire", r.can_retire.id)
    if sfx_retire then sfx_retire() end
  end
  if d.z >= r.length then finish(r, "fin") end
end

local function step_bulls(r)
  local d = r.dani
  local nearest, nd = nil, 1e9
  local all_passed = #r.bulls > 0
  for _, b in ipairs(r.bulls) do
    b.z = b.z + b.v
    b.phase = b.phase + b.v / 30
    local tx = clamp(sim.lane_at(r, b.z) + b.ox, -24, 24)
    b.x = approach(b.x, tx, 0.45)
    local dz = b.z - d.z
    if dz < 25 and b.group == 1 then all_passed = false end
    if dz < 0 and -dz < nd then nearest, nd = b, -dz end
    if d.state == "run" and not r.over and dz > -5 and dz < 20 then
      local dx = math.abs(b.x - d.x)
      if dx < 6 then
        r.stats.contacts = r.stats.contacts + 1
        local blocked = false
        for _, ru in ipairs(r.runners) do
          if ru.state == "run" and ru.z > d.z and ru.z - d.z < 9 and math.abs(ru.x - d.x) < 7 then blocked = true end
        end
        finish(r, "fallo", d.exhausted and "agotamiento" or blocked and "bloqueada" or "contacto")
        if sfx_hit then sfx_hit("toro") end
      elseif dx < 10 and not b.brushed then
        b.brushed = true
        contact(r, "roce")
      end
    end
  end
  r.nearest_bull, r.nearest_dist = nearest, nd
  if all_passed and not r.stats.herd_passed_at then
    r.stats.herd_passed_at = r.t
    log_event(r, "herd_passed", "la manada ha pasado")
  end
end

-- The moment: in Nico's stretch, an animal of the first group close behind, in Dani's line, and Dani in control.
-- Too close (under `near`) does not count: the photo is of someone running in front, not of someone being caught.
local function step_photo(r)
  local ph, p = r.photo, r.day.photo
  if not ph or ph.taken then return end
  local d = r.dani
  ph.live, ph.close = false, false
  if d.state ~= "run" or r.over or d.z < p.z0 or d.z > p.z1 then return end
  for _, b in ipairs(r.bulls) do
    local back = d.z - b.z
    if b.group == 1 and math.abs(b.x - d.x) < 7 then
      if back >= p.near and back <= p.far then ph.live = true; ph.best = math.min(ph.best or 1e9, back)
      elseif back > 0 and back < p.near then ph.close = true end
    end
  end
  if ph.live and (d.bal < 60 or d.stumble > 0) then ph.live = false end
  if ph.live then
    ph.t = ph.t + 1
    if ph.t >= p.need then
      ph.taken, ph.at, ph.z = true, r.t, d.z
      log_event(r, "photo", "foto")
      if sfx_photo then sfx_photo() end
    end
  end
end

local function threat_for(r, ru)  -- the nearest animal coming up behind a runner, and where its lane is
  local best, bd = nil, 170
  for _, b in ipairs(r.bulls) do
    local dz = ru.z - b.z
    if dz > -10 and dz < bd then best, bd = b, dz end
  end
  return best
end

local function step_runners(r)
  local d = r.dani
  for i, ru in ipairs(r.runners) do
    if ru.fall and ru.state ~= "gone" then
      local f = ru.fall
      if ru.state == "run" then
        ru.z = ru.z + ru.v
        ru.phase = ru.phase + ru.v / 22
        if ru.z >= f.at - 25 then ru.state, f.t = "trip", 0 end
      elseif ru.state == "trip" then  -- stumbling for a moment: the warning
        f.t = f.t + 1
        ru.v = approach(ru.v, 0.3, 0.02)
        ru.z = ru.z + ru.v
        if f.t >= 40 then ru.state, f.t = "down", 0; log_event(r, "fall", "un corredor al suelo") end
      elseif ru.state == "down" then
        f.t = f.t + 1
        if f.t >= f.lie then ru.state = "gone" end
        if d.state == "run" and not r.over and math.abs(ru.z - d.z) < 5 and math.abs(ru.x - d.x) < 8 and ru.bump == 0 then
          ru.bump = 90
          contact(r, "caido")
        end
        if ru.bump > 0 then ru.bump = ru.bump - 1 end
      end
    elseif ru.state ~= "gone" then
      ru.phase = ru.phase + ru.v / 22
      if ru.bump > 0 then ru.bump = ru.bump - 1 end
      local want_v = ru.v0
      local b = threat_for(r, ru)
      if ru.state == "run" and b then
        local lane = sim.lane_at(r, ru.z) + 0
        if math.abs(ru.x - lane) < 17 and not ru.pending and ru.lean == 0 then
          local side = lane >= 0 and -1 or 1
          if math.abs(ru.tx - side * 22) > 3 then ru.pending, ru.lean = side * (17 + (i % 3) * 3), 14 end
        end
        want_v = ru.v0 + 0.12
        -- once against the wall, they press into it and slow down: the wall fills up
        if ru.lean == 0 and not ru.pending and math.abs(ru.x - ru.tx) < 2 and math.abs(ru.x) >= 15 then want_v = 0.66 end
      elseif ru.state == "run" then
        ru.next_move = ru.next_move - 1
        if ru.next_move <= 0 and ru.lean == 0 then
          ru.next_move = math.random(180, 420)
          local nx = clamp(ru.x + (math.random() < 0.5 and -1 or 1) * math.random(8, 16), -24, 24)
          ru.pending, ru.lean = nx, 18
        end
      end
      -- runners queue behind one another rather than walking through
      for j, o in ipairs(r.runners) do
        if j ~= i and o.state ~= "gone" and o.z > ru.z and o.z - ru.z < 9 and math.abs(o.x - ru.x) < 6 then
          want_v = math.min(want_v, o.v)
        end
      end
      if ru.state == "run" and ru.retire and r.stats.herd_passed_at then
        for _, zn in ipairs(r.zones) do
          if ru.z >= zn.z0 and ru.z <= zn.z1 then ru.state, ru.tx, ru.pending, ru.lean = "retire", zn.side * 34, nil, 0 end
        end
      end
      -- nobody runs into Dani from behind: a runner close behind his line keeps his pace
      if ru.state == "run" and d.state == "run" and ru.z < d.z and d.z - ru.z < 12 and math.abs(ru.x - d.x) < 7 then
        want_v = math.min(want_v, d.v - 0.03)
      end
      ru.v = approach(ru.v, ru.state == "retire" and 0.5 or want_v, 0.015)
      if ru.lean > 0 then
        ru.lean = ru.lean - 1  -- shoulders first: the move is shown before it is made
        if ru.lean == 0 then ru.tx, ru.pending = ru.pending, nil end
      else
        ru.x = approach(ru.x, ru.tx, ru.state == "retire" and 0.5 or 0.36)
      end
      if ru.state == "retire" and math.abs(ru.x) >= 33 then ru.state = "gone" end
      -- a bull never goes through a runner: the runner is pushed to the side
      for _, bb in ipairs(r.bulls) do
        if bb.z - ru.z > -4 and bb.z - ru.z < 20 and math.abs(bb.x - ru.x) < 8 and ru.state == "run" then
          ru.x = clamp(ru.x + (ru.x >= bb.x and 1.4 or -1.4), -sim.WALL, sim.WALL)
          ru.tx = ru.x
        end
      end
      ru.z = ru.z + ru.v
      -- Dani bumping into a runner (or a runner into Dani)
      if d.state == "run" and ru.state == "run" and not r.over then
        local dz, dx = ru.z - d.z, ru.x - d.x
        if math.abs(dz) < 4 and math.abs(dx) < 5 then
          if ru.bump == 0 then
            ru.bump = 60
            contact(r, "corredor")
          end
          if dz > 0 then d.v = math.min(d.v, ru.v - 0.05); d.z = ru.z - 4 else ru.v = math.min(ru.v, d.v - 0.05); ru.z = d.z - 4 end
          d.x = clamp(d.x - (dx >= 0 and 0.5 or -0.5), -sim.WALL, sim.WALL)
        end
      end
    end
  end
end

local function record(r)
  if r.t % 3 ~= 0 then return end
  local d = r.dani
  local s = {t = r.t, dx = d.x, dz = d.z, st = d.state, b = {}, ru = {},
             ph = r.photo and r.photo.taken and r.photo.at > r.t - 3 or nil}
  for _, b in ipairs(r.bulls) do
    if math.abs(b.z - d.z) < 260 then s.b[#s.b + 1] = {b.x, b.z, b.kind == "toro"} end
  end
  for _, ru in ipairs(r.runners) do
    if ru.state ~= "gone" and math.abs(ru.z - d.z) < 260 then s.ru[#s.ru + 1] = {ru.x, ru.z, ru.state == "down"} end
  end
  r.rec[#r.rec + 1] = s
  if #r.rec > 200 then table.remove(r.rec, 1) end
end

function sim.step(r, inp)
  r.t = r.t + 1
  step_dani(r, inp or {})
  step_bulls(r)
  step_runners(r)
  step_photo(r)
  record(r)
end

function sim.zone_ahead(r, range)  -- the next way out not yet behind Dani, within range
  local d = r.dani
  for _, zn in ipairs(r.zones) do
    if zn.z1 >= d.z and zn.z0 - d.z < (range or 220) then return zn end
  end
end

return sim
