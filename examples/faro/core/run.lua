-- one climb of the lighthouse: what carries from floor to floor (warmth, matches, the score, the time, the ánimas freed)
local C = require("core.const")
local R = {}

function R.new()
  R.warmth, R.matches, R.score, R.ticks, R.freed = C.WARMTH, C.MATCHES, 0, 0, 0
  R.floor, R.wet = 1, false
end

R.new()
return R
