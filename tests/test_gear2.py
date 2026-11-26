# Uniques/aspects, set bonus, smith upgrade.
exec(open("tests/test_gear.py").read().split("run(600)")[0])
run(600); tap("start", 40); tap("a", 30); tap("a", 40); tap("a", 30)      # fighter
atk0, arm0 = w("wATK"), w("wDEF")
# equip EMBERHEART (unique 0: longsword, legendary, aspect EMBERS) at ilvl 100, +0
for k, v in enumerate([3, 4, 100, 0, 0, 11, 16, 0x40]): setm("wEquip", v, k)
# two IRONWARD set pieces (set 0): great helm (base 19) head slot 2, platemail (base 25) chest slot 3
for k, v in enumerate([20, 6, 100, 0, 0, 13, 0, 0x80]): setm("wEquip", v, 2 * 8 + k)
for k, v in enumerate([26, 6, 100, 0, 0, 14, 0, 0x80]): setm("wEquip", v, 3 * 8 + k)
setm("wPauseCur", 0); tap("start", 20); tap("a", 30); tap("b", 20)   # sheet -> recalc
print("ATK", atk0, "->", w("wATK"), "ARM", arm0, "->", w("wDEF"), "aspects", bin(m("wAspects")), "sets", m("wSetCount"), "PWR", w("wPowerLvl"))
setm("wPauseCur", 1); tap("a", 30); tap("right", 30); shot("6_worn_unique"); tap("b", 20); tap("b", 20)
# smith: gold + ore
setw("wGold", 999)
for k, v in enumerate([20, 9]): setm("wInv", v, 4 + k)
setm("wPlayerX", 112); setm("wPlayerY", 57); setm("wPlayerDir", 1); run(2)
tap("a", 30); tap("a", 30); tap("down"); tap("down"); tap("a", 30); shot("7_smith")
tap("a", 30); tap("a", 30); shot("8_smith_after")
print("main upgrade", m("wEquip", 4), "gold", w("wGold"), "ore slot", m("wInv", 4), m("wInv", 5), "ATK", w("wATK"))
pb.stop()
