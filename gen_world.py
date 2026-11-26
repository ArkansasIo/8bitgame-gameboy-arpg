# Generates world.inc: rooms (bank 2), room links, spawns, monsters,
# bestiary text and world-map layout.  Monster stats: SRD 5.1 (CC-BY-4.0).
import random

R_W, R_H = 20, 17
FLOOR, FLOOR2, WALL, OBST, HAZ, PROP = 1, 2, 3, 4, 5, 6
CH = {'.': FLOOR, ',': FLOOR2, '#': WALL, 'T': OBST, '~': HAZ, 'o': PROP}

# ---------------------------------------------------------------- zones ---
ZONES = ["OAKHOLLOW", "WHISPERWOOD", "SUNSCAR DUNES", "FROSTFANG REACH",
         "MIREFEN MARSH", "THE OLD CRYPT"]

# ------------------------------------------------------------- monsters ---
# name, AC, HP, atk, dice n, dice sides, dmg bonus, XP, sprite tile, gold die,
# flags (boss bits: 1 forest, 2 desert, 4 tundra, 8 swamp, $80 final), size/type, lore
M = [
 ("GOBLIN",       15,  7, 4, 1, 6, 2,  50, 12, 6, 0,    "SMALL HUMANOID",
  ["CRUEL RAIDERS WHO", "STRIKE IN PACKS", "FROM THE DARK."], "SCIMITAR", "SLASHING", "1/4"),
 ("GIANT BAT",    13, 22, 4, 1, 6, 2,  50, 20, 0, 0,    "LARGE BEAST",
  ["IT HUNTS BY SOUND", "AND NEVER SITS", "STILL."], "BITE", "PIERCING", "1/4"),
 ("SKELETON",     13, 13, 4, 1, 6, 2,  50, 28, 4, 0,    "MEDIUM UNDEAD",
  ["OLD GUARDS OF THE", "CRYPT, RAISED BY", "DARK MAGIC."], "SHORTSWORD", "PIERCING", "1/4"),
 ("OGRE",         11, 59, 6, 2, 8, 4, 450, 37, 0, 0x80, "LARGE GIANT",
  ["THE BRUTE WHO", "RULES THE CRYPT", "AND ITS DEAD."], "GREATCLUB", "BLUDGEONING", "2"),
 ("WOLF",         13, 11, 4, 2, 4, 2,  50, 41, 0, 0,    "MEDIUM BEAST",
  ["PACK HUNTERS OF", "THE WILD WOODS", "AND COLD HILLS."], "BITE", "PIERCING", "1/4"),
 ("GIANT SPIDER", 14, 26, 5, 1, 8, 3, 200, 45, 0, 1,    "LARGE BEAST",
  ["QUEEN OF THE WEB", "THAT CHOKES THE", "WHISPERWOOD."], "BITE", "PIERCING", "1"),
 ("GIANT LIZARD", 12, 19, 4, 1, 8, 2,  50, 49, 0, 0,    "LARGE BEAST",
  ["BASKS ON HOT ROCK", "AND BITES ANY", "WHO WANDER NEAR."], "BITE", "PIERCING", "1/4"),
 ("GNOLL",        15, 22, 4, 1, 6, 2, 100, 53, 8, 0,    "MEDIUM HUMANOID",
  ["HYENA-FACED", "MARAUDERS OF THE", "OPEN DUNES."], "SPEAR", "PIERCING", "1/2"),
 ("MUMMY",        11, 58, 5, 2, 6, 3, 700, 57, 0, 2,    "MEDIUM UNDEAD",
  ["A PRIEST-KING", "WHO WAKES TO", "GUARD HIS TOMB."], "ROTTING FIST", "BLUDGEONING", "3"),
 ("GIANT FROG",   11, 18, 3, 1, 6, 1,  50, 61, 0, 0,    "MEDIUM BEAST",
  ["ITS TONGUE SNAPS", "FROM THE REEDS", "WITHOUT WARNING."], "BITE", "PIERCING", "1/4"),
 ("ZOMBIE",        8, 22, 3, 1, 6, 1,  50, 65, 2, 0,    "MEDIUM UNDEAD",
  ["SLOW, TIRELESS,", "AND ALWAYS", "HUNGRY."], "SLAM", "BLUDGEONING", "1/4"),
 ("LIZARDFOLK",   15, 22, 4, 1, 6, 2, 100, 69, 6, 0,    "MEDIUM HUMANOID",
  ["COLD-EYED HUNTERS", "OF THE DEEP", "MARSH."], "SPEAR", "PIERCING", "1/2"),
 ("GIANT TOAD",   11, 39, 4, 1,10, 2, 200, 61, 0, 8,    "LARGE BEAST",
  ["SO BIG IT CAN", "SWALLOW A MAN", "WHOLE."], "BITE", "PIERCING", "1"),
 ("WINTER WOLF",  13, 75, 6, 2, 6, 4, 700, 41, 0, 4,    "LARGE MONSTER",
  ["A WHITE BEAST", "THAT SPEAKS AND", "BREATHES FROST."], "BITE", "PIERCING", "3"),
]
NPC_BASE = 16   # types 16+ are townsfolk
NPCS = [("ELDER", 73), ("MERCHANT", 77), ("GUARD", 81), ("INNKEEPER", 77)]
T = {m[0]: i + 1 for i, m in enumerate(M)}

