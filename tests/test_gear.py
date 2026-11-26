# Gear: starting kit, drops, pickup, equip, worn/bag tabs, smith upgrade, salvage.
from pyboy import PyBoy
sym = {}
for line in open("game.sym"):
    p = line.split()
    if len(p) == 2 and ":" in p[0]:
        sym[p[1]] = int(p[0].split(":")[1], 16)
pb = PyBoy("arpg_gb_quest.gb", window="null", sound_emulated=False, cgb=True)
pb.set_emulation_speed(0)
m = lambda n, o=0: pb.memory[sym[n] + o]
w = lambda n, o=0: m(n, o) + 256 * m(n, o + 1)
def setm(n, v, o=0): pb.memory[sym[n] + o] = v
def setw(n, v, o=0): setm(n, v & 255, o); setm(n, v >> 8, o + 1)
def run(n):
    for _ in range(n): pb.tick()
def tap(b, f=14):
    pb.button_press(b); run(3); pb.button_release(b); run(f)
def shot(name):
    pb.screen.image.convert("RGB").resize((320, 288), 0).save(f"shots/g_{name}.png")
def inst(base, i): return [m(base, i * 8 + k) for k in range(8)]
run(600); tap("start", 40); tap("a", 40); tap("a", 30)      # fighter
print("worn main", inst("wEquip", 0), "chest", inst("wEquip", 3), "ATK", w("wATK"), "ARM", w("wDEF"), "PWR", w("wPowerLvl"))
# forest, huge luck -> gear drops; invulnerable bot collects
setw("wLck", 6000); setw("wHP", 9999); setw("wMaxHP", 9999)
setm("wPlayerX", 4); setm("wPlayerY", 56); pb.button_press("left"); run(6); pb.button_release("left"); run(5)
for k in range(900):
    setw("wHP", 9999)
    if m("wPickupOn"):
        setm("wPlayerX", m("wPickupX")); setm("wPlayerY", m("wPickupY")); run(2); continue
    px, py = m("wPlayerX"), m("wPlayerY"); best = None
    for i in range(4):
        t = m("wEnemies", i * 32)
        if t and t < 16:
            ex, ey = m("wEnemies", i * 32 + 1), m("wEnemies", i * 32 + 2)
            d = abs(ex - px) + abs(ey - py)
            if best is None or d < best[0]: best = (d, ex, ey)
    if not best: break
    d, ex, ey = best
    btn = ("right" if ex > px else "left") if abs(ex - px) > abs(ey - py) else ("down" if ey > py else "up")
    if d < 22: pb.button_press(btn); run(1); pb.button_release(btn); tap("a", 4)
    else: pb.button_press(btn); run(8); pb.button_release(btn)
bag = [inst("wGear", i) for i in range(20) if m("wGear", i * 8)]
print("bag items:", len(bag), bag[:4])
setw("wLck", 6)
setm("wPauseCur", 1); tap("start", 20); tap("a", 30); shot("1_gear_tab")
atk0 = w("wATK")
tap("a", 20); shot("2_equip_sub"); tap("a", 30); shot("3_after_equip")
print("after equip ATK", atk0, "->", w("wATK"), "PWR", w("wPowerLvl"), "worn main", inst("wEquip", 0))
tap("right", 30); shot("4_worn_tab"); tap("right", 30); shot("5_items_tab"); tap("right", 30)
tap("b", 20); tap("b", 20)
pb.stop()
