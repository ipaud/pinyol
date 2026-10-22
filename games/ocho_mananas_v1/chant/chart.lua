-- The chart of the calls, from Pau's MIDI of the chant (san_fermin_16bit_v2_agudo.mid, kept in
-- output/canto_referencias/pau/): the whole chant, 17 notes in four phrases, at the times and pitches he wrote.
-- Every call sings all of it. What changes is what the player has to touch: the first calls ask for the notes that
-- carry the phrase, the later ones for more and more of them, and for gestures on the long notes. There is no
-- metronome: the chant has none.
local M = {}

M.ONSETS = {0, 0.54, 1.08, 1.31, 2.24, 2.80, 3.35, 3.58, 4.56, 4.78, 5.34, 5.62, 5.86, 6.98, 7.31, 7.83, 8.00}
M.PITCH = {69, 73, 75, 73, 70, 71, 76, 73, 70, 72, 73, 75, 73, 70, 71, 73, 69}   -- midi numbers
M.N = #M.ONSETS
M.LAST = 1.5          -- how long the last note rings
M.LEAD_IN = 0.8       -- seconds of calm before the first note
M.PHRASES = {{1, 4}, {5, 8}, {9, 13}, {14, 17}}
M.LYRICS = {"A San Fermín pedimos,", "por ser nuestro patrón,", "nos guíe en el encierro,", "dándonos su bendición."}

-- the order the notes are asked for: phrase starts and ends first, then the ones between
local PRIORITY = {1, 5, 9, 14, 4, 8, 13, 17, 3, 7, 11, 15, 2, 6, 10, 12, 16}

local function ticks(sec) return math.floor(sec * 60 + 0.5) end

-- how hard a call is, 0 to 1: three calls a morning, eight mornings
function M.level(day, phase)
  return ((day - 1) * 3 + (phase - 1)) / 23
end

function M.due(n, day)
  -- later mornings compress the phrase a little, rather than speeding the melody up
  local t = M.ONSETS[n] * (1 - math.max(0, day - 1) * 0.015)
  return ticks(M.LEAD_IN + t)
end

function M.span(n, day)  -- how long note n lasts, in ticks
  if n < M.N then return M.due(n + 1, day) - M.due(n, day) end
  return ticks(M.LAST)
end

function M.last_tick(day) return M.due(M.N, day) + ticks(M.LAST) end

-- The notes to touch in a call: [{n = note, due = tick, span = ticks, kind = "tap" | "slide" | "reverse" | "spin"}]
function M.targets(day, phase)
  local L = M.level(day, phase)
  local count = math.floor(5 + L * 12 + 0.5)
  local chosen = {}
  for i = 1, count do chosen[PRIORITY[i]] = true end
  local kind = {}
  if L >= 0.22 then kind[4] = "slide" end
  if L >= 0.40 then kind[8] = "slide" end
  if L >= 0.50 then kind[13] = "reverse" end
  if L >= 0.62 then kind[8] = "reverse" end
  if L >= 0.74 then kind[17] = "spin" end
  local out = {}
  for n = 1, M.N do
    if chosen[n] then
      out[#out + 1] = {n = n, due = M.due(n, day), span = M.span(n, day), kind = kind[n] or "tap"}
    end
  end
  for i, t in ipairs(out) do t.combo = i end  -- the number on a circle is its order in the call, 1 to 17, never repeated
  for i, t in ipairs(out) do  -- a hit window must not reach the next target
    local prev = out[i - 1] and t.due - out[i - 1].due or 999
    local nxt = out[i + 1] and out[i + 1].due - t.due or 999
    t.gap = math.min(prev, nxt)
  end
  return out
end

-- hit window in ticks, wide in the easy calls
function M.window(day, phase, t)
  local w = math.floor(14 - M.level(day, phase) * 8 + 0.5)
  return math.max(4, math.min(w, t.gap // 2 - 1))
end

return M
