# Generates data.inc: items, classes, skills, shop stock (bank 1).
# Weapon/armor/potion stats follow SRD 5.1 (CC-BY-4.0); rarity tiers are
# a Diablo-style loot layer on top (common / magic / rare / legendary).

RARITY = ["COMMON", "MAGIC", "RARE", "LEGENDARY"]
# type: 0 consumable, 1 weapon, 2 armor
# consumable: p1 effect(0 heal dice, 1 full heal), p2 count, p3 sides, p4 bonus
# weapon:     p1 dice count, p2 sides, p3 magic bonus, p4 flags (1 finesse, 2 +2d6 fire)
# armor:      p1 base AC, p2 dex cap (9 = none), p3 magic bonus, p4 flags (4 no crits)
ITEMS = [
    ("POTION",       0, 0,   50, 0, 2, 4, 2),
    ("GR.POTION",    0, 1,  150, 0, 4, 4, 4),
    ("ELIXIR",       0, 2,  300, 1, 0, 0, 0),
    ("DAGGER",       1, 0,    2, 1, 4, 0, 1),
    ("SHORTSWORD",   1, 0,   10, 1, 6, 0, 1),
    ("MACE",         1, 0,    5, 1, 6, 0, 0),
    ("QUARTERSTAFF", 1, 0,    2, 1, 6, 0, 0),
    ("LONGSWORD",    1, 0,   15, 1, 8, 0, 0),
    ("GREATSWORD",   1, 0,   50, 2, 6, 0, 0),
    ("RAPIER",       1, 0,   25, 1, 8, 0, 1),
    ("LEATHER",      2, 0,   10, 11, 9, 0, 0),
    ("CHAIN SHIRT",  2, 0,   50, 13, 2, 0, 0),
    ("CHAIN MAIL",   2, 0,   75, 16, 0, 0, 0),
    ("PLATE",        2, 0,  400, 18, 0, 0, 0),
    ("LONGSWORD+1",  1, 1,  300, 1, 8, 1, 0),
    ("RAPIER+1",     1, 1,  300, 1, 8, 1, 1),
    ("CHAIN MAIL+1", 2, 2,  500, 16, 0, 1, 0),
    ("FLAME TONGUE", 1, 3,  900, 1, 8, 0, 2),
    ("ADAMANTINE",   2, 2,  800, 18, 0, 0, 4),
    ("IRON ORE",     3, 0,   20, 0, 0, 0, 0),
]
ID = {it[0]: i + 1 for i, it in enumerate(ITEMS)}
SHOP = ["POTION", "GR.POTION", "ELIXIR", "IRON ORE"]
# zone boss loot (by boss flag bit): spider, mummy, winter wolf, giant toad
BOSS_LOOT = ["RAPIER+1", "CHAIN MAIL+1", "FLAME TONGUE", "ADAMANTINE"]
# random common drops (1 in 16 kills)
RANDOM_LOOT = ["IRON ORE", "IRON ORE", "IRON ORE", "POTION", "POTION", "GR.POTION", "IRON ORE", "ELIXIR"]

