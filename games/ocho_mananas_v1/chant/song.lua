-- Original instrumental guide melody for the rhythm prototype.
-- It is not a transcription of the official San Fermín chant.
local M = {}
local CHART = require("chant.chart")

local PHRASES = {
  {"D4", "F#4", "A4", "G4", "F#4", "E4", "D4", "A3"},
  {"F#4", "G4", "A4", "B4", "A4", "G4", "F#4", "D4"},
  {"A4", "B4", "D5", "C#5", "B4", "A4", "G4", "D5"},
}

function M.start()
  M.played = 0
  M.last_beat = -1
end

function M.update(phase_tick, phase, day, count)
  if phase_tick <= 0 then return end
  if M.played == nil or M.last_beat == nil then M.start() end

  local beat = CHART.beat_at_tick(phase_tick)
  if beat > M.last_beat then
    M.last_beat = beat
    -- A quiet original bass pulse gives the player a steady reference tempo.
    tone(3, beat % 4 == 0 and "D3" or "A3", {
      wave = "sine", vol = beat % 4 == 0 and 0.12 or 0.075, decay = 0.07
    })
  end

  local next_note = M.played + 1
  if next_note <= count and phase_tick >= CHART.onset_tick(next_note, phase, day) then
    local phrase = PHRASES[phase]
    local pitch = phrase[((next_note - 1) % #phrase) + 1]
    tone(2, pitch, {wave = "triangle", vol = 0.32, decay = 0.24})
    M.played = next_note
  end
end

function M.stop()
  tone(2)
  tone(3)
end

return M
