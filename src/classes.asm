; ============================================================================
;  CLASSES - class select, ability modifiers, derived stats, character sheet
;  Fighter / Rogue / Wizard / Cleric built on SRD 5.1 rules.
; ============================================================================
SECTION "Classes", ROM0

; ---- character creation: race, then class -----------------------------------
OpenClassSelect:                 ; (new game) starts with the race screen
    call EnterMenuState
    xor a
    ld [wRaceCur], a
    ld [wClassCur], a
    ld [wClassTop], a
OpenRaceSelect:
    ld a, M_RACE
    ld [wMenu], a
    call DrawRaceSelect
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

CreateFrame:                     ; hl = title
    push hl
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 12
    call DrawBox
    ld b, 0
    ld c, 12
    ld d, 20
    ld e, 6
    call DrawBox
    pop hl
    ld b, 2
    ld c, 1
    jp WinPrint

DrawRaceSelect:
    ld hl, StrChooseRace
    call CreateFrame
    ld c, 0
.n:
    push bc
    ld a, c
    ld hl, RaceNames
    call TableWord
    pop bc
    push bc
    ld a, c
    add a, 2
    ld c, a
    ld b, 3
    call WinPrint
    pop bc
    inc c
    ld a, c
    cp NUM_RACES
    jr nz, .n
RaceRefresh:
    ld a, [wRaceCur]
    ld [wTmpSel], a
    ld a, NUM_RACES
    ld b, 2
    call CursorColumn
    call ClearDesc
    ld a, [wRaceCur]
    ld hl, RaceDescs
    call TableWord
    jp WinPrintList

ClearDesc:                       ; rows 13-16 inside the lower box
    ld c, 13
.l:
    ld b, 1
    ld d, 18
    xor a
    push bc
    call WinFillRow
    pop bc
    inc c
    ld a, c
    cp 17
    jr nz, .l
    ret

; single-step cursor at col 2: a = rows, b = first row, wTmpSel = selected row
CursorColumn:
    ld d, a
    ld c, b
    ld e, 0
.l:
    ld a, [wTmpSel]
    cp e
    ld a, T_BLANK
    jr nz, .p
    ld a, T_CUR
.p:
    ld b, 2
    call WinPutTile
    inc c
    inc e
    ld a, e
    cp d
    jr nz, .l
    ret

MenuRace:
    ld hl, wRaceCur
    ld b, NUM_RACES
    call ListNav
    jp c, RaceRefresh
    ldh a, [hNewKeys]
    and PAD_A | PAD_START
    ret z
    call SfxMenu
    ld a, [wRaceCur]
    ld [wRace], a
    ld a, M_CLASS
    ld [wMenu], a
    call DrawClassSelect
    jp ShowFresh

; class list: 18 entries, 9 visible (rows 2-10), scrolling
DrawClassSelect:
    ld hl, StrChooseClass
    call CreateFrame
    ld a, [wClassCur]
    ld b, a
    ld a, [wClassTop]
    cp b
    jr c, .s1
    jr z, .s1
    ld a, b
    ld [wClassTop], a
.s1:
    ld a, [wClassTop]
    add a, 8
    cp b
    jr nc, .s2
    ld a, b
    sub 8
    ld [wClassTop], a
.s2:
    ld c, 0
.n:
    push bc
    ld a, [wClassTop]
    add a, c
    ld hl, ClassNames
    call TableWord
    pop bc
    push bc
    ld a, c
    add a, 2
    ld c, a
    ld b, 3
    call WinPrint
    pop bc
    inc c
    ld a, c
    cp 9
    jr nz, .n
    ld hl, StrClassCount
    ld b, 16
    ld c, 10
    call WinPrint
ClassRefresh:
    ld a, [wClassTop]
    ld b, a
    ld a, [wClassCur]
    sub b
    ld [wTmpSel], a
    ld a, 9
    ld b, 2
    call CursorColumn
    call ClearDesc
    ld a, [wClassCur]
    ld hl, ClassDescs
    call TableWord
    jp WinPrintList

