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
    ld hl, StrHitDie             ; "HIT DIE D10"
    ld b, 2
    ld c, 16
    call WinPrint
    ld a, [wClassCur]
    call GetClassRow
    ld de, 5
    add hl, de
    ld a, [hl]
    ld b, 11
    ld c, 16
    jp WinPutNum2

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
    ld de, wSTR
    ld bc, 5
    call Memcpy                  ; STR DEX CON INT WIS
    ld a, [hl+]
    ld [wHD], a
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
    ; starting bag: weapon, armor, 2 potions
    ld hl, wInv
    ld bc, INV_SLOTS * 2
    xor a
    call Memset
    ld a, [wWeapon]
    call InvAdd
    ld a, [wArmor]
    and a
    call nz, InvAdd
    ld a, ITEM_POTION
    call InvAdd
    ld a, ITEM_POTION
    call InvAdd
    ; HP = hit die + CON
    ld a, [wHD]
    ld b, a
    ld a, [wCON]
    add a, b
    ld [wHP], a
    ld [wMaxHP], a
    ; spell slots (casters only)
    xor a
    ld [wMaxSlots], a
    ld a, [wCastMod]
    and a
    jr z, .noSlots
    ld a, 2
    ld [wMaxSlots], a
.noSlots:
    ld a, [wMaxSlots]
    ld [wSlots], a
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
    call LoadClassGfx
    jp RecalcStats

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

; ---- derived stats: AC, attack, damage ------------------------------------
RecalcStats:
    ld a, [wLevel]               ; proficiency +2 (levels 1-4), +3 at 5
    cp 5
    ld a, 2
    jr c, .p
    inc a
.p:
    ld [wProf], a
    ; weapon
    ld a, 1
    ld [wDmgN], a
    ld a, 2
    ld [wDmgS], a
    xor a
    ld [wWpnMagic], a
    ld [wWpnFlags], a
    ld a, [wWeapon]
    and a
    jr z, .noWeapon
    call GetItem
    ld de, 4
    add hl, de
    ld a, [hl+]
    ld [wDmgN], a
    ld a, [hl+]
    ld [wDmgS], a
    ld a, [hl+]
    ld [wWpnMagic], a
    ld a, [hl]
    ld [wWpnFlags], a
.noWeapon:
    ld a, [wSTR]                 ; finesse: use the better of STR / DEX
    ld b, a
    ld a, [wWpnFlags]
    and 1
    jr z, .useB
    ld a, [wDEX]
    add a, 8
    ld c, a
    ld a, b
    add a, 8
    cp c
    jr nc, .useB
    ld a, [wDEX]
    ld b, a
.useB:
    ld a, [wWpnMagic]
    add a, b
    ld [wDmgB], a
    ld b, a
    ld a, [wProf]
    add a, b
    ld [wAtk], a
    ; armor
    ld a, [wDEX]
    ld b, a
    xor a
    ld [wArmFlags], a
    ld a, [wArmor]
    and a
    jr nz, .armor
    ld a, 10
    add a, b
    ld [wAC], a
    jr .spell
.armor:
    call GetItem
    ld de, 4
    add hl, de
    ld a, [hl+]                  ; base
    ld c, a
    ld a, [hl+]                  ; dex cap
    cp b
    jr nc, .capOk
    ld b, a
.capOk:
    ld a, [hl+]                  ; magic
    add a, c
    add a, b
    ld [wAC], a
    ld a, [hl]
    ld [wArmFlags], a
.spell:
    ld a, [wCastMod]
    ld b, a
    ld a, [wProf]
    add a, b
    ld [wSpellAtk], a
    ret

GetPlayerAC:                     ; a = AC incl. Shield spell; preserves bc de hl
    ld a, [wShieldT]
    and a
    ld a, [wAC]
    ret z
    add a, 5
    ret

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

