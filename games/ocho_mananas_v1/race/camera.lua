-- The rear camera's numbers. HOR and CAM_H make the Mode 7 road meet STREET_REAR's kerbs (art/build_scenery.py
-- prints them for a new picture); FOV puts Dani's feet near the bottom of the screen.
return {
  HOR = 44,      -- the horizon line, in world pixels
  HOR_M = 48,    -- the same for STREET_REAR_M (Mercaderes), whose horizon sits 8 screen pixels lower
  CAM_H_M = 30.0,
  FOV = 210,     -- mode7's fov: screen pixels per unit of lateral distance at depth 1
  CAM_H = 29.8,  -- how high the camera is, in street units (a runner is 16 tall, the street 64 wide)
  CB = 64,       -- how far behind Dani the camera follows
  HALF = 32,     -- half the street's width
  END = 640,     -- the far end of the painted street
  BASE = 4096,   -- the map's y for z = 0 (the route runs towards smaller y)
  -- the side view: the far wall's foot, the near kerb, and how many pixels a unit of route is at each depth
  SIDE_TOP = 108, SIDE_BOTTOM = 134, SIDE_X = 176,
}