MenuClass:
    ld hl, wClassCur
    ld b, NUM_CLASSES
    call ListNav
    jr nc, .nm
    ld a, [wClassCur]            ; still on screen? just move the cursor
    ld b, a
    ld a, [wClassTop]
    cp b
    jr z, .inView
    jr nc, .redraw
.inView:
    add a, 8
    cp b
    jr c, .redraw
    jp ClassRefresh
.redraw:
    call DrawClassSelect
    jp ShowFresh
.nm:
    ldh a, [hNewKeys]
    and PAD_B
    jr z, .nb
    call SfxMenu
    jp OpenRaceSelect
.nb:
    ldh a, [hNewKeys]
    and PAD_A | PAD_START
    ret z
    call SfxPickup
    ld a, [wClassCur]
    ld [wClass], a
    call ApplyClass
    jp OpenIntro

GetClassRow:                     ; a = class -> hl = ClassTable row (16 bytes)
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld de, ClassTable
    add hl, de
    ret

SetClassArch:                    ; wClassArch from the class table
    ld a, [wClass]
    call GetClassRow
    ld a, [hl]
    ld [wClassArch], a
    ret

; ---- set up a fresh character of race wRace + class wClass -----------------------
ApplyClass:
    call SetClassArch
    ld a, [wClass]
    call GetClassRow
    inc hl
    inc hl
    inc hl                       ; skip arch + kit
    ld a, [hl+]
    ld [wSkill1], a
    ld a, [hl+]
    ld [wSkill2], a
    ld a, [hl+]
    ld [wBAction], a
    ld a, [hl]
    ld [wCastMod], a
    ld hl, wInv                  ; bag: 2 potions
    ld bc, INV_SLOTS * 2
    xor a
    call Memset
    call GiveStartingGear
    ld a, ITEM_POTION
    call InvAdd
    ld a, ITEM_POTION
    call InvAdd
    ld a, 1
    ld [wCharge1], a
    ld [wCharge2], a
    xor a
    ld [wSurgeT], a
    ld [wShieldT], a
    ld [wDodge], a
    ld [wPoison], a
    ld [wDashT], a
    ld [wCastCD], a
    ld [wMPRegenT], a
    call InitAttributes
    jp LoadClassGfx

; hero tiles 0-11 + palette for the current class
LoadClassGfx:
    call LCDOff
    ld a, [wClassArch]
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl                   ; *64
    ld d, h
    ld e, l
    add hl, hl                   ; *128
    add hl, de                   ; *192
    ld de, ClassTiles
    add hl, de
    ld de, $8000
    ld bc, 192
    ld a, BANK_GFX
    call FarCopy                 ; (must run from ROM0)
    call LoadPalettes
    jp LCDOn

GetItem:                         ; a = item id -> hl = ItemTable row (8 bytes)
    dec a
    add a, a
    add a, a
    add a, a
    ld e, a
    ld d, 0
    ld hl, ItemTable
    add hl, de
    ret

WinPutItemName:                  ; a = item id (0 = NONE) at b,c
    and a
    ld hl, StrNone
    jp z, WinPrint
    dec a
    add a, a
    ld e, a
    ld d, 0
    ld hl, ItemNames
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp WinPrint

StrChooseClass: db "CHOOSE YOUR CLASS", $FF
StrChooseRace:  db "CHOOSE YOUR RACE", $FF
StrClassCount:  db "18", $FF
StrACl:  db "AC", $FF
StrSTR:  db "STR", $FF
StrDEX:  db "DEX", $FF
StrINT:  db "INT", $FF
StrPRF:  db "PRF", $FF
StrATK:  db "ATK", $FF
StrDMG:  db "DMG", $FF
StrWPN:  db "WPN", $FF
StrARM:  db "ARM", $FF
StrGoldL: db "G", $FF
StrNone: db "NONE", $FF
