-- keys: the stage's piano floor. A white key ('P' tiles along the floor) sinks a few pixels and plays a note when he steps on it, and the notes climb along the level
-- (pentatonic, higher every sixty columns). Pressed keys are kept in a short list and drawn as a darker band over the key.
local K = require("core.const")
local Snd = require("core.sound")
local Deco = require("core.deco")
local K2 = {}
local BLACKKEY = {[0] = true, [1] = true, [3] = true, [4] = true, [5] = true} -- the columns (c % 7) that carry a raised black key (core/tiles.lua)
local pk = {}

local SCALE = {"C", "D", "E", "G", "A"}
local active, n = {}, 0
local last = -1

function K2.clear() active, n, last = {}, 0, -1 end

function K2.note_of(c) return SCALE[c % 5 + 1] .. (3 + math.min(3, c // 60)) end

-- called every tick with the hero's state: a new key under his soles is a new note
function K2.track(s)
  if s.ground and s.gchar == "P" then
    local c = math.floor(s.x / 32)
    if c ~= last then
      last = c
      n = n + 1
      local k = active[n]
      if not k then k = {} active[n] = k end
      k.c, k.t = c, 16
      tone(2, K2.note_of(c), {wave = "triangle", vol = 0.28, attack = 0.004, decay = 0.4, sustain = 0})
      K2.pressed = c
    end
  elseif not s.ground then
    last = -1
  end
end

function K2.update()
  local i = 1
  while i <= n do
    local k = active[i]
    k.t = k.t - 1
    if k.t <= 0 then active[i], active[n] = active[n], k n = n - 1 else i = i + 1 end
  end
end

function K2.draw()
  for i = 1, n do
    local k = active[i]
    local d = math.min(5, k.t // 2 + 1)
    if BLACKKEY[k.c % 7] and Deco.has("KT_FLOORKEY") then -- the key with its black key sunk, instead of the darker band
      Deco.img("KT_FLOORKEY", 1, k.c * 32, K.FLOOR * 32 + 0, pk)
    else
      rect(k.c * 32 + 1, K.FLOOR * 32, 30, d, 0x3A2A5A)
    end
  end
end

return K2
