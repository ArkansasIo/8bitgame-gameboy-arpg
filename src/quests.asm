; ============================================================================
;  QUESTS - quest givers, kill counters, rewards, quest log
;   Q0 THE FOUR SEALS  (Elder)   break the 4 zone seals, then slay the Ogre
;   Q1 WOLF PACK       (Guard)   slay 4 wolves              -> 60 G
;   Q2 GOBLIN RAIDERS  (Guard)   slay 6 goblins             -> 80 G + GR.POTION
;   Q3 RESTLESS DEAD   (Elder)   slay 5 undead              -> 120 G + LONGSWORD+1
;  state: 0 unknown, 1 active, 2 ready to turn in, 3 done
; ============================================================================
SECTION "Quests", ROMX, BANK[1]

DEF Q_MAIN   EQU 0
DEF Q_WOLVES EQU 1
DEF Q_GOBLIN EQU 2
DEF Q_UNDEAD EQU 3
DEF NUM_QUESTS EQU 4

; a = monster type killed
QuestOnKill:
    ld b, a
    cp TYPE_WOLF
    ld c, Q_WOLVES
    call z, .count
    ld a, b
    cp TYPE_GOBLIN
    ld c, Q_GOBLIN
    call z, .count
    ld a, b
    cp TYPE_SKELETON
    jr z, .undead
    cp TYPE_ZOMBIE
    jr z, .undead
    cp TYPE_MUMMY
    ret nz
.undead:
    ld c, Q_UNDEAD
.count:                          ; c = quest: bump its counter if active
    push bc
    ld hl, wQState
    ld a, l
    add a, c
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, [hl]
    cp 1
    jr nz, .done
    push hl
    ld hl, QuestGoal
    ld a, l
    add a, c
    ld l, a
    jr nc, .nc2
    inc h
.nc2:
    ld d, [hl]                   ; goal
    ld hl, wQKill
    ld a, l
    add a, c
    ld l, a
    jr nc, .nc3
    inc h
.nc3:
    inc [hl]
    ld a, [hl]
    pop hl
    cp d
    jr c, .done
    ld [hl], 2                   ; ready to turn in
    push hl
    ld hl, MsgQuest
    call SetMsg
    pop hl
    call SfxClear
.done:
    pop bc
    ret

QuestGoal: db 0, 4, 6, 5

QState:                          ; c = quest -> a = state, hl = &state
    ld hl, wQState
    ld a, l
    add a, c
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, [hl]
    ret

; ---- the Elder -----------------------------------------------------------------
TalkElder:
    ld c, Q_MAIN
    call QState
    and a
    jr nz, .started
    ld [hl], 1                   ; accept the main quest + the undead quest
    ld c, Q_UNDEAD
    call QState
    ld [hl], 1
    ld hl, DlgElderStart
    jr .say
.started:
    ld c, Q_UNDEAD
    call QState
    cp 2
    jr nz, .noReward
    ld [hl], 3
    ld de, 120
    call AddGold16
    ld a, ITEM_LONGSWORDP1
    call InvAdd
    call SfxWin
    ld hl, DlgElderReward
    jr .say
.noReward:
    ld a, [wBossFlags]
    and $0F
    cp $0F
    ld hl, DlgElderCrypt
    jr z, .say
    ld hl, DlgElderSeals
.say:
    ld de, 0
    jp OpenDialog

; ---- the Guard captain ---------------------------------------------------------
TalkGuard:
    ld c, Q_WOLVES
    call QState
    and a
    jr nz, .w1
    ld [hl], 1                   ; offer: wolves
    ld hl, DlgGuardWolves
    jr .say
.w1:
    cp 2
    jr z, .wolvesDone
    cp 3
    jr z, .goblins
    ld hl, DlgGuardWolvesWait
    jr .say
.wolvesDone:
    ld [hl], 3                   ; reward + next quest
    ld de, 60
    call AddGold16
    ld c, Q_GOBLIN
    call QState
    ld [hl], 1
    call SfxWin
    ld hl, DlgGuardWolvesDone
    jr .say
.goblins:
    ld c, Q_GOBLIN
    call QState
    cp 2
    jr z, .goblinsDone
    cp 3
    ld hl, DlgGuardIdle
    jr z, .say
    ld hl, DlgGuardGoblinWait
    jr .say
.goblinsDone:
    ld [hl], 3
    ld de, 80
    call AddGold16
    ld a, ITEM_GR_POTION
    call InvAdd
    call SfxWin
    ld hl, DlgGuardGoblinDone
.say:
    ld de, 0
    jp OpenDialog

; ---- quest log -------------------------------------------------------------------
OpenQuests:
    ld a, M_QUESTS
    ld [wMenu], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 18
    call DrawBox
    ld hl, StrQuestLog
    ld b, 2
    ld c, 1
    call WinPrint
    xor a
    ld [wTmp], a                 ; quest index
    ld a, 3
    ld [wTmp + 1], a             ; row
