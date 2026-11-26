; ============================================================================
;  DUNGEON QUEST - a tiny action RPG for Game Boy / Game Boy Color
;  Assembler: RGBDS 0.9+   (rgbasm / rgblink / rgbfix)
;
;  * GBC-enhanced: full color on Game Boy Color / GBA / GBA SP,
;    falls back to 4-shade grey on the original Game Boy.
;  * Window menus (START): STATUS, ITEMS, SKILLS, BESTIARY, OPTIONS,
;    RETIRE, EXIT - with nested sub-menus and message boxes.
;  * D&D 5e rules (SRD 5.1, CC-BY-4.0): d20 attack rolls vs AC, natural 1 /
;    natural 20, damage dice, critical hits double the dice, XP + levels,
;    fighter hit die d10, Second Wind, Potions of Healing (2d4+2).
;
;  Controls:  D-pad move   A/B sword   START menu   (menus: A ok, B back)
; ============================================================================

; ---------------------------------------------------------------- hardware --
DEF rP1    EQU $FF00
DEF rDIV   EQU $FF04
DEF rIF    EQU $FF0F
DEF rNR10  EQU $FF10
DEF rNR11  EQU $FF11
DEF rNR12  EQU $FF12
DEF rNR13  EQU $FF13
DEF rNR14  EQU $FF14
DEF rNR21  EQU $FF16
DEF rNR22  EQU $FF17
DEF rNR23  EQU $FF18
DEF rNR24  EQU $FF19
DEF rNR41  EQU $FF20
DEF rNR42  EQU $FF21
DEF rNR43  EQU $FF22
DEF rNR44  EQU $FF23
DEF rNR50  EQU $FF24
DEF rNR51  EQU $FF25
DEF rNR52  EQU $FF26
DEF rLCDC  EQU $FF40
DEF rSTAT  EQU $FF41
DEF rSCY   EQU $FF42
DEF rSCX   EQU $FF43
DEF rLY    EQU $FF44
DEF rLYC   EQU $FF45
DEF rDMA   EQU $FF46
DEF rBGP   EQU $FF47
DEF rOBP0  EQU $FF48
DEF rOBP1  EQU $FF49
DEF rWY    EQU $FF4A
DEF rWX    EQU $FF4B
DEF rVBK   EQU $FF4F
DEF rBCPS  EQU $FF68
DEF rBCPD  EQU $FF69
DEF rOCPS  EQU $FF6A
DEF rOCPD  EQU $FF6B
DEF rIE    EQU $FFFF

; LCD on, window map $9C00, BG tiles $9000, BG map $9800, OBJ 8x8, BG on
DEF LCDC_ON    EQU %11000011
DEF SCRN       EQU $9800
DEF WINMAP     EQU $9C00

DEF PAD_A      EQU $01
DEF PAD_B      EQU $02
DEF PAD_START  EQU $08

DEF OAM_DMGPAL1 EQU $10
DEF OAM_XFLIP   EQU $20
DEF OAM_YFLIP   EQU $40

; CGB object palettes
DEF OP_FIGHTER  EQU 0
DEF OP_GOBLIN   EQU 1
DEF OP_BAT      EQU 2
DEF OP_SKELETON EQU 3
DEF OP_SWORD    EQU 4
DEF OP_HEART    EQU 5
DEF OP_FLASH    EQU 6
DEF OP_OGRE     EQU 7

; ------------------------------------------------------------- game consts --
DEF STATE_TITLE    EQU 0
DEF STATE_PLAY     EQU 1
DEF STATE_GAMEOVER EQU 2
DEF STATE_WIN      EQU 3
DEF STATE_MENU     EQU 4

DEF M_PAUSE     EQU 0
DEF M_STATUS    EQU 1
DEF M_ITEMS     EQU 2
DEF M_ITEMSUB   EQU 3
DEF M_BOXMSG    EQU 4
DEF M_OPTIONS   EQU 5
DEF M_SKILLS    EQU 6
DEF M_BEAST     EQU 7
DEF M_BEASTPAGE EQU 8
DEF M_INTRO     EQU 9

DEF DIR_DOWN   EQU 0
DEF DIR_UP     EQU 1
DEF DIR_LEFT   EQU 2
DEF DIR_RIGHT  EQU 3

; --- D&D 5e character: human fighter, standard array, chain mail, longsword
DEF PLAYER_AC    EQU 16          ; chain mail
DEF ATK_BONUS    EQU 4           ; STR +2, proficiency +2
DEF DMG_BONUS    EQU 2           ; STR +2
DEF CON_MOD      EQU 2
DEF START_HP     EQU 12          ; d10 max + CON
DEF MAX_LEVEL    EQU 5
DEF MAX_ITEM     EQU 9

DEF ATTACK_TIME  EQU 12
DEF MAX_ENEMIES  EQU 3
DEF ENEMY_SIZE   EQU 16
DEF ROOM_W       EQU 20
DEF ROOM_H       EQU 17

DEF TYPE_NONE     EQU 0
DEF TYPE_GOBLIN   EQU 1
DEF TYPE_BAT      EQU 2
DEF TYPE_SKELETON EQU 3
DEF TYPE_OGRE     EQU 4

; monster stat block offsets (8 bytes each, SRD 5.1)
DEF MS_AC   EQU 0
DEF MS_HP   EQU 1
DEF MS_ATK  EQU 2
DEF MS_DN   EQU 3
DEF MS_DS   EQU 4
DEF MS_DB   EQU 5
DEF MS_XP   EQU 6

; sprite tile ids
DEF T_FIGHTER_S EQU 8
DEF T_GOBLIN    EQU 12
DEF T_BAT       EQU 20
DEF T_SKELETON  EQU 28
DEF T_SWORD_VH  EQU 32
DEF T_SWORD_VT  EQU 33
DEF T_SWORD_HH  EQU 34
DEF T_SWORD_HT  EQU 35
DEF T_HEART_PU  EQU 36
DEF T_OGRE      EQU 37

; bg tile ids
DEF T_BLANK     EQU 0
DEF T_WALL      EQU 3
DEF TILE_SOLID  EQU 3
DEF T_BOX_E     EQU 9
DEF T_BOX_F     EQU 10
DEF T_DIGIT0    EQU 16
DEF T_FRAME     EQU 64
DEF T_TL        EQU 64
DEF T_TOP       EQU 65
DEF T_TR        EQU 66
DEF T_LEFT      EQU 67
DEF T_RIGHT     EQU 68
DEF T_BL        EQU 69
DEF T_BOTTOM    EQU 70
DEF T_BR        EQU 71
DEF T_CUR       EQU 72
DEF T_CURH      EQU 73

; enemy struct offsets
DEF E_TYPE  EQU 0
DEF E_X     EQU 1
DEF E_Y     EQU 2
DEF E_HP    EQU 3
DEF E_TIMER EQU 4
DEF E_DX    EQU 5
DEF E_DY    EQU 6
DEF E_HURT  EQU 7
DEF E_KX    EQU 8
DEF E_KY    EQU 9
DEF E_NOHIT EQU 10

MACRO SFX_GUARD
    ld a, [wSoundOn]
    and a
    ret z
ENDM

; graphics + "text" charmap (selected for the rest of the file)
INCLUDE "gfx.inc"

NEWCHARMAP room
CHARMAP ".", 1
CHARMAP ",", 2
CHARMAP "#", 3
CHARMAP "T", 4
CHARMAP "~", 5
CHARMAP "o", 6
SETCHARMAP text

; ============================================================== vectors ====
SECTION "VBlankVec", ROM0[$40]
    jp VBlankHandler
SECTION "StatVec", ROM0[$48]
    jp StatHandler

SECTION "Header", ROM0[$100]
    nop
    jp Main
    ds $150 - @, 0

; ================================================================ main =====
SECTION "Main", ROM0

Main:
    di
    ld sp, $E000
    cp $11                       ; A = $11 on Game Boy Color / GBA
    ld a, 0
    jr nz, .dmg
    inc a
.dmg:
    ld [wIsCGB], a
    call LCDOff

    ld hl, DMARoutine
    ld de, hOAMDMA
    ld bc, DMARoutineEnd - DMARoutine
    call Memcpy

    xor a
    ldh [rVBK], a
    ld hl, SpriteTiles
    ld de, $8000
    ld bc, SpriteTilesEnd - SpriteTiles
    call Memcpy
    ld hl, BgTiles
    ld de, $9000
    ld bc, BgTilesEnd - BgTiles
    call Memcpy
    ld hl, FontTiles
    ld de, $9000 + T_DIGIT0 * 16
    ld bc, FontTilesEnd - FontTiles
    call Copy1bpp
    ld hl, FrameTiles
    ld de, $9000 + T_FRAME * 16
    ld bc, FrameTilesEnd - FrameTiles
    call Memcpy

    ld hl, wShadowOAM
    ld bc, 160
    xor a
    call Memset
    ld hl, $FE00
    ld bc, 160
    xor a
    call Memset
    ld hl, wWinBuf
    ld bc, 20 * 18
    xor a
    call Memset

    ; DMG palettes
    ld a, %11100100
    ldh [rBGP], a
    ld a, %11100000
    ldh [rOBP0], a
    ld a, %01001100
    ldh [rOBP1], a
    xor a
    ldh [rSCX], a
    ldh [rSCY], a

    ; persistent options
    xor a
    ld [wPalSet], a
    ld a, 1
    ld [wSoundOn], a
    call LoadPalettes

    ; CGB: window map attributes -> menu palette 7
    ld a, [wIsCGB]
    and a
    jr z, .noAttr
    ld a, 1
    ldh [rVBK], a
    ld hl, WINMAP
    ld bc, 32 * 32
    ld a, 7
    call Memset
    xor a
    ldh [rVBK], a
.noAttr:

    ld a, $80
    ldh [rNR52], a
    ld a, $77
    ldh [rNR50], a
    ld a, $FF
    ldh [rNR51], a

    ld a, $A5
    ldh [hRng], a
    xor a
    ldh [hKeys], a
    ldh [hNewKeys], a
    ldh [hFrame], a
    ld [wHudOn], a
    ld [wWinOn], a
    ld [wWinDirtyAny], a

    ld a, $FF
    ldh [rLYC], a
    ld a, $40                    ; STAT: LYC interrupt (set once - DMG STAT-write quirk)
    ldh [rSTAT], a
    ld a, %00000011              ; VBlank + STAT
    ldh [rIE], a
    xor a
    ldh [rIF], a
    ei

; ------------------------------------------------------------- title -------
StartTitle:
    ld sp, $E000
    ld a, STATE_TITLE
    ld [wGameState], a
    xor a
    ld [wHudOn], a
    ld [wWinOn], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld a, T_WALL
    call WinFillRow
    ld c, 17
    ld a, T_WALL
    call WinFillRow
    ld b, 2
    ld c, 2
    ld d, 16
    ld e, 5
    call DrawBox
    ld hl, TitleList
    call WinPrintList
    call LCDOff
    ld hl, wWinBuf               ; copy the composed screen to the BG map
    ld de, SCRN
    ld c, 18
.row:
    ld b, 20
.col:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, .col
    ld a, e
    add a, 12
    ld e, a
    jr nc, .nc
    inc d
.nc:
    dec c
    jr nz, .row
    ld a, [wIsCGB]
    and a
    jr z, .noAttr
    ld a, 1
    ldh [rVBK], a
    ld hl, SCRN
    ld bc, 32 * 18
    ld a, 6
    call Memset
    ld hl, SCRN
    ld bc, 20
    ld a, 1
    call Memset
    ld hl, SCRN + 17 * 32
    ld bc, 20
    ld a, 1
    call Memset
    xor a
    ldh [rVBK], a
.noAttr:
    call LCDOn

