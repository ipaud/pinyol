-- tunes: the cabinet's sound, made by code. Its music is a sound chip's three voices as a 1985 board had them (two
-- squares and a noise, here a square, a triangle and a noise): a village band's pasacalle for the climb, a tune in
-- A minor for the moon, a fanfare for the palmera. Notes are played from _update on a step counter (docs/lua.md, "A
-- tune is notes played from _update on a beat"). The effects are sounds made from numbers.
local M = {}

local SONGS = {
  fiesta = {step = 8, loop = true,
    mel = "G4 C5 E5 G5 E5 - C5 . D5 F5 A5 G5 F5 E5 D5 . E5 G5 C6 B5 A5 G5 F5 E5 D5 E5 F5 D5 C5 - - . " ..
          "E5 E5 F5 G5 A5 - G5 . F5 F5 E5 D5 E5 - C5 . A4 C5 F5 A5 G5 E5 C5 E5 D5 B4 G4 B4 C5 - - .",
    bass = "C3 . G2 . C3 . G2 . F2 . C3 . G2 . D3 . C3 . G2 . F2 . A2 . G2 . D3 . C3 . G2 . " ..
           "C3 . G2 . F2 . C3 . D3 . A2 . C3 . G2 . F2 . C3 . C3 . G2 . G2 . D3 . C3 . C3 .",
    drum = string.rep("k h s h ", 16)},
  boss = {step = 6, loop = true,
    mel = "A4 C5 E5 A5 G5 E5 C5 E5 F5 E5 D5 C5 B4 C5 D5 E5 A4 C5 E5 A5 B5 A5 G5 E5 F5 D5 B4 G#4 A4 - - .",
    bass = "A2 A3 A2 A3 C3 C4 C3 C4 F2 F3 F2 F3 G2 G3 G2 G3 A2 A3 A2 A3 E2 E3 E2 E3 D3 D4 E2 E3 A2 . A2 .",
    drum = string.rep("k h s h k k s h ", 4)},
  final = {step = 7, loop = false,
    mel = "C5 E5 G5 C6 - - E6 - D6 - C6 - - - - .",
    bass = "C3 . . . G2 . . . C3 . G2 . C3 . . .",
    drum = "k . . . s . . . k . s . k . . ."},
  over = {step = 9, loop = false,
    mel = "G4 F4 E4 D4 C4 - - .", bass = "C3 . G2 . C2 - - .", drum = "k . . . k . . ."},
}

local function split(s)
  local t = {}
  for w in s:gmatch("%S+") do t[#t + 1] = w end
  return t
end

for _, s in pairs(SONGS) do s.mel, s.bass, s.drum = split(s.mel), split(s.bass), split(s.drum) end

local song, pos, tick = nil, 0, 0
M.name = nil

function M.init()
  sound("SFX_SHOT", {wave = "square", freq = 1500, slide = -4000, sustain = 0.0, decay = 0.03, volume = 0.06, duty = 0.25})
  sound("SFX_POP", {wave = "noise", freq = 600, slide = -700, sustain = 0.02, decay = 0.16, volume = 0.28})
  sound("SFX_BANG", {wave = "noise", freq = 1200, slide = -2000, sustain = 0.01, decay = 0.09, volume = 0.4, punch = 0.6})
  sound("SFX_TRO", {wave = "noise", freq = 300, slide = -200, sustain = 0.12, decay = 0.6, volume = 0.5, punch = 0.8, lowpass = 0.5})
  sound("SFX_HIT", {wave = "saw", freq = 620, slide = -900, sustain = 0.12, decay = 0.4, volume = 0.35})
  sound("SFX_SHIELD", {wave = "square", freq = 900, slide = -1200, sustain = 0.06, decay = 0.2, volume = 0.2, vibrato = 0.4, vibrato_speed = 30})
  sound("SFX_PICK", {wave = "square", freq = 520, arp = 1.5, arp_time = 0.06, sustain = 0.08, decay = 0.2, volume = 0.2})
  sound("SFX_BLIP", {wave = "square", freq = 1100, sustain = 0.0, decay = 0.04, volume = 0.1})
  sound("SFX_DING", {wave = "fm", freq = 660, fm_ratio = 3.5, fm_index = 1.6, sustain = 0.05, decay = 1.2, volume = 0.3})
  sound("SFX_DONG", {wave = "fm", freq = 330, fm_ratio = 3.5, fm_index = 1.0, sustain = 0.05, decay = 0.8, volume = 0.22, lowpass = 0.4})
  sound("SFX_BOING", {wave = "sine", freq = 180, slide = 700, sustain = 0.1, decay = 0.4, volume = 0.35, vibrato = 0.5, vibrato_speed = 12})
  sound("SFX_WHISTLE", {wave = "sine", freq = 700, slide = 1400, sustain = 0.9, decay = 0.2, volume = 0.22, vibrato = 0.2, vibrato_speed = 18})
  sound("SFX_CLEAR", {wave = "square", freq = 440, arp = 2, arp_time = 0.1, sustain = 0.2, decay = 0.4, volume = 0.2})
  sound("SFX_START", {wave = "square", freq = 330, arp = 1.5, arp_time = 0.08, sustain = 0.15, decay = 0.35, volume = 0.22})
  sound("SFX_TOAST", {wave = "square", freq = 660, arp = 1.5, arp_time = 0.07, sustain = 0.06, decay = 0.2, volume = 0.14})
end

local last = {}
function M.sfx(id, gain) -- never twice in the same tick (a traca pops a dozen foes at once)
  local now = ticks()
  if last[id] == now then return end
  last[id] = now
  sfx(id, gain)
end

function M.play(name) -- a song from its start; nil: silence
  if name == M.name and name and SONGS[name].loop then return end
  M.name, song, pos, tick = name, name and SONGS[name], 0, 0
  for v = 0, 2 do tone(v) end
end

local function held(list, i) -- how many steps a note lasts: itself and the "-" after it
  local n = 1
  while list[i + n] == "-" do n = n + 1 end
  return n
end

local function play_step(i)
  local s = song
  local secs = s.step / 60
  local m = s.mel[i]
  if m == "." then tone(0) elseif m ~= "-" then
    tone(0, m, {wave = "square", duty = 0.25, vol = 0.16, decay = 0.2, sustain = 0.55, len = held(s.mel, i) * secs * 0.9, release = 0.04})
  end
  local b = s.bass[i]
  if b and b ~= "." and b ~= "-" then tone(1, b, {wave = "triangle", vol = 0.34, decay = 0.14, sustain = 0.2, len = secs * 0.8}) end
  local d = s.drum[(i - 1) % #s.drum + 1]
  if d == "k" then tone(2, 80, {wave = "noise", vol = 0.3, decay = 0.07})
  elseif d == "s" then tone(2, 1800, {wave = "noise", vol = 0.16, decay = 0.09})
  elseif d == "h" then tone(2, 7000, {wave = "noise", lfsr = 7, vol = 0.05, decay = 0.025}) end
end

function M.update()
  if not song then return end
  tick = tick + 1
  if tick < song.step then return end
  tick = 0
  pos = pos + 1
  if pos > #song.mel then
    if not song.loop then M.name, song = nil, nil return end
    pos = 1
  end
  play_step(pos)
end

return M
