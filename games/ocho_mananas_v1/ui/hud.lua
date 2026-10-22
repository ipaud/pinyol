-- What the race shows over the street (screen pixels, 480x320): the clock, air and balance, the street's map,
-- the herd behind (a small radar that does not need the look back), side warnings and the way-out prompt.
local frame = require("ui.frame")
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

-- The top bar is a navy panel whose lower edge is at y 30; the room inside it is y 0 to 21 (the panel's top border is
-- above the screen). Everything in it is centred on y 11.
local BAR_MID = 11

local function segments(x, icon, value, col, dark, blink)
  frame.icon(icon, x, BAR_MID - 10, 20)
  local bx = x + 24
  local bw = 6 * 7 + 1
  rect(bx, BAR_MID - 8, bw + 4, 16, INK)
  local full = value / 100 * 6
  for i = 0, 5 do
    local c = dark
    if full >= i + 1 then c = col elseif full > i then c = (full - i) > 0.5 and col or dark end
    if blink and (ticks() // 8) % 2 == 0 then c = dark end
    rect(bx + 2 + i * 7, BAR_MID - 6, 6, 12, c)
  end
  box(bx, BAR_MID - 8, bw + 4, 16, 0xC8A850)
  return bx + bw + 4 + 12
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
  frame.panel("navy", -8, -12, 496, 42)
  text(opts.clock or hud.clock(r.t), 14, BAR_MID - 14, {font = "jersey_body", color = WHITE})  -- its digits fill y 3 to 17
  local x = segments(110, "AIR", d.air, AIR, AIR_D, d.exhausted)
  x = segments(x, "BAL", d.bal, BAL, BAL_D, d.bal < 30)
  text(opts.street or "ESTAFETA", x + 6, BAR_MID - 6, {font = "jersey_small", color = 0xC8D0E8})
  minimap(r, 352, BAR_MID - 8, 112)
  -- the herd behind, as dots on the street's width: top is Dani's line, bottom 30 m back
  local rx, ry, rw, rh = 362, 34, 110, 44
  local herd_near = false  -- the radar only shows while the herd is within reach of it
  for _, b in ipairs(r.bulls) do
    local back = d.z - b.z
    if back > -10 and back < 300 then herd_near = true end
  end
  if opts.radar ~= false and herd_near then
    frame.panel("ink", rx - 2, ry - 2, rw + 4, rh + 4)
    line(rx + 6, ry + 6, rx + rw - 6, ry + 6, 0x3A4478)
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
    frame.panel("teal", 150, py, 180, 32)
    frame.icon("A", 158, py - 2, 34)
    text("RETIRARSE", 250, py + 5, {font = "jersey_body", color = WHITE, align = "center", shadow = 0x0A3A30})
  elseif d.state == "run" and opts.zone_hint ~= false then
    local sim = require("race.sim")
    local ahead = sim.zone_ahead(r, 230)
    if ahead then
      local m = math.max(0, math.floor((ahead.z0 - d.z) / 9))
      local s = (ahead.side < 0 and "< " or "") .. "Retirada a la " .. (ahead.side < 0 and "izquierda" or "derecha")
                .. (ahead.side > 0 and " >" or "") .. (m > 0 and ("  " .. m .. " m") or "  ahora")
      local w = textw(s, {font = "jersey_small"}) + 16
      frame.panel("teal", 240 - w // 2, 34, w, 30)
      text(s, 240, 43, {font = "jersey_small", color = TEAL_L, align = "center"})
    end
  end
  if d.exhausted then  -- on the left, below the street's name, clear of the way-out hint
    frame.panel("red", 8, 34, 100, 30)
    text("SIN AIRE", 58, 43, {font = "jersey_small", color = WHITE, align = "center"})
  end
  -- Nico's photo: where it is, and how it is going while it can be taken
  local ph, p = r.photo, r.day.photo
  if ph and p and opts.photo ~= false then
    local show = (not ph.taken and d.z > p.z0 - 260 and d.z <= p.z1 and d.state == "run") or (ph.taken and r.t - ph.at < 150)
    if show then
      local x, y = 8, 70
      frame.panel(ph.live and "gold" or "ink", x, y, 176, 42)
      frame.icon(ph.live and "FLASH" or "CAM", x + 4, y + 3, 34)
      if ph.live then img("VIEWFINDER", 0, 0, {alpha = 0.55}) end
      local msg, col
      if ph.taken then msg, col = "¡FOTO!", GOLD
      elseif d.z < p.z0 then msg, col = "Nico, balcón " .. (p.side > 0 and "dcho." or "izdo."), WHITE
      elseif ph.close then msg, col = "¡Demasiado cerca!", 0xFF6050
      elseif ph.live then msg, col = "¡Ahora! Aguanta", GOLD
      else msg, col = "Delante del grupo", 0xC8C0D0 end
      text(msg, x + 42, y + 6, {font = "jersey_small", color = ph.live and INK or col})
      rect(x + 42, y + 26, 124, 8, 0x2A3058)
      rect(x + 42, y + 26, math.floor(124 * math.min(1, ph.t / p.need)), 8, ph.taken and GOLD or 0xE0A040)
    end
  end
  if opts.banner then
    local w = math.min(textw(opts.banner, "jersey_small") + 24, 470)
    frame.panel("navy", 240 - w // 2, 110, w, 30)
    text(opts.banner, 240, 116, {font = "jersey_small", color = WHITE, align = "center"})
  end
end

return hud
