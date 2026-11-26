# Phase 2 test: class select, merchant shop, bag, skills, status, fire bolt.
from pyboy import PyBoy
sym = {}
for line in open("game.sym"):
    p = line.split()
    if len(p) == 2 and ":" in p[0]:
        sym[p[1]] = int(p[0].split(":")[1], 16)
pb = PyBoy("dungeon_quest.gb", window="null", sound_emulated=False, cgb=True)
pb.set_emulation_speed(0)
m = lambda n, o=0: pb.memory[sym[n] + o]
def setm(n, v, o=0): pb.memory[sym[n] + o] = v
def run(n):
    for _ in range(n): pb.tick()
def tap(b, w=12):
    pb.button_press(b); run(3); pb.button_release(b); run(w)
def shot(name):
    pb.screen.image.convert("RGB").resize((320, 288), 0).save(f"shots/s_{name}.png")
run(420); tap("start", 30)
tap("down"); tap("down"); shot("01_class_wizard")
tap("a", 40); shot("02_intro"); tap("a", 30)
print("class", m("wClass"), "hp", m("wHP"), "ac", m("wAC"), "atk", m("wAtk"), "spell", m("wSpellAtk"), "slots", m("wSlots"))
setm("wGold", 244); setm("wGold", 1, 1)   # 500 gold
setm("wPlayerX", 112); setm("wPlayerY", 57); tap("up", 6)
tap("a", 30); shot("03_merchant_dialog")
tap("a", 30); shot("04_shop")
tap("a", 30); shot("05_buy_list")
tap("down"); tap("a", 20); shot("06_bought")
tap("a", 20); tap("b", 20); tap("b", 20)
tap("start", 20); tap("down"); tap("a", 30); shot("07_bag")
tap("a", 20); shot("08_bag_sub"); tap("b", 20); tap("b", 20)
tap("down"); tap("a", 30); shot("09_skills")
tap("b", 20); tap("up"); tap("up"); tap("a", 30); shot("10_status")
tap("b", 20); tap("b", 20)
setm("wPlayerX", 4); setm("wPlayerY", 56); pb.button_press("left"); run(6); pb.button_release("left"); run(30)
setm("wPlayerDir", 3); tap("b", 3); run(4); shot("11_firebolt")
run(30); print("room", m("wRoom"), "enemies hp", [m("wEnemies", i*16+3) for i in range(4)], "msg", m("wMsgT"))
pb.stop()
