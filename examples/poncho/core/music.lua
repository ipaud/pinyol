-- music: a little tune made of notes (`tone`), two voices: a bouncy square melody and a triangle bass, 124 beats a minute, eight bars round and round.
-- The toy keyboard's own notes use voice 3; this leaves it alone.
local M = {}

local STEP = 7 -- ticks to a sixteenth
local MEL = { -- two bars each line, 16 steps a bar; 0 a rest
  "E5 0 G5 0 A5 G5 E5 0 D5 0 E5 0 C5 0 0 0", "E5 0 G5 0 A5 G5 E5 0 G5 0 A5 0 B5 0 0 0",
  "A5 0 G5 0 E5 D5 C5 0 D5 0 E5 0 G5 0 0 0", "E5 G5 A5 0 C6 A5 G5 0 E5 0 D5 0 C5 0 0 0",
}
local BASS = {"C3 0 0 0 G3 0 0 0 C3 0 0 0 G3 0 0 0", "A2 0 0 0 E3 0 0 0 A2 0 0 0 E3 0 0 0", "F2 0 0 0 C3 0 0 0 F2 0 0 0 C3 0 0 0", "G2 0 0 0 D3 0 0 0 G2 0 0 0 D3 0 0 0"}

local function parse(lines)
  local out = {}
  for _, l in ipairs(lines) do
    for n in l:gmatch("%S+") do out[#out + 1] = n end
  end
  return out
end
local mel, bass = parse(MEL), parse(BASS)

M.on, M.t, M.step = false, 0, 0

function M.start() M.on, M.t, M.step = true, 0, 0 end
function M.stop() if M.on then tone(0) tone(1) end M.on = false end

function M.update()
  if not M.on then return end
  M.t = M.t + 1
  if M.t % STEP ~= 1 then return end
  local i = M.step % #mel + 1
  M.step = M.step + 1
  local m, b = mel[i], bass[i % #bass + 1]
  if m ~= "0" then tone(0, m, {wave = "square", duty = 0.25, vol = 0.12, decay = 0.16, sustain = 0}) end
  if b ~= "0" then tone(1, b, {wave = "triangle", vol = 0.3, decay = 0.3, sustain = 0}) end
end

return M
