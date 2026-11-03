-- dawn: the door out opens on the vineyards at sunrise, with the mountain's stone fingers far away. Drawn with
-- voxels() the way Comanche drew its hills in 1992, a column at a time from a height map and a colour map (art.py):
-- the same trick as the cellar's walls, turned to the open air.
local lang = require("lang")
local D = {}

local t, cam
D.done = false

function D.enter(tally)
  canvas("DAWN", 240, 160)
  t, D.done, D.tally = 0, false, tally
  cam = {x = 128, y = 252, z = 70}
end

function D.update(any_press)
  t = t + 1
  cam.y = math.max(196, cam.y - 0.1)
  cam.z = math.min(96, cam.z + 0.05)
  if t > 240 and any_press then D.done = true end
  return D.done
end

local function line_of(key, value) return lang.tr(key) .. " " .. value end

function D.draw()
  local k = math.min(1, t / 420)
  local sky = k < 1 and rgb(math.floor(120 + 126 * k), math.floor(90 + 104 * k), math.floor(110 + 34 * k)) or 0xF6C290
  voxels("DAWN", {height = "DAWN_H", colour = "DAWN_C", x = cam.x, y = cam.y, angle = 270, z = cam.z, horizon = 58,
                  distance = 230, fov = 70, scale = 92, sky = sky, fog = 320})
  img("DAWN", 0, 0, {scale = 2})
  local sy = 120 - 60 * k -- the sun coming up behind the mountain
  light(330, sy, 100, 0xFFA040, {intensity = 0.25 + 0.2 * k})
  light(330, sy, 24, 0xFFF0C0, {intensity = 0.9})
  if t < 120 then return end
  local a = math.min(1, (t - 120) / 60)
  text(lang.tr("dawn_title"), 240, 24, {font = "dos_vga_title", align = "center", color = 0xFFF2C0, outline = 0x5A2A10,
                                         shadow = 0x3A1A08})
  if a < 1 then return end
  local tl = D.tally
  local lines = {line_of("dawn_score", string.format("%06d", tl.score)),
                 line_of("dawn_ghosts", tl.ghosts), line_of("dawn_bottles", tl.bottles),
                 line_of("dawn_matches", tl.matches)}
  local x, y, w = 120, 196, 240
  rect(x - 12, y - 10, w + 24, 104, 0x1A100A)
  box(x - 12, y - 10, w + 24, 104, 0xD8A860)
  for i, s in ipairs(lines) do text(s, x, y + (i - 1) * 20, {font = "dos_vga_body", color = 0xF0E0B0}) end
  local rec = tl.new_record and lang.tr("dawn_record_new") or line_of("dawn_record", string.format("%06d", tl.record))
  text(rec, 240, y + 80, {font = "dos_vga_body", align = "center", color = tl.new_record and 0xFFD040 or 0xB89868})
  if t > 240 and (t // 30) % 2 == 0 then text(lang.tr("press_back"), 240, 6, {font = "dos_vga_small", align = "center", color = 0xFFFFFF}) end
end

return D
