; ============================================================================
;  INVENTORY - 10-slot bag, stacking consumables, equipment, rarity tiers
; ============================================================================
SECTION "Inventory", ROMX, BANK[1]

; a = item id -> carry set if the bag is full. preserves nothing important
InvAdd:
    ld [wTmpItem], a
    call GetItem
    ld a, [hl]                   ; type
    and a
    jr nz, .newSlot              ; gear never stacks
    ld hl, wInv                  ; stack consumables
    ld b, INV_SLOTS
.find:
    ld a, [wTmpItem]
    cp [hl]
    jr nz, .nf
    inc hl
    ld a, [hl]
    cp MAX_ITEM
    jr nc, .full
    inc [hl]
    or a
    ret
.nf:
    inc hl
    inc hl
    dec b
    jr nz, .find
.newSlot:
    ld hl, wInv
    ld b, INV_SLOTS
.empty:
    ld a, [hl]
    and a
    jr z, .put
    inc hl
    inc hl
    dec b
    jr nz, .empty
.full:
    scf
    ret
.put:
    ld a, [wTmpItem]
    ld [hl+], a
    ld [hl], 1
    or a
    ret

; a = slot index: remove one; empty slots are closed up
InvRemove:
    add a, a
    ld e, a
    ld d, 0
    ld hl, wInv
    add hl, de
    inc hl
    dec [hl]
    ret nz
    dec hl
    ld d, h                      ; shift the rest down
    ld e, l
    inc hl
    inc hl
.sh:
    ld a, l
    cp LOW(wInv + INV_SLOTS * 2)
    jr z, .last
    ld a, [hl+]
    ld [de], a
    inc de
    jr .sh
.last:
    xor a
    ld [de], a
    inc de
    ld [de], a
    ret

InvCount:                        ; a = used slots
    ld hl, wInv
    ld b, INV_SLOTS
    ld c, 0
.l:
    ld a, [hl]
    and a
    jr z, .done
    inc c
    inc hl
    inc hl
    dec b
    jr nz, .l
.done:
    ld a, c
    ret

InvSlotPtr:                      ; a = slot -> hl = &wInv[slot]
    add a, a
    ld e, a
    ld d, 0
    ld hl, wInv
    add hl, de
    ret

IsEquipped:                      ; a = item id -> z if equipped
    ld b, a
    ld a, [wWeapon]
    cp b
    ret z
    ld a, [wArmor]
    cp b
    ret

; ---- bag menu ----------------------------------------------------------------
OpenItems:
    ld a, M_ITEMS
    ld [wMenu], a
    call InvClampCursor
    call DrawBag
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

InvClampCursor:
    call InvCount
    and a
    jr z, .zero
    ld b, a
    ld a, [wInvCur]
    cp b
    jr c, .ok
    ld a, b
    dec a
    ld [wInvCur], a
.ok:
    ret
.zero:
    xor a
    ld [wInvCur], a
    ret

DrawBag:
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 13
    call DrawBox
    ld b, 0
    ld c, 13
    ld d, 20
    ld e, 5
    call DrawBox
    ld hl, StrBag
    ld b, 2
    ld c, 1
    call WinPrint
    ; scroll so the cursor is visible (5 rows)
    ld a, [wInvCur]
    ld b, a
    ld a, [wInvTop]
    cp b
    jr c, .t1
    jr z, .t1
    ld a, b
    ld [wInvTop], a
.t1:
    ld a, [wInvTop]
    add a, 4
    cp b
    jr nc, .t2
    ld a, b
    sub 4
    ld [wInvTop], a
.t2:
    xor a
    ld [wTmp + 1], a             ; visible row
.row:
    ld a, [wInvTop]
    ld b, a
    ld a, [wTmp + 1]
    add a, b
    cp INV_SLOTS
    jr nc, .rowsDone
    ld [wTmp], a
    call InvSlotPtr
    ld a, [hl+]
    and a
    jr z, .rowsDone
    ld [wTmpItem], a
    ld a, [hl]
    ld [wTmpCount], a
    ld a, [wTmp + 1]
    add a, a
    add a, 3
    ld c, a
    ld b, 2
    ld a, [wTmpItem]
    push bc
    call WinPutItemName
    pop bc
    ld a, [wTmpItem]
    call IsEquipped
    jr nz, .notEq
    ld a, "E"
    ld b, 17
    call WinPutTile
    jr .nextRow
