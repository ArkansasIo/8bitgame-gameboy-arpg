# Buff/debuff engine: Action Surge buffs, monster debuffs + DoT, fire bolt burn.
from pyboy import PyBoy
sym = {}
for line in open("game.sym"):
    p = line.split()
    if len(p) == 2 and ":" in p[0]:
        sym[p[1]] = int(p[0].split(":")[1], 16)
def boot():
    pb = PyBoy("arpg_gb_quest.gb", window="null", sound_emulated=False, cgb=True)
    pb.set_emulation_speed(0); return pb
pb = boot()
m = lambda n, o=0: pb.memory[sym[n] + o]
w = lambda n, o=0: m(n, o) + 256 * m(n, o + 1)
def setm(n, v, o=0): pb.memory[sym[n] + o] = v
def setw(n, v): setm(n, v & 255); setm(n, v >> 8, 1)
def run(n):
    for _ in range(n): pb.tick()
def tap(b, f=14):
    pb.button_press(b); run(3); pb.button_release(b); run(f)
def shot(name):
    pb.screen.image.convert("RGB").resize((320, 288), 0).save(f"shots/fx_{name}.png")
run(600); tap("start", 40); tap("a", 40); tap("a", 30)            # fighter
setm("wPauseCur", 2); tap("start", 20); tap("a", 30); tap("down"); tap("a", 30)   # Action Surge
print("buffs power", m("wBuffPower"), "haste", m("wBuffHaste"), "atkTime", m("wAtkTime"))
tap("a", 20); tap("b", 20); tap("b", 20); run(10); shot("1_hud_buffs")
# forest: let goblins hit us
setm("wPlayerX", 4); setm("wPlayerY", 56); pb.button_press("left"); run(6); pb.button_release("left"); run(5)
setm("wSRes", 0)
got = None
for k in range(1500):
    if m("wHP", 1) == 0 and m("wHP") < 120: setw("wHP", 200)
    if m("wGameState") != 1: break
    for i in range(4):
        t = m("wEnemies", i * 32)
        if t and t < 16:
            setm("wPlayerX", m("wEnemies", i * 32 + 1)); setm("wPlayerY", m("wEnemies", i * 32 + 2) + 6); break
    setm("wSRes", 0)
    run(1)
    if m("wDebPoison") and got is None:
        got = k; hp0 = w("wHP"); run(130); hp1 = w("wHP")
        print("poisoned at frame", k, "power", w("wPoisonPwr"), "HP", hp0, "->", hp1, "secs left", m("wDebPoison"))
        shot("2_poisoned"); break
print("debuff seen:", got is not None)
pb.stop()
# wizard fire bolt -> burn on monster
pb = boot()
run(600); tap("start", 40); tap("down"); tap("down"); tap("a", 40); tap("a", 30)
setw("wHP", 9999); setw("wMaxHP", 9999)
setm("wPlayerX", 4); setm("wPlayerY", 56); pb.button_press("left"); run(6); pb.button_release("left"); run(5)
burned = False
for k in range(60):
    setw("wHP", 9999)
    for i in range(4):
        t = m("wEnemies", i * 32)
        if t and t < 16:
            ex, ey = m("wEnemies", i * 32 + 1), m("wEnemies", i * 32 + 2)
            setm("wPlayerX", (ex + 40) % 140); setm("wPlayerY", ey); setm("wPlayerDir", 2); setm("wCastCD", 0)
            pb.button_press("b"); run(2); pb.button_release("b"); run(14)
            if m("wEnemies", i * 32 + 18):
                print("monster burning: type", t, "dot secs", m("wEnemies", i * 32 + 18), "pwr", w("wEnemies", i * 32 + 19)); burned = True
            break
    if burned: break
print("burn applied:", burned)
pb.stop()