# zone -> (monster list for respawning rooms, boss, palette slot per type)
ZONE_MON = {
    1: (["GOBLIN", "WOLF", "GOBLIN"], "GIANT SPIDER"),
    2: (["GIANT LIZARD", "GNOLL", "SKELETON"], "MUMMY"),
    3: (["WOLF", "SKELETON", "GIANT BAT"], "WINTER WOLF"),
    4: (["GIANT FROG", "ZOMBIE", "LIZARDFOLK"], "GIANT TOAD"),
    5: (["SKELETON", "GIANT BAT", "ZOMBIE"], "OGRE"),
}

# zone level bands (levels 1-720)
ZONE_LV = {0: (1, 1), 1: (1, 25), 2: (25, 100), 3: (100, 250), 4: (250, 450), 5: (450, 720)}
ZONE_SHORT = ["OAKHOLLOW", "WHISPERWOOD", "SUNSCAR", "FROSTFANG", "MIREFEN", "OLD CRYPT"]

# ---------------------------------------------------------------- world ---
# room: (name/zone, grid x, grid y, flags)  flags: 1 town(safe), 2 boss, 4 locked
ROOMS = [(0, 3, 3, 1)]
for i in range(3):
    ROOMS.append((1, 2 - i, 3, 2 if i == 2 else 0))   # forest west
for i in range(3):
    ROOMS.append((2, 4 + i, 3, 2 if i == 2 else 0))   # desert east
for i in range(3):
    ROOMS.append((3, 3, 2 - i, 2 if i == 2 else 0))   # tundra north
for i in range(3):
    ROOMS.append((4, 3, 4 + i, 2 if i == 2 else 0))   # swamp south
for i in range(3):
    ROOMS.append((5, 4 + i, 6, (4 if i == 0 else 0) | (2 if i == 2 else 0)))  # crypt
pos = {(r[1], r[2]): i for i, r in enumerate(ROOMS)}

def links(i):
    _, x, y, _ = ROOMS[i]
    g = lambda dx, dy: pos.get((x + dx, y + dy), 255)
    return [g(0, -1), g(0, 1), g(-1, 0), g(1, 0)]   # N S W E

TOWN = [
"########....########",
"#,,,,..........,,,,#",
"#.######....######.#",
"#.######....######.#",
"#.######....######.#",
"#..................#",
"#..o............o..#",
"....................",
"....................",
"....................",
"#..o............o..#",
"#.######....######.#",
"#.######....######.#",
"#.######....######.#",
"#,~~,..........,,,,#",
"#,~~,..........,,,,#",
"########....########",
]

