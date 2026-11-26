# Requires RGBDS 0.9+ (https://rgbds.gbdev.io) and Python 3
ROM = dungeon_quest.gb

$(ROM): game.asm gfx.inc
	rgbasm -Wall -o game.o game.asm
	rgblink -n game.sym -m game.map -o $(ROM) game.o
	rgbfix -v -c -p 0xFF -t "DUNGEONQUEST" $(ROM)

gfx.inc: gen_gfx.py
	python3 gen_gfx.py

clean:
	rm -f game.o game.sym game.map $(ROM)
