; ============================================================================
;  TOWN - talking to townsfolk, dialogue boxes, merchant shop, inn
; ============================================================================
SECTION "Town", ROMX, BANK[1]

; ---- who is in front of the hero? -----------------------------------------
; carry set + a = NPC type when an NPC stands in front (town only)
FindNpcInFront:
    ld a, [wRoomFlags]
    and FLAG_TOWN
    ret z
    ld a, [wPlayerDir]
    add a, a
    ld e, a
    ld d, 0
    ld hl, TalkOfs
    add hl, de
    ld a, [wPlayerX]
    add a, [hl]
    ld b, a                      ; probe x
    inc hl
    ld a, [wPlayerY]
    add a, [hl]
    ld c, a                      ; probe y
    ld hl, wEnemies
    ld e, MAX_ENEMIES
.l:
    ld a, [hl]
    cp NPC_BASE
    jr c, .next
    ld d, a
    push hl
    inc hl
    ld a, b                      ; ex <= px < ex + 16
    sub [hl]
    jr c, .no
    cp 16
    jr nc, .no
    inc hl
    ld a, c
    sub [hl]
    jr c, .no
    cp 16
    jr nc, .no
    pop hl
    ld a, d
    scf
    ret
.no:
    pop hl
.next:
    push de
    ld de, ENEMY_SIZE
    add hl, de
    pop de
    dec e
    jr nz, .l
    or a
    ret

TalkOfs: db 8, 22,  8, -4,  -4, 10,  20, 10

TalkTo:                          ; a = NPC type
    push af
    call EnterMenuState
    call SfxMenu
    pop af
    sub NPC_BASE
    ld hl, TalkHandlers
    jp JumpTable

TalkHandlers:
    dw TalkElder, TalkMerchant, TalkGuard, OpenInn

TalkMerchant:
    ld hl, DlgMerchant
    ld de, OpenShop
    jp OpenDialog

; ---- dialogue box (bottom of the screen, 2 lines per page) -----------------
; hl = pages {dw line1, dw line2}... dw 0 ; de = handler at the end (0 = close)
OpenDialog:
    ld a, l
    ld [wDlgPtr], a
    ld a, h
    ld [wDlgPtr + 1], a
    ld a, e
    ld [wDlgEnd], a
    ld a, d
    ld [wDlgEnd + 1], a
    ld a, M_DIALOG
    ld [wMenu], a
    call DrawDialogPage
    ld a, 7
    ld b, 96
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ReshowSprites

DrawDialogPage:
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 6
    call DrawBox
    ld hl, wDlgPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a
    push hl
    ld h, d
    ld l, e
    ld b, 1
    ld c, 2
    call WinPrint
    pop hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld b, 1
    ld c, 4
    call WinPrint
    ld a, T_CURH
    ld b, 18
    ld c, 4
    jp WinPutTile

MenuDialog:
    ldh a, [hNewKeys]
    and PAD_A | PAD_B
    ret z
    call SfxMenu
    ld hl, wDlgPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld de, 4
    add hl, de
    ld a, [hl+]
    or [hl]
    dec hl
    jr z, .end
    ld a, l
    ld [wDlgPtr], a
    ld a, h
    ld [wDlgPtr + 1], a
    jp DrawDialogPage
.end:
    ld a, [wDlgEnd]
    ld l, a
    ld a, [wDlgEnd + 1]
    ld h, a
    or l
    jp z, CloseMenu
    jp hl

; ---- inn: rest for 10 gold (long rest) -------------------------------------
OpenInn:
    ld a, M_INN
    ld [wMenu], a
    xor a
    ld [wSubCur], a
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 6
    call DrawBox
    ld hl, StrInnAsk
    ld b, 1
    ld c, 2
    call WinPrint
    ld hl, StrYesNo
    ld b, 3
    ld c, 4
    call WinPrint
    call InnCursor
    ld a, 7
    ld b, 96
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ReshowSprites

InnCursor:
    ld c, 4
    ld b, 2
    xor a
    call WinPutTile
    ld b, 9
    xor a
    call WinPutTile
    ld b, 2
    ld a, [wSubCur]
    and a
    jr z, .p
    ld b, 9
.p:
    ld a, T_CUR
    jp WinPutTile

MenuInn:
    ldh a, [hNewKeys]
    and $F0
    jr z, .noMove
    ld a, [wSubCur]
    xor 1
    ld [wSubCur], a
    call SfxMenu
    jp InnCursor
