-- the board's tour (tools/board_perf.py --tour): the level's first stretch on foot, the scooter on the flat, over the ramps, near the end
return {
  {3, 'require("core.play").enter() G.state = "play" D.bot(true)'},
  {14, 'D.bot(true)'},
  {10, 'D.tp(2600) D.scooter(true) D.bot(true)'},
  {10, 'D.tp(4200) D.scooter(true) D.bot(true)'},
  {8, 'D.tp(5600) D.bot(true)'},
  {8, 'D.tp(300) D.costume("dino") D.foe("robot", 200, 4) D.bot(true)'}, -- a costume at work: the breath of fire, particles
  {8, 'D.tp(3200) D.costume("futbol") D.bot(true)'},
}