.q:
    ld a, [wTmp]
    ld c, a
    call QState
    and a
    jp z, .next
    ld [wTmpCount], a
    ld a, [wTmp]                 ; name
    add a, a
    ld e, a
    ld d, 0
    ld hl, QuestNames
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [wTmp + 1]
    ld c, a
    ld b, 2
    call WinPrint
    ld a, [wTmp + 1]             ; status line below
    inc a
    ld c, a
    ld b, 3
    ld a, [wTmpCount]
    cp 3
    ld hl, StrQDone
    jr z, .st
    cp 2
    ld hl, StrQTurnIn
    jr z, .st
    ld a, [wTmp]
    and a
    jr z, .main
    ld hl, StrQSlain             ; "SLAIN n/N"
    push bc
    call WinPrint
    pop bc
    ld a, [wTmp]
    ld hl, wQKill
    add a, l
    ld l, a
    jr nc, .k
    inc h
.k:
    ld a, [hl]
    ld b, 9
    call WinPutNum2
    ld a, "/"
    ld b, 11
    call WinPutTile
    ld a, [wTmp]
    ld hl, QuestGoal
    add a, l
    ld l, a
    jr nc, .g
    inc h
.g:
    ld a, [hl]
    add a, T_DIGIT0
    ld b, 12
    call WinPutTile
    jr .adv
.main:
    ld a, [wBossFlags]
    and $0F
    cp $0F
    ld hl, StrQOgre
    jr z, .st
    ld hl, StrQSeals             ; "SEALS n/4"
    push bc
    call WinPrint
    call CountCleared
    pop bc
    add a, T_DIGIT0
    ld b, 9
    call WinPutTile
    jr .adv
.st:
    call WinPrint
.adv:
    ld a, [wTmp + 1]
    add a, 3
    ld [wTmp + 1], a
.next:
    ld hl, wTmp
    inc [hl]
    ld a, [hl]
    cp NUM_QUESTS
    jp c, .q
    ld a, [wTmp + 1]
    cp 3
    jr nz, .any
    ld hl, StrNoQuests
    ld b, 2
    ld c, 3
    call WinPrint
.any:
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

MenuQuests:
    ldh a, [hNewKeys]
    and PAD_A | PAD_B | PAD_START
    ret z
    call SfxMenu
    jp ReturnToPause

QuestNames: dw StrQ0, StrQ1, StrQ2, StrQ3
StrQ0: db "THE FOUR SEALS", $FF
StrQ1: db "WOLF PACK", $FF
StrQ2: db "GOBLIN RAIDERS", $FF
StrQ3: db "RESTLESS DEAD", $FF
StrQuestLog: db "QUEST LOG", $FF
StrQDone:    db "COMPLETE", $FF
StrQTurnIn:  db "RETURN TO TOWN", $FF
StrQSlain:   db "SLAIN   /", $FF
StrQSeals:   db "SEALS  /4", $FF
StrQOgre:    db "SLAY THE OGRE!", $FF
StrNoQuests: db "TALK TO TOWNSFOLK", $FF
MsgQuest:    db "QUEST"

; ---- dialogue -------------------------------------------------------------------
DlgElderStart:
    dw .a, .b
    dw .c, .d
    dw .e, .f
    dw .g, .h
    dw 0
.a: db "AT LAST, A HERO!", $FF
.b: db "THE OGRE SEALED", $FF
.c: db "THE OLD CRYPT", $FF
.d: db "WITH FOUR SEALS.", $FF
.e: db "WOOD, DUNES, ICE,", $FF
.f: db "AND MIRE. BREAK", $FF
.g: db "THEM. AND PUT 5", $FF
.h: db "RESTLESS DEAD DOWN", $FF
DlgElderSeals:
    dw .a, .b
    dw 0
.a: db "BREAK THE SEALS:", $FF
.b: db "WOOD DUNE ICE MIRE", $FF
DlgElderCrypt:
    dw .a, .b
    dw .c, .d
    dw 0
.a: db "THE SEALS ARE GONE", $FF
.b: db "THE CRYPT OPENS", $FF
.c: db "EAST OF THE MIRE.", $FF
.d: db "END THE OGRE!", $FF
DlgElderReward:
    dw .a, .b
    dw .c, .d
    dw 0
.a: db "THE DEAD REST.", $FF
.b: db "TAKE THIS BLADE", $FF
.c: db "AND 120 GOLD.", $FF
.d: db "GOT LONGSWORD+1!", $FF
DlgGuardWolves:
    dw .a, .b
    dw .c, .d
    dw 0
.a: db "WOLVES RAID OUR", $FF
.b: db "FLOCKS. SLAY 4", $FF
.c: db "IN THE WOOD OR", $FF
.d: db "ICE. 60 GOLD!", $FF
DlgGuardWolvesWait:
    dw .a, .b
    dw 0
.a: db "THE WOLVES STILL", $FF
.b: db "HOWL. HURRY!", $FF
DlgGuardWolvesDone:
    dw .a, .b
    dw .c, .d
    dw 0
.a: db "WELL HUNTED! HERE", $FF
.b: db "IS 60 GOLD.", $FF
.c: db "NOW, 6 GOBLINS", $FF
.d: db "RAID THE WOOD...", $FF
DlgGuardGoblinWait:
    dw .a, .b
    dw 0
.a: db "6 GOBLINS. THE", $FF
.b: db "WOOD IS FULL!", $FF
DlgGuardGoblinDone:
    dw .a, .b
    dw 0
.a: db "80 GOLD AND A", $FF
.b: db "GREATER POTION!", $FF
DlgGuardIdle:
    dw .a, .b
    dw 0
.a: db "THE ROADS ARE", $FF
.b: db "SAFER. THANKS!", $FF
