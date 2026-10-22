-- The guide melody of the three calls, sung by a small crowd: Pau's own MIDI of the chant
-- (san_fermin_16bit_v2_agudo.mid, kept in output/canto_referencias/pau/), 17 notes in four phrases, pitches and
-- timings as he wrote them (chant/chart.lua has the timings). Earlier guesses from crowd recordings and from his
-- singing are dropped.
--
-- The crowd sings in unison with the octaves as a mixed crowd does (women up, men down), each voice a little out of
-- tune and wobbling on its own, so it chorus-es; the three calls grow: the first is a few voices, the second adds
-- the octave above, the third the whole square. The four synth voices are all the chant's (the hits use sfx).
local M = {}
local CHART = require("chant.chart")

-- one note for each tap; the three calls use the same melody (a call just plays more of it)
-- one note each, as in the MIDI
M.NOTES = {"A4", "C#5", "D#5", "C#5", "A#4", "B4", "E5", "C#5", "A#4", "C5", "C#5", "D#5", "C#5", "A#4", "B4", "C#5", "A4"}

local SEMI = {C = 0, D = 2, E = 4, F = 5, G = 7, A = 9, B = 11}
local function hz(name)
  local n, acc, oct = name:match("^(%a)([#b]?)(%d)$")
  local midi = 12 * (tonumber(oct) + 1) + SEMI[n] + (acc == "#" and 1 or acc == "b" and -1 or 0)
  return 440 * 2 ^ ((midi - 69) / 12)
end

-- voice 2: the tune; 0: the octave above, 1: the octave below; each: pitch factor, wave, volume, vibrato speed
local CHOIR = {
  {voice = 2, mul = 1.000, wave = "triangle", vol = 0.30, vib = 5.2, from = 1},
  {voice = 0, mul = 2.006, wave = "sine",     vol = 0.18, vib = 6.1, from = 2},
  {voice = 1, mul = 0.4985, wave = "triangle", vol = 0.20, vib = 4.6, from = 3},
}

function M.start()
  M.played = 0
    M.crowd = sfx("CROWD", 0.07, {loop = true})
end

function M.update(phase_tick, phase, day, count)
  if phase_tick <= 0 then return end
  if M.played == nil then M.start() end

  local k = M.played + 1
  if k <= count and phase_tick >= CHART.onset_tick(k, phase, day) then
    local f = hz(M.NOTES[((k - 1) % #M.NOTES) + 1])
    local here = CHART.onset_tick(k, phase, day)
    local nxt = k < count and CHART.onset_tick(k + 1, phase, day) or here + CHART.LAST * 60
    local len = (nxt - here) / 60 * 1.02  -- sung: each note runs into the next
    for _, v in ipairs(CHOIR) do
      if phase >= v.from then
        tone(v.voice, f * v.mul, {wave = v.wave, vol = v.vol * (k == count and 1.15 or 1), attack = 0.05, sustain = 0.8,
                                  decay = 0.2, len = len, release = 0.15,
                                  vibrato = {depth = 22, speed = v.vib, delay = 0.12}})
      end
    end
    M.played = k
  end
end

function M.stop()
  for v = 0, 3 do tone(v) end
  if M.crowd then sfx_stop(M.crowd); M.crowd = nil end
end

return M
