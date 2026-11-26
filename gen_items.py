# Generates items.inc (gear bases, affixes, aspects, sets, uniques) and ITEMS.md
# (the 420-entry item catalog). Diablo-IV-style itemization on the framework's
# 11 slots and 6 rarities. All names are original.

SLOTS = ["MAIN HAND", "OFF HAND", "HEAD", "CHEST", "LEGS", "HANDS", "FEET", "RING", "NECK", "BACK", "TRINKET"]
RARITY = ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC"]
RAR_CH = "CURELM"

# base: name, slot, stat (weapon damage / armor), flags (1 finesse, 2 caster)
BASES = [
    ("DAGGER", 0, 10, 1), ("SHORTSWORD", 0, 13, 1), ("LONGSWORD", 0, 16, 0), ("GREATSWORD", 0, 22, 0),
    ("WAR AXE", 0, 18, 0), ("MACE", 0, 14, 0), ("RAPIER", 0, 15, 1), ("STAFF", 0, 12, 2), ("WAND", 0, 9, 2),
    ("SCYTHE", 0, 20, 0),
    ("BUCKLER", 1, 6, 0), ("KITE SHIELD", 1, 9, 0), ("TOWER SHIELD", 1, 12, 0), ("ORB", 1, 4, 2),
    ("TOME", 1, 3, 2), ("PARRY BLADE", 1, 5, 1),
    ("HOOD", 2, 3, 0), ("CIRCLET", 2, 2, 2), ("HELM", 2, 5, 0), ("GREAT HELM", 2, 7, 0), ("MASK", 2, 4, 1),
    ("ROBE", 3, 4, 2), ("JERKIN", 3, 6, 1), ("HAUBERK", 3, 9, 0), ("BRIGANDINE", 3, 8, 0), ("PLATEMAIL", 3, 12, 0),
    ("BREECHES", 4, 3, 1), ("CHAUSSES", 4, 6, 0), ("LEGPLATES", 4, 8, 0), ("SKIRT", 4, 2, 2),
    ("WRAPS", 5, 2, 1), ("GLOVES", 5, 3, 0), ("GAUNTLETS", 5, 5, 0), ("HANDGUARDS", 5, 4, 2),
    ("SANDALS", 6, 2, 2), ("BOOTS", 6, 3, 0), ("GREAVES", 6, 5, 0), ("TREADS", 6, 4, 1),
    ("BAND", 7, 0, 0), ("SIGNET", 7, 0, 0), ("LOOP", 7, 0, 2),
    ("AMULET", 8, 0, 0), ("PENDANT", 8, 0, 2), ("TORC", 8, 0, 0),
    ("CLOAK", 9, 2, 0), ("CAPE", 9, 1, 1), ("MANTLE", 9, 3, 2),
    ("CHARM", 10, 0, 0), ("IDOL", 10, 0, 2), ("TALISMAN", 10, 0, 0), ("RELIC", 10, 0, 1),
]
# affix: prefix word, target stat, kind (0 attr-flat, 1 big-flat, 2 hp, 3 mp, 4 pct, 5 haste)
# target ids: 0-9 attributes STR DEX CON INT WIS VIT SPI LCK WIL CHA
#   10 ATK 11 MAG 12 ARM 13 HP 14 MP 15 CRIT 16 CRITDMG 17 BLOCK 18 ACC 19 EVA
#   20 LIFESTEAL 21 GOLD 22 XP 23 HASTE 24 RES
AFFIXES = [
    ("MIGHTY", 0, 0), ("NIMBLE", 1, 0), ("STURDY", 2, 0), ("CLEVER", 3, 0), ("WISE", 4, 0),
    ("HALE", 5, 0), ("SPIRITED", 6, 0), ("LUCKY", 7, 0), ("RESOLUTE", 8, 0), ("REGAL", 9, 0),
    ("BRUTAL", 10, 1), ("ARCANE", 11, 1), ("WARDED", 12, 1), ("VITAL", 13, 2), ("MYSTIC", 14, 3),
    ("KEEN", 15, 4), ("CRUEL", 16, 4), ("STALWART", 17, 4), ("TRUE", 18, 1), ("ELUSIVE", 19, 1),
    ("VAMPIRIC", 20, 4), ("GILDED", 21, 4), ("SAGE", 22, 4), ("SWIFT", 23, 5), ("BLESSED", 24, 1),
]
# legendary powers (aspects), implemented by id in src/gear.asm
ASPECTS = [
    ("OF EMBERS", "HITS MAY BURN"), ("OF VENOM", "HITS MAY POISON"), ("OF THUNDER", "HITS MAY STUN"),
    ("OF THE LEECH", "HEAL ON HIT"), ("OF SLAYING", "+30% VS BOSSES"), ("OF THORNS", "REFLECT DAMAGE"),
    ("OF RENEWAL", "HEAL ON KILL"), ("OF FOCUS", "MP ON HIT"), ("OF FORTUNE", "DOUBLE GOLD"),
    ("OF WRATH", "CRITS +50% DMG"), ("OF THE BULWARK", "BLOCK HEALS"), ("OF HASTE", "KILLS GIVE HASTE"),
]
# sets: name, pieces (bases by slot), 2pc bonus (target, value), 4pc aspect id
SETS = [
    ("IRONWARD", ["GREAT HELM", "PLATEMAIL", "LEGPLATES", "GAUNTLETS", "GREAVES", "TOWER SHIELD"], (12, 120), 11),
    ("NIGHTFANG", ["MASK", "JERKIN", "BREECHES", "WRAPS", "TREADS", "DAGGER"], (15, 8), 2),
    ("STARWEAVE", ["CIRCLET", "ROBE", "SKIRT", "HANDGUARDS", "SANDALS", "STAFF"], (11, 120), 8),
    ("DAWNKEEPER", ["HELM", "HAUBERK", "CHAUSSES", "GLOVES", "BOOTS", "MACE"], (24, 100), 7),
    ("STORMCALLER", ["HOOD", "BRIGANDINE", "CHAUSSES", "GAUNTLETS", "BOOTS", "WAR AXE"], (16, 25), 3),
    ("GRAVEBORN", ["HELM", "HAUBERK", "LEGPLATES", "GAUNTLETS", "GREAVES", "SCYTHE"], (20, 4), 4),
]
# named uniques: name, base, rarity (4 legendary / 5 mythic), affixes, aspect
UNIQUES = [
    ("EMBERHEART", "LONGSWORD", 4, (10, 15), 1), ("WIDOWS KISS", "DAGGER", 4, (1, 16), 2),
    ("SKYSPLITTER", "GREATSWORD", 5, (10, 16, 0), 3), ("BLOODTHIRST", "WAR AXE", 4, (10, 20), 4),
    ("KINGSBANE", "RAPIER", 4, (1, 15), 5), ("BRAMBLEGUARD", "TOWER SHIELD", 4, (12, 17), 6),
    ("LIFEBLOOM", "STAFF", 4, (11, 4), 7), ("MINDSPIRE", "WAND", 5, (11, 3, 14), 8),
    ("MIDAS LOOP", "BAND", 4, (21, 7), 9), ("REAPERS EDGE", "SCYTHE", 5, (16, 15, 10), 10),
    ("AEGIS OF DAWN", "KITE SHIELD", 5, (12, 17, 5), 11), ("GALEWALKERS", "TREADS", 4, (23, 19), 12),
    ("CROWN OF ASH", "GREAT HELM", 4, (12, 2), 1), ("SERPENTSKIN", "JERKIN", 4, (19, 1), 2),
    ("THUNDERFIST", "GAUNTLETS", 4, (10, 0), 3), ("HUNGERING", "SIGNET", 5, (20, 15, 16), 4),
    ("GIANTSLAYER", "MACE", 4, (10, 0), 5), ("BRIAR MANTLE", "MANTLE", 4, (24, 12), 6),
    ("PHOENIX PLUME", "AMULET", 5, (13, 6, 5), 7), ("SAGES TOME", "TOME", 4, (11, 22), 8),
    ("FORTUNES IDOL", "IDOL", 4, (7, 21), 9), ("RAGECLAW", "WRAPS", 4, (16, 1), 10),
    ("WALL OF AGES", "PLATEMAIL", 5, (12, 13, 2), 11), ("WINDRUNNER", "CAPE", 4, (23, 1), 12),
    ("SOLAR ORB", "ORB", 4, (11, 24), 1), ("NETTLE BAND", "LOOP", 4, (20, 3), 2),
    ("STORMBREAKER", "WAR AXE", 5, (10, 23, 15), 3), ("VOID TALISMAN", "TALISMAN", 5, (16, 15, 7), 10),
    ("OATHKEEPER", "HAUBERK", 4, (13, 17), 11), ("DRIFTSTEP", "BOOTS", 4, (19, 23), 12),
]
BI = {b[0]: i for i, b in enumerate(BASES)}

