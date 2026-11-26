; ============================================================================
;  SAVE - battery-backed SRAM save slot (MBC5), continue from the title
; ============================================================================
SECTION "Save", ROMX, BANK[1]

DEF SRAM_BASE EQU $A000
DEF SAVE_VERSION EQU 2

; persistent RAM blocks: dw address, db length
SaveMap:
    dw wLevel
    db 26
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

SaveGame:
    call SramOn
    ld de, SRAM_BASE
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
HasSave:                         ; nz if a valid save exists
    call SramOn
    call CheckSave
    push af
    call SramOff
    pop af
    ret

CheckSave:                       ; (SRAM on) -> nz if valid
    ld hl, SRAM_BASE
    ld a, [hl+]
    cp "D"
    jr nz, .bad
    ld a, [hl+]
    cp "Q"
    jr nz, .bad
    ld a, [hl+]
    cp SAVE_VERSION
    jr nz, .bad
    ld de, SaveMap               ; total length = sum of block sizes
    ld b, 0
.len:
    ld a, [de]
    inc de
    ld c, a
    ld a, [de]
    inc de
    or c
    jr z, .sum
    ld a, [de]
    inc de
    add a, b
    ld b, a
    jr .len
.sum:
    ld c, 0
.s:
    ld a, [hl+]
    add a, c
    ld c, a
    dec b
    jr nz, .s
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
    ld de, SRAM_BASE + 3
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
    call RecalcStats
    call LoadClassGfx
    call RecalcStats
    ld a, STATE_PLAY
    ld [wGameState], a
    call BuildHUD
    ld a, 1
    ld [wHudOn], a
    jp LoadRoom

; ---- pause menu: SAVE -------------------------------------------------------
OpenSaveAsk:
    ld a, M_SAVEASK
    ld [wMenu], a
    xor a
    ld [wSubCur], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 6
    call DrawBox
    ld hl, StrSaveAsk
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

MenuSaveAsk:
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
    jr nz, .back
    ldh a, [hNewKeys]
    and PAD_A
    ret z
    ld a, [wSubCur]
    and a
    jr nz, .back
    call SaveGame
    call SfxWin
    ld hl, DlgSaved
    ld de, 0
    jp OpenDialog
.back:
    call SfxMenu
    jp ReturnToPause

DlgSaved:
    dw .a, .b
    dw 0
.a: db "YOUR JOURNEY HAS", $FF
.b: db "BEEN SAVED.", $FF
StrSaveAsk: db "SAVE YOUR GAME?", $FF