# skills: name, desc1, desc2, kind (0 = charge, recharges on short rest; 1 = spell slot)
SKILLS = [
    ("SECOND WIND",   "HEAL 25% OF",      "YOUR MAX HP.",    0),   # 1
    ("ACTION SURGE",  "POWER + HASTE",    "BUFFS FOR 10S.",  0),   # 2
    ("UNCANNY DODGE", "HALVE THE NEXT",   "3 HITS TAKEN.",   0),   # 3
    ("POISON BLADE",  "NEXT 6 HITS",      "POISON FOES.",    0),   # 4
    ("MAGIC MISSILE", "MAG X2 DAMAGE,",   "NEVER MISSES.",   1),   # 5
    ("SHIELD",        "FORTIFY: +50%",    "ARMOR FOR 10S.",  1),  # 6
    ("CURE WOUNDS",   "HEAL + REGEN",     "FOR 8 SECONDS.",  1),  # 7
    ("GUIDING BOLT",  "MAG X3 RADIANT",   "TO NEAREST FOE.", 1),   # 8
]
# ---- races (9): name, attribute bonuses STR DEX CON INT WIS VIT SPI LCK WIL CHA, desc
RACES = [
    ("HUMAN",      (1, 1, 1, 1, 1, 1, 1, 1, 1, 1), ["ADAPTABLE AND", "DRIVEN. +1 ALL."]),
    ("ELF",        (0, 3, 0, 2, 2, 0, 1, 0, 0, 0), ["GRACEFUL, KEEN-", "EYED, LONG-LIVED."]),
    ("DWARF",      (2, 0, 3, 0, 0, 3, 0, 0, 1, 0), ["STOUT MOUNTAIN", "FOLK. HARD TO KILL"]),
    ("HALFLING",   (0, 3, 0, 0, 0, 0, 0, 3, 1, 2), ["SMALL, QUICK AND", "VERY LUCKY."]),
    ("ORC",        (4, 0, 1, 0, 0, 3, 0, 0, 1, 0), ["FIERCE AND STRONG", "AS IRON."]),
    ("GNOME",      (0, 1, 0, 4, 1, 0, 1, 2, 0, 0), ["TINKERS AND", "SPELL-SCHOLARS."]),
    ("HALF-GIANT", (5, 0, 3, 0, 0, 2, 0, 0, 0, 0), ["TOWERING. SLOW", "BUT MIGHTY."]),
    ("FAE",        (0, 2, 0, 1, 2, 0, 3, 1, 0, 2), ["FOREST SPIRITS", "OF WIND + LIGHT."]),
    ("DRAGONKIN",  (3, 0, 1, 0, 0, 1, 1, 0, 2, 2), ["SCALED, PROUD,", "AND IRON-WILLED."]),
]
# ---- classes (18): name, sprite archetype (0 fighter 1 rogue 2 wizard 3 cleric),
#      start STR DEX CON INT WIS VIT SPI LCK WIL CHA, growth (same order),
#      kit (main-hand base, chest base), skill1, skill2, B-action, desc
# kit bases index gen_items.BASES; skills 1-8; B 0 melee 1 bolt 2 flame 3 dash
CLASSES = [
    ("FIGHTER",   0, (14,11,13, 6, 8,13, 6, 6,10, 8), (2,1,2,0,0,2,0,0,1,0), (2, 23), 1, 2, 0, ["MASTER OF ARMS.", "TOUGH, HEAVY", "ARMOR, BIG HITS."]),
    ("ROGUE",     1, ( 9,14,11, 9, 8,10, 7,12, 8,10), (1,2,1,0,0,1,0,2,0,1), (1, 22), 3, 4, 3, ["SNEAK ATTACK ON", "FIRST STRIKE. B", "DASHES AWAY."]),
    ("WIZARD",    2, ( 6,10, 9,15,10, 8,14, 8,11, 9), (0,1,1,3,1,1,2,0,1,0), (7, 21), 5, 6, 1, ["FRAIL BUT DEADLY", "B CASTS FIRE BOLT", "SPELLS COST MP."]),
    ("CLERIC",    3, (11, 8,12, 7,14,11,12, 7,12,10), (1,0,1,0,3,2,1,0,1,1), (5, 23), 7, 8, 2, ["HEALER IN MAIL.", "B: SACRED FLAME.", "SPELLS COST MP."]),
    ("PALADIN",   0, (13, 8,13, 6,11,12,10, 6,12,12), (2,0,2,0,1,2,1,0,1,1), (5, 25), 1, 7, 0, ["HOLY KNIGHT WHO", "HEALS AND HITS", "HARD."]),
    ("RANGER",    1, (10,15,10, 8,10,10, 8,10, 8, 8), (1,3,1,0,1,1,0,1,0,0), (6, 22), 3, 5, 1, ["WILDS HUNTER.", "B SHOOTS BOLTS", "FROM AFAR."]),
    ("BARBARIAN", 0, (16,10,14, 5, 6,15, 5, 7,10, 6), (3,1,2,0,0,3,0,0,1,0), (4, 22), 2, 1, 0, ["RAGE-FUELLED", "BRUTE. HUGE HP", "AND DAMAGE."]),
    ("MONK",      1, (11,14,12, 7,12,11,10, 9,11, 8), (1,2,1,0,1,1,1,1,1,0), (5, 22), 3, 1, 3, ["FISTS OF STONE.", "B DASHES. HEALS", "SELF IN BATTLE."]),
    ("DRUID",     3, ( 8, 9,10,10,15,10,13, 8,10, 9), (0,1,1,1,3,1,2,0,1,0), (7, 21), 7, 8, 2, ["NATURE'S VOICE.", "HEALS AND SMITES", "WITH THE WILD."]),
    ("WARLOCK",   2, ( 7,10,10,14, 9, 9,13, 9,12,11), (0,1,1,3,0,1,2,0,1,1), (8, 21), 5, 4, 1, ["PACT MAGE OF", "CURSES AND", "VENOM."]),
    ("SORCERER",  2, ( 6,11, 9,16, 8, 8,15, 9,10,12), (0,1,1,3,0,1,2,1,0,1), (8, 21), 5, 6, 1, ["BORN WITH RAW", "MAGIC. HUGE", "SPELL POWER."]),
    ("BARD",      1, ( 8,12,10,10,11, 9,11,11, 9,15), (0,2,1,1,1,1,1,1,0,2), (6, 22), 7, 6, 2, ["SONGS THAT HEAL", "AND SHIELD. FINE", "MERCHANT PRICES."]),
    ("KNIGHT",    0, (14, 9,15, 6, 8,14, 6, 6,12, 9), (2,0,3,0,0,2,0,0,2,0), (3, 25), 6, 1, 0, ["SHIELD-WALL OF", "THE REALM. THE", "BEST ARMOR."]),
    ("NECROMANCER",2,( 6, 9,10,15,11, 9,14, 8,12, 8), (0,1,1,3,1,1,2,0,1,0), (7, 21), 8, 4, 1, ["DARK SCHOLAR OF", "DEATH, BLIGHT", "AND BONE."]),
    ("BERSERKER", 0, (16,12,12, 5, 6,13, 5, 8, 9, 6), (3,2,1,0,0,2,0,1,0,0), (9, 22), 2, 4, 0, ["SCREAMING STORM", "OF BLADES. ALL", "OFFENSE."]),
    ("ASSASSIN",  1, (10,16, 9, 9, 8, 9, 7,14, 8, 8), (1,3,0,0,0,1,0,3,0,0), (0, 22), 4, 3, 3, ["SHADOW KILLER.", "POISON, CRITS", "AND SPEED."]),
    ("TEMPLAR",   3, (12, 8,13, 6,13,12,11, 6,13,10), (2,0,2,0,2,2,1,0,1,0), (5, 25), 8, 6, 2, ["WAR-PRIEST WHO", "SMITES WITH", "RADIANT FIRE."]),
    ("SHAMAN",    3, ( 9, 9,11,12,13,10,13, 8,10, 9), (0,1,1,2,2,1,2,0,1,0), (7, 23), 7, 5, 2, ["SPIRIT CALLER.", "HEALS AND HURLS", "SPIRIT DARTS."]),
]
L = ["; AUTO-GENERATED by gen_data.py - do not edit", ""]
s = lambda t: f'"{t}", $FF'
db = lambda v: "    db " + ", ".join(str(x & 255) for x in v)
L.append(f"DEF NUM_ITEMS EQU {len(ITEMS)}")
L.append(f"DEF NUM_SHOP EQU {len(SHOP)}")
for name, i in ID.items():
    L.append(f"DEF ITEM_{name.replace(' ', '_').replace('+', 'P').replace('.', '_')} EQU {i}")
