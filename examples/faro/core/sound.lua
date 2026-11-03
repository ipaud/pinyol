-- The sound: every effect a PlayStation ADPCM sample (audio/SFX_*.vag, made by gen/sfx.py), every song a MIDI file on a bank of ADPCM samples
-- (audio/*.mid + BANK.bank: the console's SEQ and VAB), the rain and the sea streamed from the card (audio/AMB_*.spum), and all of it in ONE reverb room,
-- as the sound chip's own reverb wrapped a whole game: a stone hall inside the tower, a large studio outside in the storm.
local S = {}
local song, room = nil, nil

-- how much of each sound goes into the room, and how loud
local SEND = {STEP = 0.15, JUMP = 0.2, LAND = 0.2, LIFT = 0.5, CALM = 0.7, FREE = 0.8, MOAN = 0.8, HURT = 0.5, THUNDER = 0.4, WAVE = 0.3,
              GEAR = 0.4, HATCH = 0.5, OIL = 0.4, SPLASH = 0.4, BURNER = 0.5, ROAR = 0.6, SLAM = 0.4, INK = 0.4, HORN = 0.7, LAMP = 0.8,
              BLIP = 0.1, OK = 0.2}
local GAIN = {STEP = 0.35, THUNDER = 0.9, MOAN = 0.5, HORN = 0.9, LAMP = 0.9, ROAR = 0.9}

function S.room(name, force)
  if name == room and not force then return end
  room = name
  if name == "hall" then reverb("hall", 0.45, {music = 0.35, ambient = 0.2})
  elseif name == "outside" then reverb("studio_large", 0.35, {music = 0.25, ambient = 0.1})
  else reverb("studio_medium", 0.3, {music = 0.3, ambient = 0.1}) end
end

function S.current_room() return room end

function S.play(id, opts)
  opts = opts or {}
  return sfx("SFX_" .. id, (GAIN[id] or 0.7) * (opts.gain or 1), {reverb = SEND[id] or 0.3, pan = opts.pan or 0, pitch = opts.pitch,
             pitch_var = opts.var, delay = opts.delay, max = opts.max or 3, cooldown = opts.cooldown})
end

-- a sound placed between the ears by where it is on the screen
function S.at(id, x, opts)
  opts = opts or {}
  opts.pan = math.max(-0.8, math.min(0.8, (x - 240) / 300))
  return S.play(id, opts)
end

-- songs: the one playing changes with a fade; a jingle plays once over the silence, then the song that waits comes back
local jt, back = nil, nil
function S.music(name, fade)
  if jt then back = name return end
  if name == song then return end
  song = name
  if name then music(name, fade or 600, {bank = "BANK", loop = true}) else music(nil, fade or 600) end
end

function S.jingle(name, secs, keep)
  if not jt then back = keep ~= false and song or nil end
  jt, song = math.floor(secs * 60) + 12, name
  music(name, 0, {bank = "BANK", loop = false})
end

function S.update()
  if not jt then return end
  jt = jt - 1
  if jt > 0 then return end
  local b = back
  jt, back, song = nil, nil, nil
  if b then S.music(b, 600) else music(nil, 200) end
end

function S.stop()
  jt, back, song = nil, nil, nil
  music(nil, 300)
end

function S.current() return song end

function S.ambient(name)
  if name then ambient("AMB_" .. name, 1200) else ambient() end
end

return S
