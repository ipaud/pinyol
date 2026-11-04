-- explain: "Cómo funciona", from the console's menu. The gallery seen from above with the rays fanning out of the
-- watchman's eyes, and the view being built beside it one column at a time, as raycast() builds it: for each of the
-- 240 columns a ray walks the map square by square until it meets a wall; the nearer the wall, the taller its strip.
-- Three pages: the rays and the columns, a column's numbers (height, texture, fog), the doors and the things.
local W = require("world")
local V = require("view")
local lang = require("lang")
local E = {}

E.hook = function() end
local page, col, paused, hold = 1, 0, false, 0
local MX, MY, MW, MH, CS = 8, 40, 220, 150, 10
local VX, VY = 234, 40

function E.enter(back)
  E.back = back
  page, col, paused, hold = 1, 0, false, 0
  E.hook("curioso")
end

-- one ray as raycast() casts it (docs/lua.md "First person"), done in Lua so its steps can be shown: from the eye along
-- the column's direction, square to square (DDA), until a wall; a door counts where its own slid wall stands
local function ray(c)
  local P = W.P
  local a = math.rad(P.a)
  local dx, dy, k = math.cos(a), math.sin(a), math.tan(math.rad(33))
  local cam = 2 * c / V.VW - 1
  local rx, ry = dx - dy * k * cam, dy + dx * k * cam
  local mx, my = math.floor(P.x), math.floor(P.y)
  local ddx, ddy = rx == 0 and 1e30 or math.abs(1 / rx), ry == 0 and 1e30 or math.abs(1 / ry)
  local sx, sy = rx < 0 and -1 or 1, ry < 0 and -1 or 1
  local tx = rx < 0 and (P.x - mx) * ddx or (mx + 1 - P.x) * ddx
  local ty = ry < 0 and (P.y - my) * ddy or (my + 1 - P.y) * ddy
  local side, steps, d, door = 0, 0, 0, nil
  for _ = 1, 64 do
    if tx < ty then tx, mx, side = tx + ddx, mx + sx, 0 else ty, my, side = ty + ddy, my + sy, 1 end
    steps = steps + 1
    local ch = W.cell(mx, my)
    if W.WALL[ch] then
      local dr = W.door_at(mx, my)
      if not (dr and dr.active) then d = side == 0 and tx - ddx or ty - ddy break end
      if dr.open < 1 then
        local across = W.WALL[W.cell(mx - 1, my)] and W.WALL[W.cell(mx + 1, my)]
        local e, out = side == 0 and tx - ddx or ty - ddy, math.min(tx, ty)
        local t, w
        if across then t = (my + 0.5 - P.y) / ry w = P.x + t * rx - mx else t = (mx + 0.5 - P.x) / rx w = P.y + t * ry - my end
        if t >= e and t <= out and w >= dr.open then d, door, side = t, dr, across and 1 or 0 break end
      end
    end
  end
  d = math.max(0.01, d)
  local hx, hy = P.x + rx * d, P.y + ry * d
  local u = side == 0 and hy or hx
  return {d = d, x = hx, y = hy, side = side, steps = steps, ch = W.cell(mx, my), u = u - math.floor(u), door = door}
end

function E.update() -- true when the player is done
  if btnp("left") then page = (page + 1) % 3 + 1 col = 0 end
  if btnp("right") then page = page % 3 + 1 col = 0 end
  if btnp("a") then paused = not paused end
  if not paused then
    if col < V.VW - 1 then col = math.min(V.VW - 1, col + (page == 1 and 2 or 1)) else
      hold = hold + 1
      if hold > 60 then col, hold = 0, 0 end
    end
  end
  return btnp("b") or btnp("start")
end

local function to_map(x, y, ox, oy) return MX + MW // 2 + (x - ox) * CS, MY + MH // 2 + (y - oy) * CS end