L.append("")
L.append('SECTION "GameData", ROM0')
L.append("; type rarity priceLo priceHi p1 p2 p3 p4")
L.append("ItemTable:")
for name, typ, rar, price, p1, p2, p3, p4 in ITEMS:
    L.append(db([typ, rar, price & 255, price >> 8, p1, p2, p3, p4]))
L.append("ItemNames:")
L.append("    dw " + ", ".join(f"StrItem{i}" for i in range(len(ITEMS))))
for i, it in enumerate(ITEMS):
    assert len(it[0]) <= 12, it[0]
    L.append(f"StrItem{i}: db {s(it[0])}")
L.append("RarityNames:")
L.append("    dw " + ", ".join(f"StrRarity{i}" for i in range(4)))
for i, r in enumerate(RARITY):
    L.append(f"StrRarity{i}: db {s(r)}")
L.append("ShopStock:")
L.append(db([ID[n] for n in SHOP]))
L.append("BossLoot:")
L.append(db([ID[n] for n in BOSS_LOOT]))
L.append("RandomLoot:")
L.append(db([ID[n] for n in RANDOM_LOOT]))
L.append("; kind per skill")
L.append("SkillKinds:")
L.append(db([k[3] for k in SKILLS]))
L.append("SkillNames:")
L.append("    dw " + ", ".join(f"StrSkill{i}" for i in range(len(SKILLS))))
L.append("SkillDescs:")
L.append("    dw " + ", ".join(f"StrSkillD{i}a, StrSkillD{i}b" for i in range(len(SKILLS))))
for i, k in enumerate(SKILLS):
    for t in k[:3]:
        assert len(t) <= 16, t
    L.append(f"StrSkill{i}: db {s(k[0])}")
    L.append(f"StrSkillD{i}a: db {s(k[1])}")
    L.append(f"StrSkillD{i}b: db {s(k[2])}")
