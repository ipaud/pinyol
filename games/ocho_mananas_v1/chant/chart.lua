-- The chart of the three calls, from Pau's MIDI of the chant (san_fermin_16bit_v2_agudo.mid, in output/canto_referencias/pau/):
-- the onset of each note in seconds from the first one. There is no metronome: the chant has none. Later mornings
-- compress the phrase a little and narrow the hit window, rather than speeding the melody up.
local M = {}

M.TICKS_PER_MINUTE = 60 * 60
M.BPM = 112          -- only the beat counter below uses it (kept for the callers that ask for one)
M.LEAD_IN = 0.8      -- seconds of calm before the first syllable

-- 17 notes in four phrases of 4, 4, 5 and 4 (the MIDI at 158 bpm, as written)
M.ONSETS = {0, 0.54, 1.08, 1.31, 2.24, 2.80, 3.35, 3.58, 4.56, 4.78, 5.34, 5.62, 5.86, 6.98, 7.31, 7.83, 8.00}
M.LAST = 0.76        -- how long the last note of a call rings

local function frame_at(sec)
  return math.floor(sec * 60 + 0.5)
end

function M.beat_at_tick(tick)
  return math.floor(tick * M.BPM / M.TICKS_PER_MINUTE)
end

local function onset_s(index, phase, day)
  local n = #M.ONSETS
  local round = (index - 1) // n
  local t = M.ONSETS[(index - 1) % n + 1] + round * (M.ONSETS[n] + 0.6)
  local compression = 1 - math.max(0, day - 1) * 0.022
  t = t * compression
  -- From morning three, some arrivals lean a little late: it asks for listening, the note count is the same.
  if day >= 3 and index > 1 and index % 2 == 0 then t = t + (day >= 7 and 0.07 or 0.035) end
  return M.LEAD_IN + t
end

function M.onset_tick(index, phase, day)
  return frame_at(onset_s(index, phase, day))
end

-- ticks to the nearest neighbouring syllable (a hit window wider than half of it would swallow the next one)
function M.gap(index, phase, day)
  local here = M.onset_tick(index, phase, day)
  local prev = index > 1 and here - M.onset_tick(index - 1, phase, day) or 999
  return math.min(prev, M.onset_tick(index + 1, phase, day) - here)
end

return M
