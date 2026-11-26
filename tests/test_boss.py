from pyboy import PyBoy
sym = {}
for line in open("game.sym"):
    p = line.split()
    if len(p) == 2 and ":" in p[0]:
        sym[p[1]] = int(p[0].split(":")[1], 16)
pb = PyBoy("dungeon_quest.gb", window="null", sound_emulated=False, cgb=True)
pb.set_emulation_speed(0)
m = lambda n, o=0: pb.memory[sym[n] + o]
def setm(n, v): pb.memory[sym[n]] = v
def run(n):
    for _ in range(n): pb.tick()
def tap(b, w=12):
    pb.button_press(b); run(3); pb.button_release(b); run(w)
def hold(b, n):
    pb.button_press(b); run(n); pb.button_release(b); run(1)
def shot(name):
    pb.screen.image.convert("RGB").resize((480, 432), 0).save(f"shots/boss_{name}.png")
def goto(tx, ty, frames=800):
    for _ in range(frames // 4):
        px, py = m("wPlayerX"), m("wPlayerY")
        if abs(px - tx) < 2 and abs(py - ty) < 2: return
        if abs(px - tx) >= 2: hold("right" if tx > px else "left", 4)
        else: hold("down" if ty > py else "up", 4)
def hunt(frames):
    for f in range(0, frames, 8):
        if m("wGameState") != 1: return
        setm("wHP", 99); setm("wPlayerInv", 60)  # god mode for the test bot
        px, py = m("wPlayerX"), m("wPlayerY")
        best = None
        for i in range(3):
            b = sym["wEnemies"] + i * 16
            if pb.memory[b]:
                ex, ey = pb.memory[b + 1], pb.memory[b + 2]
                d = abs(ex - px) + abs(ey - py)
                if best is None or d < best[0]: best = (d, ex, ey)
        if not best: return
        d, ex, ey = best
        dx, dy = ex - px, ey - py
        btn = ("right" if dx > 0 else "left") if abs(dx) > abs(dy) else ("down" if dy > 0 else "up")
        if d < 22: hold(btn, 1); tap("a", 4)
        else: hold(btn, 8)

run(420); tap("start", 30); tap("a", 20)
setm("wRoomsCleared", 7)        # pretend rooms 0-2 are done
setm("wXP", 0x90); setm("wXP", 0x90)
pb.memory[sym["wXP"]] = 400 & 255; pb.memory[sym["wXP"] + 1] = 400 >> 8
# room 0 still has goblins loaded; walk out the south door to room 2 (cleared), then east
setm("wPlayerX", 72); setm("wPlayerY", 124); hold("down", 6); run(10)
print("room", m("wRoom"))
setm("wPlayerX", 140); setm("wPlayerY", 56); hold("right", 6); run(10)
print("room", m("wRoom"), "enemies", [pb.memory[sym["wEnemies"] + i*16] for i in range(3)])
shot("01_crypt")
hunt(600); shot("02_fight")
hunt(6000)
print("state", m("wGameState"), "lvl", m("wLevel"), "hp", m("wHP"), "/", m("wMaxHP"),
      "xp", m("wXP") + 256 * m("wXP", 1), "cleared", m("wRoomsCleared"))
run(30); shot("03_end")
tap("start", 30); tap("down"); tap("down"); tap("down")
pb.stop()