def gen_room(i, rng):
    zone, x, y, flags = ROOMS[i]
    if zone == 0:
        return [[CH[c] for c in row] for row in TOWN]
    g = [[FLOOR] * R_W for _ in range(R_H)]
    for r in range(R_H):
        for c in range(R_W):
            if r in (0, R_H - 1) or c in (0, R_W - 1):
                g[r][c] = WALL
    n, s, w, e = links(i)
    if n != 255:
        for c in range(8, 12): g[0][c] = FLOOR
    if s != 255:
        for c in range(8, 12): g[R_H - 1][c] = FLOOR
    if w != 255:
        for r in range(7, 10): g[r][0] = FLOOR
    if e != 255:
        for r in range(7, 10): g[r][R_W - 1] = FLOOR
    lane = lambda r, c: (6 <= r <= 10) or (7 <= c <= 12)
    def free(r, c, h, wd):
        for rr in range(r - 1, r + h + 1):
            for cc in range(c - 1, c + wd + 1):
                if not (1 <= rr < R_H - 1 and 1 <= cc < R_W - 1): return False
                if g[rr][cc] != FLOOR or lane(rr, cc): return False
        return True
    boss = flags & 2
    n_obst = 4 if boss else 7
    # 2x2 obstacles
    for _ in range(80):
        if n_obst == 0: break
        r, c = rng.randrange(1, R_H - 3), rng.randrange(1, R_W - 3)
        if free(r, c, 2, 2):
            for rr in range(2):
                for cc in range(2): g[r + rr][c + cc] = OBST
            n_obst -= 1
    # hazard pools
    for _ in range(40 if not boss else 0):
        r, c = rng.randrange(1, R_H - 3), rng.randrange(1, R_W - 5)
        if free(r, c, 2, 4):
            for rr in range(2):
                for cc in range(4): g[r + rr][c + cc] = HAZ
            break
    # props and floor detail
    for _ in range(5):
        r, c = rng.randrange(1, R_H - 1), rng.randrange(1, R_W - 1)
        if free(r, c, 1, 1): g[r][c] = PROP
    for _ in range(18):
        r, c = rng.randrange(1, R_H - 1), rng.randrange(1, R_W - 1)
        if g[r][c] == FLOOR: g[r][c] = FLOOR2
    return g

def solid(g, px, py):
    if py < 8: return True
    r, c = (py - 8) // 8, px // 8
    if r >= R_H or c >= R_W: return True
    return g[r][c] >= WALL

def box_ok(g, x, y):
    return not any(solid(g, x + dx, y + dy) for dx in (2, 13) for dy in (8, 15))

def spawns(i, g, rng):
    zone, x, y, flags = ROOMS[i]
    out = []
    if zone == 0:
        for k, (nm, tile) in enumerate(NPCS):
            sx, sy = [(32, 40), (112, 40), (32, 72), (112, 72)][k]
            out.append((NPC_BASE + k, sx, sy, [1, 2, 3, 7][k]))
        return out
    mons, boss = ZONE_MON[zone]
    pick = list(mons)
    if flags & 2:
        pick = [boss, mons[0], mons[1]]
    for k, name in enumerate(pick):
        for _ in range(400):
            sx, sy = rng.randrange(16, 128, 4), rng.randrange(16, 112, 4)
            if not box_ok(g, sx, sy): continue
            if abs(sx - 72) < 40 and abs(sy - 60) < 28 and not (flags & 2 and k == 0): continue
            if any(abs(sx - o[1]) < 20 and abs(sy - o[2]) < 20 for o in out): continue
            if flags & 2 and k == 0:
                sx, sy = 72, 56
                if not box_ok(g, sx, sy): continue
            pal = 7 if (flags & 2 and k == 0) else 1 + mons.index(name)
            out.append((T[name], sx, sy, pal))
            break
    return out

rng = random.Random(1987)
maps = [gen_room(i, rng) for i in range(len(ROOMS))]
assert box_ok(maps[0], 72, 56)
spawn_tab = [spawns(i, maps[i], rng) for i in range(len(ROOMS))]

# ----------------------------------------------------------------- emit ---
L = ["; AUTO-GENERATED by gen_world.py - do not edit", ""]
def db(vals):
    return "    db " + ", ".join(str(v) for v in vals)
def s(txt):
    return f'"{txt}", $FF'

L.append(f"DEF NUM_ROOMS EQU {len(ROOMS)}")
L.append(f"DEF NUM_MONSTERS EQU {len(M)}")
L.append(f"DEF NPC_BASE EQU {NPC_BASE}")
L.append(f"DEF MONSTER_STRIDE EQU 12")
for name, i in T.items():
    L.append(f"DEF TYPE_{name.replace(' ', '_')} EQU {i}")
