-- What the race shows over the street (screen pixels, 480x320): the clock, air and balance, the street's map,
-- the herd behind (a small radar that does not need the look back), side warnings and the way-out prompt.
local hud = {}

local NAVY, INK = 0x141B3A, 0x0B0F22
local AIR, AIR_D = 0x4AB0F4, 0x1E4E86
local BAL, BAL_D = 0xF06048, 0x7A2430
local TEAL, TEAL_L = 0x28967A, 0x96ECC8
local WHITE, GOLD = 0xF6F2E8, 0xFFE048

function hud.clock(ticks)
  local s = ticks // 60
  return string.format("08:%02d:%02d", s // 60, s % 60)
end

local function segments(x, y, label, value, col, dark, blink)
  text(label, x, y + 3, {font = "gba_small", scale = 2, color = WHITE})
  local lw = textw(label, {font = "gba_small", scale = 2})
  local bx = x + lw + 6
  rect(bx - 2, y + 1, 6 * 8 + 3, 18, INK)
  local full = value / 100 * 6
  for i = 0, 5 do
    local c = dark
    if full >= i + 1 then c = col elseif full > i then c = (full - i) > 0.5 and col or dark end
    if blink and (ticks() // 8) % 2 == 0 then c = dark end
    rect(bx + i * 8, y + 3, 6, 14, c)
  end
  box(bx - 2, y + 1, 6 * 8 + 3, 18, 0x5A6290)
  return bx + 6 * 8 + 6
end

local function minimap(r, x, y, w)
  local L = r.length
  line(x, y + 8, x + w, y + 8, 0x8A90B8)
  for _, zn in ipairs(r.zones) do
    local a, b = x + zn.z0 / L * w, x + zn.z1 / L * w
    rect(math.floor(a), y + (zn.side < 0 and 3 or 9), math.max(2, math.floor(b - a)), 4, TEAL)
  end
  for _, bl in ipairs(r.bulls) do
    if bl.z > 0 and bl.z < L then rect(math.floor(x + bl.z / L * w), y + 6, 2, 5, 0x302030) end
  end
  local dx = math.floor(x + math.min(r.dani.z, L) / L * w)
  tri(dx - 4, y - 1, dx + 4, y - 1, dx, y + 6, GOLD)
end

function hud.draw(r, opts)
  local d = r.dani
  rect(0, 0, 480, 28, NAVY)
  line(0, 28, 480, 28, 0x3A4478)
  text(opts.clock or hud.clock(r.t), 8, 3, {font = "gba_title", color = WHITE, shadow = INK})
  local x = segments(110, 4, "AIRE", d.air, AIR, AIR_D, d.exhausted)
  segments(x + 8, 4, "EQUILIBRIO", d.bal, BAL, BAL_D, d.bal < 30)
  text(opts.street or "ESTAFETA", 474, 1, {font = "gba_small", scale = 2, color = WHITE, align = "right"})
  minimap(r, 380, 14, 92)
  if d.exhausted then
    plate(118, 32, 96, 20, 0x7A2430)
    text("SIN AIRE", 166, 34, {font = "gba_small", scale = 2, color = WHITE, align = "center"})
  end
  -- the herd behind, as dots on the street's width: top is Dani's line, bottom 30 m back
  local rx, ry, rw, rh = 362, 34, 110, 44
  if opts.radar ~= false and #r.bulls > 0 then
    rect(rx, ry, rw, rh, INK)
    box(rx, ry, rw, rh, 0x5A6290)
    line(rx + 4, ry + 6, rx + rw - 4, ry + 6, 0x3A4478)
    text("DETRÁS", rx + rw - 4, ry + rh - 14, {font = "gba_small", scale = 2, color = 0x6A70A0, align = "right"})
    local px = rx + rw / 2 + d.x / 32 * (rw / 2 - 6)
    tri(px - 4, ry + 2, px + 4, ry + 2, px, ry + 8, GOLD)
    for _, b in ipairs(r.bulls) do
      local back = d.z - b.z
      if back > -10 and back < 300 then
        local bx = rx + rw / 2 + b.x / 32 * (rw / 2 - 6)
        local by = ry + 8 + math.max(0, back) / 300 * (rh - 12)
        local near = back < 70
        local col = b.kind == "toro" and (near and 0xFF5040 or 0xC8C0D0) or 0xE8D8B0
        if not near or (ticks() // 6) % 2 == 0 then rect(math.floor(bx - 2), math.floor(by - 2), 5, 5, col) end
      end
    end
  end
  -- side warnings: an animal close behind, on the side it will pass
  local warn_l, warn_r = 0, 0
  for _, b in ipairs(r.bulls) do
    local back = d.z - b.z
    if back > 0 and back < 110 then
      local k = 1 - back / 110
      if b.x < d.x - 2 then warn_l = math.max(warn_l, k) elseif b.x > d.x + 2 then warn_r = math.max(warn_r, k)
      else warn_l, warn_r = math.max(warn_l, k), math.max(warn_r, k) end
    end
  end
  for s, k in pairs({[-1] = warn_l, [1] = warn_r}) do
    if opts.warn ~= false and k > 0 and (k < 0.6 or (ticks() // 5) % 2 == 0) then
      local cx = s < 0 and 18 or 462
      local cy = 236
      local c = k > 0.6 and 0xFF4030 or 0xFFA040
      tri(cx, cy - 16, cx, cy + 16, cx - s * 14, cy, c)
      tri(cx + s * 10, cy - 16, cx + s * 10, cy + 16, cx - s * 4, cy, c)
    end
  end
  -- the way out
  local zn = r.can_retire
  if zn and d.state == "run" then
    local py = opts.prompt_y or 250
    plate(150, py, 180, 30, TEAL)
    text("A  RETIRARSE", 240, py + 4, {font = "gba_title", color = WHITE, align = "center", shadow = 0x0A3A30})
  elseif d.state == "run" and opts.zone_hint ~= false then
    local sim = require("race.sim")
    local ahead = sim.zone_ahead(r, 230)
    if ahead then
      local m = math.max(0, math.floor((ahead.z0 - d.z) / 9))
      local s = (ahead.side < 0 and "< " or "") .. "Retirada a la " .. (ahead.side < 0 and "izquierda" or "derecha")
                .. (ahead.side > 0 and " >" or "") .. (m > 0 and ("  " .. m .. " m") or "  ahora")
      local w = textw(s, {font = "gba_small", scale = 2}) + 16
      plate(240 - w // 2, 32, w, 20, 0x1C5E50)
      text(s, 240, 34, {font = "gba_small", scale = 2, color = TEAL_L, align = "center"})
    end
  end
  -- Nico's photo: where it is, and how it is going while it can be taken
  local ph, p = r.photo, r.day.photo
  if ph and p and opts.photo ~= false then
    local show = (not ph.taken and d.z > p.z0 - 260 and d.z <= p.z1 and d.state == "run") or (ph.taken and r.t - ph.at < 150)
    if show then
      local x, y = 8, 34
      rect(x, y, 150, 40, INK)
      box(x, y, 150, 40, ph.live and GOLD or 0x5A6290)
      rect(x + 8, y + 10, 18, 12, 0xC8C8D8)  -- a little camera
      rect(x + 12, y + 7, 6, 3, 0xC8C8D8)
      circ(x + 17, y + 16, 4, INK)
      circ(x + 17, y + 16, 2, ph.live and GOLD or 0x5A6290)
      local msg, col
      if ph.taken then msg, col = "¡FOTO!", GOLD
      elseif d.z < p.z0 then msg, col = "Nico, balcón " .. (p.side > 0 and "dcho." or "izdo."), WHITE
      elseif ph.close then msg, col = "¡Demasiado cerca!", 0xFF6050
      elseif ph.live then msg, col = "¡Ahora! Aguanta", GOLD
      else msg, col = "Delante del grupo", 0xC8C0D0 end
      text(msg, x + 34, y + 4, {font = "gba_small", scale = 2, color = col})
      rect(x + 34, y + 24, 108, 8, 0x2A3058)
      rect(x + 34, y + 24, math.floor(108 * math.min(1, ph.t / p.need)), 8, ph.taken and GOLD or 0xE0A040)
    end
  end
  if opts.banner then
    local w = textw(opts.banner, "gba_body") + 24
    rect(240 - w // 2, 58, w, 26, 0x0B0F22)
    box(240 - w // 2, 58, w, 26, GOLD)
    text(opts.banner, 240, 61, {font = "gba_body", color = WHITE, align = "center"})
  end
end

return hud