.titleLoop:
    call WaitVBlank
    call ReadJoypad
    ld hl, hFrame
    inc [hl]
    call DrawTitleSprites
    ldh a, [hNewKeys]
    and PAD_START | PAD_A
    jr z, .titleLoop
    ldh a, [rDIV]
    or 1
    ldh [hRng], a
    call SfxPickup
    call NewGame

; ------------------------------------------------------------ game loop ----
GameLoop:
    call WaitVBlank
    call ReadJoypad
    ld hl, hFrame
    inc [hl]
    ld a, [wGameState]
    cp STATE_MENU
    jr z, .menu
    cp STATE_PLAY
    jr nz, .ended
    ldh a, [hNewKeys]
    and PAD_START
    jr z, .play
    call OpenPauseMenu
    jr GameLoop
.play:
    call UpdatePlayer
    call UpdateEnemies
    call UpdatePickup
    call CheckRoomClear
    call DrawSprites
    call BuildHUD
    jr GameLoop
.menu:
    call UpdateMenu
    jr GameLoop
.ended:
    call DrawSprites
    ldh a, [hNewKeys]
    and PAD_START
    jr z, GameLoop
    jp StartTitle

NewGame:
    ld a, START_HP
    ld [wHP], a
    ld [wMaxHP], a
    ld a, 1
    ld [wLevel], a
    ld [wSecondWind], a
    ld a, 2
    ld [wItems + 0], a           ; potions of healing
    ld a, 1
    ld [wItems + 1], a           ; elixir
    ld a, 72
    ld [wPlayerX], a
    ld a, 56
    ld [wPlayerY], a
    xor a
    ld [wXP], a
    ld [wXP + 1], a
    ld [wPlayerDir], a
    ld [wAttack], a
    ld [wPlayerInv], a
    ld [wKnockT], a
    ld [wRoom], a
    ld [wRoomsCleared], a
    ld [wPickupOn], a
    ld [wMsgT], a
    ld [wSeen], a
    ld [wPauseCur], a
    ld [wItemCur], a
    ld [wBeastCur], a
    ld a, STATE_PLAY
    ld [wGameState], a
    call BuildHUD
    ld a, 1
    ld [wHudOn], a
    call LoadRoom
    jp OpenIntro

; ============================================================ rooms ========
LoadRoom:
    call LCDOff
    ld a, [wRoom]
    add a, a
    ld e, a
    ld d, 0
    ld hl, RoomTable
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    ld de, wRoomMap
    ld bc, ROOM_W * ROOM_H
    call Memcpy
    pop hl
    ld de, SCRN + 32
    ld c, ROOM_H
.row:
    ld b, ROOM_W
.col:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, .col
    ld a, e
    add a, 32 - ROOM_W
    ld e, a
    jr nc, .nc
    inc d
.nc:
    dec c
    jr nz, .row

    ; CGB attributes: HUD row + per-tile palettes
    ld a, [wIsCGB]
    and a
    jr z, .noAttr
    ld a, 1
    ldh [rVBK], a
    ld hl, SCRN
    ld bc, 20
    ld a, 5
    call Memset
    ld hl, wRoomMap
    ld de, SCRN + 32
    ld c, ROOM_H
.arow:
    ld b, ROOM_W
.acol:
    ld a, [hl+]
    push hl
    ld hl, AttrTable
    add a, l
    ld l, a
    jr nc, .anc
    inc h
.anc:
    ld a, [hl]
    pop hl
    ld [de], a
    inc de
    dec b
    jr nz, .acol
    ld a, e
    add a, 32 - ROOM_W
    ld e, a
    jr nc, .anc2
    inc d
.anc2:
    dec c
    jr nz, .arow
    xor a
    ldh [rVBK], a
.noAttr:

    ld hl, wEnemies
    ld bc, ENEMY_SIZE * MAX_ENEMIES
    xor a
    call Memset
    xor a
    ld [wPickupOn], a

    ld a, [wRoom]
    call RoomBit
    ld b, a
    ld a, [wRoomsCleared]
    and b
    jr nz, .done

    ld a, [wRoom]
    ld l, a
    add a, a
    add a, a
    add a, a
    add a, l
    ld e, a
    ld d, 0
    ld hl, SpawnTable
    add hl, de
    ld de, wEnemies
    ld c, MAX_ENEMIES
.spawn:
    push bc
    push de
    push hl
    ld hl, wCur
    ld bc, ENEMY_SIZE
    xor a
    call Memset
    pop hl
    ld a, [hl+]
    ld [wCur + E_TYPE], a
    ld a, [hl+]
    ld [wCur + E_X], a
    ld a, [hl+]
    ld [wCur + E_Y], a
    push hl
    ld a, [wCur + E_TYPE]
    and a
    jr z, .empty
    push af
    dec a
    call RoomBit                 ; mark as seen for the bestiary
    ld b, a
    ld a, [wSeen]
    or b
    ld [wSeen], a
    pop af
    call GetTypeStats
    inc hl
    ld a, [hl]                   ; MS_HP
    ld [wCur + E_HP], a
    ld a, 30
    ld [wCur + E_TIMER], a
.empty:
    pop hl
    pop de
    push hl
    ld hl, wCur
    ld bc, ENEMY_SIZE
    call Memcpy
    pop hl
    pop bc
    dec c
    jr nz, .spawn
.done:
    jp LCDOn

; a = index (0..7) -> a = 1 << index
RoomBit:
    push hl
    ld hl, BitTable
    add a, l
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, [hl]
    pop hl
    ret

CheckRoomClear:
    ld a, [wGameState]
    cp STATE_PLAY
    ret nz
    ld a, [wRoom]
    call RoomBit
    ld b, a
    ld a, [wRoomsCleared]
    and b
    ret nz
    ld a, [wEnemies + 0 * ENEMY_SIZE]
    ld c, a
    ld a, [wEnemies + 1 * ENEMY_SIZE]
    or c
    ld c, a
    ld a, [wEnemies + 2 * ENEMY_SIZE]
    or c
    ret nz
    ld a, [wRoomsCleared]
    or b
    ld [wRoomsCleared], a
    push af
    ld a, 1                      ; short rest: Second Wind recharges
    ld [wSecondWind], a
    call SfxClear
    pop af
    cp $0F
    ret nz
    jp ShowWin

; ============================================================ player =======
UpdatePlayer:
    ld a, [wMsgT]
    and a
    jr z, .noMsg
    dec a
    ld [wMsgT], a
.noMsg:
    ld a, [wPlayerInv]
    and a
    jr z, .noInv
    dec a
    ld [wPlayerInv], a
.noInv:
    xor a
    ld [wPlayerMoving], a
    ld a, [wKnockT]
    and a
    jr z, .input
    dec a
    ld [wKnockT], a
    ld a, [wKnockX]
    ld d, a
    ld a, [wKnockY]
    ld e, a
    call PlayerTryMove
    call PlayerTryMove
    jr .attack
.input:
    ld a, [wAttack]
    and a
    jr nz, .attack
    ld de, 0
    ldh a, [hKeys]
    ld b, a
    bit 4, b
    jr z, .nr
    ld d, 1
    ld a, DIR_RIGHT
    ld [wPlayerDir], a
.nr:
    bit 5, b
    jr z, .nl
    ld d, $FF
    ld a, DIR_LEFT
    ld [wPlayerDir], a
.nl:
    bit 6, b
    jr z, .nu
    ld e, $FF
    ld a, DIR_UP
    ld [wPlayerDir], a
.nu:
    bit 7, b
    jr z, .nd
    ld e, 1
    ld a, DIR_DOWN
    ld [wPlayerDir], a
.nd:
    ld a, d
    or e
    jr z, .attack
    ld a, 1
    ld [wPlayerMoving], a
    call PlayerTryMove
.attack:
    ldh a, [hNewKeys]
    and PAD_A | PAD_B
    jr z, .noNewAttack
    ld a, [wAttack]
    and a
    jr nz, .noNewAttack
    ld a, ATTACK_TIME
    ld [wAttack], a
    call SfxSwing
    jr .room
.noNewAttack:
    ld a, [wAttack]
    and a
    jr z, .room
    dec a
    ld [wAttack], a
.room:
    ld a, [wPlayerX]
    cp 2
    jr c, .goLeft
    cp 142
    jr nc, .goRight
    ld a, [wPlayerY]
    cp 4
    jr c, .goUp
    cp 126
    jr nc, .goDown
    ret
.goLeft:
    ld a, 140
    ld [wPlayerX], a
    ld a, [wRoom]
    dec a
    jr .change
.goRight:
    ld a, 4
    ld [wPlayerX], a
    ld a, [wRoom]
    inc a
    jr .change
.goUp:
    ld a, 124
    ld [wPlayerY], a
    ld a, [wRoom]
    sub 2
    jr .change
.goDown:
    ld a, 6
    ld [wPlayerY], a
    ld a, [wRoom]
    add a, 2
.change:
    ld [wRoom], a
    xor a
    ld [wKnockT], a
    ld [wAttack], a
    jp LoadRoom

PlayerTryMove:                   ; d = dx, e = dy; preserves de
    ld a, d
    and a
    jr z, .y
    ld a, [wPlayerX]
    add a, d
    ld b, a
    ld a, [wPlayerY]
    ld c, a
    call CheckBoxBlocked
    jr c, .y
    ld a, b
    ld [wPlayerX], a
.y:
    ld a, e
    and a
    ret z
    ld a, [wPlayerX]
    ld b, a
    ld a, [wPlayerY]
    add a, e
    ld c, a
    call CheckBoxBlocked
    ret c
    ld a, c
    ld [wPlayerY], a
    ret

KnockFromCur:                    ; push the player away from wCur
    ld a, [wPlayerX]
    ld b, a
    ld a, [wCur + E_X]
    call SignDiff
    ld [wKnockX], a
    ld a, [wPlayerY]
    ld b, a
    ld a, [wCur + E_Y]
    call SignDiff
    ld [wKnockY], a
    ld a, 8
    ld [wKnockT], a
    ret

; --- monster makes an attack roll against the fighter (5e) ---------------
EnemyAttack:
    ld a, [wCur + E_TYPE]
    call GetTypeStats
    ld c, 20
    call RollDie
    cp 1
    jr z, .miss                  ; natural 1 always misses
    ld b, 0
    cp 20
    jr nz, .notCrit
    ld b, 1                      ; natural 20: hit + double dice
.notCrit:
    ld d, a
    inc hl
    inc hl                       ; MS_ATK
    ld a, b
    and a
    jr nz, .hit
    ld a, [hl]
    add a, d
    cp PLAYER_AC
    jr c, .miss
.hit:
    inc hl
    ld a, [hl+]                  ; dice count
    ld e, a
    ld a, b
    and a
    ld a, e
    jr z, .nd
    add a, a
.nd:
    ld b, a
    ld a, [hl+]                  ; dice sides
    ld c, a
    ld a, [hl]                   ; bonus
    ld e, a
    call RollDice
    add a, e
    jp PlayerTakeDamage
.miss:
    ld a, 30
    ld [wPlayerInv], a
    call KnockFromCur
    ld hl, MsgBlock
    call SetMsg
    jp SfxBlock

PlayerTakeDamage:                ; a = damage
    ld b, a
    ld a, [wHP]
    sub b
    jr c, .dead
    jr z, .dead
    ld [wHP], a
    ld a, 60
    ld [wPlayerInv], a
    call KnockFromCur
    jp SfxHurt
.dead:
    xor a
    ld [wHP], a
    call SfxHurt
    jp ShowGameOver

; de = XP to add
AddXP:
    ld hl, wXP
    ld a, [hl]
    add a, e
    ld [hl+], a
    ld a, [hl]
    adc a, d
    ld [hl], a
