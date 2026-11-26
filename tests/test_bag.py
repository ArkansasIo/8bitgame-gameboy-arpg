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
def tap(b, w=14):
    pb.button_press(b); run(3); pb.button_release(b); run(w)
def shot(name):
    pb.screen.image.convert("RGB").resize((320, 288), 0).save(f"shots/b_{name}.png")
run(420); tap("start", 30); tap("down"); tap("down"); tap("a", 40); tap("a", 30)
tap("start", 30); print("menu", m("wMenu")); tap("down"); tap("a", 30); print("menu", m("wMenu")); shot("1_bag")
tap("a", 20); shot("2_bagsub"); tap("b", 20); tap("b", 20)
tap("down"); tap("a", 30); print("menu", m("wMenu")); shot("3_skills")
tap("a", 20); shot("4_missile_none"); tap("a", 20); tap("b", 20); tap("b", 20)
print("state", m("wGameState"))
setm("wPlayerX", 4); setm("wPlayerY", 56); pb.button_press("left"); run(6); pb.button_release("left"); run(150)
print("room", m("wRoom"))
pb.button_press("right"); run(2); pb.button_release("right")
tap("b", 2); run(3); shot("5_firebolt"); run(40)
print("enemy hp", [m("wEnemies", i*16+3) for i in range(4)], "proj", m("wProjOn"))
pb.stop()