.noMove:
    ldh a, [hNewKeys]
    and PAD_B
    jp nz, CloseMenuSfx
    ldh a, [hNewKeys]
    and PAD_A
    ret z
    ld a, [wSubCur]
    and a
    jp nz, CloseMenuSfx
    ld de, 10
    call SpendGold
    jr c, .poor
    call LongRest
    call SfxWin
    ld hl, DlgRested
    ld de, 0
    jp OpenDialog
.poor:
    call SfxBlock
    ld hl, DlgPoor
    ld de, 0
    jp OpenDialog

LongRest:                        ; full HP / MP, class charges
    call FullRestore
    ld a, 1
    ld [wCharge1], a
    ld [wCharge2], a
    ret

; de = cost -> carry set (and nothing spent) if not enough gold
SpendGold:
    ld a, [wGold]
    sub e
    ld l, a
    ld a, [wGold + 1]
    sbc a, d
    ret c
    ld [wGold + 1], a
    ld a, l
    ld [wGold], a
    or a
    ret

; ---- merchant shop ------------------------------------------------------------
OpenShop:
    call EnterMenuState
    ld a, M_SHOP
    ld [wMenu], a
    xor a
    ld [wShopSel], a
    call DrawShopFrame
    ld hl, StrWelcome
    ld b, 2
    ld c, 3
    call WinPrint
    ld hl, StrWelcome2
    ld b, 2
    ld c, 5
    call WinPrint
    call DrawShopModes
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

DrawShopFrame:
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
    ld hl, StrMerchant
    ld b, 2
    ld c, 1
    jp WinPrint

DrawShopModes:
    ld hl, ShopModeList
    call WinPrintList
ShopModeCursor:
    ld c, 15
    ld b, 2
    xor a
    call WinPutTile
    ld b, 8
    xor a
    call WinPutTile
    ld b, 14
    xor a
    call WinPutTile
    ld a, [wShopSel]
    ld b, a
    add a, a
    add a, b
    add a, a                     ; *6
    add a, 2
    ld b, a
    ld a, T_CUR
    jp WinPutTile

MenuShop:
    ldh a, [hNewKeys]
    ld b, a
    bit 5, b
    jr z, .nl
    ld a, [wShopSel]
    and a
    ret z
    dec a
    jr .set
.nl:
    bit 4, b
    jr z, .nr
    ld a, [wShopSel]
    cp 2
    ret nc
    inc a
.set:
    ld [wShopSel], a
    call SfxMenu
    jp ShopModeCursor
.nr:
    ld a, b
    and PAD_B
    jp nz, CloseMenuSfx
    ld a, b
    and PAD_A
    ret z
    call SfxMenu
    ld a, [wShopSel]
    cp 2
    jp z, CloseMenu
    inc a
    ld [wShopMode], a            ; 1 = buy, 2 = sell
    xor a
    ld [wShopCur], a
    ld [wShopTop], a
    ld a, M_SHOPLIST
    ld [wMenu], a
    jp DrawShopList

ShopListCount:                   ; a = number of entries in the current list
    ld a, [wShopMode]
    cp 1
    jp nz, InvCount
    ld a, NUM_SHOP
    ret

ShopEntryItem:                   ; a = index -> a = item id
    ld b, a
    ld a, [wShopMode]
    cp 1
    jr nz, .sell
    ld a, b
    ld hl, ShopStock
    add a, l
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, [hl]
    ret
.sell:
    ld a, b
    call InvSlotPtr
    ld a, [hl]
    ret

ShopEntryPrice:                  ; a = item id -> de = price (half when selling)
    call GetItem
    inc hl
    inc hl
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [wShopMode]
    cp 1
    ret z
    srl d
    rr e
    ret

DrawShopList:
    call DrawShopFrame
    ld a, [wShopMode]
    cp 1
    ld hl, StrBuy
    jr z, .t
    ld hl, StrSell
.t:
    ld b, 12
    ld c, 1
    call WinPrint
    ld a, [wShopCur]             ; keep the cursor on screen (5 rows)
    ld b, a
    ld a, [wShopTop]
    cp b
    jr c, .s1
    jr z, .s1
    ld a, b
    ld [wShopTop], a
.s1:
    ld a, [wShopTop]
    add a, 4
    cp b
    jr nc, .s2
    ld a, b
    sub 4
    ld [wShopTop], a
.s2:
    xor a
    ld [wTmp + 1], a