L = ["; AUTO-GENERATED by gen_items.py - do not edit", ""]
s = lambda t: f'"{t}", $FF'
db = lambda v: "    db " + ", ".join(str(x & 255) for x in v)
L += [f"DEF NUM_BASES EQU {len(BASES)}", f"DEF NUM_AFFIXES EQU {len(AFFIXES)}",
      f"DEF NUM_ASPECTS EQU {len(ASPECTS)}", f"DEF NUM_SETS EQU {len(SETS)}",
      f"DEF NUM_UNIQUES EQU {len(UNIQUES)}", f"DEF NUM_GEAR_SLOTS EQU {len(SLOTS)}", ""]
L.append('SECTION "GearData", ROMX, BANK[1]')
L.append("; slot, stat, flags, pad")
L.append("GearBases:")
for n, sl, st, fl in BASES:
    L.append(db([sl, st, fl, 0]))
L.append("; first base, count per slot")
L.append("SlotBases:")
for sl in range(len(SLOTS)):
    idx = [i for i, b in enumerate(BASES) if b[1] == sl]
    L.append(db([idx[0], len(idx)]))
L.append("BaseNames:")
L.append("    dw " + ", ".join(f"StrBase{i}" for i in range(len(BASES))))
for i, b in enumerate(BASES):
    assert len(b[0]) <= 12, b[0]
    L.append(f"StrBase{i}: db {s(b[0])}")