; ---- character sheet --------------------------------------------------------
OpenStatus:
    ld a, M_STATUS
    ld [wMenu], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 18
    call DrawBox
    ld a, [wClass]
    add a, a
    ld e, a
    ld d, 0
    ld hl, ClassNames
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld b, 2
    ld c, 2
    call WinPrint
    ld hl, SheetList
    call WinPrintList
    ld a, [wLevel]
    ld b, 15
    ld c, 2
    call WinPutNum2
    ld a, [wHP]
    ld b, 5
    ld c, 4
    call WinPutNum2
    ld a, [wMaxHP]
    ld b, 8
    ld c, 4
    call WinPutNum2
    call GetPlayerAC
    ld b, 15
    ld c, 4
    call WinPutNum2
    ld a, [wXP]
    ld e, a
    ld a, [wXP + 1]
    ld d, a
    call Num16ToStr
    ld hl, wNumBuf
    ld b, 5
    ld c, 5
    call WinPrint
    ld a, [wLevel]
    cp MAX_LEVEL
    jr nc, .max
    dec a
    add a, a
    ld e, a
    ld d, 0
    ld hl, LevelTable
    add hl, de
    ld a, [hl+]
    ld e, a
    ld d, [hl]
    call Num16ToStr
    ld hl, wNumBuf
    jr .next
.max:
    ld hl, StrMax
.next:
    ld b, 15
    ld c, 5
    call WinPrint
    ; ability modifiers
    ld a, [wSTR]
    ld b, 6
    ld c, 7
    call WinPutMod
    ld a, [wDEX]
    ld b, 14
    ld c, 7
    call WinPutMod
    ld a, [wCON]
    ld b, 6
    ld c, 8
    call WinPutMod
    ld a, [wINT]
    ld b, 14
    ld c, 8
    call WinPutMod
    ld a, [wWIS]
    ld b, 6
    ld c, 9
    call WinPutMod
    ld a, [wProf]
    ld b, 14
    ld c, 9
    call WinPutMod
    ld a, [wAtk]
    ld b, 6
    ld c, 11
    call WinPutMod
    ld a, [wDmgN]                ; damage: NdS
    add a, T_DIGIT0
    ld b, 14
    ld c, 11
    call WinPutTile
    ld a, "D"
    inc b
    call WinPutTile
    ld a, [wDmgS]
    inc b
    call WinPutNum2
    ld a, [wWeapon]
    ld b, 6
    ld c, 13
    call WinPutItemName
    ld a, [wArmor]
    ld b, 6
    ld c, 14
    call WinPutItemName
    call CountCleared
    add a, T_DIGIT0
    ld b, 9
    ld c, 16
    call WinPutTile
    ld a, [wGold]
    ld e, a
    ld a, [wGold + 1]
    ld d, a
    call Num16ToStr
    ld hl, wNumBuf
    ld b, 15
    ld c, 16
    call WinPrint
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

WinPutMod:                       ; a = signed modifier -> "+2" / "-1" at b,c
    bit 7, a
    jr nz, .neg
    push af
    ld a, "+"
    call WinPutTile
    pop af
    jr .digit
.neg:
    cpl
    inc a
    push af
    ld a, "-"
    call WinPutTile
    pop af
.digit:
    add a, T_DIGIT0
    inc b
    call WinPutTile
    dec b
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

SheetList:
    TXT 12, 2, StrLV
    TXT 2, 4, StrHP
    TXT 7, 4, StrSlash
    TXT 12, 4, StrACl
    TXT 2, 5, StrXPLabel
    TXT 10, 5, StrNext
    TXT 2, 7, StrSTR
    TXT 10, 7, StrDEX
    TXT 2, 8, StrCON
    TXT 10, 8, StrINT
    TXT 2, 9, StrWIS
    TXT 10, 9, StrPRF
    TXT 2, 11, StrATK
    TXT 10, 11, StrDMG
    TXT 2, 13, StrWPN
    TXT 2, 14, StrARM
    TXT 2, 16, StrRooms
    TXT 13, 16, StrGoldL
    db $FF
StrChooseClass: db "CHOOSE YOUR CLASS", $FF
StrHitDie: db "HIT DIE D", $FF
StrACl:  db "AC", $FF
StrSTR:  db "STR", $FF
StrDEX:  db "DEX", $FF
StrCON:  db "CON", $FF
StrINT:  db "INT", $FF
StrWIS:  db "WIS", $FF
StrPRF:  db "PRF", $FF
StrATK:  db "ATK", $FF
StrDMG:  db "DMG", $FF
StrWPN:  db "WPN", $FF
StrARM:  db "ARM", $FF
StrGoldL: db "G", $FF
StrNone: db "NONE", $FF
