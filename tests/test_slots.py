# Boot logo, loading screen, 5 save slots, load from title.
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
w = lambda n: m(n) + 256 * m(n, 1)
def setm(n, v, o=0): pb.memory[sym[n] + o] = v
def run(n):
    for _ in range(n): pb.tick()
def tap(b, f=14):
    pb.button_press(b); run(3); pb.button_release(b); run(f)
def shot(name):
    pb.screen.image.convert("RGB").resize((320, 288), 0).save(f"shots/sl_{name}.png")
run(330); shot("0_boot_logo")
run(260); shot("1_title")
tap("start", 20); shot("2_loading"); run(40); tap("a", 30); tap("down"); tap("down"); tap("a", 40); tap("a", 30)  # wizard
setm("wGold", 77)
setm("wPauseCur", 6); tap("start", 20); tap("a", 30); shot("3_save_slots")
tap("down"); tap("down"); tap("a", 40); shot("4_saved_slot3"); tap("a", 20)
print("saved slot3: class", m("wClass"), "gold", m("wGold"))
pb.stop()
pb = boot()
run(600); tap("start", 30); shot("5_title_choice"); tap("a", 30); shot("6_load_slots")
tap("down"); tap("down"); tap("a", 90); shot("7_loaded")
print("loaded: class", m("wClass"), "gold", m("wGold"), "state", m("wGameState"), "slot", m("wSlot"))
pb.stop()
