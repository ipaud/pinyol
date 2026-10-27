-- the board's tour (tools/board_perf.py --tour): the level's first stretch on foot, the scooter on the flat, over the ramps, near the end
return {
  {3, 'require("core.play").enter() G.state = "play" D.bot(true)'},
  {14, 'D.bot(true)'},
  {10, 'D.tp(2600) D.scooter(true) D.bot(true)'},
  {10, 'D.tp(4200) D.scooter(true) D.bot(true)'},
  {8, 'D.tp(5600) D.bot(true)'},
  {8, 'D.tp(300) D.costume("dino") D.foe("robot", 200, 4) D.bot(true)'}, -- a costume at work: the breath of fire, particles
  {8, 'D.tp(3200) D.costume("futbol") D.bot(true)'},
  -- world 2 (the market): the start with a conveyor and cherries, the pit with the cart, the arena of Mama Sandia
  {10, 'D.world(2) D.bot(true)'},
  {10, 'D.tp(3100) D.bot(true)'},
  {12, 'D.tp(6100) D.fight(true)'},
  -- world 3 (the chalk park): the start, the swings over the pit, the rainbow of ramps with the scooter
  {10, 'D.world(3) D.bot(true)'},
  {10, 'D.tp(3300) D.bot(true)'},
  {10, 'D.tp(4800) D.scooter(true) D.bot(true)'},
}
