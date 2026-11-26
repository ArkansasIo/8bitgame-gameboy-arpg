# Phase 3 test: elder + guard quests, quest log, turn-in, save, continue.
from pyboy import PyBoy
sym = {}
for line in open("game.sym"):
    p = line.split()
    if len(p) == 2 and ":" in p[0]:
        sym[p[1]] = int(p[0].split(":")[1], 16)
def boot():
    pb = PyBoy("arpg_gb_quest.gb", window="null", sound_emulated=False, cgb=True)
    pb.set_emulation_speed(0)
    return pb
pb = boot()
m = lambda n, o=0: pb.memory[sym[n] + o]
def setm(n, v, o=0): pb.memory[sym[n] + o] = v
def run(n):
    for _ in range(n): pb.tick()
def tap(b, w=14):
    pb.button_press(b); run(3); pb.button_release(b); run(w)
def shot(name):
    pb.screen.image.convert("RGB").resize((320, 288), 0).save(f"shots/q_{name}.png")
def face_up_at(x, y):
    setm("wPlayerX", x); setm("wPlayerY", y); setm("wPlayerDir", 1); run(2)
run(420); tap("start", 30); tap("a", 40); tap("a", 30)          # fighter
face_up_at(32, 57); tap("a", 30); shot("1_elder")
for _ in range(4): tap("a", 20)
print("quests", [m("wQState", i) for i in range(4)])
face_up_at(32, 89); tap("a", 30); shot("2_guard")
tap("a", 20); tap("a", 20)
setm("wQKill", 4, 1); setm("wQState", 2, 1)                       # pretend 4 wolves slain
setm("wPauseCur", 0); tap("start", 20); [tap("down") for _ in range(3)]; tap("a", 30); shot("3_questlog"); tap("b", 20); tap("b", 20)
face_up_at(32, 89); tap("a", 30); shot("4_turnin")
for _ in range(2): tap("a", 20)
print("quests", [m("wQState", i) for i in range(4)], "gold", m("wGold"))
setm("wPauseCur", 0); tap("start", 20); [tap("down") for _ in range(6)]; tap("a", 30); shot("5_saveask")
tap("a", 30); shot("6_saved"); tap("a", 20)
saved = (m("wGold"), m("wClass"), [m("wQState", i) for i in range(4)], m("wRoom"))
pb.stop()
pb = boot()
run(420); tap("start", 30); shot("7_continue_menu"); tap("a", 40); shot("8_continued")
print("saved", saved, "loaded", (m("wGold"), m("wClass"), [m("wQState", i) for i in range(4)], m("wRoom")), "state", m("wGameState"))
pb.stop()
