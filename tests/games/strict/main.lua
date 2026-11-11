-- A "strict" _G, as many Lua games use: reading a name nobody set raises. The engine looks up _draw, _pause and the others;
-- that lookup must not stop the game (or abort the engine, as it did): a name the game does not have is a callback it has not got.
ticks = 0
function _update() ticks = ticks + 1 end
setmetatable(_G, {__index = function(_, k) error("undefined global " .. tostring(k), 2) end})
