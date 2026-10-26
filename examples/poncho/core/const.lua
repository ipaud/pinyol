-- const: sizes and the feel of Poncho. Everything is drawn at the screen's own 480x320 (like Taller): positions are pixels, speeds pixels a tick (60 a second).
-- Only the far wall (one bitmap layer, scrolled line by line) lives in the 240x160 world; sprites, tiles and shapes are overlay.
-- A character stands at (x, y): x its middle, y its soles.
return {
  W = 480, H = 320, TILE = 32,
  COLS = 192, ROWS = 14, FLOOR = 11, -- the level: 6144 x 448 px, the floor's surface is the top of row 11 (y = 352)
  -- the body (not the sprite: the sprite's size is read from data/sheets.lua)
  HALF_W = 15, BODY_H = 58,
  -- walking and running
  WALK_V = 2.3, RUN_V = 4.3, RUN_AFTER = 42,   -- ticks of holding a direction before the walk becomes a run by itself (C runs at once)
  ACCEL = 0.26, ACCEL_RUN = 0.15, FRICTION = 0.34, FRICTION_RUN = 0.2, SKID = 0.62, AIR_ACCEL = 0.17, AIR_DRAG = 0.035, START_V = 0.7,
  -- jumping
  GRAV = 0.52, JUMP_V = 10.4, CUT_V = 3.4, HANG_V = 1.7, HANG_G = 0.5, FALL_G = 1.12, FAST_G = 1.75, MAX_FALL = 9, FAST_FALL = 12.5,
  COYOTE = 7, BUFFER = 6, LAND_HARD = 5.2,
  -- scooter
  S_PUSH = 0.07, S_PULSE = 0.24, S_TURBO = 1.55, S_TOP = 6.6, S_TOP_TURBO = 8.8, S_ROLL = 0.035, S_BRAKE = 0.34, S_DRIFT = 0.15, S_DRIFT_V = 2.6,
  S_OVER = 0.03, RAMP_LAUNCH = 0.75, S_BOUNCE = 0.2,
  -- harm
  HEARTS = 3, INVULN = 100, HURT_T = 22,
  SPRING_V = 15.2, STOMP_V = 8.6, STOMP_V_HELD = 11.4,
  -- costumes: a tap of C (up to TAP ticks) is the power; holding C runs
  TAP = 8, HEAD_V = 8, HEAD_LEN = 22, FIRE_LEN = 40, POUND_V = 15, BOOTS_V = 12, SPLASH_LEN = 26, FUT_T = 300, FUT_MULT = 1.3, FUT_V = 8.5, FUT_LEN = 14, POWER_CD = 20,
  -- camera
  CAM_LEAD = 14, CAM_LEAD_MAX = 110, CAM_LERP = 0.1, CAM_FEET = 236, CAM_UP = 96, CAM_DOWN = 26,
}