L.append("")
L.append('SECTION "RoomMaps", ROMX, BANK[2]')
L.append("RoomMaps:")
L.append("    dw " + ", ".join(f"RoomMap{i}" for i in range(len(ROOMS))))
for i, g in enumerate(maps):
    L.append(f"RoomMap{i}:")
    for row in g:
        L.append(db(row))
L.append("")
L.append('SECTION "WorldData", ROMX, BANK[1]')
L.append("; N, S, W, E, zone, flags, mapx, mapy")
L.append("RoomInfo:")
for i, (zone, x, y, flags) in enumerate(ROOMS):
    L.append(db(links(i) + [zone, flags, x, y]))
L.append("; 4 spawns per room: type, x, y, palette")
L.append("SpawnTable:")
for sp in spawn_tab:
    row = []
    for k in range(4):
        row += list(sp[k]) if k < len(sp) else [0, 0, 0, 0]
    L.append(db(row))
L.append("; AC HP ATK DN DS DB XPlo XPhi TILE GOLD FLAGS pad")
L.append("MonsterStats:")
for m in M:
    L.append(db([m[1], m[2], m[3], m[4], m[5], m[6], m[7] & 255, m[7] >> 8, m[8], m[9], m[10], 0]))
for nm, tile in NPCS:   # NPC "stats": only the tile matters
    pass
L.append("NpcTiles:")
L.append(db([t for _, t in NPCS]))
L.append("ZoneNames:")
L.append("    dw " + ", ".join(f"StrZone{i}" for i in range(len(ZONES))))
for i, z in enumerate(ZONES):
    L.append(f"StrZone{i}: db {s(z)}")
L.append("; base monster level per room (bosses use it exactly)")
L.append("RoomLevels:")
lv=[]
for i, (zone, x, y, flags) in enumerate(ROOMS):
    lo, hi = ZONE_LV[zone]
    k = [j for j, r in enumerate(ROOMS) if r[0] == zone].index(i)
    lv.append(hi if flags & 2 else lo + (hi - lo) * k // 3)
L.append("    dw " + ", ".join(str(v) for v in lv))
L.append("ZoneBanners:")
L.append("    dw " + ", ".join(f"StrBanner{i}" for i in range(len(ZONES))))
for i, z in enumerate(ZONE_SHORT):
    lo, hi = ZONE_LV[i]
    t = z if i == 0 else f"{z} {lo}-{hi}"
    assert len(t) <= 18, t
    L.append(f"StrBanner{i}: db {s(t)}")
L.append("MonsterNames:")
L.append("    dw " + ", ".join(f"StrMon{i}" for i in range(len(M))))
for i, m in enumerate(M):
    L.append(f"StrMon{i}: db {s(m[0])}")
L.append("BeastPages:")
L.append("    dw " + ", ".join(f"BeastPage{i}" for i in range(len(M))))
for i, m in enumerate(M):
    name, ac, hp, atk, dn, ds, dbn, xp, tile, gold, flags, kind, lore, weapon, dtype, cr = m
    lines = [
        (2, 2, name), (2, 3, kind),
        (2, 5, f"AC {ac:<4}HP {hp}"), (2, 6, f"CR {cr:<4}XP {xp}"),
        (2, 8, f"{weapon} +{atk}"), (2, 9, f"{dn}D{ds}+{dbn} {dtype}"),
        (2, 11, lore[0]), (2, 12, lore[1]), (2, 13, lore[2]),
    ]
    L.append(f"BeastPage{i}:")
    for k, (c, r, t) in enumerate(lines):
        assert len(t) <= 17, t
        L.append(f"    db {c}, {r}")
        L.append(f"    dw .s{k}")
    L.append("    db $FF")
    for k, (c, r, t) in enumerate(lines):
        L.append(f".s{k}: db {s(t)}")
# world map: room cell positions on the window
L.append("; world map cell (col,row) per room")
L.append("MapCells:")
cells = []
for zone, x, y, flags in ROOMS:
    cells += [4 + x * 2, 3 + y * 2]
L.append(db(cells))
open("world.inc", "w").write("\n".join(L) + "\n")
print("rooms", len(ROOMS), "monsters", len(M))
for i, sp in enumerate(spawn_tab):
    if len(sp) < 3 and ROOMS[i][0] != 0:
        print("WARN room", i, "only", len(sp), "spawns")
