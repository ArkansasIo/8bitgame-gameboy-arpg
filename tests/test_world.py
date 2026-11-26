# Phase 1 world test: walks the hub and every zone, screenshots each.
import sys
from pyboy import PyBoy
sym = {}
for line in open("game.sym"):
    p = line.split()
    if len(p) == 2 and ":" in p[0]:
        sym[p[1]] = int(p[0].split(":")[1], 16)
pb = PyBoy("arpg_gb_quest.gb", window="null", sound_emulated=False, cgb=True)
pb.set_emulation_speed(0)
m = lambda n, o=0: pb.memory[sym[n] + o]
def setm(n, v, o=0): pb.memory[sym[n] + o] = v
def run(n):
    for _ in range(n): pb.tick()
def tap(b, w=12):
    pb.button_press(b); run(3); pb.button_release(b); run(w)
def hold(b, n):
    pb.button_press(b); run(n); pb.button_release(b); run(1)
def shot(name):
    pb.screen.image.convert("RGB").resize((320, 288), 0).save(f"shots/w_{name}.png")
EDGE = {"left": (4, 56), "right": (140, 56), "up": (72, 6), "down": (72, 124)}
def go(d):
    setm("wPlayerInv", 90)
    x, y = EDGE[d]
    setm("wPlayerX", x); setm("wPlayerY", y); hold(d, 6); run(4)
run(420); tap("start", 30); tap("a", 30); tap("a", 40); tap("a", 20)
shot("00_town"); print("room", m("wRoom"), "zone", m("wZone"))
for path, name in [("left", "forest"), ("right", "back"), ("right", "desert"), ("left", "back2"),
                   ("up", "tundra"), ("down", "back3"), ("down", "swamp"), ("down", "swamp2"),
                   ("down", "swamp3")]:
    go(path); run(20); shot(f"{len(name)}_{name}")
    print(name, "room", m("wRoom"), "zone", m("wZone"), "enemies", [pb.memory[sym['wEnemies'] + i*32] for i in range(4)])
# try sealed crypt (east of swamp3)
go("right"); run(10); shot("sealed"); print("sealed? room", m("wRoom"))
setm("wBossFlags", 15); go("right"); run(20); shot("crypt"); print("crypt room", m("wRoom"), "zone", m("wZone"))
tap("start", 20); tap("down"); tap("down"); tap("down"); tap("a", 30); shot("map")
tap("b", 20); tap("down"); tap("a", 30); shot("bestiary")
pb.stop()
