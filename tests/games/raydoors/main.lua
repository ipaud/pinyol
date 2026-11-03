-- raycast() doors (tests/raydoors.script): a door is a thin wall across the middle of its square, slid aside by `open`;
-- its square's sides are drawn with `jamb`
MAP = {
  "#######",
  "#..D..#",  -- (3, 1): open squares west and east of it, so it runs north to south, at x = 3.5
  "###E###",  -- (3, 2): walls west and east of it, so it runs east to west, at y = 2.5
  "#.....#",
  "#######",
}
WALLS = {["#"] = 0x0000FF, D = 0xFFFF00, E = 0x00FF00}
function view(x, y, angle, doors, jamb)
  return raycast("VIEW", {map = MAP, walls = WALLS, x = x, y = y, angle = angle, fov = 66, doors = doors, jamb = jamb})
end
function near(a, b) return math.abs(a - b) < 0.02 end
function rgb(x, y) local c = pget(x, y, "VIEW") or 0 return c >> 16 & 255, c >> 8 & 255, c & 255 end
function _init() canvas("VIEW", 240, 136) end
function _update() end
function _draw() cls(0) img("VIEW", 0, 0, {scale = 2}) end