.row:
    call ShopListCount
    ld b, a
    ld a, [wShopTop]
    ld c, a
    ld a, [wTmp + 1]
    add a, c
    cp b
    jr nc, .rowsDone
    call ShopEntryItem
    ld [wTmpItem], a
    ld a, [wTmp + 1]
    add a, a
    add a, 3
    ld c, a
    ld b, 2
    ld a, [wTmpItem]
    push bc
    call WinPutItemName
    ld a, [wTmpItem]
    call ShopEntryPrice
    call Num16ToStr
    pop bc
    ld hl, wNumBuf
    ld b, 14
    call WinPrint
    ld hl, wTmp + 1
    inc [hl]
    ld a, [hl]
    cp 5
    jr c, .row
.rowsDone:
    call ShopListCount
    and a
    jr nz, .some
    ld hl, StrEmptyBag
    ld b, 2
    ld c, 3
    call WinPrint
    jr .gold
.some:
    ld a, [wShopTop]
    ld b, a
    ld a, [wShopCur]
    sub b
    ld e, a
    ld b, 1
    ld c, 3
    ld d, 5
    ld a, T_CUR
    call DrawListCursor
    ld a, [wShopCur]
    call ShopEntryItem
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

MenuShopList:
    call ShopListCount
    and a
    jr z, .back
    ld b, a
    ld hl, wShopCur
    call ListNav
    jp c, DrawShopList
    ldh a, [hNewKeys]
    and PAD_A
    jr nz, .act
.back:
    ldh a, [hNewKeys]
    and PAD_B
    ret z
    call SfxMenu
    ld a, M_SHOP
    ld [wMenu], a
    call DrawShopFrame
    jp DrawShopModes
.act:
    ld a, [wShopCur]
    call ShopEntryItem
    ld [wTmpItem], a
    ld a, [wShopMode]
    cp 1
    jr nz, .sell
    ld a, [wTmpItem]             ; BUY
    call ShopEntryPrice
    push de
    call SpendGold
    pop de
    jr c, .poor
    push de
    ld a, [wTmpItem]
    call InvAdd
    pop de
    jr c, .full
    call SfxPickup
    ld hl, StrBought
    jr .msg
.full:
    call AddGold16               ; refund
    ld hl, StrBagFull
    jr .msg
.poor:
    call SfxBlock
    ld hl, StrPoor
    jr .msg
.sell:
    ld a, [wTmpItem]
    call IsEquipped
    ld hl, StrCantToss
    jr z, .msg
    ld a, [wTmpItem]
    call ShopEntryPrice
    call AddGold16
    ld a, [wShopCur]
    call InvRemove
    call InvCount
    and a
    jr z, .s0
    ld b, a
    ld a, [wShopCur]
    cp b
    jr c, .s0
    ld a, b
    dec a
    ld [wShopCur], a
.s0:
    call SfxPickup
    ld hl, StrSold
.msg:
    ld de, StrEmpty
    ld bc, BackToShopList
    jp ShowPanelMsg

BackToShopList:
    ld a, M_SHOPLIST
    ld [wMenu], a
    jp DrawShopList

AddGold16:                       ; de = amount, capped at 999
    ld hl, wGold
    ld a, [hl]
    add a, e
    ld [hl+], a
    ld a, [hl]
    adc a, d
    ld [hl], a
    jp ClampGold

ShopModeList:
    TXT 3, 15, StrBuy
    TXT 9, 15, StrSell
    TXT 15, 15, StrExitW
    db $FF

; ---- dialogue text -------------------------------------------------------------
DlgMerchant:
    dw .a, .b
    dw 0
.a: db "BLADES, MAIL AND", $FF
.b: db "POTIONS. LOOK!", $FF
DlgRested:
    dw .a, .b
    dw 0
.a: db "YOU SLEEP WELL.", $FF
.b: db "HP + SPELLS BACK!", $FF
DlgPoor:
    dw .a, .b
    dw 0
.a: db "NO COIN, NO BED.", $FF
.b: db "COME BACK LATER.", $FF

StrInnAsk:   db "REST FOR 10 GOLD?", $FF
StrYesNo:    db "YES    NO", $FF
StrWelcome:  db "WELCOME, HERO!", $FF
StrWelcome2: db "WHAT DO YOU NEED?", $FF
StrMerchant: db "MERCHANT", $FF
StrBuy:      db "BUY", $FF
StrSell:     db "SELL", $FF
StrExitW:    db "EXIT", $FF
StrBought:   db "BOUGHT IT!", $FF
StrSold:     db "SOLD!", $FF
StrPoor:     db "NOT ENOUGH GOLD.", $FF
StrBagFull:  db "YOUR BAG IS FULL.", $FF
