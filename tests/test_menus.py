import sys
from pyboy import PyBoy

cgb = sys.argv[1] == "cgb"
tag = "cgb" if cgb else "dmg"
sym = {}
for line in open("game.sym"):
    p = line.split()
    if len(p) == 2 and ":" in p[0]:
        sym[p[1]] = int(p[0].split(":")[1], 16)

pb = PyBoy("dungeon_quest.gb", window="null", sound_emulated=False, cgb=cgb)
pb.set_emulation_speed(0)
m = lambda n, o=0: pb.memory[sym[n] + o]

def run(n):
    for _ in range(n):
        pb.tick()

def tap(b, wait=12):
    pb.button_press(b); run(3); pb.button_release(b); run(wait)

def hold(b, n):
    pb.button_press(b); run(n); pb.button_release(b); run(1)

def shot(name):
    pb.screen.image.convert("RGB").resize((480, 432), 0).save(f"shots/{tag}_{name}.png")

run(420); shot("01_title")
print("isCGB", m("wIsCGB"))
tap("start", 30); shot("02_intro")
tap("a", 20); shot("03_play")
tap("start", 20); shot("04_pause")
tap("a", 20); shot("05_status")
tap("b", 20); tap("down"); tap("a", 20); shot("06_items")
tap("a", 20); shot("07_item_sub")
tap("a", 20); shot("08_item_msg")
tap("a", 20); tap("b", 20)
tap("down"); tap("a", 20); shot("09_skills")
tap("b", 20); tap("down"); tap("a", 20); shot("10_bestiary")
tap("a", 20); shot("11_beast_page")
tap("b", 20); tap("b", 20)
tap("down"); tap("a", 20); shot("12_options")
tap("right", 20); shot("13_options_green")
tap("right", 20); tap("left", 20); tap("left", 20)
tap("b", 20); tap("b", 20); shot("14_back_to_play")

# fight with d20 rolls
def hunt(frames):
    for f in range(0, frames, 8):
        if m("wGameState") != 1:
            return
        px, py = m("wPlayerX"), m("wPlayerY")
        best = None
        for i in range(3):
            b = sym["wEnemies"] + i * 16
            if pb.memory[b]:
                ex, ey = pb.memory[b + 1], pb.memory[b + 2]
                d = abs(ex - px) + abs(ey - py)
                if best is None or d < best[0]:
                    best = (d, ex, ey)
        if not best:
            return
        d, ex, ey = best
        dx, dy = ex - px, ey - py
        btn = ("right" if dx > 0 else "left") if abs(dx) > abs(dy) else ("down" if dy > 0 else "up")
        if d < 22:
            hold(btn, 1); tap("a", 4)
        else:
            hold(btn, 8)

hunt(300); shot("15_combat")
hunt(2500)
print("state", m("wGameState"), "hp", m("wHP"), "/", m("wMaxHP"), "lvl", m("wLevel"),
      "xp", m("wXP") + 256 * m("wXP", 1), "cleared", m("wRoomsCleared"), "seen", m("wSeen"))
shot("16_after_fight")
pb.stop()