local function draw_map(rays)
  local P = W.P
  clip(MX, MY, MW, MH)
  rect(MX, MY, MW, MH, 0x0C0806)
  local cx, cy = math.floor(P.x), math.floor(P.y)
  for y = cy - 9, cy + 9 do
    for x = cx - 12, cx + 12 do
      local ch = W.cell(x, y)
      local sx, sy = to_map(x, y, P.x, P.y)
      local dr = W.door_at(x, y)
      if dr and dr.active then -- a door: a thin wall across its square, slid aside by how open it is
        rect(sx, sy, CS, CS, 0x1C140E)
        local across = W.WALL[W.cell(x - 1, y)] and W.WALL[W.cell(x + 1, y)]
        if across then rect(sx + math.floor(dr.open * CS), sy + CS // 2 - 1, CS - math.floor(dr.open * CS), 2, 0xD08A40)
        else rect(sx + CS // 2 - 1, sy + math.floor(dr.open * CS), 2, CS - math.floor(dr.open * CS), 0xD08A40) end
      elseif W.WALL[ch] then rect(sx, sy, CS - 1, CS - 1, 0x6E5E4C)
      else rect(sx, sy, CS - 1, CS - 1, 0x241A12) end
    end
  end
  local ex, ey = to_map(P.x, P.y, P.x, P.y)
  for i, r in ipairs(rays) do
    local hx, hy = to_map(r.x, r.y, P.x, P.y)
    line(ex, ey, hx, hy, i == #rays and 0xFFF080 or 0x806030)
  end
  if page == 3 then -- the things, numbered in the order they are drawn: the farthest first
    local list = {}
    for _, it in ipairs(W.things) do list[#list + 1] = it end
    for _, g in ipairs(W.ghosts) do list[#list + 1] = g end
    table.sort(list, function(p, q) return (p.x - P.x) ^ 2 + (p.y - P.y) ^ 2 > (q.x - P.x) ^ 2 + (q.y - P.y) ^ 2 end)
    for i, it in ipairs(list) do
      local sx, sy = to_map(it.x, it.y, P.x, P.y)
      circ(sx, sy, 3, it.state and 0xF0F0FF or 0x60C070)
      if i <= 9 then text(tostring(i), sx + 4, sy - 6, {font = "dos_vga_small", color = 0xF0E0B0}) end
    end
  end
  circ(ex, ey, 3, 0xFFF080)
  clip()
  box(MX - 1, MY - 1, MW + 2, MH + 2, 0xB08850)
end

function E.draw()
  local P = W.P
  V.setup(P.x, P.y, P.a, W.fog())
  V.cast("VIEW")
  cls(0x100A06)
  text(lang.tr("ex_title"), 240, 8, {font = "dos_vga_title", align = "center", color = 0xFFD880})
  text(lang.tr("ex_page", {n = page}), 472, 180, {font = "dos_vga_small", align = "right", color = 0xB89868})
  local rays = {}
  local every = page == 1 and 12 or 9999
  for c = 0, col, every do rays[#rays + 1] = ray(c) end
  local r = ray(col)
  rays[#rays + 1] = r
  draw_map(rays)
  -- the view: page 1 only the columns cast so far, the others whole with the column being explained marked
  img("VIEW", VX, VY)
  if page == 1 and col < V.VW - 1 then rect(VX + col + 1, VY, V.VW - col - 1, V.VH, 0x000000) end
  local h = math.floor(V.VH / r.d)
  local y0 = math.max(VY, VY + V.VH // 2 - h // 2)
  local y1 = math.min(VY + V.VH, VY + V.VH // 2 + h // 2)
  rect(VX + col, y0, 1, y1 - y0, 0xFFF080)
  box(VX - 1, VY - 1, V.VW + 2, V.VH + 2, 0xB08850)
  text(lang.tr("ex_col", {c = col, of = V.VW}), VX, VY + V.VH + 4, {font = "dos_vga_small", color = 0xB89868})
  local fogk = math.max(0, 1 - r.d / W.fog())
  local args = {c = col, d = string.format("%.2f", r.d), h = h, steps = r.steps, u = math.floor(r.u * 64), fog = math.floor(fogk * 100),
                n = #W.things + #W.ghosts, open = r.door and math.floor(r.door.open * 100) or 0}
  local body = lang.tr("ex_" .. page, args)
  local live = lang.tr(page == 3 and (r.door and "ex_live_door" or "ex_live_3") or "ex_live", args)
  textbox(body, 8, 198, 464, 82, {font = "dos_vga_body", color = 0xE8D8B0, valign = "top", fonts = {"dos_vga_small"}})
  textbox(live, 8, 282, 464, 18, {font = "dos_vga_body", color = 0xFFD880, valign = "top", fonts = {"dos_vga_small"}})
  text(lang.tr(paused and "ex_keys_paused" or "ex_keys"), 240, 302, {font = "dos_vga_small", align = "center", color = 0x9A8060})
end

return E
