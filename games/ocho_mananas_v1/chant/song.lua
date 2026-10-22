-- The guide melody of the three calls. PROVISIONAL: the first line of the chant ("A San Fermín pedimos") as an
-- automatic pitch tracker heard it in a crowd recording (YouTube hUMifd5xwb0, 1.7-4.4 s; see
-- output/canto_referencias/). It is a crowd singing with drifting pitch, so the notes are the tracker's best guess
-- and the rhythm is the game's chart, not the singers'. Cross-checked against three other crowd recordings
-- (xP9kX_kzbcM, bJZmIe1qJts an octave up, Y2JU9UyVkvs): all hover around B3 with A#3, A3 and G#3 beside it, but
-- which neighbour each syllable takes is uncertain by a semitone. Not confirmed by ear. Replace NOTES with a verified
-- transcription (and its source) when there is one.
local M = {}
local CHART = require("chant.chart")

-- one note for each tap; the three calls use the same melody (a call just plays more of it)
M.NOTES = {"B3", "B3", "A#3", "G#3", "A3", "G#3"}

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
    -- an unpitched tick keeps the tempo without suggesting a key the melody has not been checked against
    tone(3, 220, {wave = "noise", vol = beat % 4 == 0 and 0.07 or 0.04, decay = 0.03})
  end

  local next_note = M.played + 1
  if next_note <= count and phase_tick >= CHART.onset_tick(next_note, phase, day) then
    tone(2, M.NOTES[((next_note - 1) % #M.NOTES) + 1], {wave = "triangle", vol = 0.32, decay = 0.3})
    M.played = next_note
  end
end

function M.stop()
  tone(2)
  tone(3)
end

return M