CheckLevelUp:
    ld a, [wLevel]
    cp MAX_LEVEL
    ret nc
    dec a
    add a, a
    ld e, a
    ld d, 0
    ld hl, LevelTable
    add hl, de
    ld a, [hl+]
    ld e, a
    ld d, [hl]
    ld a, [wXP]
    sub e
    ld a, [wXP + 1]
    sbc a, d
    ret c
    ld hl, wLevel
    inc [hl]
    ld c, 10                     ; fighter hit die d10 + CON
    call RollDie
    add a, CON_MOD
    ld b, a
    ld a, [wMaxHP]
    add a, b
    ld [wMaxHP], a
    ld a, [wHP]
    add a, b
    ld [wHP], a
    ld hl, MsgLvUp
    call SetMsg
    call SfxWin
    jr CheckLevelUp

SetMsg:                          ; hl = 5-char HUD message
    ld a, l
    ld [wMsgPtr], a
    ld a, h
    ld [wMsgPtr + 1], a
    ld a, 60
    ld [wMsgT], a
    ret

; ============================================================ collision ====
IsSolidAt:                       ; b = x, c = y -> carry if solid
    push hl
    ld a, c
    sub 8
    jr c, .solid
    srl a
    srl a
    srl a
    cp ROOM_H
    jr nc, .solid
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    push de
    ld d, h
    ld e, l
    add hl, hl
    add hl, hl
    add hl, de
    ld a, b
    srl a
    srl a
    srl a
    cp ROOM_W
    jr nc, .solidPop
    ld e, a
    ld d, 0
    add hl, de
    ld de, wRoomMap
    add hl, de
    ld a, [hl]
    pop de
    pop hl
    cp TILE_SOLID
    ccf
    ret
.solidPop:
    pop de
.solid:
    pop hl
    scf
    ret

CheckBoxBlocked:                 ; b,c = entity top-left; feet box
    push bc
    ld a, b
    add a, 2
    ld b, a
    ld a, c
    add a, 8
    ld c, a
    call IsSolidAt
    jr c, .yes
    ld a, b
    add a, 11
    ld b, a
    call IsSolidAt
    jr c, .yes
    ld a, c
    add a, 7
    ld c, a
    call IsSolidAt
    jr c, .yes
    ld a, b
    sub 11
    ld b, a
    call IsSolidAt
    jr c, .yes
    pop bc
    or a
    ret
.yes:
    pop bc
    scf
    ret

RectOverlap:                     ; carry = wRectA overlaps wRectB
    ld a, [wRectB + 0]
    ld b, a
    ld a, [wRectB + 2]
    add a, b
    ld c, a
    ld a, [wRectA + 0]
    cp c
    ret nc
    ld d, a
    ld a, [wRectA + 2]
    add a, d
    ld c, a
    ld a, b
    cp c
    ret nc
    ld a, [wRectB + 1]
    ld b, a
    ld a, [wRectB + 3]
    add a, b
    ld c, a
    ld a, [wRectA + 1]
    cp c
    ret nc
    ld d, a
    ld a, [wRectA + 3]
    add a, d
    ld c, a
    ld a, b
    cp c
    ret nc
    scf
    ret

SetPlayerRectA:
    ld a, [wPlayerX]
    add a, 3
    ld [wRectA + 0], a
    ld a, [wPlayerY]
    add a, 4
    ld [wRectA + 1], a
    ld a, 10
    ld [wRectA + 2], a
    ld a, 11
    ld [wRectA + 3], a
    ret

SetEnemyRectB:
    ld a, [wCur + E_X]
    add a, 2
    ld [wRectB + 0], a
    ld a, [wCur + E_Y]
    add a, 3
    ld [wRectB + 1], a
    ld a, 12
    ld [wRectB + 2], a
    ld [wRectB + 3], a
    ret

SetSwordRectA:
    ld a, [wPlayerDir]
    add a, a
    add a, a
    ld e, a
    ld d, 0
    ld hl, SwordRects
    add hl, de
    ld a, [wPlayerX]
    add a, [hl]
    ld [wRectA + 0], a
    inc hl
    ld a, [wPlayerY]
    add a, [hl]
    ld [wRectA + 1], a
    inc hl
    ld a, [hl+]
    ld [wRectA + 2], a
    ld a, [hl]
    ld [wRectA + 3], a
    ret

; ============================================================ enemies ======
GetTypeStats:                    ; a = type (1..) -> hl = stat block. clobbers de
    dec a
    add a, a
    add a, a
    add a, a
    ld e, a
    ld d, 0
    ld hl, MonsterStats
    add hl, de
    ret

UpdateEnemies:
    ld hl, wEnemies
    ld c, MAX_ENEMIES
.loop:
    ld a, [hl]
    and a
    jr z, .skip
    push bc
    push hl
    ld de, wCur
    ld bc, ENEMY_SIZE
    call Memcpy
    call UpdateCurEnemy
    pop de
    push de
    ld hl, wCur
    ld bc, ENEMY_SIZE
    call Memcpy
    pop hl
    pop bc
.skip:
    ld de, ENEMY_SIZE
    add hl, de
    dec c
    jr nz, .loop
    ret

UpdateCurEnemy:
    ld a, [wGameState]
    cp STATE_PLAY
    ret nz
    ld a, [wCur + E_NOHIT]
    and a
    jr z, .nh
    dec a
    ld [wCur + E_NOHIT], a
.nh:
    ld a, [wCur + E_HURT]
    and a
    jr z, .ai
    dec a
    ld [wCur + E_HURT], a
    cp 8
    jr c, .contact
    ld a, [wCur + E_KX]
    ld d, a
    ld a, [wCur + E_KY]
    ld e, a
    call EnemyTryMove
    call EnemyTryMove
    jr .contact
.ai:
    ld a, [wCur + E_TIMER]
    and a
    jr z, .think
    dec a
    ld [wCur + E_TIMER], a
    jr .move
.think:
    call EnemyThink
.move:
    ld a, [wCur + E_TYPE]
    cp TYPE_BAT
    jr z, .doMove                ; bats: full speed
    cp TYPE_SKELETON
    jr z, .threeQuarter
    ldh a, [hFrame]              ; goblins + ogre: half speed
    and 1
    jr nz, .contact
    jr .doMove
.threeQuarter:
    ldh a, [hFrame]
    and 3
    jr z, .contact
.doMove:
    ld a, [wCur + E_DX]
    ld d, a
    ld a, [wCur + E_DY]
    ld e, a
    call EnemyTryMove

.contact:
    ld a, [wCur + E_HURT]
    and a
    jr nz, .sword
    ld a, [wPlayerInv]
    and a
    jr nz, .sword
    call SetPlayerRectA
    call SetEnemyRectB
    call RectOverlap
    jr nc, .sword
    call EnemyAttack
    ld a, [wGameState]
    cp STATE_PLAY
    ret nz
.sword:
    ld a, [wAttack]
    and a
    ret z
    ld a, [wCur + E_HURT]
    ld b, a
    ld a, [wCur + E_NOHIT]
    or b
    ret nz
    call SetSwordRectA
    call SetEnemyRectB
    call RectOverlap
    ret nc
    ; --- the fighter's attack roll: d20 + 4 vs monster AC --------------
    ld a, ATTACK_TIME
    ld [wCur + E_NOHIT], a       ; one roll per swing
    xor a
    ld [wWasCrit], a
    ld a, [wCur + E_TYPE]
    call GetTypeStats
    ld c, 20
    call RollDie
    cp 1
    jr z, .miss
    cp 20
    jr z, .crit
    add a, ATK_BONUS
    cp [hl]                      ; MS_AC
    jr c, .miss
    ld b, 1
    jr .dmg
.crit:
    ld a, 1
    ld [wWasCrit], a
    ld hl, MsgCrit
    call SetMsg
    ld b, 2                      ; crit: roll the damage dice twice
.dmg:
    ld c, 8                      ; longsword d8
    call RollDice
    add a, DMG_BONUS
    ld b, a
    ld a, [wCur + E_HP]
    sub b
    jr c, .kill
    jr z, .kill
    ld [wCur + E_HP], a
    ld a, 16
    ld [wCur + E_HURT], a
    ld a, [wPlayerDir]
    add a, a
    ld e, a
    ld d, 0
    ld hl, DirVec
    add hl, de
    ld a, [hl+]
    ld [wCur + E_KX], a
    ld a, [hl]
    ld [wCur + E_KY], a
    ld a, [wWasCrit]
    and a
    jp nz, SfxCrit
    jp SfxHit
.miss:
    ld hl, MsgMiss
    call SetMsg
    jp SfxBlock
.kill:
    ld a, [wCur + E_TYPE]
    call GetTypeStats
    ld de, MS_XP
    add hl, de
    ld a, [hl+]
    ld e, a
    ld d, [hl]
    call AddXP
    ld a, [wPickupOn]
    and a
    jr nz, .noDrop
    call Rand
    and 1
    jr nz, .noDrop
    ld a, 1
    ld [wPickupOn], a
    ld a, [wCur + E_X]
    ld [wPickupX], a
    ld a, [wCur + E_Y]
    ld [wPickupY], a
.noDrop:
    xor a
    ld [wCur + E_TYPE], a
    jp SfxKill

EnemyTryMove:                    ; d = dx, e = dy; preserves de
    ld a, d
    and a
    jr z, .y
    ld a, [wCur + E_X]
    add a, d
    ld b, a
    cp 8
    jr c, .bx
    cp 137
    jr nc, .bx
    ld a, [wCur + E_Y]
    ld c, a
    call CheckBoxBlocked
    jr c, .bx
    ld a, b
    ld [wCur + E_X], a
    jr .y
.bx:
    xor a
    ld [wCur + E_TIMER], a
.y:
    ld a, e
    and a
    ret z
    ld a, [wCur + E_Y]
    add a, e
    ld c, a
    cp 12
    jr c, .by
    cp 119
    jr nc, .by
    ld a, [wCur + E_X]
    ld b, a
    call CheckBoxBlocked
    jr c, .by
    ld a, c
    ld [wCur + E_Y], a
    ret
.by:
    xor a
    ld [wCur + E_TIMER], a
    ret

EnemyThink:
    ld a, [wCur + E_TYPE]
    cp TYPE_BAT
    jr z, .bat
    cp TYPE_GOBLIN
    jr nz, .hunter
    ; goblin: chase along the longer axis, sometimes skulk about
    call Rand
    and 3
    jr z, .wander
    ld a, [wPlayerX]
    ld b, a
    ld a, [wCur + E_X]
    call AbsDiff
    ld d, a
    ld a, [wPlayerY]
    ld b, a
    ld a, [wCur + E_Y]
    call AbsDiff
    ld e, a
    call ChaseDir
    ld a, d
    cp e
    jr c, .vert
    xor a
    ld [wCur + E_DY], a
    jr .gTimer
.vert:
    xor a
    ld [wCur + E_DX], a
.gTimer:
    ld a, 40
    ld [wCur + E_TIMER], a
    ret
.wander:
    call RandDir
    ld [wCur + E_DX], a
    call RandDir
    ld [wCur + E_DY], a
    ld a, 30
    ld [wCur + E_TIMER], a
    ret
.hunter:                         ; skeleton + ogre: relentless
    call Rand
    and 3
    jr z, .wander
    call ChaseDir
    ld a, 12
    ld [wCur + E_TIMER], a
    ret
.bat:
    call Rand
    and 1
    jr z, .batRand
    call ChaseDir
    jr .batTimer
.batRand:
    call RandDir
    ld [wCur + E_DX], a
    call RandDir
    ld [wCur + E_DY], a
.batTimer:
    call Rand
    and 15
    add a, 8
    ld [wCur + E_TIMER], a
    ret

