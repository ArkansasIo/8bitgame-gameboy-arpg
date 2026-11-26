# ARPG GB QUEST: an action RPG for Game Boy Color

**Version 0.4.0, build 20261126**

A top-down action RPG written in SM83 assembly. It runs on a Game Boy Color, GBA or GBA SP
in full color, and on an original Game Boy in grayscale. The game uses a 64 KB MBC5
cartridge with a battery save.

![screenshots](screenshots.png)

## Story
Goblins raid the village of **Oakhollow** by night. An ogre has sealed itself inside the
Old Crypt with four magic seals, each guarded by a beast in a different land. Break the seals
in Whisperwood, the Sunscar Dunes, Frostfang Reach and Mirefen Marsh, then end the ogre.

## Controls
| Button | In play | In menus |
|---|---|---|
| D-pad | Move | Move cursor / change option |
| A | Swing weapon / talk to townsfolk | Confirm |
| B | Class action (Fire Bolt, Sacred Flame, Dash, or a second swing) | Back |
| START | Pause menu | Close |

## Game systems
| System | What it does | Source |
|---|---|---|
| World | Hub town plus 5 zones (16 rooms) with their own tiles, palettes, monsters and bosses; a zone-name banner; the crypt is sealed until all 4 bosses are dead | `gen_world.py`, `game.asm` |
| Classes | Fighter, Rogue, Wizard and Cleric, each with SRD hit dice, ability modifiers, starting gear, sprite and colors | `src/classes.asm`, `gen_data.py` |
| Progression | Levels 1-720 for players and monsters; XP curve 15 + 8L + L^2/64; +3 attribute points per level plus class growth | `src/stats.asm` |
| Attributes | STR, DEX, VIT, INT, FTH, LCK (spend points from the character sheet) | `src/stats.asm` |
| Sub-stats | Max HP, Max MP, ATK, MAG, DEF, crit %, crit damage (150-300%), dodge %, block %, attack speed | `src/stats.asm` |
| Combat | Spread (90-110%) damage minus half of defense, crits, dodge, block, MP-based spells, MP regen | `src/stats.asm`, `src/combat.asm` |
| Monster scaling | Each zone has a level band (1-25, 25-100, 100-250, 250-450, 450-720); HP/ATK/DEF/XP scale from SRD templates | `gen_world.py`, `src/stats.asm` |
| Class features | Second Wind, Action Surge, Sneak Attack, Uncanny Dodge, Poison Blade, Cunning Action dash | `src/combat.asm` |
| Spells | Fire Bolt and Sacred Flame (projectiles), Magic Missile, Shield, Cure Wounds, Guiding Bolt; spell slots that grow with level | `src/combat.asm` |
| Loot | Diablo-style rarity tiers (Common / Magic / Rare / Legendary), gold drops, random gear drops, and a unique item from each boss (Flame Tongue, Adamantine armor, ...) | `src/combat.asm`, `gen_data.py` |
| Inventory | 10-slot bag; potions stack; equip or toss; stats recalculated on equip | `src/inventory.asm` |
| Town | Talk to NPCs, dialogue boxes, a merchant to buy and sell, an inn to rest (long rest) | `src/town.asm` |
| Quests | Main quest plus 3 side quests with kill counters, turn-ins, gold and item rewards, and a quest log | `src/quests.asm` |
| Save | Battery save slot with a checksum; Continue from the title screen | `src/save.asm` |
| Menus | STATUS, ITEMS, SKILLS, QUESTS, MAP, BESTIARY (14 monsters), SAVE, OPTIONS (palette, sound) | `game.asm` |

## Build
```
make            # needs RGBDS 0.9+ (https://rgbds.gbdev.io) and Python 3
```
The generators (`gen_gfx.py`, `gen_world.py`, `gen_data.py`) rebuild the `.inc` data files
automatically when you change them. Play `arpg_gb_quest.gb` in mGBA, SameBoy, BGB or
Emulicious, or on a flash cart.

## Files
```
game.asm         engine: boot, banks, rendering, window menus, rooms, player, enemies, HUD, sound
src/stats.asm    levels 1-720, attributes, sub-stats, damage formulas, HUD, sheet
src/classes.asm  class select, ability scores, derived stats, character sheet
src/combat.asm   damage rolls, kills + loot, projectiles, skills and spells
src/inventory.asm bag, equipment, rarity display, potions
src/town.asm     NPC talk, dialogue engine, shop, inn
src/quests.asm   quest state machine, quest givers, quest log
src/save.asm     SRAM save / load / continue
gen_gfx.py       pixel art (sprites, biome tiles, font, frames) + GBC palettes -> gfx.inc
gen_world.py     world graph, generated rooms, spawns, monster stats, bestiary -> world.inc
gen_data.py      items, classes, skills, shop stock -> data.inc
tests/           PyBoy scripts that play through each system
```

## How it works
- **Memory banks:** bank 0 holds the engine, bank 1 the menus/systems/data, bank 2 the room
  maps and bank 3 the graphics. Only code in bank 0 switches banks.
- **Menus:** each menu is drawn into a RAM buffer and copied to the window layer during
  VBlank, 3 rows per frame. A LY=LYC interrupt turns the window off below the box.
- **Biomes:** on entering a zone, 6 background tiles and all 16 color palettes are swapped.

## Legal
This work includes material taken from the System Reference Document 5.1 ("SRD 5.1")
by Wizards of the Coast LLC and available at
https://dnd.wizards.com/resources/systems-reference-document. The SRD 5.1 is licensed
under the Creative Commons Attribution 4.0 International License available at
https://creativecommons.org/licenses/by/4.0/legalcode.

The story, characters, places, lore text, pixel art and code are original. The loot rarity
tiers are a common genre mechanic and contain no content from any other game. This project
isn't affiliated with or endorsed by Wizards of the Coast, Nintendo, Blizzard or NCSOFT.
