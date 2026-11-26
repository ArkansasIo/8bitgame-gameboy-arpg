# Requires RGBDS 0.9+ (https://rgbds.gbdev.io) and Python 3
ROM = arpg_gb_quest.gb
VERSION = 0.5.0
BUILD = 20261126

$(ROM): game.asm gfx.inc world.inc data.inc $(wildcard src/*.asm)
	rgbasm -Wall -o game.o game.asm
	rgblink -n game.sym -m game.map -o $(ROM) game.o
	rgbfix -v -c -m 0x1B -r 2 -n 6 -p 0xFF -t "ARPGGBQUEST" $(ROM)
	@echo "ARPG GB QUEST v$(VERSION) build $(BUILD): $$(wc -c < $(ROM)) bytes"

gfx.inc: gen_gfx.py
	python3 gen_gfx.py

world.inc: gen_world.py
	python3 gen_world.py

data.inc: gen_data.py
	python3 gen_data.py

clean:
	rm -f game.o game.sym game.map $(ROM)