ChaseDir:
    ld a, [wPlayerX]
    ld b, a
    ld a, [wCur + E_X]
    call SignDiff
    ld [wCur + E_DX], a
    ld a, [wPlayerY]
    ld b, a
    ld a, [wCur + E_Y]
    call SignDiff
    ld [wCur + E_DY], a
    ret

SignDiff:                        ; a = from, b = to -> -1 / 0 / +1
    cp b
    jr z, .zero
    jr c, .pos
    ld a, $FF
    ret
.pos:
    ld a, 1
    ret
.zero:
    xor a
    ret

AbsDiff:
    sub b
    ret nc
    cpl
    inc a
    ret

; ============================================================ pickup =======
UpdatePickup:
    ld a, [wPickupOn]
    and a
    ret z
    call SetPlayerRectA
    ld a, [wPickupX]
    add a, 4
    ld [wRectB + 0], a
    ld a, [wPickupY]
    add a, 4
    ld [wRectB + 1], a
    ld a, 8
    ld [wRectB + 2], a
    ld [wRectB + 3], a
    call RectOverlap
    ret nc
    xor a
    ld [wPickupOn], a
    ld a, [wMaxHP]
    ld b, a
    ld a, [wHP]
    cp b
    jr nc, .toPotion
    add a, 4                     ; heart heals 4 HP
    cp b
    jr c, .ok
    ld a, b
.ok:
    ld [wHP], a
    ld hl, MsgHeal
    call SetMsg
    jp SfxPickup
.toPotion:                       ; at full HP a heart becomes a potion
    ld a, [wItems]
    cp MAX_ITEM
    jr nc, .full
    inc a
    ld [wItems], a
.full:
    ld hl, MsgPotion
    call SetMsg
    jp SfxPickup

; ============================================================ drawing ======
ClearOAM:
    ld hl, wShadowOAM
    ld bc, 160
    xor a
    call Memset
    ld a, LOW(wShadowOAM)
    ld [wOamPtr], a
    ld a, HIGH(wShadowOAM)
    ld [wOamPtr + 1], a
    ret

DrawSprites:
    call ClearOAM
    ld a, [wGameState]
    cp STATE_PLAY
    jr z, .go
    cp STATE_MENU
    ret nz
.go:
    call DrawPlayer
    call DrawSword
    call DrawEnemies
    jp DrawPickup

DrawPlayer:
    ld a, [wPlayerInv]
    and 4
    ret nz
    ld a, [wPlayerX]
    ld b, a
    ld a, [wPlayerY]
    ld c, a
    ld a, [wPlayerDir]
    cp DIR_LEFT
    jr z, .left
    cp DIR_RIGHT
    jr z, .right
    add a, a
    add a, a
    ld d, a
    ld e, OP_FIGHTER
    ld a, [wPlayerMoving]
    and a
    jr z, .draw
    ldh a, [hFrame]
    and 8
    jr z, .draw
    ld e, OP_FIGHTER | OAM_XFLIP
    jr .draw
.left:
    ld d, T_FIGHTER_S
    ld e, OP_FIGHTER | OAM_XFLIP
    jr .side
.right:
    ld d, T_FIGHTER_S
    ld e, OP_FIGHTER
.side:
    ld a, [wPlayerMoving]
    and a
    jr z, .draw
    ldh a, [hFrame]
    and 8
    jr z, .draw
    dec c
.draw:
    jp DrawMeta16

DrawSword:
    ld a, [wAttack]
    and a
    ret z
    ld a, [wPlayerDir]
    add a, a
    add a, a
    add a, a
    ld e, a
    ld d, 0
    ld hl, SwordSprites
    add hl, de
    call .one
.one:
    ld a, [wPlayerX]
    add a, [hl]
    ld b, a
    inc hl
    ld a, [wPlayerY]
    add a, [hl]
    ld c, a
    inc hl
    ld a, [hl+]
    ld d, a
    ld a, [hl+]
    ld e, a
    jp DrawSprite8

DrawEnemies:
    ld hl, wEnemies
    ld c, MAX_ENEMIES
.loop:
    push bc
    push hl
    ld a, [hl+]
    and a
    jr z, .next
    ld [wTmp], a
    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    ld c, a
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, [hl]                   ; E_HURT
    and 2
    ld [wTmp + 1], a
    ld a, [wTmp]
    cp TYPE_GOBLIN
    jr nz, .notGoblin
    ld d, T_GOBLIN
    ld e, OP_GOBLIN
    ldh a, [hFrame]
    and 16
    jr z, .draw
    ld d, T_GOBLIN + 4
    jr .draw
.notGoblin:
    cp TYPE_BAT
    jr nz, .notBat
    ld d, T_BAT
    ld e, OP_BAT
    ldh a, [hFrame]
    and 8
    jr z, .draw
    ld d, T_BAT + 4
    jr .draw
.notBat:
    cp TYPE_SKELETON
    jr nz, .ogre
    ld d, T_SKELETON
    ld e, OP_SKELETON
    jr .rattle
.ogre:
    ld d, T_OGRE
    ld e, OP_OGRE
.rattle:
    ldh a, [hFrame]
    and 16
    jr z, .draw
    ld a, e
    or OAM_XFLIP
    ld e, a
.draw:
    ld a, [wTmp + 1]
    and a
    jr z, .noFlash
    ld a, e
    and OAM_XFLIP
    or OP_FLASH | OAM_DMGPAL1
    ld e, a
.noFlash:
    call DrawMeta16
.next:
    pop hl
    ld de, ENEMY_SIZE
    add hl, de
    pop bc
    dec c
    jr nz, .loop
    ret

DrawPickup:
    ld a, [wPickupOn]
    and a
    ret z
    ld a, [wPickupX]
    add a, 4
    ld b, a
    ld a, [wPickupY]
    add a, 4
    ld c, a
    ldh a, [hFrame]
    and 16
    jr z, .nb
    dec c
.nb:
    ld d, T_HEART_PU
    ld e, OP_HEART
    jp DrawSprite8

DrawTitleSprites:
    call ClearOAM
    ld b, 40
    ld c, 60
    ld d, T_FIGHTER_S
    ld e, OP_FIGHTER
    call DrawMeta16
    ld b, 58
    ld c, 68
    ld d, T_SWORD_HH
    ld e, OP_SWORD
    call DrawSprite8
    ld b, 66
    ld d, T_SWORD_HT
    call DrawSprite8
    ld b, 88
    ld c, 60
    ld d, T_GOBLIN
    ld e, OP_GOBLIN
    ldh a, [hFrame]
    and 16
    jr z, .g
    ld d, T_GOBLIN + 4
.g:
    call DrawMeta16
    ld b, 108
    ld c, 60
    ld d, T_OGRE
    ld e, OP_OGRE
    call DrawMeta16
    ld b, 128
    ld c, 52
    ld d, T_BAT
    ld e, OP_BAT
    ldh a, [hFrame]
    and 8
    jr z, .bt
    ld d, T_BAT + 4
.bt:
    jp DrawMeta16

DrawMeta16:                      ; b x, c y, d tile, e attr
    push bc
    push de
    bit 5, e
    jr nz, .flip
    call DrawSprite8
    ld a, b
    add a, 8
    ld b, a
    inc d
    call DrawSprite8
    ld a, c
    add a, 8
    ld c, a
    inc d
    inc d
    call DrawSprite8
    ld a, b
    sub 8
    ld b, a
    dec d
    call DrawSprite8
    pop de
    pop bc
    ret
.flip:
    inc d
    call DrawSprite8
    ld a, b
    add a, 8
    ld b, a
    dec d
    call DrawSprite8
    ld a, c
    add a, 8
    ld c, a
    inc d
    inc d
    call DrawSprite8
    ld a, b
    sub 8
    ld b, a
    inc d
    call DrawSprite8
    pop de
    pop bc
    ret

DrawSprite8:                     ; b x, c y, d tile, e attr. preserves bc de hl
    push hl
    ld hl, wOamPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    cp 160
    jr nc, .full
    ld a, c
    add a, 16
    ld [hl+], a
    ld a, b
    add a, 8
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ld a, e
    ld [hl+], a
    ld a, l
    ld [wOamPtr], a
    ld a, h
    ld [wOamPtr + 1], a
.full:
    pop hl
    ret

; hide sprites that would draw on top of the current menu window
HideSpritesUnderWindow:
    ld hl, wShadowOAM
    ld c, 40
.loop:
    ld a, [hl]
    and a
    jr z, .next
    ld d, a                      ; oam y
    inc hl
    ld a, [hl]                   ; oam x
    dec hl
    ld e, a
    ld a, [wWinX]
    sub 7
    ld b, a
    ld a, e
    cp b
    jr c, .next
    jr z, .next
    ld a, [wWinY]
    add a, 8
    ld b, a
    ld a, d
    cp b
    jr c, .next
    jr z, .next
    ld a, [wWinBottom]
    add a, 16
    ld b, a
    ld a, d
    cp b
    jr nc, .next
    xor a
    ld [hl], a
.next:
    ld a, l
    add a, 4
    ld l, a
    dec c
    jr nz, .loop
    ret

; ============================================================ HUD ==========
; HP12/12  [][][][]  MSG.. L1
BuildHUD:
    ld hl, wHudBuf
    ld bc, 20
    xor a
    call Memset
    ld hl, wHudBuf
    ld a, "H"
    ld [hl+], a
    ld a, "P"
    ld [hl+], a
    ld a, [wHP]
    call Dec2
    ld a, d
    ld [hl+], a
    ld a, e
    ld [hl+], a
    ld a, "/"
    ld [hl+], a
    ld a, [wMaxHP]
    call Dec2
    ld a, d
    ld [hl+], a
    ld a, e
    ld [hl+], a
    ld hl, wHudBuf + 8
    ld a, [wRoomsCleared]
    ld b, a
    ld c, 4
.room:
    srl b
    ld a, T_BOX_F
    jr c, .wr
    ld a, T_BOX_E
.wr:
    ld [hl+], a
    dec c
    jr nz, .room
    ld a, [wMsgT]
    and a
    jr z, .lvl
    ld a, [wMsgPtr]
    ld l, a
    ld a, [wMsgPtr + 1]
    ld h, a
    ld de, wHudBuf + 13
    ld c, 5
.msg:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, .msg
.lvl:
    ld a, "L"
    ld [wHudBuf + 18], a
    ld a, [wLevel]
    add a, T_DIGIT0
    ld [wHudBuf + 19], a
    ret

; a = 0..99 -> d = tens tile (blank if 0), e = ones tile
Dec2:
    ld d, 0
.t:
    cp 10
    jr c, .o
    sub 10
    inc d
    jr .t
.o:
    add a, T_DIGIT0
    ld e, a
    ld a, d
    and a
    ret z
    add a, T_DIGIT0
    ld d, a
    ret

; de = 0..9999 -> wNumBuf = 4 tiles (leading blanks), $FF
Num16ToStr:
    ld hl, wNumBuf
    ld bc, 1000
    call .digit
    ld bc, 100
    call .digit
    ld bc, 10
    call .digit
    ld a, e
    add a, T_DIGIT0
    ld [hl+], a
    ld a, $FF
    ld [hl], a
    ld hl, wNumBuf
    ld b, 3
.lz:
    ld a, [hl]
    cp T_DIGIT0
    ret nz
    xor a
    ld [hl+], a
    dec b
    jr nz, .lz
    ret
.digit:
    ld a, T_DIGIT0
.dl:
    push af
    ld a, e
    sub c
    ld e, a
    ld a, d
    sbc a, b
    ld d, a
    jr c, .under
    pop af
    inc a
    jr .dl
.under:
    ld a, e
    add a, c
    ld e, a
    ld a, d
    adc a, b
    ld d, a
    pop af
    ld [hl+], a
    ret

CountCleared:                    ; a = number of cleared rooms
    ld a, [wRoomsCleared]
    ld b, a
    ld c, 4
    xor a