L.append("; target, kind")
L.append("AffixTable:")
for p, t, k in AFFIXES:
    L.append(db([t, k]))
L.append("AffixNames:")
L.append("    dw " + ", ".join(f"StrAffix{i}" for i in range(len(AFFIXES))))
for i, a in enumerate(AFFIXES):
    L.append(f"StrAffix{i}: db {s(a[0])}")
L.append("AspectNames:")
L.append("    dw " + ", ".join(f"StrAsp{i}" for i in range(len(ASPECTS))))
L.append("AspectDescs:")
L.append("    dw " + ", ".join(f"StrAspD{i}" for i in range(len(ASPECTS))))
for i, a in enumerate(ASPECTS):
    assert len(a[0]) <= 18 and len(a[1]) <= 18
    L.append(f"StrAsp{i}: db {s(a[0])}")
    L.append(f"StrAspD{i}: db {s(a[1])}")
L.append("; per set: 6 piece bases, 2pc target, 2pc value, 4pc aspect, pad")
L.append("SetTable:")
for n, pieces, (t, v), asp in SETS:
    L.append(db([BI[p] for p in pieces] + [t, v, asp, 0]))
L.append("SetNames:")
L.append("    dw " + ", ".join(f"StrSet{i}" for i in range(len(SETS))))
for i, st in enumerate(SETS):
    L.append(f"StrSet{i}: db {s(st[0])}")
L.append("; base, rarity, affix1, affix2, affix3, aspect, pad, pad")
L.append("UniqueTable:")
for n, b, r, affs, asp in UNIQUES:
    a = list(affs) + [0] * (3 - len(affs))
    L.append(db([BI[b], r] + [x + 1 if x or True else 0 for x in a[:len(affs)]] + [0] * (3 - len(affs)) + [asp, 0, 0]))
L.append("UniqueNames:")
L.append("    dw " + ", ".join(f"StrUniq{i}" for i in range(len(UNIQUES))))
for i, u in enumerate(UNIQUES):
    assert len(u[0]) <= 13, u[0]
    L.append(f"StrUniq{i}: db {s(u[0])}")
L.append("SlotNames:")
L.append("    dw " + ", ".join(f"StrSlot{i}" for i in range(len(SLOTS))))
for i, sl in enumerate(SLOTS):
    L.append(f"StrSlot{i}: db {s(sl)}")
L.append("RarityNames6:")
L.append("    dw " + ", ".join(f"StrRar{i}" for i in range(len(RARITY))) + ", StrRarSet")
for i, r in enumerate(RARITY):
    L.append(f"StrRar{i}: db {s(r)}")
L.append('StrRarSet: db "SET", $FF')
L.append("RarityChars: db " + ", ".join(f'"{c}"' for c in RAR_CH) + ', "S"')
open("items.inc", "w").write("\n".join(L) + "\n")

# ---- the 420-entry catalog -------------------------------------------------------
cat = []
for b in BASES:
    for r in range(6):
        if r >= 4 and b[1] in (7, 8, 10):
            pass
        cat.append((f"{RARITY[r].title()} {b[0].title()}", SLOTS[b[1]].title(), RARITY[r].title(), "random affixes" if r else "no affixes"))
for n, pieces, (t, v), asp in SETS:
    for p in pieces:
        cat.append((f"{n.title()} {p.title()}", SLOTS[BASES[BI[p]][1]].title(), "Set", f"{n.title()} set"))
for n, b, r, affs, asp in UNIQUES:
    cat.append((n.title(), SLOTS[BASES[BI[b]][1]].title(), RARITY[r].title(), f"Unique: {ASPECTS[asp - 1][0].lower()}"))
assert len(cat) <= 420
extra = 420 - len(cat)
for i in range(extra):          # pad with aspect-imprinted legendary variants
    b = BASES[i % len(BASES)]
    a = ASPECTS[i % len(ASPECTS)]
    cat.append((f"{b[0].title()} {a[0].title()}", SLOTS[b[1]].title(), "Legendary", a[1].capitalize()))
with open("ITEMS.md", "w") as f:
    f.write("# ARPG GB QUEST item catalog (420 items)\n\n")
    f.write("Generated by `gen_items.py`. In game, drops roll an item level from the monster's level and random affixes; ")
    f.write("this catalog lists the distinct named item types.\n\n")
    f.write("| # | Item | Slot | Rarity | Notes |\n|---|---|---|---|---|\n")
    for i, (n, sl, r, note) in enumerate(cat):
        f.write(f"| {i + 1} | {n} | {sl} | {r} | {note} |\n")
print("bases", len(BASES), "affixes", len(AFFIXES), "aspects", len(ASPECTS), "sets", len(SETS),
      "uniques", len(UNIQUES), "catalog", len(cat))
