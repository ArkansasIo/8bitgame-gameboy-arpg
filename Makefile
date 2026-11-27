# Requires RGBDS 0.9+ (https://rgbds.gbdev.io) and Python 3
ROM = arpg_gb_quest.gb
VERSION = 0.8.0
BUILD = 20261127

$(ROM): game.asm gfx.inc world.inc data.inc $(wildcard src/*.asm)
	rgbasm -Wall -o game.o game.asm
	rgblink -n game.sym -m game.map -o $(ROM) game.o
	rgbfix -v -c -m 0x1B -r 2 -n 8 -p 0xFF -t "ARPGGBQUEST" $(ROM)
	@echo "ARPG GB QUEST v$(VERSION) build $(BUILD): $$(wc -c < $(ROM)) bytes"

gfx.inc: gen_gfx.py
	python3 gen_gfx.py

world.inc: gen_world.py
	python3 gen_world.py

data.inc: gen_data.py
	python3 gen_data.py

clean:
	rm -f game.o game.sym game.map $(ROM)
	rm -rf dist

# Browser build for OpenGame: the ROM plus the binjgb web player, in dist/
web: $(ROM) web/index.html web/style.css web/player.js web/LICENSES.txt
	rm -rf dist && mkdir -p dist
	cp web/index.html web/style.css web/player.js web/LICENSES.txt web/vendor/binjgb.js web/vendor/binjgb.wasm dist/
	cp $(ROM) dist/arpg_gb_quest.gbc
	@echo "web build in dist/ ($$(du -sh dist | cut -f1))"

.PHONY: clean web
