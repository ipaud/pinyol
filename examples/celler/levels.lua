-- The five galleries of the cellar, from the ramp down to the way out at dawn. One character a square:
--   walls   # rock   V brick vault   B bottle rack (en rima)   R barrel heads   P riddling racks (pupitres)
--   doors   D wooden door (opens when pushed)   G iron gate with a padlock (the gallery's key)   H gate worked by a lever
--           S a bottle rack that is a secret passage (B pushes it)
--   other   L lever (B pulls it: every H of the gallery opens)   E stairs down to the next gallery   X the door out
--   things  @ start   k key   t ghost cork   c candle   a bottle of cava   r the Reserva of 1992   s a cork
--           b barrel   g demijohn (both stand in the way)
-- The strings are read once (world.load) into the map raycast draws, with the things taken out of it.
local L = {}

L[1] = { -- the ramp: a door, a ghost cork, the key and its gate
  name = "g1", angle = 0, fog = 1,
  map = {
    "####################",
    "#@....D......D.....#",
    "#.###.#..t...#..k..#",
    "#.#c#.#......#.....#",
    "#.#.#.#...b..###D###",
    "#...#.#......#.....#",
    "#####.#..t...#.t...#",
    "#.a...D......#.....#",
    "######VVVVVVV#..a..#",
    "#E.....G...........#",
    "####################",
  },
}

L[2] = { -- the bottle racks: a lever opens the gate to the key
  name = "g2", angle = 90, fog = 1,
  map = {
    "BBBBBBBBBBBBBBBBBBBB",
    "B@....B.....c...a..B",
    "B.BBB.B.BBBBDBBBBB.B",
    "B.B.t.B.B........B.B",
    "B.B.BBB.B.BBBBBB.B.B",
    "B.D.....B.B..k.B.B.B",
    "B.BBBBBBB.B....H.B.B",
    "B.B.a...B.BBBBBB.B.B",
    "B.B.BBB.B......t.B.B",
    "B.B.B.t.BBBBBBBBBB.B",
    "B...B.............sB",
    "BBBBBB.BBBBGBBBBBBBB",
    "BL.....BBB...E.BBBBB",
    "BBBBBBBBBBBBBBBBBBBB",
  },
}

L[3] = { -- the barrel hall: a secret passage in a bottle rack, the Reserva behind it
  name = "g3", angle = 0, fog = 1,
  map = {
    "RRRRRRRRRRRRRRRRRRRRRR",
    "R@.....R.....t.....c.R",
    "R..b...R.b.......b...R",
    "R......D.....b.......R",
    "R..t...R.b.......b...R",
    "RRRDRRRR.....t.......R",
    "BBB.BBBR.b.......b...R",
    "B.....BRRRRRRDRRRRRRRR",
    "B.a.t.B..............R",
    "B.....BRRRRRRRRRRRRR.R",
    "BBBSBBBR.k....t.....aR",
    "R..r..BR.............R",
    "R.....BRRRRRRRRRRRRGRR",
    "RRRRRRRRRRRRRRRRR...ER",
    "RRRRRRRRRRRRRRRRRRRRRR",
  },
}

L[4] = { -- the riddling racks: darker, two levers, more ghost corks
  name = "g4", angle = 270, fog = 0.8,
  map = {
    "PPPPPPPPPPPPPPPPPPPPPP",
    "PL...P.....t..P.....LP",
    "P....P.PPPPPP.P......P",
    "P..t.D.P.k..P.D..t...P",
    "P....P.P....P.P......P",
    "PPDPPP.PPHPPP.PPPPPDPP",
    "P........t...........P",
    "P.c..PPPPPPPPPPPP..s.P",
    "P....P..........P...aP",
    "P....G....t.....P....P",
    "P....P..a.......P..t.P",
    "P.@..PPPPPEPPPPPP.c..P",
    "PPPPPPPPPPPPPPPPPPPPPP",
  },
}

L[5] = { -- the old well: the last key, every ghost cork left, and the door out to the dawn
  name = "g5", angle = 0, fog = 1,
  map = {
    "##########################",
    "#@...D....t.....#........#",
    "#....#..........#.c...t..#",
    "#..c.#..g....g..D........#",
    "#....#..........#..b..b..#",
    "###D##..t....t..#........#",
    "VVV.VV..........###D######",
    "V..a.V###DD###..#........#",
    "V....V#.....#...#...t....#",
    "V.t..D#..k..#...#........#",
    "V....V#.....#...H........#",
    "VVVVVV###.###...#..s.....#",
    "#.....t...........L#####G#",
    "#.a.........t......#...X.#",
    "##########################",
  },
}

L.count = 5
return L
