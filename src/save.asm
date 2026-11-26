; ============================================================================
;  SAVE - battery-backed SRAM save slot (MBC5), continue from the title
; ============================================================================
SECTION "Save", ROM0

DEF SRAM_BASE EQU $A000
DEF SAVE_VERSION EQU 4

; persistent RAM blocks: dw address, db length
SaveMap:
    dw wLevel
    db 34
    dw wClass
    db 13
    dw wCharge1
    db 2
    dw wRoom
    db 3
    dw wBossFlags
    db 3
    dw wInv
    db INV_SLOTS * 2
    dw wQState
    db NUM_QUESTS * 2
    dw wPalSet
    db 2
    dw wPlayerX
    db 2
    dw wEquip
    db NUM_GEAR_SLOTS * 8
    dw wGear
    db GEAR_BAG * 8
    dw 0

SramOn:
    ld a, $0A
    ld [rRAMG], a
    xor a
    ld [$4000], a                ; RAM bank 0
    ret

SramOff:
    xor a
    ld [rRAMG], a
    ret

DEF NUM_SLOTS EQU 5

SlotBase:                        ; hl = de = $A000 + slot * $100
    ld a, [wSlot]
    add a, a                     ; 512 bytes per slot
    add a, HIGH(SRAM_BASE)
    ld h, a
    ld d, a
    ld l, 0
    ld e, 0
    ret

SaveGame:
    call SramOn
    call SlotBase
    ld a, "D"
    ld [de], a
    inc de
    ld a, "Q"
    ld [de], a
    inc de
    ld a, SAVE_VERSION
    ld [de], a
    inc de
    ld c, 0                      ; checksum
    ld hl, SaveMap
.block:
    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    or b
    jr z, .end
    ld a, [hl+]                  ; length
    push hl
    dec hl
    dec hl
    push af
    ld a, [hl-]
    ld l, [hl]
    ld h, a                      ; hl = source
    pop af
    ld b, a
.copy:
    ld a, [hl+]
    ld [de], a
    inc de
    add a, c
    ld c, a
    dec b
    jr nz, .copy
    pop hl
    jr .block
.end:
    ld a, c
    ld [de], a
    jp SramOff

; carry clear + data restored if a valid save exists. hl = SaveMap walk
HasSave:                         ; nz if any slot holds a valid save
    ld a, [wSlot]
    push af
    ld c, NUM_SLOTS
.l:
    ld a, c
    dec a
    ld [wSlot], a
    push bc
    call SlotValid
    pop bc
    jr nz, .yes
    dec c
    jr nz, .l
    pop af
    ld [wSlot], a
    xor a
    ret
.yes:
    pop af
    ld [wSlot], a
    or 1
    ret

SlotValid:                       ; nz if slot wSlot is valid
    call SramOn
    call CheckSave
    push af
    call SramOff
    pop af
    ret

CheckSave:                       ; (SRAM on) -> nz if valid
    call SlotBase
    ld a, [hl+]
    cp "D"
    jr nz, .bad
    ld a, [hl+]
    cp "Q"
    jr nz, .bad
    ld a, [hl+]
    cp SAVE_VERSION
    jr nz, .bad
    ld de, SaveMap               ; checksum block by block
    ld c, 0
.blk:
    ld a, [de]
    inc de
    ld b, a
    ld a, [de]
    inc de
    or b
    jr z, .sumDone
    ld a, [de]
    inc de
    ld b, a
.s:
    ld a, [hl+]
    add a, c
    ld c, a
    dec b
    jr nz, .s
    jr .blk
.sumDone:
    ld a, [hl]
    cp c
    jr nz, .bad
    or 1
    ret
.bad:
    xor a
    ret

LoadGame:                        ; restore every block from SRAM
    call SramOn
    call SlotBase
    inc e
    inc e
    inc e
    ld hl, SaveMap
.block:
    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    or b
    jr z, .end
    ld a, [hl+]
    push hl
    dec hl
    dec hl
    push af
    ld a, [hl-]
    ld l, [hl]
    ld h, a                      ; hl = destination
    pop af
    ld b, a
.copy:
    ld a, [de]
    inc de
    ld [hl+], a
    dec b
    jr nz, .copy
    pop hl
    jr .block
.end:
    jp SramOff

; continue: rebuild the session from the restored data
ContinueGame:
    call LoadGame
    xor a
    ld [wAttack], a
    ld [wPlayerInv], a
    ld [wKnockT], a
    ld [wPickupOn], a
    ld [wMsgT], a
    ld [wBannerT], a
    ld [wPauseCur], a
    ld [wInvCur], a
    ld [wInvTop], a
    ld [wSkillCur], a
    ld [wBeastCur], a
    ld [wBeastPage], a
    ld [wProjOn], a
    ld [wSurgeT], a
    ld [wShieldT], a
    ld [wDodge], a
    ld [wPoison], a
    ld [wDashT], a
    ld [wCastCD], a
    ld [wPlayerDir], a
    ld a, $FF
    ld [wLoadedZone], a
    call ClearEffects
    call RecalcStats
    call LoadClassGfx
    call RecalcStats
    ld a, STATE_PLAY
    ld [wGameState], a
    call BuildHUD
    ld a, 1
    ld [wHudOn], a
    jp LoadRoom