.l:
    srl b
    adc a, 0
    dec c
    jr nz, .l
    ret

; ============================================================ window kit ===
; Menus are drawn into wWinBuf (20x18) and streamed to the window map
; ($9C00) during VBlank, 3 rows per frame. A LYC interrupt switches the
; window off below wWinBottom, so boxes can float mid-screen.

WinPtr:                          ; b col, c row -> hl. preserves bc de
    push de
    ld l, c
    ld h, 0
    add hl, hl
    add hl, hl
    ld d, h
    ld e, l
    add hl, hl
    add hl, hl
    add hl, de
    ld e, b
    ld d, 0
    add hl, de
    ld de, wWinBuf
    add hl, de
    pop de
    ret

MarkRows:                        ; b first row, c count. clobbers a hl c
    ld hl, wWinDirty
    ld a, l
    add a, b
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, 1
.l:
    ld [hl+], a
    dec c
    jr nz, .l
    ld [wWinDirtyAny], a
    ret

WinClearAll:
    ld hl, wWinBuf
    ld bc, 20 * 18
    xor a
    call Memset
    ld b, 0
    ld c, 18
    jp MarkRows

WinFillRow:                      ; a tile, b col, c row, d count
    push af
    call WinPtr
    pop af
    push de
.l:
    ld [hl+], a
    dec d
    jr nz, .l
    pop de
    push bc
    ld b, c
    ld c, 1
    call MarkRows
    pop bc
    ret

WinPutTile:                      ; a tile, b col, c row. preserves bc de hl
    push hl
    push af
    call WinPtr
    pop af
    ld [hl], a
    push bc
    ld b, c
    ld c, 1
    call MarkRows
    pop bc
    pop hl
    ret

WinPutNum2:                      ; a = 0..99 at b,c. preserves bc
    call Dec2
    ld a, d
    call WinPutTile
    inc b
    ld a, e
    call WinPutTile
    dec b
    ret

WinPrint:                        ; hl = $FF string, b col, c row
    push hl
    call WinPtr
    ld d, h
    ld e, l
    push bc
    ld b, c
    ld c, 1
    call MarkRows
    pop bc
    pop hl
.l:
    ld a, [hl+]
    cp $FF
    ret z
    ld [de], a
    inc de
    jr .l

WinPrintList:                    ; hl -> {db col,row ; dw str}* , $FF
    ld a, [hl+]
    cp $FF
    ret z
    ld b, a
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a
    push hl
    ld h, d
    ld l, e
    call WinPrint
    pop hl
    jr WinPrintList

DrawBox:                         ; b col, c row, d width, e height
    ld a, b
    ld [wBoxCol], a
    ld a, c
    ld [wBoxRow], a
    ld [wBoxCur], a
    ld a, d
    ld [wBoxW], a
    ld a, e
    ld [wBoxH], a
    ld b, c
    ld c, e
    call MarkRows
    ld a, T_TL
    ld b, T_TOP
    ld c, T_TR
    call .row
    ld a, [wBoxH]
    sub 2
    ld e, a
.mid:
    ld a, T_LEFT
    ld b, T_BLANK
    ld c, T_RIGHT
    push de
    call .row
    pop de
    dec e
    jr nz, .mid
    ld a, T_BL
    ld b, T_BOTTOM
    ld c, T_BR
.row:                            ; a left, b mid, c right at wBoxCur row
    push af
    push bc
    ld a, [wBoxCol]
    ld b, a
    ld a, [wBoxCur]
    ld c, a
    inc a
    ld [wBoxCur], a
    call WinPtr
    pop bc
    pop af
    ld [hl+], a
    ld a, [wBoxW]
    sub 2
    ld d, a
    ld a, b
.ml:
    ld [hl+], a
    dec d
    jr nz, .ml
    ld [hl], c
    ret

; b col, c first row, d count, e selected, a tile  (rows step by 2)
DrawListCursor:
    ld [wTmpTile], a
    ld a, e
    ld [wTmpSel], a
    ld e, 0
.l:
    ld a, [wTmpSel]
    cp e
    ld a, T_BLANK
    jr nz, .p
    ld a, [wTmpTile]
.p:
    call WinPutTile
    inc c
    inc c
    inc e
    ld a, e
    cp d
    jr nz, .l
    ret

; hl = cursor var, b = count. carry set if moved (up/down with wrap)
ListNav:
    ldh a, [hNewKeys]
    bit 6, a
    jr nz, .up
    bit 7, a
    jr nz, .down
    or a
    ret
.up:
    ld a, [hl]
    and a
    jr nz, .u1
    ld a, b
.u1:
    dec a
    ld [hl], a
    call SfxMenu
    scf
    ret
.down:
    ld a, [hl]
    inc a
    cp b
    jr c, .d1
    xor a
.d1:
    ld [hl], a
    call SfxMenu
    scf
    ret

SetWindow:                       ; a = WX, b = WY, c = bottom line
    ld [wWinX], a
    ld a, b
    ld [wWinY], a
    ld a, c
    ld [wWinBottom], a
    ld a, 1
    ld [wWinOn], a
    ret

ShowFresh:                       ; hide window until the redraw is streamed
    ld a, 1
    ld [wWinHide], a
    ret

JumpTable:                       ; a = index, hl = table of dw
    add a, a
    add a, l
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp hl

; ============================================================ menus ========
UpdateMenu:
    ld a, [wMenu]
    ld hl, MenuHandlers
    jp JumpTable

MenuHandlers:
    dw MenuPause, MenuStatus, MenuItems, MenuItemSub, MenuBoxMsg
    dw MenuOptions, MenuSkills, MenuBeast, MenuBeastPage, MenuIntro

EnterMenuState:
    ld a, STATE_MENU
    ld [wGameState], a
    xor a
    ld [wHudOn], a
    ret

CloseMenu:
    ld a, STATE_PLAY
    ld [wGameState], a
    xor a
    ld [wWinOn], a
    call BuildHUD
    ld a, 1
    ld [wHudOn], a
    ret

CloseMenuSfx:
    call SfxMenu
    jp CloseMenu

ReshowSprites:
    call DrawSprites
    jp HideSpritesUnderWindow

; ---- intro ---------------------------------------------------------------
OpenIntro:
    call EnterMenuState
    ld a, M_INTRO
    ld [wMenu], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 18
    call DrawBox
    ld hl, IntroList
    call WinPrintList
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

MenuIntro:
    ldh a, [hNewKeys]
    and PAD_A | PAD_START
    ret z
    jp CloseMenuSfx

; ---- pause ---------------------------------------------------------------
OpenPauseMenu:
    call EnterMenuState
    call SfxMenu
ReturnToPause:
    ld a, M_PAUSE
    ld [wMenu], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 11
    ld e, 16
    call DrawBox
    ld hl, PauseList
    call WinPrintList
    call PauseCursor
    ld a, 9 * 8 + 7
    ld b, 0
    ld c, 16 * 8
    call SetWindow
    call ShowFresh
    jp ReshowSprites

PauseCursor:
    ld b, 1
    ld c, 2
    ld d, 7
    ld a, [wPauseCur]
    ld e, a
    ld a, T_CUR
    jp DrawListCursor

MenuPause:
    ld hl, wPauseCur
    ld b, 7
    call ListNav
    jp c, PauseCursor
    ldh a, [hNewKeys]
    and PAD_B | PAD_START
    jp nz, CloseMenuSfx
    ldh a, [hNewKeys]
    and PAD_A
    ret z
    call SfxMenu
    ld a, [wPauseCur]
    ld hl, PauseActions
    jp JumpTable

PauseActions:
    dw OpenStatus, OpenItems, OpenSkills, OpenBestiary, OpenOptions, Retire, CloseMenu

Retire:
    jp StartTitle

; ---- status (character sheet) -------------------------------------------
OpenStatus:
    ld a, M_STATUS
    ld [wMenu], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 18
    call DrawBox
    ld hl, StatusList
    call WinPrintList
    ld a, [wLevel]
    ld b, 14
    ld c, 2
    call WinPutNum2
    ld a, [wHP]
    ld b, 5
    ld c, 5
    call WinPutNum2
    ld a, [wMaxHP]
    ld b, 8
    ld c, 5
    call WinPutNum2
    ld a, [wXP]
    ld e, a
    ld a, [wXP + 1]
    ld d, a
    call Num16ToStr
    ld hl, wNumBuf
    ld b, 7
    ld c, 6
    call WinPrint
    ld a, [wLevel]               ; XP needed for next level
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
    ld b, 7
    ld c, 7
    call WinPrint
    call CountCleared
    add a, T_DIGIT0
    ld b, 8
    ld c, 16
    call WinPutTile
    ld a, [wSecondWind]
    add a, T_DIGIT0
    ld b, 14
    ld c, 15
    call WinPutTile
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

MenuStatus:
    ldh a, [hNewKeys]
    and PAD_A | PAD_B | PAD_START
    ret z
    call SfxMenu
    jp ReturnToPause

; ---- items ---------------------------------------------------------------
OpenItems:
    ld a, M_ITEMS
    ld [wMenu], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 18
    ld e, 9
    call DrawBox
    ld hl, ItemList
    call WinPrintList
    call ItemCounts
    ld a, T_CUR
    call ItemCursor
    ld a, 2 * 8 + 7
    ld b, 16
    ld c, 16 + 9 * 8
    call SetWindow
    call ShowFresh
    jp ReshowSprites

ItemCounts:
    ld a, "*"
    ld b, 13
    ld c, 2
    call WinPutTile
    ld a, [wItems + 0]
    inc b
    call WinPutNum2
    ld a, "*"
    ld b, 13
    ld c, 4
    call WinPutTile
    ld a, [wItems + 1]
    inc b
    jp WinPutNum2

ItemCursor:                      ; a = cursor tile
    push af
    ld a, [wItemCur]
    ld e, a
    pop af
    ld b, 1
    ld c, 2
    ld d, 3
    jp DrawListCursor

BackToItems:
    ld a, M_ITEMS
    ld [wMenu], a
    ld a, T_CUR
    call ItemCursor
    call ItemCounts
    ld a, 16 + 9 * 8
    ld [wWinBottom], a
    jp ReshowSprites

MenuItems:
    ld hl, wItemCur
    ld b, 3
    call ListNav
    jr nc, .noMove
    ld a, T_CUR
    jp ItemCursor
.noMove:
    ldh a, [hNewKeys]
    and PAD_B
    jr z, .notB
    call SfxMenu
    jp ReturnToPause
.notB:
    ldh a, [hNewKeys]
    and PAD_A
    ret z
    call SfxMenu
    ld a, [wItemCur]
    cp 2
    jp z, ReturnToPause
    ld e, a
    ld d, 0
    ld hl, wItems
    add hl, de
    ld a, [hl]
    and a
    jr nz, OpenItemSub
    ld hl, StrNoneLeft
    ld de, StrEmpty
    ld bc, BackToItems
    jp ShowBoxMsg

OpenItemSub:
    ld a, M_ITEMSUB
    ld [wMenu], a
    xor a
    ld [wSubCur], a
    ld a, T_CURH
    call ItemCursor
    ld b, 0
    ld c, 9
    ld d, 18
    ld e, 3
    call DrawBox
    ld hl, SubList
    call WinPrintList
    call SubCursor
    ld a, 16 + 12 * 8
    ld [wWinBottom], a
    jp HideSpritesUnderWindow

SubCursor:                       ; two spots on one row
    ld c, 10
    ld b, 2
    xor a
    call WinPutTile
    ld b, 9
    xor a
    call WinPutTile
    ld b, 2
    ld a, [wSubCur]
    and a
    jr z, .put
    ld b, 9
.put:
    ld a, T_CUR
    jp WinPutTile

