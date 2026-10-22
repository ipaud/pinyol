-- A playable guide chart for the three calls before the encierro.
-- Its clock is deliberately independent from the official recording, which is not bundled.
local M = {}

M.BPM = 112
M.TICKS_PER_MINUTE = 60 * 60
M.LEAD_IN_BEATS = 1.375

-- Distances between taps, in beats. The three calls grow more active in turn.
M.SPACING = {1.75, 1.5, 1.25}

local function frame_at(beat)
  return math.floor(beat * M.TICKS_PER_MINUTE / M.BPM + 0.5)
end

function M.beat_at_tick(tick)
  return math.floor(tick * M.BPM / M.TICKS_PER_MINUTE)
end

function M.onset_tick(index, phase, day)
  local spacing = M.SPACING[phase]
  -- The tempo stays fixed; later mornings compress the phrase slightly and
  -- tighten the judgement window, rather than making the backing pulse race.
  local compression = 1 - math.max(0, day - 1) * 0.022
  local beat = M.LEAD_IN_BEATS + (index - 1) * spacing * compression

  -- From morning three, some arrivals lean into the offbeat. The chart keeps
  -- the same number of notes; it asks for better listening and anticipation.
  if day >= 3 and index > 1 and index % 2 == 0 then
    beat = beat + (day >= 7 and 0.25 or 0.125)
  end
  return frame_at(beat)
end

return M
