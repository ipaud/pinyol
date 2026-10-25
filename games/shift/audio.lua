-- One tune, four sound chips. Step and phrase survive era changes.
local Audio = {step = 0, era = 3, shift_t = 0}
local tune = {"C4", "G4", "D5", "G4", "E4", "A4", "D5", "A4", "F4", "C5", "E5", "C5", "G4", "D5", "F5", "D5"}
function Audio.init()
  sound("SHIFT", "powerup", 21)
  sound("JUMP", "jump", 8)
  sound("HIT", "hit", 12)
  sound("NODE", "coin", 4)
end
function Audio.shift(from, to)
  Audio.era, Audio.shift_t = to, 12
  local waves = {[1] = "square", [2] = "square", [3] = "triangle", [4] = "saw"}
  sfx("SHIFT", 0.55, {pitch = from == to and 1 or (to > from and 1.08 or 0.92)})
  tone(3, "C3", {wave = waves[to], slide = 1000, decay = 0.16, volume = 0.12})
end
function Audio.tick(era, playing)
  if Audio.shift_t > 0 then Audio.shift_t = Audio.shift_t - 1 end
  if not playing then return end
  Audio.step = Audio.step + 1
  if Audio.step % 18 ~= 0 then return end
  local note = tune[(Audio.step // 18 - 1) % #tune + 1]
  local wave = era == 3 and "triangle" or (era == 4 and "saw" or "square")
  tone(0, note, {wave = wave, duty = era == 2 and 0.25 or 0.5, decay = era == 4 and 0.2 or 0.12,
                 volume = era == 3 and 0.17 or 0.12})
  if era == 4 and Audio.step % 36 == 0 then tone(2, 130, {wave = "noise", decay = 0.07, volume = 0.12}) end
end
return Audio