L.append(f"DEF NUM_CLASSES EQU {len(CLASSES)}")
L.append(f"DEF NUM_RACES EQU {len(RACES)}")
L.append("; arch kitMain kitChest skill1 skill2 baction castmod pad*9")
L.append("ClassTable:")
for c in CLASSES:
    name, arch, st, gr, kit, s1, s2, ba, desc = c
    L.append(db([arch, kit[0], kit[1], s1, s2, ba, 2 if arch in (2, 3) else 0] + [0] * 9))
L.append("ClassStart:")
for c in CLASSES:
    L.append(db(list(c[2])))
L.append("ClassGrowth:")
for c in CLASSES:
    L.append(db(list(c[3])))
L.append("ClassNames:")
L.append("    dw " + ", ".join(f"StrClass{i}" for i in range(len(CLASSES))))
L.append("ClassDescs:")
L.append("    dw " + ", ".join(f"StrClassD{i}" for i in range(len(CLASSES))))
for i, c in enumerate(CLASSES):
    assert len(c[0]) <= 11, c[0]
    L.append(f"StrClass{i}: db {s(c[0])}")
    L.append(f"StrClassD{i}:")
    for k, t in enumerate(c[8]):
        assert len(t) <= 18, t
        L.append(f"    db 1, {13 + k}")
        L.append(f"    dw .d{k}")
    L.append("    db $FF")
    for k, t in enumerate(c[8]):
        L.append(f".d{k}: db {s(t)}")
ATTR = ["STR", "DEX", "CON", "INT", "WIS", "VIT", "SPI", "LCK", "WIL", "CHA"]
L.append("RaceTable:")
for r in RACES:
    L.append(db(list(r[1])))
L.append("RaceNames:")
L.append("    dw " + ", ".join(f"StrRace{i}" for i in range(len(RACES))))
L.append("RaceDescs:")
L.append("    dw " + ", ".join(f"StrRaceD{i}" for i in range(len(RACES))))
for i, r in enumerate(RACES):
    L.append(f"StrRace{i}: db {s(r[0])}")
    bon = " ".join(f"+{v}{ATTR[k]}" for k, v in sorted(enumerate(r[1]), key=lambda kv: -kv[1]) if v)[:18]
    if r[0] == "HUMAN": bon = "+1 TO EVERYTHING"
    L.append(f"StrRaceD{i}:")
    for k, t in enumerate(r[2] + [bon]):
        assert len(t) <= 18, t
        L.append(f"    db 1, {13 + k + (1 if k == 2 else 0)}")
        L.append(f"    dw .d{k}")
    L.append("    db $FF")
    for k, t in enumerate(r[2] + [bon]):
        L.append(f".d{k}: db {s(t)}")
open("data.inc", "w").write("\n".join(L) + "\n")
print("items", len(ITEMS), "skills", len(SKILLS), "classes", len(CLASSES), "races", len(RACES))
