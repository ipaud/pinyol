-- sound: the effects, made from numbers when the game starts (`sound`). `Snd.play("jump")` is all a module needs.
local S = {}

local DEFS = {
  jump = {wave = "square", duty = 0.25, freq = 330, slide = 1100, sustain = 0.03, decay = 0.1, volume = 0.2},
  land = {wave = "noise", freq = 220, sustain = 0.01, decay = 0.06, lowpass = 0.25, volume = 0.4},
  step = {wave = "noise", freq = 500, sustain = 0.0, decay = 0.025, lowpass = 0.3, volume = 0.12},
  skid = {wave = "noise", freq = 2400, sustain = 0.03, decay = 0.1, highpass = 0.5, lowpass = 0.8, volume = 0.1},
  coin = {wave = "square", freq = 1046, arp = 1.335, arp_time = 0.06, duty = 0.5, sustain = 0.05, decay = 0.2, volume = 0.26},
  cream = {wave = "square", freq = 523, arp = 1.5, arp_time = 0.06, duty = 0.25, sustain = 0.12, decay = 0.35, volume = 0.3},
  stomp = {wave = "fm", freq = 420, fm_ratio = 2.2, fm_index = 2, slide = -600, sustain = 0.02, decay = 0.12, volume = 0.35},
  hurt = {wave = "saw", freq = 420, slide = -700, sustain = 0.05, decay = 0.2, lowpass = 0.6, volume = 0.35},
  die = {wave = "saw", freq = 500, slide = -420, sustain = 0.15, decay = 0.4, lowpass = 0.5, volume = 0.38},
  spring = {wave = "square", duty = 0.5, freq = 200, slide = 2200, sustain = 0.08, decay = 0.2, volume = 0.26},
  bump = {wave = "noise", freq = 160, slide = -80, sustain = 0.02, decay = 0.12, lowpass = 0.2, volume = 0.45},
  scooter = {wave = "square", duty = 0.125, freq = 660, arp = 1.5, arp_time = 0.05, sustain = 0.2, decay = 0.3, volume = 0.24},
  ramp = {wave = "triangle", freq = 300, slide = 1500, sustain = 0.06, decay = 0.25, volume = 0.28},
  win = {wave = "square", freq = 523, arp = 1.5, arp_time = 0.12, duty = 0.25, sustain = 0.3, decay = 0.5, volume = 0.3},
  select = {wave = "square", freq = 1320, duty = 0.125, sustain = 0.01, decay = 0.04, volume = 0.26},
  confirm = {wave = "square", freq = 880, arp = 1.5, arp_time = 0.05, duty = 0.25, sustain = 0.04, decay = 0.12, volume = 0.24},
  wind = {wave = "square", duty = 0.125, freq = 1800, slide = 2500, sustain = 0.0, decay = 0.03, volume = 0.1},
  dash = {wave = "noise", freq = 1500, slide = -1000, attack = 0.02, sustain = 0.05, decay = 0.12, highpass = 0.3, lowpass = 0.7, volume = 0.25},
  fire = {wave = "noise", freq = 900, sustain = 0.25, decay = 0.2, highpass = 0.2, lowpass = 0.6, volume = 0.22},
  pound = {wave = "noise", freq = 140, slide = -80, sustain = 0.05, decay = 0.35, lowpass = 0.3, volume = 0.5},
  splash = {wave = "noise", freq = 2600, slide = -1400, sustain = 0.04, decay = 0.2, highpass = 0.4, lowpass = 0.9, volume = 0.22},
  crate = {wave = "noise", freq = 700, slide = -400, sustain = 0.03, decay = 0.18, lowpass = 0.5, volume = 0.4},
  dress = {wave = "square", freq = 660, arp = 1.5, arp_time = 0.05, duty = 0.25, sustain = 0.1, decay = 0.3, volume = 0.28},
  boing = {wave = "sine", freq = 220, slide = 700, sustain = 0.02, decay = 0.2, volume = 0.3},
}

function S.init()
  for name, d in pairs(DEFS) do sound("SFX_" .. name:upper(), d) end
end

function S.play(name, gain, opts)
  if not DEFS[name] then return end
  return sfx("SFX_" .. name:upper(), gain, opts)
end

-- the toy keyboard's notes: voice 3, a note each time (`Snd.note("E5")`)
function S.note(n, vol)
  tone(3, n, {wave = "fm", fm_ratio = 2, fm_index = 1.2, vol = vol or 0.4, attack = 0.004, decay = 0.35, sustain = 0})
end

return S
