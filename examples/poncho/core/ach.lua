-- ach: the achievements (game.json lists them). `Ach.earn(id)` shows a note the first time.
local lang = require("lang")
local A = {}
A.on_new = nil -- function(text) called when one is earned for the first time

function A.earn(id)
  if achieve(id) and A.on_new then A.on_new(lang.tr("ach_" .. id)) end
end

return A
