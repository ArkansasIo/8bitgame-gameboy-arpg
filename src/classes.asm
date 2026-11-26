; ============================================================================
;  CLASSES - class select, ability modifiers, derived stats, character sheet
;  Fighter / Rogue / Wizard / Cleric built on SRD 5.1 rules.
; ============================================================================
SECTION "Classes", ROMX, BANK[1]

; ---- class select (new game) ---------------------------------------------
OpenClassSelect:
    call EnterMenuState
    ld a, M_CLASS
    ld [wMenu], a
    xor a
    ld [wClassCur], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 18
    call DrawBox
    ld hl, StrChooseClass
    ld b, 2
    ld c, 1
    call WinPrint
    ld c, 0
.names:
    push bc
    ld a, c
    add a, a
    ld e, a
    ld d, 0
    ld hl, ClassNames
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, c
    add a, a
    add a, 3
    ld c, a
    ld b, 3
    call WinPrint
    pop bc
    inc c
    ld a, c
    cp 4
    jr nz, .names
    call ClassSelectRefresh
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

ClassSelectRefresh:
    ld b, 2
    ld c, 3
    ld d, 4
    ld a, [wClassCur]
    ld e, a
    ld a, T_CUR
    call DrawListCursor
    ld b, 1                      ; clear description rows 12-16
    ld c, 12
    ld d, 18
.clr:
    xor a
    push bc
    call WinFillRow
    pop bc
    inc c
    ld a, c
    cp 17
    jr nz, .clr
    ld a, [wClassCur]
    add a, a
    ld e, a
    ld d, 0
    ld hl, ClassDescs
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call WinPrintList
    ret

MenuClass:
    ld hl, wClassCur
    ld b, 4
    call ListNav
    jp c, ClassSelectRefresh
    ldh a, [hNewKeys]
    and PAD_A | PAD_START
    ret z
    call SfxPickup
    ld a, [wClassCur]
    ld [wClass], a
    call ApplyClass
    jp OpenIntro

GetClassRow:                     ; a = class -> hl = ClassTable row (16 bytes)
    swap a
    ld e, a
    ld d, 0
    ld hl, ClassTable
    add hl, de
    ret

; ---- set up a fresh character of class wClass -----------------------------
ApplyClass:
    ld a, [wClass]
    call GetClassRow
    ld de, 6
    add hl, de
    ld a, [hl+]
    ld [wWeapon], a
    ld a, [hl+]
    ld [wArmor], a
    ld a, [hl+]
    ld [wCastMod], a
    ld a, [hl+]
    ld [wSkill1], a
    ld a, [hl+]
    ld [wSkill2], a
    ld a, [hl]
    ld [wBAction], a
    ld hl, wInv                  ; starting bag: weapon, armor, 2 potions
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
    ld a, [wClass]
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
StrHitDie: db "HIT DIE D", $FF
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
