# Character creation: race (9) + class (18), stats, sprite archetype, save/load.
exec(open("tests/test_gear.py").read().split("run(600)")[0])
run(600); tap("start", 40); shot("c1_race")
tap("down"); tap("down"); shot("c2_race_dwarf"); tap("a", 30)            # DWARF
for _ in range(13): tap("down", 6)
run(20); shot("c3_class_necro")                                            # NECROMANCER (13)
tap("a", 40); tap("a", 30); run(10); shot("c4_town")
print("race", m("wRace"), "class", m("wClass"), "arch", m("wClassArch"), "STR", w("wStr"), "CON", w("wCon"), "INT", w("wInt"),
      "HP", w("wMaxHP"), "MP", w("wMaxMP"), "skills", m("wSkill1"), m("wSkill2"), "B", m("wBAction"), "main", inst("wEquip", 0)[:3])
setm("wPauseCur", 0); tap("start", 20); tap("a", 30); tap("right", 30); shot("c5_sheet2"); tap("b", 20)
setm("wPauseCur", 6); tap("a", 30); tap("a", 40); tap("a", 20)              # save slot 1
pb.stop()
pb = PyBoy("arpg_gb_quest.gb", window="null", sound_emulated=False, cgb=True); pb.set_emulation_speed(0)
run(600); tap("start", 30); tap("a", 30); shot("c6_slots"); tap("a", 90)
print("after load race", m("wRace"), "class", m("wClass"), "arch", m("wClassArch"), "INT", w("wInt"))
pb.stop()