.notEq:
    ld a, [wTmpItem]
    call GetItem
    ld a, [hl]
    and a
    jr nz, .nextRow
    ld a, "*"
    ld b, 15
    call WinPutTile
    ld a, [wTmpCount]
    add a, T_DIGIT0
    ld b, 16
    call WinPutTile
.nextRow:
    ld hl, wTmp + 1
    inc [hl]
    ld a, [hl]
    cp 5
    jr c, .row
.rowsDone:
    call InvCount
    and a
    jr nz, .some
    ld hl, StrEmptyBag
    ld b, 2
    ld c, 3
    call WinPrint
    jr .gold
.some:
    call BagCursor
    ld a, [wInvCur]
    call InvSlotPtr
    ld a, [hl]
    ld b, 1
    ld c, 14
    call WinPutItemInfo
.gold:
    ld hl, StrGoldL
    ld b, 1
    ld c, 16
    call WinPrint
    ld a, [wGold]
    ld e, a
    ld a, [wGold + 1]
    ld d, a
    call Num16ToStr
    ld hl, wNumBuf
    ld b, 3
    ld c, 16
    jp WinPrint

BagCursor:                       ; a = tile
    ld a, [wInvTop]
    ld b, a
    ld a, [wInvCur]
    sub b
    ld e, a
    ld b, 1
    ld c, 3
    ld d, 5
    ld a, T_CUR
    jp DrawListCursor

; a = item id: "RARITY  1D8+1" / "RARITY  AC 16" / "HEAL 2D4+2" at b,c
WinPutItemInfo:
    ld [wTmpItem], a
    call GetItem
    push hl
    inc hl
    ld a, [hl]                   ; rarity
    add a, a
    ld e, a
    ld d, 0
    ld hl, RarityNames
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push bc
    call WinPrint
    pop bc
    pop hl
    ld a, b
    add a, 10
    ld b, a
    ld a, [hl]                   ; type
    push hl
    ld de, 4
    add hl, de
    ld d, h
    ld e, l
    pop hl
    and a
    jr z, .potion
    cp 2
    jr z, .armor
    ld a, [de]                   ; weapon: NdS+M
    add a, T_DIGIT0
    call WinPutTile
    inc b
    ld a, "D"
    call WinPutTile
    inc b
    inc de
    ld a, [de]
    push de
    call Dec2
    ld a, d
    and a
    jr z, .oneDigit
    call WinPutTile
    inc b
.oneDigit:
    ld a, e
    call WinPutTile
    inc b
    pop de
    inc de
    ld a, [de]
    and a
    ret z
    push af
    ld a, "+"
    call WinPutTile
    inc b
    pop af
    add a, T_DIGIT0
    jp WinPutTile
.armor:
    ld a, "A"
    call WinPutTile
    inc b
    ld a, "C"
    call WinPutTile
    inc b
    inc b
    ld a, [de]                   ; base AC
    ld h, a
    inc de
    inc de
    ld a, [de]                   ; + magic bonus
    add a, h
    jp WinPutNum2
.potion:
    ld a, "H"
    call WinPutTile
    inc b
    ld a, "P"
    call WinPutTile
    inc b
    ld a, [de]
    and a
    jr z, .dice
    ld a, "*"                    ; full heal
    inc b
    jp WinPutTile
.dice:
    inc b
    inc de
    ld a, [de]
    add a, T_DIGIT0
    call WinPutTile
    inc b
    ld a, "D"
    call WinPutTile
    inc b
    inc de
    ld a, [de]
    add a, T_DIGIT0
    jp WinPutTile

MenuItems:
    call InvCount
    and a
    jr z, .onlyBack
    ld b, a
    ld hl, wInvCur
    call ListNav
    jr nc, .noMove
    jp DrawBag
.noMove:
    ldh a, [hNewKeys]
    and PAD_A
    jr nz, OpenItemSub
.onlyBack:
    ldh a, [hNewKeys]
    and PAD_B
    ret z
    call SfxMenu
    jp ReturnToPause

OpenItemSub:
    call SfxMenu
    ld a, M_ITEMSUB
    ld [wMenu], a
    xor a
    ld [wSubCur], a
    call BagCursorHollow
    ld b, 0
    ld c, 13
    ld d, 20
    ld e, 5
    call DrawBox
    ld a, [wInvCur]
    call InvSlotPtr
    ld a, [hl]
    call GetItem
    ld a, [hl]
    and a
    ld hl, StrUse
    jr z, .p
    ld hl, StrEquip
