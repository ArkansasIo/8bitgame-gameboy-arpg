# Phase 4 test: level 1-720 stat system, sheet, point spending, scaling monsters.
from pyboy import PyBoy
sym = {}
for line in open("game.sym"):
    p = line.split()
    if len(p) == 2 and ":" in p[0]:
        sym[p[1]] = int(p[0].split(":")[1], 16)
pb = PyBoy("arpg_gb_quest.gb", window="null", sound_emulated=False, cgb=True)
pb.set_emulation_speed(0)
m = lambda n, o=0: pb.memory[sym[n] + o]
w = lambda n: m(n) + 256 * m(n, 1)
def setm(n, v, o=0): pb.memory[sym[n] + o] = v
def setw(n, v): setm(n, v & 255); setm(n, v >> 8, 1)
def run(n):
    for _ in range(n): pb.tick()
def tap(b, f=14):
    pb.button_press(b); run(3); pb.button_release(b); run(f)
def shot(name):
    pb.screen.image.convert("RGB").resize((320, 288), 0).save(f"shots/st_{name}.png")
run(420); shot("0_title"); tap("start", 30); tap("a", 40); tap("a", 30)
print("L", w("wLevel"), "HP", w("wHP"), "/", w("wMaxHP"), "MP", w("wMP"), "ATK", w("wATK"), "DEF", w("wDEF"),
      "CRIT", m("wCrit"), "STR", w("wStr"))
shot("1_town_hud")
setw("wStatPts", 9)
setm("wPauseCur", 0); tap("start", 20); tap("a", 30); shot("2_sheet")
tap("a", 30); tap("a"); tap("a"); tap("down"); tap("a"); shot("3_alloc"); tap("b", 30)
print("after alloc STR", w("wStr"), "DEX", w("wDex"), "pts", w("wStatPts"), "ATK", w("wATK"))
tap("b", 20); tap("b", 20)
# forest: fight with an unkillable bot
setw("wHP", 9999); setw("wMaxHP", 9999)
setm("wPlayerX", 4); setm("wPlayerY", 56); pb.button_press("left"); run(6); pb.button_release("left"); run(10)
print("room", m("wRoom"), "monsters (type,lvl,hp):",
      [(m("wEnemies", i*16), m("wEnemies", i*16+13) + 256*m("wEnemies", i*16+14), m("wEnemies", i*16+3) + 256*m("wEnemies", i*16+12)) for i in range(4)])
for k in range(400):
    setw("wHP", 9999)
    px, py = m("wPlayerX"), m("wPlayerY")
    best = None
    for i in range(4):
        t = m("wEnemies", i*16)
        if t and t < 16:
            ex, ey = m("wEnemies", i*16+1), m("wEnemies", i*16+2)
            d = abs(ex-px) + abs(ey-py)
            if best is None or d < best[0]: best = (d, ex, ey)
    if not best: break
    d, ex, ey = best
    btn = ("right" if ex > px else "left") if abs(ex-px) > abs(ey-py) else ("down" if ey > py else "up")
    if d < 22: pb.button_press(btn); run(1); pb.button_release(btn); tap("a", 4)
    else: pb.button_press(btn); run(8); pb.button_release(btn)
    if k == 20: shot("4_combat")
print("after fight L", w("wLevel"), "XP", w("wXP"), "pts", w("wStatPts"), "STR", w("wStr"), "MaxHP", w("wMaxHP"))
# endgame check: jump to level 700 and recompute
setw("wLevel", 700); setw("wStr", 1500); setw("wVit", 1400); setw("wDex", 800); setw("wLck", 600)
setm("wPauseCur", 0); tap("start", 20); tap("a", 30); shot("5_sheet_lv700")
print("lv700 ATK", w("wATK"), "MaxHP", w("wMaxHP"), "DEF", w("wDEF"), "crit", m("wCrit"), "dodge", m("wDodgeP"), "block", m("wBlockP"))
pb.stop()
