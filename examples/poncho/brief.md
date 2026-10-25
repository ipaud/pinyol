# Poncho (working title: Poncho y el Patinete Loco)

16-bit look (SNES / Mega Drive). A Japanese-90s "weird and fun" platformer for a 3-year-old hero.
The references (photos of a real child's clothes, toys) stay in `raw/` (git-ignored): never commit them.

## Answers (AGENTS.md ask-first) and assumptions
- Graphics: image model (sprite_kit + sheet_jobs, a canonical reference per character). Logo and cover: image model, two variants, the user picks.
- Universe: its own. Lives: web and card (not the flash). es / ca / en, 7+ achievements, a "how it works" menu item, reduce_flashing, a test script.
- Quality bar (user): a lot of detail, very fluid play, enough frames for fluid motion, like the last era of the 16 bits.

## Poncho
Boy, 3 years old. Curly mid-length brown hair (his most recognisable trait: show it, caps sit high), big dark eyes, rosy cheeks. Outfit: cream five-panel cap, black-and-white zebra t-shirt, yellow shorts, white sneakers with light-blue sides. Alt outfit: yellow "Gold Coast" tee. Props: kick scooter (blue deck-stem, orange wheels), red toy car, ice cream.
Costumes = powers: barretina (red, headbutt), dinosaur onesie (stomp, fire), green rain boots (splash), green-and-white striped football shirt (brief invulnerability).
Helpers: golden dog, spotted cow, yellow chick. The toy keyboard is his FRIEND (he loves to play it): it is a checkpoint / power (notes), never an enemy.

## Worlds
1. The giant playroom (the Bluey-style backpack is a tent). 2. The living fruit market. 3. The chalk park (drawings come alive). 4. The keyboard stage. Final boss: "el Gran Silencio", a bored shadow that eats the colours and the music; Poncho beats it with rhythm (the keyboard) and the scooter.

## Budgets (the Cirera's picture memory is ~3.2 MB; sheets load in 10-frame pieces; 15 colours per sheet)
- Poncho ~40 px tall, ~140 frames: idle (breathing + blink + look around), walk 8, run 10, scooter push/glide/drift/brake, jump in 4 phases + land, hurt, win, each costume's moves.
- Enemies 12-20 frames each; bosses bigger, in pieces. Parallax of 3-4 layers per world, per-line water/heat, Mode 7 only in the boss.
- Play: coyote time, jump buffer, soft acceleration, camera lead, 60 fps fixed (measure on the board per world).