.p:
    ld b, 3
    ld c, 15
    call WinPrint
    ld hl, StrToss
    ld b, 11
    ld c, 15
    call WinPrint
    jp SubCursor

BagCursorHollow:
    ld a, [wInvTop]
    ld b, a
    ld a, [wInvCur]
    sub b
    ld e, a
    ld b, 1
    ld c, 3
    ld d, 5
    ld a, T_CURH
    jp DrawListCursor

SubCursor:                       ; two choices on row 15 (cols 2 / 10)
    ld c, 15
    ld b, 2
    xor a
    call WinPutTile
    ld b, 10
    xor a
    call WinPutTile
    ld b, 2
    ld a, [wSubCur]
    and a
    jr z, .put
    ld b, 10
.put:
    ld a, T_CUR
    jp WinPutTile

MenuItemSub:
    ldh a, [hNewKeys]
    and $F0
    jr z, .noMove
    ld a, [wSubCur]
    xor 1
    ld [wSubCur], a
    call SfxMenu
    jp SubCursor
.noMove:
    ldh a, [hNewKeys]
    and PAD_B
    jr z, .notB
    call SfxMenu
    ld a, M_ITEMS
    ld [wMenu], a
    jp DrawBag
.notB:
    ldh a, [hNewKeys]
    and PAD_A
    ret z
    call SfxMenu
    ld a, [wInvCur]
    call InvSlotPtr
    ld a, [hl]
    ld [wTmpItem], a
    ld a, [wSubCur]
    and a
    jr nz, .toss
    ld a, [wTmpItem]
    call GetItem
    ld a, [hl]
    and a
    jr z, .use
    cp 1                         ; equip weapon / armor
    ld a, [wTmpItem]
    jr nz, .eqArmor
    ld [wWeapon], a
    jr .equipped
.eqArmor:
    ld [wArmor], a
.equipped:
    call RecalcStats
    ld hl, StrEquipped
    ld de, StrEmpty
    jr .msg
.toss:
    ld a, [wTmpItem]
    call IsEquipped
    ld hl, StrCantToss
    ld de, StrEmpty
    jr z, .msg
    ld a, [wInvCur]
    call InvRemove
    call InvClampCursor
    ld hl, StrTossed
    ld de, StrEmpty
    jr .msg
.use:                            ; potions
    ld a, [wMaxHP]
    ld b, a
    ld a, [wHP]
    cp b
    ld hl, StrHpFull
    ld de, StrEmpty
    jr nc, .msg
    ld a, [wTmpItem]
    call GetItem
    ld de, 4
    add hl, de
    ld a, [hl+]
    and a
    jr z, .dice
    ld a, 99
    jr .heal
.dice:
    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    ld c, a
    call RollDice
    add a, [hl]
.heal:
    call HealPlayer
    ld a, [wInvCur]
    call InvRemove
    call InvClampCursor
    ld hl, StrUsedItem
    ld de, StrRecovered
.msg:
    ld bc, BackToBag
    jp ShowPanelMsg

BackToBag:
    ld a, M_ITEMS
    ld [wMenu], a
    jp DrawBag

; hl = line 1, de = line 2, bc = handler when dismissed (bottom panel, rows 13-17)
ShowPanelMsg:
    ld a, c
    ld [wMsgBack], a
    ld a, b
    ld [wMsgBack + 1], a
    push de
    push hl
    ld a, M_BOXMSG
    ld [wMenu], a
    ld b, 0
    ld c, 13
    ld d, 20
    ld e, 5
    call DrawBox
    pop hl
    ld b, 1
    ld c, 14
    call WinPrint
    pop hl
    ld b, 1
    ld c, 16
    jp WinPrint

HealPlayer:                      ; a = amount (capped at max HP)
    ld b, a
    ld a, [wHP]
    add a, b
    jr c, .cap
    ld b, a
    ld a, [wMaxHP]
    cp b
    jr c, .cap
    ld a, b
    ld [wHP], a
    jp SfxPickup
.cap:
    ld a, [wMaxHP]
    ld [wHP], a
    jp SfxPickup

StrBag:       db "BAG", $FF
StrEmptyBag:  db "EMPTY", $FF
StrEquip:     db "EQUIP", $FF
StrEquipped:  db "EQUIPPED!", $FF
StrCantToss:  db "IT IS EQUIPPED.", $FF
StrUsedItem:  db "YOU DRINK IT.", $FF