MenuItemSub:
    ldh a, [hNewKeys]
    and $F0                      ; any direction toggles USE / TOSS
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
    jp BackToItems
.notB:
    ldh a, [hNewKeys]
    and PAD_A
    ret z
    call SfxMenu
    ld a, [wItemCur]
    ld e, a
    ld d, 0
    ld hl, wItems
    add hl, de
    ld a, [wSubCur]
    and a
    jr z, .use
    dec [hl]                     ; TOSS
    ld hl, StrTossed
    ld de, StrEmpty
    jr .msg
.use:
    push hl
    ld a, [wMaxHP]
    ld b, a
    ld a, [wHP]
    cp b
    pop hl
    jr c, .canHeal
    ld hl, StrHpFull
    ld de, StrEmpty
    jr .msg
.canHeal:
    dec [hl]
    ld a, [wItemCur]
    and a
    jr nz, .elixir
    ld b, 2                      ; Potion of Healing: 2d4 + 2
    ld c, 4
    call RollDice
    add a, 2
    call HealPlayer
    ld hl, StrUsedPotion
    ld de, StrRecovered
    jr .msg
.elixir:
    ld a, 99
    call HealPlayer
    ld hl, StrUsedElixir
    ld de, StrFullyHealed
.msg:
    ld bc, BackToItems
    jp ShowBoxMsg

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

; hl = line 1, de = line 2, bc = handler to run when dismissed
ShowBoxMsg:
    ld a, c
    ld [wMsgBack], a
    ld a, b
    ld [wMsgBack + 1], a
    push de
    push hl
    ld a, [wMenu]
    cp M_SKILLS
    jr z, .skills
    ld a, T_CURH
    call ItemCursor
    jr .box
.skills:
    ld a, T_CURH
    call SkillCursor
.box:
    ld a, M_BOXMSG
    ld [wMenu], a
    ld b, 0
    ld c, 9
    ld d, 18
    ld e, 5
    call DrawBox
    pop hl
    ld b, 1
    ld c, 10
    call WinPrint
    pop hl
    ld b, 1
    ld c, 12
    call WinPrint
    ld a, 16 + 14 * 8
    ld [wWinBottom], a
    jp HideSpritesUnderWindow

MenuBoxMsg:
    ldh a, [hNewKeys]
    and PAD_A | PAD_B
    ret z
    call SfxMenu
    ld a, [wMsgBack]
    ld l, a
    ld a, [wMsgBack + 1]
    ld h, a
    jp hl

; ---- skills (fighter class features) ------------------------------------
OpenSkills:
    ld a, M_SKILLS
    ld [wMenu], a
    xor a
    ld [wSkillCur], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 18
    ld e, 9
    call DrawBox
    ld hl, SkillList
    call WinPrintList
    call SkillUses
    ld a, T_CUR
    call SkillCursor
    ld a, 2 * 8 + 7
    ld b, 16
    ld c, 16 + 9 * 8
    call SetWindow
    call ShowFresh
    jp ReshowSprites

SkillUses:
    ld a, [wSecondWind]
    add a, T_DIGIT0
    ld b, 14
    ld c, 2
    jp WinPutTile

SkillCursor:
    push af
    ld a, [wSkillCur]
    ld e, a
    pop af
    ld b, 1
    ld c, 2
    ld d, 2
    jp DrawListCursor

BackToSkills:
    ld a, M_SKILLS
    ld [wMenu], a
    ld a, T_CUR
    call SkillCursor
    call SkillUses
    ld a, 16 + 9 * 8
    ld [wWinBottom], a
    jp ReshowSprites

MenuSkills:
    ld hl, wSkillCur
    ld b, 2
    call ListNav
    jr nc, .noMove
    ld a, T_CUR
    jp SkillCursor
.noMove:
    ldh a, [hNewKeys]
    and PAD_B
    jr z, .notB
    call SfxMenu
    jp ReturnToPause
.notB:
    ldh a, [hNewKeys]
    and PAD_A
    ret z
    call SfxMenu
    ld a, [wSkillCur]
    and a
    jp nz, ReturnToPause
    ld a, [wSecondWind]
    and a
    jr nz, .have
    ld hl, StrNoUses
    ld de, StrRestHint
    jr .msg
.have:
    ld a, [wMaxHP]
    ld b, a
    ld a, [wHP]
    cp b
    jr c, .heal
    ld hl, StrHpFull
    ld de, StrEmpty
    jr .msg
.heal:
    xor a
    ld [wSecondWind], a
    ld c, 10                     ; Second Wind: 1d10 + fighter level
    call RollDie
    ld b, a
    ld a, [wLevel]
    add a, b
    call HealPlayer
    ld hl, StrSecondWind
    ld de, StrCatchBreath
.msg:
    ld bc, BackToSkills
    jp ShowBoxMsg

; ---- bestiary ------------------------------------------------------------
OpenBestiary:
    ld a, M_BEAST
    ld [wMenu], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 18
    ld e, 12
    call DrawBox
    ld c, 0                      ; list monster names (????? if unseen)
.names:
    push bc
    ld a, c
    call RoomBit
    ld b, a
    ld a, [wSeen]
    and b
    pop bc
    push bc
    ld hl, StrUnknown
    jr z, .print
    ld a, c
    add a, a
    ld e, a
    ld d, 0
    ld hl, BeastNames
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
.print:
    ld a, c
    add a, a
    add a, 2
    ld c, a
    ld b, 2
    call WinPrint
    pop bc
    inc c
    ld a, c
    cp 4
    jr nz, .names
    ld hl, StrCancel
    ld b, 2
    ld c, 10
    call WinPrint
    call BeastCursor
    ld a, 2 * 8 + 7
    ld b, 16
    ld c, 16 + 12 * 8
    call SetWindow
    call ShowFresh
    jp ReshowSprites

BeastCursor:
    ld b, 1
    ld c, 2
    ld d, 5
    ld a, [wBeastCur]
    ld e, a
    ld a, T_CUR
    jp DrawListCursor

MenuBeast:
    ld hl, wBeastCur
    ld b, 5
    call ListNav
    jp c, BeastCursor
    ldh a, [hNewKeys]
    and PAD_B
    jr z, .notB
    call SfxMenu
    jp ReturnToPause
.notB:
    ldh a, [hNewKeys]
    and PAD_A
    ret z
    ld a, [wBeastCur]
    cp 4
    jr nz, .entry
    call SfxMenu
    jp ReturnToPause
.entry:
    call RoomBit
    ld b, a
    ld a, [wSeen]
    and b
    jp z, SfxBlock               ; not encountered yet
    call SfxMenu
    ; full-page monster entry (SRD 5.1 stat block + lore)
    ld a, M_BEASTPAGE
    ld [wMenu], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 18
    call DrawBox
    ld a, [wBeastCur]
    add a, a
    ld e, a
    ld d, 0
    ld hl, BeastPages
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call WinPrintList
    ld hl, BeastFooter
    call WinPrintList
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

MenuBeastPage:
    ldh a, [hNewKeys]
    and PAD_A | PAD_B
    ret z
    call SfxMenu
    jp OpenBestiary

; ---- options -------------------------------------------------------------
OpenOptions:
    ld a, M_OPTIONS
    ld [wMenu], a
    xor a
    ld [wOptCur], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 18
    call DrawBox
    ld hl, OptionsList
    call WinPrintList
    call OptionsCursors
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

OptionsCursors:
    ld hl, OptSpots              ; clear all marker spots
    ld c, 6
.clr:
    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    push bc
    ld c, a
    xor a
    call WinPutTile
    pop bc
    dec c
    jr nz, .clr
    ld a, [wPalSet]              ; palette marker
    ld e, a
    ld d, 0
    ld hl, PalCols
    add hl, de
    ld b, [hl]
    ld c, 4
    ld a, [wOptCur]
    and a
    ld a, T_CUR
    jr z, .p1
    ld a, T_CURH
.p1:
    call WinPutTile
    ld b, 1                      ; sound marker
    ld a, [wSoundOn]
    and a
    jr nz, .s0
    ld b, 8
.s0:
    ld c, 9
    ld a, [wOptCur]
    cp 1
    ld a, T_CUR
    jr z, .s1
    ld a, T_CURH
.s1:
    call WinPutTile
    ld a, [wOptCur]              ; cancel
    cp 2
    ret nz
    ld b, 1
    ld c, 12
    ld a, T_CUR
    jp WinPutTile

MenuOptions:
    ld hl, wOptCur
    ld b, 3
    call ListNav
    jp c, OptionsCursors
    ldh a, [hNewKeys]
    and PAD_B
    jr nz, .back
    ldh a, [hNewKeys]
    ld b, a
    ld a, [wOptCur]
    cp 2
    jr nz, .notCancel
    bit 0, b
    ret z
.back:
    call SfxMenu
    jp ReturnToPause
.notCancel:
    and a
    jr nz, .sound
    ld a, [wPalSet]              ; palette: left / right
    bit 5, b
    jr z, .pr
    and a
    ret z
    dec a
    jr .setPal
.pr:
    bit 4, b
    ret z
    cp 2
    ret nc
    inc a
.setPal:
    ld [wPalSet], a
    call LCDOff
    call LoadPalettes
    call LCDOn
    call SfxMenu
    jp OptionsCursors
.sound:
    bit 5, b
    jr z, .sr
    ld a, 1
    jr .setSnd
.sr:
    bit 4, b
    ret z
    xor a
.setSnd:
    ld [wSoundOn], a
    call SfxMenu
    jp OptionsCursors

; ---- end screens (window banner) -----------------------------------------
ShowGameOver:
    ld a, STATE_GAMEOVER
    ld [wGameState], a
    ld hl, StrGameOver
    jr ShowEndBanner
ShowWin:
    ld a, STATE_WIN
    ld [wGameState], a
    call SfxWin
    ld hl, StrWin
ShowEndBanner:
    push hl
    call BuildHUD
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 7
    call DrawBox
    pop hl
    ld b, 2
    ld c, 2
    call WinPrint
    ld hl, StrRestart
    ld b, 2
    ld c, 4
    call WinPrint
    ld a, 7
    ld b, 48
    ld c, 48 + 7 * 8
    call SetWindow
    jp ShowFresh

; ============================================================ palettes =====
LoadPalettes:                    ; LCD must be off
    ld a, [wIsCGB]
    and a
    ret z
    ld a, [wPalSet]
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl                   ; *128
    ld de, CgbPalettes
    add hl, de
    ld a, $80
    ldh [rBCPS], a
    ld c, 64
.bg:
    ld a, [hl+]
    ldh [rBCPD], a
    dec c
    jr nz, .bg
    ld a, $80
    ldh [rOCPS], a
    ld c, 64
.ob:
    ld a, [hl+]
    ldh [rOCPD], a
    dec c
    jr nz, .ob
    ret

; ============================================================ sound ========
SfxSwing:
    SFX_GUARD
    xor a
    ldh [rNR41], a
    ld a, $A1
    ldh [rNR42], a
    ld a, $24
    ldh [rNR43], a
    ld a, $80
    ldh [rNR44], a
    ret
SfxHit:
    SFX_GUARD
    ld a, $1C
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $F2
    ldh [rNR12], a
    xor a
    ldh [rNR13], a
    ld a, $86
    ldh [rNR14], a
    ret
SfxCrit:
    SFX_GUARD
    ld a, $16
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $F3
    ldh [rNR12], a
    ld a, $80
    ldh [rNR13], a
    ld a, $87
    ldh [rNR14], a
    ret
SfxBlock:
    SFX_GUARD
    ld a, $40
    ldh [rNR21], a
    ld a, $81
    ldh [rNR22], a
    ld a, $60
    ldh [rNR23], a
    ld a, $86
    ldh [rNR24], a
    ret
