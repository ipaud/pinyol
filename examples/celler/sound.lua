-- sound: the cellar as a 1992 PC sounded with a Sound Blaster in it: the music on the FM chip (AdLib's two operators:
-- a sine bent by another), the effects made from numbers (docs/lua.md, "Sounds made from numbers"). No files.
local M = {}

M.on = true -- the music; the sounds always

function M.init()
  sound("SFX_POP", {wave = "noise", freq = 700, slide = -900, sustain = 0.01, decay = 0.09, volume = 0.42, lowpass = 0.55})
  sound("SFX_THUD", {wave = "triangle", freq = 180, slide = -300, sustain = 0.01, decay = 0.08, volume = 0.3})
  sound("SFX_CLICK", {wave = "square", freq = 1400, sustain = 0, decay = 0.02, volume = 0.12, duty = 0.125})
  sound("SFX_BUBBLES", {wave = "sine", freq = 500, slide = 2200, vibrato = 0.7, vibrato_speed = 30, sustain = 0.08, decay = 0.3, volume = 0.3})
  sound("SFX_BLOW", {wave = "noise", freq = 300, sustain = 0.25, decay = 0.35, volume = 0.38, lowpass = 0.25, lowpass_sweep = -0.3})
  sound("SFX_KEY", {wave = "square", freq = 988, arp = 1.335, arp_time = 0.07, sustain = 0.1, decay = 0.3, volume = 0.22, duty = 0.25})
  sound("SFX_CANDLE", {wave = "sine", freq = 660, arp = 1.5, arp_time = 0.08, sustain = 0.12, decay = 0.35, volume = 0.25})
  sound("SFX_BOTTLE", {wave = "fm", freq = 1320, fm_ratio = 3.5, fm_index = 1.2, sustain = 0.02, decay = 0.4, volume = 0.3})
  sound("SFX_DOOR", {wave = "noise", freq = 160, sustain = 0.35, decay = 0.2, volume = 0.22, lowpass = 0.18})
  sound("SFX_GATE", {wave = "saw", freq = 90, slide = 40, vibrato = 0.4, vibrato_speed = 22, sustain = 0.45, decay = 0.2, volume = 0.2, lowpass = 0.4})
  sound("SFX_LEVER", {wave = "square", freq = 220, arp = 0.5, arp_time = 0.05, sustain = 0.05, decay = 0.15, volume = 0.28, lowpass = 0.5})
  sound("SFX_LOCKED", {wave = "square", freq = 160, sustain = 0.06, decay = 0.1, volume = 0.2, again = 0.12})
  sound("SFX_MATCH", {wave = "noise", freq = 2400, slide = -1800, sustain = 0.12, decay = 0.4, volume = 0.3, highpass = 0.3})
  sound("SFX_STAIRS", {wave = "triangle", freq = 330, arp = 0.75, arp_time = 0.12, sustain = 0.3, decay = 0.4, volume = 0.3, again = 0.24})
  sound("SFX_OUT", {wave = "triangle", freq = 110, sustain = 0.6, decay = 1.2, volume = 0.3, slide = -40})
  sound("SFX_SECRET", {wave = "noise", freq = 90, sustain = 0.7, decay = 0.3, volume = 0.26, lowpass = 0.12})
  sound("SFX_BLIP", {wave = "fm", freq = 520, fm_ratio = 2, fm_index = 0.6, sustain = 0, decay = 0.05, volume = 0.16})
  sound("SFX_TOAST", {wave = "fm", freq = 784, fm_ratio = 3, fm_index = 0.8, arp = 1.5, arp_time = 0.08, sustain = 0.05, decay = 0.3, volume = 0.18})
end

local last = {}
function M.play(id, gain, opts) -- a sound, never twice in the same tick
  local now = ticks()
  if last[id] == now then return end
  last[id] = now
  sfx(id, gain, opts)
end

-- The tune: a slow habanera in A minor, the kind a cellar's radio played, on three FM voices. A step is a sixteenth;
-- each bar two beats of a habanera bass (dotted eighth, sixteenth, two eighths).
local BPM = 84
local BASS = {"A2", "E2", "D2", "E2", "A2", "C3", "E2", "A2", "F2", "C3", "G2", "D3", "A2", "E2", "E2", "A2"}
local TUNE = { -- a note per eighth (0: rest)
  "E4", 0, "A4", "C5", "B4", "A4", "G#4", 0, "A4", 0, "C5", "E5", "D5", "C5", "B4", 0,
  "F4", "A4", "C5", "A4", "G4", "B4", "D5", "B4", "C5", "B4", "A4", "G#4", "A4", 0, 0, 0,
}
local CHORD = {"C4", "B3", "A3", "B3", "C4", "E4", "B3", "C4", "A3", "E4", "B3", "F4", "C4", "B3", "B3", "C4"}
local step, next_at, quiet = 0, 0, false

function M.music(on, soft)
  M.on, quiet = on, soft or false
  if not on then tone(0) tone(1) tone(2) end
end

function M.update()
  if not M.on then return end
  local now = ticks()
  if now < next_at then return end
  next_at = now + 3600 / BPM / 4 -- ticks a sixteenth
  local bar = (step // 8) % #BASS + 1
  local s8 = step % 8
  local v = quiet and 0.45 or 1
  if s8 == 0 or s8 == 3 or s8 == 4 or s8 == 6 then -- the habanera's rhythm
    tone(0, BASS[bar], {wave = "fm", fm_ratio = 1, fm_index = 0.9, vol = 0.32 * v, decay = 0.18, sustain = 0.2, len = 0.16})
  end
  if s8 == 0 or s8 == 4 then
    tone(2, CHORD[bar], {wave = "fm", fm_ratio = 2, fm_index = 0.4, vol = 0.1 * v, attack = 0.03, decay = 0.4, sustain = 0.4, len = 0.3})
  end
  if step % 2 == 0 then
    local n = TUNE[(step // 2) % #TUNE + 1]
    if n ~= 0 then
      tone(1, n, {wave = "fm", fm_ratio = 3, fm_index = 0.7, vol = 0.2 * v, decay = 0.25, sustain = 0.25, len = 0.2,
                  vibrato = {depth = 12, speed = 5, delay = 0.12}})
    end
  end
  step = step + 1
end

return M