; ---- save / load slot screen ------------------------------------------------
OpenSaveAsk:                     ; pause menu SAVE
    xor a
OpenSlots:                       ; a = mode (0 save, 1 load)
    ld [wSlotMode], a
    ld a, M_SAVEASK
    ld [wMenu], a
    call DrawSlots
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

DrawSlots:
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 18
    call DrawBox
    ld a, [wSlotMode]
    and a
    ld hl, StrSaveTitle
    jr z, .t
    ld hl, StrLoadTitle
.t:
    ld b, 2
    ld c, 1
    call WinPrint
    ld a, [wSlot]
    push af
    xor a
.slot:
    ld [wSlot], a
    add a, a
    add a, 3
    ld c, a
    ld b, 2
    ld a, [wSlot]
    add a, T_DIGIT0 + 1
    call WinPutTile
    push bc
    call SlotValid
    pop bc
    ld hl, StrEmptySlot
    jr z, .empty
    call SramOn                  ; class + level from the slot
    call SlotBase
    ld a, l
    add a, 3 + 34
    ld l, a
    ld a, [hl]
    ld [wTmp], a
    call SlotBase
    inc l
    inc l
    inc l
    ld a, [hl+]
    ld [wTmpW], a
    ld a, [hl]
    ld [wTmpW + 1], a
    call SramOff
    push bc
    ld a, [wTmp]
    and 3
    add a, a
    ld e, a
    ld d, 0
    ld hl, ClassNames
    add hl, de
    call LoadW
    ld b, 4
    call WinPrint
    pop bc
    push bc
    ld hl, StrLV
    ld b, 12
    call WinPrint
    pop bc
    ld hl, wTmpW
    ld b, 14
    call PutWord
    jr .next
.empty:
    ld b, 4
    call WinPrint
.next:
    ld a, [wSlot]
    inc a
    cp NUM_SLOTS
    jr c, .slot
    pop af
    ld [wSlot], a
    ld hl, StrSlotHint
    ld b, 2
    ld c, 15
    call WinPrint
    jp SlotCursor

SlotCursor:
    ld b, 1
    ld c, 3
    ld d, NUM_SLOTS
    ld a, [wSlotCur]
    ld e, a
    ld a, T_CUR
    jp DrawListCursor

; shared input: a = 0 nothing, 1 chose a slot (wSlotCur), 2 back
SlotsInput:
    ld hl, wSlotCur
    ld b, NUM_SLOTS
    call ListNav
    jr nc, .nm
    call SlotCursor
    xor a
    ret
.nm:
    ldh a, [hNewKeys]
    and PAD_B
    ld a, 2
    ret nz
    ldh a, [hNewKeys]
    and PAD_A
    ret z                        ; a = 0
    ld a, 1
    ret

MenuSaveAsk:                     ; pause-menu slot screen (save mode)
    call SlotsInput
    and a
    ret z
    cp 2
    jr z, .back
    ld a, [wSlotCur]
    ld [wSlot], a
    call SaveGame
    call SfxWin
    call DrawSlots
    ld hl, DlgSaved
    ld de, 0
    jp OpenDialog
.back:
    call SfxMenu
    jp ReturnToPause

; title screen: pick a slot to load. -> carry set if a game was loaded
TitleLoad:
    call ClearOAM
    ld a, 1
    ld [wSlotMode], a
    call DrawSlots
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
.loop:
    call WaitVBlank
    call ReadJoypad
    call SlotsInput
    and a
    jr z, .loop
    cp 2
    jr z, .back
    ld a, [wSlotCur]
    ld [wSlot], a
    call SlotValid
    jr nz, .go
    call SfxBlock
    jr .loop
.go:
    call SfxPickup
    call ShowLoading
    call ContinueGame
    scf
    ret
.back:
    call SfxMenu
    or a
    ret

; ---- loading screen ---------------------------------------------------------
ShowLoading:
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 18
    call DrawBox
    ld hl, StrLoading
    ld b, 4
    ld c, 8
    call WinPrint
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    call ClearOAM
    ld a, 0
    ld [wTmp], a
.dots:
    ld b, 8
.w:
    push bc
    call WaitVBlank
    pop bc
    dec b
    jr nz, .w
    ld a, [wTmp]
    add a, 16
    ld b, a
    ld c, 8
    ld a, "."
    call WinPutTile
    ld hl, wTmp
    inc [hl]
    ld a, [hl]
    cp 3
    jr c, .dots
    xor a
    ld [wWinOn], a
    ret

StrSaveTitle: db "SAVE GAME", $FF
StrLoadTitle: db "LOAD GAME", $FF
StrEmptySlot: db "- EMPTY -", $FF
StrSlotHint:  db "A: OK   B: BACK", $FF
StrLoading:   db "NOW LOADING", $FF
DlgSaved:
    dw .a, .b
    dw 0
.a: db "YOUR JOURNEY HAS", $FF
.b: db "BEEN SAVED.", $FF