SfxKill:
    SFX_GUARD
    xor a
    ldh [rNR41], a
    ld a, $F3
    ldh [rNR42], a
    ld a, $55
    ldh [rNR43], a
    ld a, $80
    ldh [rNR44], a
    ret
SfxHurt:
    SFX_GUARD
    ld a, $80
    ldh [rNR21], a
    ld a, $F3
    ldh [rNR22], a
    xor a
    ldh [rNR23], a
    ld a, $84
    ldh [rNR24], a
    ret
SfxPickup:
    SFX_GUARD
    ld a, $15
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $F2
    ldh [rNR12], a
    xor a
    ldh [rNR13], a
    ld a, $86
    ldh [rNR14], a
    ret
SfxClear:
    SFX_GUARD
    ld a, $80
    ldh [rNR21], a
    ld a, $F4
    ldh [rNR22], a
    ld a, $C0
    ldh [rNR23], a
    ld a, $87
    ldh [rNR24], a
    ret
SfxWin:
    SFX_GUARD
    ld a, $17
    ldh [rNR10], a
    ld a, $80
    ldh [rNR11], a
    ld a, $F7
    ldh [rNR12], a
    xor a
    ldh [rNR13], a
    ld a, $85
    ldh [rNR14], a
    ret
SfxMenu:
    SFX_GUARD
    ld a, $80
    ldh [rNR21], a
    ld a, $71
    ldh [rNR22], a
    ld a, $C0
    ldh [rNR23], a
    ld a, $87
    ldh [rNR24], a
    ret

; ============================================================ interrupts ===
VBlankHandler:
    push af
    push bc
    push de
    push hl
    ld a, HIGH(wShadowOAM)
    call hOAMDMA
    ld a, [wWinDirtyAny]
    and a
    call nz, FlushWinRows
    ld a, [wHudOn]
    and a
    jr z, .noHud
    ld hl, wHudBuf
    ld de, SCRN
    REPT 20
    ld a, [hl+]
    ld [de], a
    inc e
    ENDR
.noHud:
    ld a, [wWinOn]               ; window visibility / position / cut-off
    and a
    jr z, .winOff
    ld a, [wWinHide]
    and a
    jr z, .show
    ld a, [wWinDirtyAny]
    and a
    jr nz, .winOff               ; still streaming a fresh menu
    xor a
    ld [wWinHide], a
.show:
    ld a, [wWinX]
    ldh [rWX], a
    ld a, [wWinY]
    ldh [rWY], a
    ld a, [wWinBottom]
    cp 144
    jr c, .lyc
    ld a, $FF
.lyc:
    ldh [rLYC], a
    ldh a, [rLCDC]
    set 5, a
    ldh [rLCDC], a
    jr .done
.winOff:
    ldh a, [rLCDC]
    res 5, a
    ldh [rLCDC], a
    ld a, $FF
    ldh [rLYC], a
.done:
    ld a, 1
    ldh [hVBlankFlag], a
    pop hl
    pop de
    pop bc
    pop af
    reti

StatHandler:                     ; LY == LYC: window off for the rest of the frame
    push af
    ldh a, [rLCDC]
    res 5, a
    ldh [rLCDC], a
    pop af
    reti

FlushWinRows:                    ; copy up to 3 dirty rows to the window map
    ld hl, wWinDirty
    ld b, 0
    ld c, 3
.scan:
    ld a, [hl]
    and a
    jr z, .next
    xor a
    ld [hl], a
    push hl
    push bc
    ld a, b                      ; de = WINMAP + row * 32
    swap a
    add a, a
    and $E0
    ld e, a
    ld a, b
    srl a
    srl a
    srl a
    add a, HIGH(WINMAP)
    ld d, a
    ld l, b                      ; hl = wWinBuf + row * 20
    ld h, 0
    add hl, hl
    add hl, hl
    push de
    ld d, h
    ld e, l
    add hl, hl
    add hl, hl
    add hl, de
    ld de, wWinBuf
    add hl, de
    pop de
    REPT 20
    ld a, [hl+]
    ld [de], a
    inc e
    ENDR
    pop bc
    pop hl
    dec c
    ret z
.next:
    inc hl
    inc b
    ld a, b
    cp 18
    jr nz, .scan
    xor a
    ld [wWinDirtyAny], a
    ret

DMARoutine:
    ldh [rDMA], a
    ld a, 40
.wait:
    dec a
    jr nz, .wait
    ret
DMARoutineEnd:

; ============================================================ utils ========
WaitVBlank:
    xor a
    ldh [hVBlankFlag], a
.wait:
    halt
    ldh a, [hVBlankFlag]
    and a
    jr z, .wait
    ret

LCDOff:
    ldh a, [rLCDC]
    bit 7, a
    ret z
.wait:
    ldh a, [rLY]
    cp 144
    jr c, .wait
    xor a
    ldh [rLCDC], a
    ret

LCDOn:
    ld a, LCDC_ON
    ldh [rLCDC], a
    ret

ReadJoypad:
    ld a, $20
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0F
    swap a
    ld b, a
    ld a, $10
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0F
    or b
    ld b, a
    ld a, $30
    ldh [rP1], a
    ldh a, [hKeys]
    xor b
    and b
    ldh [hNewKeys], a
    ld a, b
    ldh [hKeys], a
    ret

Rand:                            ; LFSR mixed with DIV; preserves all but a
    push bc
    ldh a, [hRng]
    add a, a
    jr nc, .nx
    xor $1D
.nx:
    ldh [hRng], a
    ld b, a
    ldh a, [rDIV]
    xor b
    pop bc
    ret

RandDir:
    call Rand
    and 3
    dec a
    cp 2
    ret nz
    xor a
    ret

RollDie:                         ; c = sides -> a = 1..c ; preserves bc de hl
    call Rand
.mod:
    cp c
    jr c, .ok
    sub c
    jr .mod
.ok:
    inc a
    ret

RollDice:                        ; b = count, c = sides -> a = sum ; preserves bc de hl
    push bc
    push de
    ld d, 0
.l:
    call RollDie
    add a, d
    ld d, a
    dec b
    jr nz, .l
    ld a, d
    pop de
    pop bc
    ret

Memcpy:
    ld a, [hl+]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, Memcpy
    ret

Memset:
    ld d, a
.loop:
    ld a, d
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ret

Copy1bpp:
    ld a, [hl+]
    ld [de], a
    inc de
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, Copy1bpp
    ret

; ============================================================ data =========
SECTION "Data", ROM0

BitTable:   db 1, 2, 4, 8, 16, 32, 64, 128

; CGB BG palette per room tile id
AttrTable:  db 0, 0, 0, 1, 2, 3, 4, 5, 5, 5, 5

; ---- SRD 5.1 monster stat blocks --------------------------------------
;            AC  HP  ATK  dice  sides bonus  XP
MonsterStats:
    db 15,  7,  4,   1,    6,    2
    dw 50                        ; GOBLIN       CR 1/4
    db 13, 22,  4,   1,    6,    2
    dw 50                        ; GIANT BAT    CR 1/4
    db 13, 13,  4,   1,    6,    2
    dw 50                        ; SKELETON     CR 1/4
    db 11, 59,  6,   2,    8,    4
    dw 450                       ; OGRE         CR 2

; XP needed to reach level 2, 3, 4, 5 (5e advancement table)
LevelTable: dw 300, 900, 2700, 6500

DirVec:
    db 0, 1
    db 0, $FF
    db $FF, 0
    db 1, 0

SwordRects:
    db 2, 13, 12, 14
    db 2, -9, 12, 14
    db -11, 4, 14, 12
    db 13, 4, 14, 12

SwordSprites:
    db 4, 14, T_SWORD_VH, OP_SWORD,              4, 22, T_SWORD_VT, OP_SWORD
    db 4, -6, T_SWORD_VT, OP_SWORD | OAM_YFLIP,  4, 2,  T_SWORD_VH, OP_SWORD | OAM_YFLIP
    db -6, 8, T_SWORD_HT, OP_SWORD | OAM_XFLIP,  2, 8,  T_SWORD_HH, OP_SWORD | OAM_XFLIP
    db 14, 8, T_SWORD_HH, OP_SWORD,              22, 8, T_SWORD_HT, OP_SWORD

SpawnTable:
    db TYPE_GOBLIN, 120, 24,     TYPE_GOBLIN, 40, 96,     TYPE_NONE, 0, 0
    db TYPE_BAT, 64, 40,         TYPE_BAT, 120, 88,       TYPE_GOBLIN, 40, 104
    db TYPE_GOBLIN, 104, 24,     TYPE_SKELETON, 56, 88,   TYPE_GOBLIN, 120, 104
    db TYPE_OGRE, 72, 56,        TYPE_SKELETON, 32, 24,   TYPE_SKELETON, 120, 96

PalCols:  db 1, 8, 14
OptSpots: db 1, 4,  8, 4,  14, 4,  1, 9,  8, 9,  1, 12

RoomTable:
    dw Room0, Room1, Room2, Room3

SETCHARMAP room
Room0:  ; entrance hall
    db "####################"
    db "#,,......TT.......,#"
    db "#,.......TT........#"
    db "#....o.............#"
    db "#..........,,......#"
    db "#...TT.....,....o..#"
    db "#...TT.............#"
    db "#..................."
    db "#..,......,........."
    db "#..................."
    db "#.......~~~~.......#"
    db "#..o....~~~~...TT..#"
    db "#..............TT..#"
    db "#.,,..............,#"
    db "#..TT.........o....#"
    db "#..TT..............#"
    db "########....########"
Room1:  ; bat roost
    db "####################"
    db "#~~~~..........,,..#"
    db "#~~~~...o..........#"
    db "#~~.........TT.....#"
    db "#...........TT..o..#"
    db "#..,...............#"
    db "#......o.....,.....#"
    db "...................#"
    db ".........,.........#"
    db "...............TT..#"
    db "#...TT.........TT..#"
    db "#...TT.....o.......#"
    db "#..................#"
    db "#.......,,.....~~~~#"
    db "#..o............~~~#"
    db "#..................#"
    db "########....########"
Room2:  ; goblin den
    db "########....########"
    db "#..................#"
    db "#..TT..........o...#"
    db "#..TT..............#"
    db "#.......,,.........#"
    db "#..o...........TT..#"
    db "#..............TT..#"
    db "#..................."
    db "#....~~~~..........."
    db "#....~~~~....o......"
    db "#..................#"
    db "#..,,.......TT.....#"
    db "#...........TT.....#"
    db "#..o...............#"
    db "#.........,....o...#"
    db "#,,................#"
    db "####################"
Room3:  ; the ogre's crypt
    db "########....########"
    db "#..................#"
    db "#.o..............o.#"
    db "#..................#"
    db "#....TT......TT....#"
    db "#....TT......TT....#"
    db "#..................#"
    db "...................#"
    db "..........,........#"
    db "...................#"
    db "#..................#"
    db "#....TT......TT....#"
    db "#....TT......TT....#"
    db "#..................#"
    db "#.o..............o.#"
    db "#..................#"
    db "####################"
SETCHARMAP text

; ============================================================ text =========
SECTION "Text", ROM0

MACRO TXT                        ; TXT col, row, label
    db \1, \2
    dw \3
ENDM

TitleList:
    TXT 3, 3, StrTitle
    TXT 3, 5, StrTagline
    TXT 2, 11, StrGoal1
    TXT 3, 12, StrGoal2
    TXT 4, 14, StrPress
    TXT 3, 16, StrCredit
    db $FF
StrTitle:    db "DUNGEON QUEST", $FF
StrTagline:  db "A 5E ADVENTURE", $FF
StrGoal1:    db "SLAY THE OGRE OF", $FF
StrGoal2:    db "THE OLD CRYPT", $FF
StrPress:    db "PRESS START", $FF
StrCredit:   db "RULES: SRD 5.1", $FF

