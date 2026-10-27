-- beat: the stage's pulse, 120 beats a minute = one beat every 30 ticks, counted from the tick a run starts (so it is the same every time: deterministic).
-- Things that sync to it: the note hoppers (they hop on the beat), the speakers (a ring every second beat), the drum pads (a bigger bounce on the beat), the spotlight's sweep,
-- the boss's rhythm rounds. `Beat.t` is this run's tick.
local B = {}
B.LEN = 30
B.t = 0

function B.reset() B.t = 0 end
B.hold = false -- (the test script can stop the beat at a tick)
function B.update() if not B.hold then B.t = B.t + 1 end end
function B.phase() return (B.t % B.LEN) / B.LEN end                 -- 0 at the beat, up to just under 1
function B.downbeat() return B.t % B.LEN == 0 end                   -- true on the tick of a beat
function B.near(tol) local p = B.t % B.LEN return p <= tol or p >= B.LEN - tol end -- within `tol` ticks of a beat
function B.pulse() local p = B.t % B.LEN return p < 8 and (8 - p) / 8 or 0 end -- 1 on the beat, falling to 0 over 8 ticks (for things that swell)

return B
