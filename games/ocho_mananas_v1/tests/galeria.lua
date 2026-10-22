-- A contact sheet drawn with the real actor code: every picture at the size the views give it, side by side
-- (so a figure that changes size or hops from frame to frame shows), and a few at the screen's edges and far
-- too big, to see that nothing is cut but by the screen. Loaded by tests/galeria.script.
local A = require("views.actors")
local g = {}

-- x and y in screen pixels (A.draw takes the 240x160 world)
local function d(id, f, x, y, px, flip) A.draw(id, f, x / 2, y / 2, A.fit(id, px), flip) end

function g.install()
  function _update() end
  function _draw()
    cls(0x6C7490)
    rect(0, 150, 480, 1, 0xFFFFFF)
    rect(0, 235, 480, 1, 0xFFFFFF)
    rect(0, 305, 480, 1, 0xFFFFFF)
    for i = 0, 5 do d("DANI_BACK", i, 40 + i * 58, 150, 138) end
    for i = 0, 3 do d("DANI_FRONT", i, 40 + i * 58, 305, 138) end
    for i = 0, 5 do d("RUN_BACK", i, 300 + i * 34, 150, 105) end
    for i = 0, 3 do d("TORO_BACK", i, 280 + i * 50, 305, 119) end
    for i = 0, 3 do d("CABE_FRONT", i, 280 + i * 50, 235, 112) end
    d("DANI_BACK", 0, 2, 305, 200)
    d("DANI_BACK", 1, 478, 305, 200)
    d("TORO_3QF", 1, 240, 305, 119)
  end
end

return g