IntroList:
    TXT 2, 2, Intro1
    TXT 2, 3, Intro2
    TXT 2, 4, Intro3
    TXT 2, 5, Intro4
    TXT 2, 7, Intro5
    TXT 2, 8, Intro6
    TXT 2, 9, Intro7
    TXT 2, 11, Intro8
    TXT 2, 12, Intro9
    TXT 2, 14, Intro10
    TXT 6, 16, StrPressA
    db $FF
Intro1:  db "OAKHOLLOW WAKES", $FF
Intro2:  db "TO FEAR. GOBLINS", $FF
Intro3:  db "RAID BY NIGHT AND", $FF
Intro4:  db "VANISH BELOW.", $FF
Intro5:  db "AN OGRE NOW RULES", $FF
Intro6:  db "THE OLD CRYPT AND", $FF
Intro7:  db "ITS DEAD WALK.", $FF
Intro8:  db "ROLAND, FIGHTER", $FF
Intro9:  db "OF THE WATCH...", $FF
Intro10: db "CLEAR ALL 4 HALLS", $FF
StrPressA: db "PRESS A", $FF

PauseList:
    TXT 2, 2, StrStatus
    TXT 2, 4, StrItems
    TXT 2, 6, StrSkills
    TXT 2, 8, StrBestiary
    TXT 2, 10, StrOptions
    TXT 2, 12, StrRetire
    TXT 2, 14, StrExit
    db $FF
StrStatus:   db "STATUS", $FF
StrItems:    db "ITEMS", $FF
StrSkills:   db "SKILLS", $FF
StrBestiary: db "BESTIARY", $FF
StrOptions:  db "OPTIONS", $FF
StrRetire:   db "RETIRE", $FF
StrExit:     db "EXIT", $FF

StatusList:
    TXT 2, 2, StrName
    TXT 11, 2, StrLV
    TXT 2, 3, StrClass
    TXT 2, 5, StrHP
    TXT 7, 5, StrSlash
    TXT 12, 5, StrAC
    TXT 2, 6, StrXPLabel
    TXT 2, 7, StrNext
    TXT 2, 9, StrAbil1
    TXT 2, 10, StrAbil2
    TXT 2, 11, StrAbil3
    TXT 2, 13, StrProf
    TXT 2, 14, StrWeapon
    TXT 2, 15, StrWind
    TXT 2, 16, StrRooms
    db $FF
StrName:    db "ROLAND", $FF
StrLV:      db "LV", $FF
StrClass:   db "HUMAN FIGHTER", $FF
StrHP:      db "HP", $FF
StrSlash:   db "/", $FF
StrAC:      db "AC 16", $FF
StrXPLabel: db "XP", $FF
StrNext:    db "NEXT", $FF
StrMax:     db " MAX", $FF
StrAbil1:   db "STR 15  DEX 13", $FF
StrAbil2:   db "CON 14  INT  8", $FF
StrAbil3:   db "WIS 12  CHA 10", $FF
StrProf:    db "PROF +2  ATK +4", $FF
StrWeapon:  db "LONGSWORD 1D8+2", $FF
StrWind:    db "SECOND WIND  /1", $FF
StrRooms:   db "ROOMS  /4", $FF

ItemList:
    TXT 2, 2, StrPotion
    TXT 2, 4, StrElixir
    TXT 2, 6, StrCancel
    db $FF
StrPotion:  db "POTION", $FF
StrElixir:  db "ELIXIR", $FF
StrCancel:  db "CANCEL", $FF
SubList:
    TXT 3, 10, StrUse
    TXT 10, 10, StrToss
    db $FF
StrUse:     db "USE", $FF
StrToss:    db "TOSS", $FF

SkillList:
    TXT 2, 2, StrSWName
    TXT 15, 2, StrOfOne
    TXT 2, 4, StrCancel
    TXT 2, 6, StrSWDesc1
    TXT 2, 7, StrSWDesc2
    db $FF
StrSWName:  db "SECOND WIND", $FF
StrOfOne:   db "/1", $FF
StrSWDesc1: db "HEAL 1D10+LV.", $FF
StrSWDesc2: db "RECHARGES: REST", $FF

StrEmpty:       db $FF
StrNoneLeft:    db "NONE LEFT!", $FF
StrTossed:      db "TOSSED ONE.", $FF
StrHpFull:      db "HP IS FULL!", $FF
StrUsedPotion:  db "USED POTION!", $FF
StrRecovered:   db "HP RESTORED.", $FF
StrUsedElixir:  db "USED ELIXIR!", $FF
StrFullyHealed: db "FULLY HEALED!", $FF
StrNoUses:      db "NO USES LEFT.", $FF
StrRestHint:    db "CLEAR A ROOM.", $FF
StrSecondWind:  db "SECOND WIND!", $FF
StrCatchBreath: db "HP RESTORED.", $FF

OptionsList:
    TXT 2, 2, StrPalette
    TXT 2, 4, StrColor
    TXT 9, 4, StrGreen
    TXT 15, 4, StrGray
    TXT 2, 7, StrSound
    TXT 2, 9, StrOn
    TXT 9, 9, StrOff
    TXT 2, 12, StrCancel
    TXT 2, 15, StrGbcNote
    db $FF
StrPalette: db "PALETTE", $FF
StrColor:   db "COLOR", $FF
StrGreen:   db "GREEN", $FF
StrGray:    db "GRAY", $FF
StrSound:   db "SOUND", $FF
StrOn:      db "ON", $FF
StrOff:     db "OFF", $FF
StrGbcNote: db "PALETTE: GBC/SP", $FF

StrGameOver: db "YOU HAVE FALLEN", $FF
StrWin:      db "OAKHOLLOW SAVED!", $FF
StrRestart:  db "PRESS START", $FF
StrUnknown:  db "?????", $FF

; HUD messages: exactly 5 tiles
MsgMiss:   db "MISS "
MsgCrit:   db "CRIT!"
MsgBlock:  db "BLOCK"
MsgLvUp:   db "LV UP"
MsgHeal:   db "HEAL "
MsgPotion: db "POT+1"

; ---- bestiary (stats: SRD 5.1, CC-BY-4.0; lore: original) --------------
BeastNames: dw StrGoblin, StrBat, StrSkeleton, StrOgre
StrGoblin:   db "GOBLIN", $FF
StrBat:      db "GIANT BAT", $FF
StrSkeleton: db "SKELETON", $FF
StrOgre:     db "OGRE", $FF

BeastPages: dw PageGoblin, PageBat, PageSkeleton, PageOgre

PageGoblin:
    TXT 2, 2, StrGoblin
    TXT 2, 3, BGob1
    TXT 2, 5, BGob2
    TXT 2, 6, BGob3
    TXT 2, 8, BGob4
    TXT 2, 9, BGob5
    TXT 2, 11, BGob6
    TXT 2, 12, BGob7
    TXT 2, 13, BGob8
    db $FF
BGob1: db "SMALL HUMANOID", $FF
BGob2: db "AC 15   HP 7", $FF
BGob3: db "CR 1/4  XP 50", $FF
BGob4: db "SCIMITAR  +4", $FF
BGob5: db "1D6+2 SLASHING", $FF
BGob6: db "CRUEL RAIDERS WHO", $FF
BGob7: db "STRIKE IN PACKS", $FF
BGob8: db "FROM THE DARK.", $FF

PageBat:
    TXT 2, 2, StrBat
    TXT 2, 3, BBat1
    TXT 2, 5, BBat2
    TXT 2, 6, BBat3
    TXT 2, 8, BBat4
    TXT 2, 9, BBat5
    TXT 2, 11, BBat6
    TXT 2, 12, BBat7
    TXT 2, 13, BBat8
    db $FF
BBat1: db "LARGE BEAST", $FF
BBat2: db "AC 13   HP 22", $FF
BBat3: db "CR 1/4  XP 50", $FF
BBat4: db "BITE  +4", $FF
BBat5: db "1D6+2 PIERCING", $FF
BBat6: db "IT HUNTS BY SOUND", $FF
BBat7: db "AND NEVER SITS", $FF
BBat8: db "STILL.", $FF

PageSkeleton:
    TXT 2, 2, StrSkeleton
    TXT 2, 3, BSk1
    TXT 2, 5, BSk2
    TXT 2, 6, BSk3
    TXT 2, 8, BSk4
    TXT 2, 9, BSk5
    TXT 2, 11, BSk6
    TXT 2, 12, BSk7
    TXT 2, 13, BSk8
    db $FF
BSk1: db "MEDIUM UNDEAD", $FF
BSk2: db "AC 13   HP 13", $FF
BSk3: db "CR 1/4  XP 50", $FF
BSk4: db "SHORTSWORD  +4", $FF
BSk5: db "1D6+2 PIERCING", $FF
BSk6: db "OLD GUARDS OF THE", $FF
BSk7: db "CRYPT, RAISED BY", $FF
BSk8: db "DARK MAGIC.", $FF

PageOgre:
    TXT 2, 2, StrOgre
    TXT 2, 3, BOg1
    TXT 2, 5, BOg2
    TXT 2, 6, BOg3
    TXT 2, 8, BOg4
    TXT 2, 9, BOg5
    TXT 2, 11, BOg6
    TXT 2, 12, BOg7
    TXT 2, 13, BOg8
    db $FF
BOg1: db "LARGE GIANT", $FF
BOg2: db "AC 11   HP 59", $FF
BOg3: db "CR 2    XP 450", $FF
BOg4: db "GREATCLUB  +6", $FF
BOg5: db "2D8+4 BLUDGEONING", $FF
BOg6: db "A HULKING BRUTE", $FF
BOg7: db "WHO CRAVES GOLD", $FF
BOg8: db "AND WARM MEALS.", $FF

BeastFooter:
    TXT 2, 16, StrBack
    db $FF
StrBack: db "B: BACK", $FF

; ============================================================ RAM ==========
SECTION "ShadowOAM", WRAM0, ALIGN[8]
wShadowOAM: ds 160

SECTION "Vars", WRAM0
wIsCGB:        db
wGameState:    db
wPlayerX:      db
wPlayerY:      db
wPlayerDir:    db
wPlayerInv:    db
wPlayerMoving: db
wAttack:       db
wKnockX:       db
wKnockY:       db
wKnockT:       db
wHP:           db
wMaxHP:        db
wLevel:        db
wXP:           dw
wSecondWind:   db
wItems:        ds 2
wWasCrit:      db
wMsgT:         db
wMsgPtr:       dw
wRoom:         db
wRoomsCleared: db
wSeen:         db
wPickupOn:     db
wPickupX:      db
wPickupY:      db
wHudOn:        db
wOamPtr:       dw
wTmp:          ds 2
wRectA:        ds 4
wRectB:        ds 4
wCur:          ds ENEMY_SIZE
wEnemies:      ds ENEMY_SIZE * MAX_ENEMIES
wHudBuf:       ds 20
wRoomMap:      ds ROOM_W * ROOM_H
wNumBuf:       ds 6
wPalSet:       db
wSoundOn:      db
wMenu:         db
wPauseCur:     db
wItemCur:      db
wSubCur:       db
wSkillCur:     db
wBeastCur:     db
wOptCur:       db
wMsgBack:      dw
wTmpTile:      db
wTmpSel:       db
wBoxCol:       db
wBoxRow:       db
wBoxCur:       db
wBoxW:         db
wBoxH:         db
wWinOn:        db
wWinHide:      db
wWinX:         db
wWinY:         db
wWinBottom:    db
wWinDirtyAny:  db
wWinDirty:     ds 18
wWinBuf:       ds 20 * 18

SECTION "HRAM", HRAM
hOAMDMA:     ds 16
hVBlankFlag: db
hKeys:       db
hNewKeys:    db
hFrame:      db
hRng:        db
