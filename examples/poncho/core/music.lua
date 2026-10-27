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
-- the market's tune: a swung march in D, a little faster
local MEL2 = {"D5 0 F5 A5 0 F5 D5 0 E5 0 G5 0 A5 0 0 0", "D5 0 F5 A5 0 F5 A5 0 C6 0 A5 0 G5 0 0 0",
              "Bb5 0 A5 0 F5 D5 F5 0 E5 0 D5 0 C5 0 0 0", "D5 F5 A5 0 D6 A5 F5 0 E5 0 C5 0 D5 0 0 0"}
local BASS2 = {"D3 0 A2 0 D3 0 A2 0 D3 0 A2 0 D3 0 A2 0", "Bb2 0 F3 0 Bb2 0 F3 0 C3 0 G3 0 C3 0 G3 0",
               "G2 0 D3 0 G2 0 D3 0 A2 0 E3 0 A2 0 E3 0", "D3 0 A2 0 D3 0 A2 0 D3 0 A2 0 D3 0 A2 0"}
-- the chalk park's tune: a skipping rope rhythm in G
local MEL3 = {"G5 0 B5 0 D6 0 B5 G5 A5 0 C6 0 E6 0 C6 A5", "G5 0 B5 0 D6 B5 G5 0 F#5 0 A5 0 D6 0 0 0",
              "E5 0 G5 0 B5 0 G5 E5 F#5 0 A5 0 C6 0 A5 0", "D6 0 B5 G5 A5 0 F#5 0 G5 0 0 0 G5 B5 D6 0"}
local BASS3 = {"G2 0 D3 0 G2 0 D3 0 A2 0 E3 0 A2 0 E3 0", "G2 0 D3 0 G2 0 D3 0 D3 0 A2 0 D3 0 A2 0",
               "E2 0 B2 0 E2 0 B2 0 F#2 0 C#3 0 F#2 0 C#3 0", "D3 0 A2 0 D3 0 A2 0 G2 0 D3 0 G2 0 D3 0"}
-- the stage's tune: a slow groove in A minor, one note on every second step (steps of 7.5 ticks make a beat of 30)
local MEL4 = {"A5 0 0 C6 0 0 E6 0 A5 0 0 C6 0 0 B5 0", "G5 0 0 B5 0 0 D6 0 G5 0 0 B5 0 0 A5 0",
              "F5 0 0 A5 0 0 C6 0 F5 0 0 A5 0 0 G5 0", "E5 0 0 G5 0 0 B5 0 E6 0 0 D6 0 0 C6 0"}
local BASS4 = {"A2 0 0 0 A2 0 0 0 E3 0 0 0 E3 0 0 0", "G2 0 0 0 G2 0 0 0 D3 0 0 0 D3 0 0 0", "F2 0 0 0 F2 0 0 0 C3 0 0 0 C3 0 0 0", "E2 0 0 0 E2 0 0 0 B2 0 0 0 B2 0 0 0"}
local TUNES = {playroom = {parse(MEL), parse(BASS), 7}, market = {parse(MEL2), parse(BASS2), 6}, chalk = {parse(MEL3), parse(BASS3), 6}, stage = {parse(MEL4), parse(BASS4), 8}}
local mel, bass = TUNES.playroom[1], TUNES.playroom[2]

M.on, M.t, M.step = false, 0, 0

function M.start(id)
  local t = TUNES[id or "playroom"] or TUNES.playroom
  mel, bass, STEP = t[1], t[2], t[3]
  M.on, M.t, M.step = true, 0, 0
end
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
