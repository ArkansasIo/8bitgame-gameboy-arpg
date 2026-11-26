; ============================================================================
;  ARPG GB QUEST v0.7.0 (build 20261126) - action RPG for Game Boy Color
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
DEF rROMB0 EQU $2000
DEF rRAMG  EQU $0000
DEF BANK_MAIN  EQU 1
DEF BANK_ROOMS EQU 2
DEF BANK_GFX   EQU 3

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
DEF M_MAP       EQU 10
DEF M_CLASS     EQU 11
DEF M_SHOP      EQU 12
DEF M_SHOPLIST  EQU 13
DEF M_INN       EQU 14
DEF M_DIALOG    EQU 15
DEF M_QUESTS    EQU 16
DEF M_SAVEASK   EQU 17
DEF M_ALLOC     EQU 18
DEF M_GEAR      EQU 19
DEF M_GEARSUB   EQU 20
DEF M_SMITH     EQU 21
DEF M_RACE      EQU 22
DEF INV_SLOTS   EQU 10

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
DEF MAX_ENEMIES  EQU 4
DEF ENEMY_SIZE   EQU 32
DEF ROOM_W       EQU 20
DEF ROOM_H       EQU 17

DEF TYPE_NONE     EQU 0

; monster stat block offsets (8 bytes each, SRD 5.1)
DEF MS_AC   EQU 0
DEF MS_HP   EQU 1
DEF MS_ATK  EQU 2
DEF MS_DN   EQU 3
DEF MS_DS   EQU 4
DEF MS_DB   EQU 5
DEF MS_XP   EQU 6
DEF MS_TILE EQU 8
DEF MS_GOLD EQU 9
DEF MS_FLAGS EQU 10
DEF FLAG_TOWN EQU 1
DEF FLAG_BOSS EQU 2
DEF FLAG_LOCKED EQU 4
DEF T_COIN EQU 85
DEF T_FIREBOLT EQU 86
DEF T_SPARK EQU 87

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
DEF E_PAL   EQU 11
DEF E_HPHI  EQU 12
DEF E_LVL   EQU 13
DEF E_FRESH EQU 15
DEF E_STUN  EQU 16
DEF E_SLOW  EQU 17
DEF E_DOT   EQU 18
DEF E_DOTPWR EQU 19

MACRO TXT                        ; TXT col, row, label
    db \1, \2
    dw \3
ENDM

MACRO SFX_GUARD
    ld a, [wSoundOn]
    and a
    ret z
ENDM

; graphics + "text" charmap (selected for the rest of the file)
INCLUDE "gfx.inc"
INCLUDE "world.inc"
INCLUDE "data.inc"
INCLUDE "items.inc"

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
    ld a, BANK_MAIN
    ld [rROMB0], a
    ld a, BANK_GFX
    ld [rROMB0], a
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
    ld a, BANK_MAIN
    ld [rROMB0], a
    xor a
    ld [wZone], a

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

    call BootScreen

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
    call HasSave
    jr z, .new
    call TitleChoice
    and a
    jr nz, .new
    call TitleLoad
    jp nc, StartTitle
    jp GameLoop
.new:
    call ShowLoading
    xor a
    ld [wWinOn], a
    call NewGame
    jp GameLoop

; developer logo screen: crest + studio name, ~2.5 s or any button
BootScreen:
    call LCDOff
    ld hl, LogoTiles
    ld de, $9000 + 80 * 16
    ld bc, LogoTilesEnd - LogoTiles
    ld a, BANK_GFX
    call FarCopy
    call WinClearAll
    ld c, 3                      ; 4x4 crest at cols 8-11, rows 3-6
    ld a, 80
.lr:
    ld b, 8
.lc:
    push af
    call WinPutTile
    pop af
    inc a
    inc b
    ld e, a
    ld a, b
    cp 12
    ld a, e
    jr nz, .lc
    inc c
    ld e, a
    ld a, c
    cp 7
    ld a, e
    jr nz, .lr
    ld hl, BootList
    call WinPrintList
    ld hl, wWinBuf               ; to the BG map
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
    xor a
    ldh [rVBK], a
.noAttr:
    call LCDOn
    call SfxClear
    ld b, 150
.wait:
    push bc
    call WaitVBlank
    call ReadJoypad
    pop bc
    ldh a, [hNewKeys]
    and a
    jr nz, .fade
    dec b
    jr nz, .wait
.fade:                           ; DMG palette fade to white
    ld hl, FadeSteps
    ld c, 4
.f:
    ld a, [hl+]
    ldh [rBGP], a
    ld b, 6
.fw:
    push bc
    push hl
    call WaitVBlank
    pop hl
    pop bc
    dec b
    jr nz, .fw
    dec c
    jr nz, .f
    ld a, %11100100
    ldh [rBGP], a
    ret

FadeSteps: db %10010000, %01000000, %00000000, %00000000

TitleChoice:                     ; -> a = 0 continue, 1 new game
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 6
    call DrawBox
    ld hl, StrContinue
    ld b, 3
    ld c, 2
    call WinPrint
    ld hl, StrNewGame
    ld b, 3
    ld c, 4
    call WinPrint
    xor a
    ld [wSubCur], a
    ld a, 7
    ld b, 96
    ld c, 144
    call SetWindow
    call ShowFresh
.loop:
    ld b, 2
    ld c, 2
    ld d, 2
    ld a, [wSubCur]
    ld e, a
    ld a, T_CUR
    call DrawListCursor
    call WaitVBlank
    call ReadJoypad
    ld hl, hFrame
    inc [hl]
    call DrawTitleSprites
    ldh a, [hNewKeys]
    and $C0
    jr z, .noMove
    ld a, [wSubCur]
    xor 1
    ld [wSubCur], a
    call SfxMenu
.noMove:
    ldh a, [hNewKeys]
    and PAD_A | PAD_START
    jr z, .loop
    call SfxMenu
    ld a, [wSubCur]
    ret

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
    call UpdateProjectile
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
    ld [wBossFlags], a
    ld [wGold], a
    ld [wGold + 1], a
    ld [wPickupOn], a
    ld [wMsgT], a
    ld [wSeen], a
    ld [wSeen + 1], a
    ld [wBeastPage], a
    ld [wBannerT], a
    ld [wInvCur], a
    ld [wInvTop], a
    ld [wSkillCur], a
    ld [wProjOn], a
    ld [wPauseCur], a
    ld [wItemCur], a
    ld [wBeastCur], a
    ld hl, wQState
    ld bc, 8
    xor a
    call Memset
    ld a, $FF
    ld [wLoadedZone], a
    ld a, STATE_PLAY
    ld [wGameState], a
    call BuildHUD
    ld a, 1
    ld [wHudOn], a
    call LoadRoom
    jp OpenClassSelect

; ============================================================ rooms ========
LoadRoom:
    call LCDOff
    ld a, BANK_ROOMS             ; copy the room map out of bank 2
    ld [rROMB0], a
    ld a, [wRoom]
    add a, a
    ld e, a
    ld d, 0
    ld hl, RoomMaps
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld de, wRoomMap
    ld bc, ROOM_W * ROOM_H
    call Memcpy
    ld a, BANK_MAIN
    ld [rROMB0], a
    call GetRoomInfo
    ld de, 4
    add hl, de
    ld a, [hl+]
    ld [wZone], a
    ld a, [hl]
    ld [wRoomFlags], a
    xor a
    ld [wRested], a
    ld a, [wZone]                ; new zone: swap biome tiles + palettes
    ld b, a
    ld a, [wLoadedZone]
    cp b
    jr z, .sameZone
    ld a, b
    ld [wLoadedZone], a
    call LoadBiome
    ld a, 1
    ld [wBannerPending], a
.sameZone:
    ld hl, wRoomMap
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

    ld a, [wIsCGB]               ; CGB attributes: HUD row + per-tile palettes
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
    ld [wProjOn], a
    ; spawns: 4 per room (type, x, y, palette); monsters respawn on entry
    ld a, [wRoom]
    swap a                       ; *16
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
    ld a, [hl+]
    ld [wCur + E_PAL], a
    push hl
    ld a, [wCur + E_TYPE]
    and a
    jr z, .empty
    cp NPC_BASE
    jr nc, .empty
    call GetTypeStats
    push hl
    ld de, MS_FLAGS              ; a defeated zone boss stays dead
    add hl, de
    ld a, [wBossFlags]
    and [hl]
    pop hl
    jr z, .alive
    xor a
    ld [wCur + E_TYPE], a
    jr .empty
.alive:
    call SpawnLevel              ; level from the room's band
    call CalcCurMonster
    ld a, [wMHP]
    ld [wCur + E_HP], a
    ld a, [wMHP + 1]
    ld [wCur + E_HPHI], a
    ld a, 1
    ld [wCur + E_FRESH], a
    ld a, 30
    ld [wCur + E_TIMER], a
    ld a, [wCur + E_TYPE]
    call MarkSeen
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
    jp LCDOn

SpawnLevel:                      ; wCur level = room level (+0..3 unless boss)
    ld a, [wRoom]
    add a, a
    ld e, a
    ld d, 0
    ld hl, RoomLevels
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [wCur + E_PAL]
    cp 7                         ; palette 7 = boss slot: exact level
    jr z, .set
    call Rand
    and 3
    add a, l
    ld l, a
    jr nc, .set
    inc h
.set:
    ld a, l
    ld [wCur + E_LVL], a
    ld a, h
    ld [wCur + E_LVL + 1], a
    ret

GetRoomInfo:                     ; hl = RoomInfo + room * 8 (clobbers de)
    ld a, [wRoom]
GetRoomInfoA:
    add a, a
    add a, a
    add a, a
    ld e, a
    ld d, 0
    ld hl, RoomInfo
    add hl, de
    ret

MarkSeen:                        ; a = monster type -> set bestiary bit
    dec a
    ld c, a
    srl a
    srl a
    srl a
    ld e, a
    ld d, 0
    ld hl, wSeen
    add hl, de
    ld a, c
    and 7
    call RoomBit
    or [hl]
    ld [hl], a
    ret

IsSeen:                          ; a = index (0..) -> nz if seen
    ld c, a
    srl a
    srl a
    srl a
    ld e, a
    ld d, 0
    ld hl, wSeen
    add hl, de
    ld a, c
    and 7
    call RoomBit
    and [hl]
    ret

FarCopy:                         ; a = bank, hl = src, de = dst, bc = len (ROM0 only!)
    ld [rROMB0], a
    call Memcpy
    ld a, BANK_MAIN
    ld [rROMB0], a
    ret

LoadBiome:                       ; LCD off. tiles 1-6 + palettes for wZone
    ld a, [wZone]
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl                   ; *32
    ld d, h
    ld e, l
    add hl, hl                   ; *64
    add hl, de                   ; *96
    ld de, BiomeTiles
    add hl, de
    ld de, $9000 + 16
    ld bc, 96
    ld a, BANK_GFX
    ld [rROMB0], a
    call Memcpy
    ld a, BANK_MAIN
    ld [rROMB0], a
    jp LoadPalettes

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
    ld a, [wRested]
    and a
    ret nz
    ld a, [wRoomFlags]
    and FLAG_TOWN
    ret nz
    ld hl, wEnemies
    ld b, MAX_ENEMIES
    ld de, ENEMY_SIZE
.l:
    ld a, [hl]
    and a
    ret nz
    add hl, de
    dec b
    jr nz, .l
    ld a, 1
    ld [wRested], a
    ld [wCharge1], a             ; short rest: class charges recharge
    ld [wCharge2], a
    jp SfxClear

; ============================================================ player =======
UpdatePlayer:
    call EffectsTick
    ld a, [wGameState]
    cp STATE_PLAY
    ret nz                       ; a DoT may have ended the run
    call ClassTick
    call MPTick
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
    ld a, [wDebStun]             ; stunned: no input at all
    and a
    jp nz, .room
    ld a, [wAttack]
    and a
    jr nz, .attack
    ld a, [wDebSlow]             ; slowed: move every other frame
    and a
    jr z, .notSlow
    ldh a, [hFrame]
    and 1
    jr nz, .attack
.notSlow:
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
    ld a, [wDashT]               ; rogue dash: double speed
    and a
    call nz, PlayerTryMove
.attack:
    ldh a, [hNewKeys]
    and PAD_A
    jr nz, .aPress
    ldh a, [hNewKeys]
    and PAD_B
    jr z, .noNewAttack
    call ClassBAction
    jr nz, .room
    jr .swing
.aPress:
    call FindNpcInFront
    jr nc, .swing
    jp TalkTo
.swing:
    ld a, [wAttack]
    and a
    jr nz, .noNewAttack
    ld a, [wAtkTime]
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
    ld a, [wBannerT]
    and a
    jr z, .noBanner
    dec a
    ld [wBannerT], a
    jr nz, .noBanner
    xor a
    ld [wWinOn], a
.noBanner:
    ld a, [wPlayerX]
    ld b, 2
    cp 2
    jr c, .exit
    ld b, 3
    cp 142
    jr nc, .exit
    ld a, [wPlayerY]
    ld b, 0
    cp 4
    jr c, .exit
    ld b, 1
    cp 126
    ret c
.exit:                           ; b = direction N S W E
    push bc
    call GetRoomInfo
    pop bc
    ld a, l
    add a, b
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, [hl]
    cp 255
    ret z
    ld c, a                      ; target room
    push bc
    call GetRoomInfoA
    ld de, 5
    add hl, de
    pop bc
    ld a, [hl]
    and FLAG_LOCKED
    jr z, .open
    ld a, [wBossFlags]
    and $0F
    cp $0F
    jr z, .open
    ; sealed: push the hero back and say why
    ld a, b
    ld hl, BounceTable
    call PosFromTable
    xor a
    ld [wKnockT], a
    ld hl, StrSealed
    jp ShowBanner
.open:
    ld a, c
    ld [wRoom], a
    ld a, b
    ld hl, EnterTable
    call PosFromTable
    xor a
    ld [wKnockT], a
    ld [wAttack], a
    call LoadRoom
    ld a, [wBannerPending]
    and a
    ret z
    xor a
    ld [wBannerPending], a
    ld a, [wZone]
    add a, a
    ld e, a
    ld d, 0
    ld hl, ZoneBanners
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp ShowBanner

; a = direction, hl = table of (axis, value): axis 0 = x, 1 = y
PosFromTable:
    add a, a
    add a, l
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, [hl+]
    and a
    ld a, [hl]
    jr nz, .y
    ld [wPlayerX], a
    ret
.y:
    ld [wPlayerY], a
    ret

; zone-name banner across the top of the screen (hl = string)
ShowBanner:
    push hl
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 3
    call DrawBox
    pop hl
    push hl
    ld b, 0                      ; centre it
.len:
    ld a, [hl+]
    cp $FF
    jr z, .got
    inc b
    jr .len
.got:
    ld a, 20
    sub b
    srl a
    ld b, a
    ld c, 1
    pop hl
    call WinPrint
    ld a, 7
    ld b, 8
    ld c, 8 + 24
    call SetWindow
    call ShowFresh
    ld a, 120
    ld [wBannerT], a
    ret

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
    add a, a                     ; *4
    ld e, a
    add a, a                     ; *8
    add a, e                     ; *12
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
    ld a, [wCur + E_TYPE]
    cp NPC_BASE
    ret nc                       ; townsfolk stand still
    call MonsterEffectsTick      ; DoTs + timers once a second
    ld a, [wCur + E_TYPE]
    and a
    ret z
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
    ld a, [wCur + E_STUN]        ; stunned monsters do nothing
    and a
    jp nz, .contact
    ld a, [wCur + E_SLOW]        ; slowed: half the moves
    and a
    jr z, .fast
    ldh a, [hFrame]
    and 1
    jp nz, .contact
.fast:
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
    cp TYPE_GIANT_BAT
    jr z, .doMove                ; bats + wolves: full speed
    cp TYPE_WOLF
    jr z, .doMove
    cp TYPE_WINTER_WOLF
    jr z, .doMove
    cp TYPE_SKELETON
    jr z, .threeQuarter
    cp TYPE_GNOLL
    jr z, .threeQuarter
    cp TYPE_LIZARDFOLK
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
    ld a, ATTACK_TIME
    ld [wCur + E_NOHIT], a       ; one hit per swing
    call PlayerHitRoll           ; accuracy vs evasion
    jr nc, .miss
    call PlayerMeleeDamage
    call PowerDamageMods         ; legendary powers
    call OnHeroHit
    push hl
    ld a, [wPoison]              ; Poison Blade: poison DoT on the target
    and a
    jr z, .noPoison
    dec a
    ld [wPoison], a
    ld hl, wATK
    call LoadW
    srl h
    rr l
    srl h
    rr l
    ld d, h
    ld e, l
    ld a, FX_POISON
    ld b, 4
    call DebuffCur
.noPoison:
    ld a, [wPlayerDir]
    add a, a
    ld e, a
    ld d, 0
    ld hl, DirVec
    add hl, de
    ld a, [hl+]
    ld [wHitKX], a
    ld a, [hl]
    ld [wHitKY], a
    pop hl
    jp ApplyDamageCur
.miss:
    ld hl, MsgMiss
    call SetMsg
    jp SfxBlock
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
    cp TYPE_GIANT_BAT
    jr z, .bat
    cp TYPE_GIANT_FROG
    jr z, .bat                   ; frogs hop about erratically too
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
    ld a, [wPickupType]
    and a
    jr z, .heart
    cp 3
    jp z, PickupGear
    cp 2
    jr nz, .coins
    ld a, [wPickupAmt]           ; dropped gear / potion
    call InvAdd
    ld hl, MsgLoot
    jr nc, .lootOk
    ld hl, MsgFull
.lootOk:
    call SetMsg
    jp SfxPickup
.coins:
    ld a, [wPickupAmt]           ; coins (+gold find %, FORTUNE doubles)
    ld l, a
    ld h, 0
    push hl
    ld a, 21
    call GearPct
    pop hl
    push hl
    call ReducePctInv
    pop de
    add hl, de
    push hl
    ld a, 9
    call HasAspect
    pop hl
    jr z, .nf
    add hl, hl
.nf:
    ld d, h
    ld e, l
    call AddGold16
    ld hl, MsgGold
    call SetMsg
    jp SfxPickup
.heart:
    call HpIsFull
    jr z, .toPotion
    ld a, 2                      ; heart heals 1/8 of max HP
    call HpFraction
    call HealPlayer
    ld hl, MsgHeal
    jp SetMsg
.toPotion:                       ; at full HP a heart becomes a potion
    ld a, ITEM_POTION
    call InvAdd
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
    call DrawPickup
    call DrawProjectile
    ld a, [wGameState]
    cp STATE_PLAY
    ret nz
    ld a, [wBannerT]             ; keep sprites off the zone banner
    and a
    ret z
    jp HideSpritesUnderWindow

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
    ld a, [hl]
    and a
    jp z, .next
    ld [wTmp], a
    inc hl
    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    ld c, a
    ld de, E_HURT - E_HP
    add hl, de
    ld a, [hl]                   ; E_HURT
    and 2
    ld [wTmp + 1], a
    ld de, E_PAL - E_HURT
    add hl, de
    ld a, [hl]
    ld e, a                      ; palette
    ld a, [wTmp]
    cp NPC_BASE
    jr c, .monster
    sub NPC_BASE
    push hl
    ld hl, NpcTiles
    add a, l
    ld l, a
    jr nc, .nn
    inc h
.nn:
    ld d, [hl]
    pop hl
    jr .anim
.monster:
    push bc
    push de
    call GetTypeStats
    ld de, MS_TILE
    add hl, de
    pop de
    pop bc
    ld d, [hl]
    ld a, [wTmp]
    cp TYPE_GOBLIN               ; two-frame sprites
    jr z, .twoFrame16
    cp TYPE_GIANT_BAT
    jr nz, .anim
    ldh a, [hFrame]
    and 8
    jr z, .draw
    jr .frame2
.twoFrame16:
    ldh a, [hFrame]
    and 16
    jr z, .draw
.frame2:
    ld a, d
    add a, 4
    ld d, a
    jr .draw
.anim:                           ; everyone else: mirror to walk
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
    jp nz, .loop
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
    ld a, [wPickupType]
    and a
    jp z, DrawSprite8
    cp 3
    ld d, T_SPARK
    ld e, OP_HEART
    jp z, DrawSprite8
    cp 2
    ld d, T_SPARK
    ld e, OP_SWORD
    jp z, DrawSprite8
    ld d, T_COIN
    ld e, OP_SWORD
    jp DrawSprite8

AddGold:                         ; a = amount, capped at 999
    ld hl, wGold
    add a, [hl]
    ld [hl+], a
    ld a, [hl]
    adc a, 0
    ld [hl], a
ClampGold:
    ld a, [wGold + 1]
    cp HIGH(1000)
    jr c, .ok
    jr nz, .cap
    ld a, [wGold]
    cp LOW(1000)
    ret c
.cap:
    ld a, LOW(999)
    ld [wGold], a
    ld a, HIGH(999)
    ld [wGold + 1], a
.ok:
    ret

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
    ld bc, 10000
    call .digit
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
    ld b, 4
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

CountCleared:                    ; a = zone bosses defeated
    ld a, [wBossFlags]
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
    dw MenuOptions, MenuSkills, MenuBeast, MenuBeastPage, MenuIntro, MenuMap
    dw MenuClass, MenuShop, MenuShopList, MenuInn, MenuDialog, MenuQuests, MenuSaveAsk, MenuAlloc
    dw MenuGear, MenuGearSub, MenuSmith, MenuRace

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
    ld e, 18
    call DrawBox
    ld hl, PauseList
    call WinPrintList
    call PauseCursor
    ld a, 9 * 8 + 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ReshowSprites

PauseCursor:
    ld b, 1
    ld c, 2
    ld d, 8
    ld a, [wPauseCur]
    ld e, a
    ld a, T_CUR
    jp DrawListCursor

MenuPause:
    ld hl, wPauseCur
    ld b, 8
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
    dw OpenStatus, OpenBag, OpenSkills, OpenQuests, OpenMap, OpenBestiary, OpenSaveAsk, OpenOptions

Retire:
    jp StartTitle

OpenBag:                         ; ITEMS: the gear bag tab first
    xor a
    ld [wGearCur], a
    ld [wGearTop], a
    jp OpenGearTab

; ---- status (character sheet) -------------------------------------------
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

; ---- bestiary (7 per page, 2 pages) -------------------------------------
OpenBestiary:
    ld a, M_BEAST
    ld [wMenu], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 18
    call DrawBox
    ld a, [wBeastPage]           ; first index on this page = page * 7
    ld b, a
    add a, a
    add a, a
    add a, a
    sub b
    ld [wTmp], a
    xor a
    ld [wTmp + 1], a             ; row counter
.names:
    ld a, [wTmp]
    cp NUM_MONSTERS
    jr nc, .done
    call IsSeen
    ld hl, StrUnknown
    jr z, .print
    ld a, [wTmp]
    add a, a
    ld e, a
    ld d, 0
    ld hl, MonsterNames
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
.print:
    ld a, [wTmp + 1]
    add a, a
    add a, 2
    ld c, a
    ld b, 2
    call WinPrint
    ld hl, wTmp
    inc [hl]
    inc hl
    inc [hl]
    ld a, [hl]
    cp 7
    jr c, .names
.done:
    ld hl, StrPage
    ld b, 2
    ld c, 16
    call WinPrint
    ld a, [wBeastPage]
    add a, T_DIGIT0 + 1
    ld b, 7
    ld c, 16
    call WinPutTile
    call BeastCursor
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

BeastCursor:
    ld b, 1
    ld c, 2
    ld d, 7
    ld a, [wBeastCur]
    ld e, a
    ld a, T_CUR
    jp DrawListCursor

MenuBeast:
    ld hl, wBeastCur
    ld b, 7
    call ListNav
    jp c, BeastCursor
    ldh a, [hNewKeys]
    ld b, a
    and $30                      ; left / right: flip page
    jr z, .noPage
    ld a, [wBeastPage]
    xor 1
    ld [wBeastPage], a
    call SfxMenu
    jp OpenBestiary
.noPage:
    ld a, b
    and PAD_B
    jr z, .notB
    call SfxMenu
    jp ReturnToPause
.notB:
    ld a, b
    and PAD_A
    ret z
    ld a, [wBeastPage]
    ld b, a
    add a, a
    add a, a
    add a, a
    sub b
    ld b, a
    ld a, [wBeastCur]
    add a, b
    cp NUM_MONSTERS
    jp nc, SfxBlock
    ld [wTmp], a
    call IsSeen
    jp z, SfxBlock               ; not encountered yet
    call SfxMenu
    ld a, M_BEASTPAGE
    ld [wMenu], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 18
    call DrawBox
    ld a, [wTmp]
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
    jp ShowFresh

MenuBeastPage:
    ldh a, [hNewKeys]
    and PAD_A | PAD_B
    ret z
    call SfxMenu
    jp OpenBestiary

; ---- world map -------------------------------------------------------------
OpenMap:
    ld a, M_MAP
    ld [wMenu], a
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 18
    call DrawBox
    ld hl, StrWorldMap
    ld b, 5
    ld c, 1
    call WinPrint
    xor a
    ld [wTmp], a
.cell:
    ld a, [wTmp]
    call GetRoomInfoA            ; hl -> N S W E zone flags x y
    ld de, 5
    add hl, de
    ld a, [hl]
    ld [wTmp + 1], a             ; flags
    ld a, [wTmp]
    add a, a
    ld e, a
    ld d, 0
    ld hl, MapCells
    add hl, de
    ld b, [hl]
    inc hl
    ld c, [hl]
    ld a, [wTmp + 1]
    and FLAG_TOWN
    ld a, "*"
    jr nz, .put
    ld a, [wTmp + 1]
    and FLAG_LOCKED
    ld a, "?"
    jr nz, .put
    ld a, T_BOX_E
.put:
    push af
    ld a, [wRoom]
    ld e, a
    ld a, [wTmp]
    cp e
    jr nz, .notHere
    pop af
    ld a, T_CUR
    push af
.notHere:
    pop af
    call WinPutTile
    ld hl, wTmp
    inc [hl]
    ld a, [hl]
    cp NUM_ROOMS
    jr c, .cell
    ld hl, MapLabels
    call WinPrintList
    ld a, [wZone]                ; current zone name at the bottom
    add a, a
    ld e, a
    ld d, 0
    ld hl, ZoneNames
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld b, 2
    ld c, 16
    call WinPrint
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

MenuMap:
    ldh a, [hNewKeys]
    and PAD_A | PAD_B | PAD_START
    ret z
    call SfxMenu
    jp ReturnToPause

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
    ld a, [wPalSet]              ; COLOR -> zone set, GREEN/GRAY -> sets 6/7
    and a
    jr nz, .mono
    ld a, [wZone]
    jr .set
.mono:
    add a, 5
.set:
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
    ld a, BANK_GFX
    ld [rROMB0], a
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
    ld a, [wPalSet]              ; colour mode: hero palette by class
    and a
    jr nz, .done
    ld a, $80
    ldh [rOCPS], a
    ld a, [wClass]
    add a, a
    add a, a
    add a, a
    ld e, a
    ld d, 0
    ld hl, ClassPals
    add hl, de
    ld c, 8
.cp:
    ld a, [hl+]
    ldh [rOCPD], a
    dec c
    jr nz, .cp
.done:
    ld a, BANK_MAIN
    ld [rROMB0], a
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
INCLUDE "src/stats.asm"
INCLUDE "src/classes.asm"
INCLUDE "src/inventory.asm"
INCLUDE "src/town.asm"
INCLUDE "src/combat.asm"
INCLUDE "src/quests.asm"
INCLUDE "src/save.asm"
INCLUDE "src/gear.asm"

SECTION "Data", ROMX, BANK[1]

BitTable:   db 1, 2, 4, 8, 16, 32, 64, 128

; CGB BG palette per room tile id
AttrTable:  db 0, 0, 0, 1, 2, 3, 4, 5, 5, 5, 5

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

PalCols:  db 1, 8, 14
OptSpots: db 1, 4,  8, 4,  14, 4,  1, 9,  8, 9,  1, 12

SETCHARMAP text

BounceTable: db 1, 8,  1, 120,  0, 8,  0, 136
EnterTable:  db 1, 124, 1, 6,  0, 140, 0, 4

; ============================================================ text =========
SECTION "Text", ROM0


BootList:
    TXT 5, 9, StrDev
    TXT 6, 11, StrPresents
    TXT 3, 15, StrMadeWith
    db $FF
StrDev:      db "ARKANSASIO", $FF
StrPresents: db "PRESENTS", $FF
StrMadeWith: db "MADE FOR GBC/SP", $FF

TitleList:
    TXT 3, 3, StrTitle
    TXT 4, 5, StrTagline
    TXT 2, 11, StrGoal1
    TXT 3, 12, StrGoal2
    TXT 4, 14, StrPress
    TXT 3, 16, StrCredit
    db $FF
StrTitle:    db "ARPG GB QUEST", $FF
StrTagline:  db "VERSION 0.7.0", $FF
StrGoal1:    db "FIVE LANDS. FOUR", $FF
StrGoal2:    db "SEALS. ONE OGRE.", $FF
StrPress:    db "PRESS START", $FF
StrCredit:   db "BUILD 20261126", $FF

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
Intro10: db "BREAK THE 4 SEALS", $FF
StrPressA: db "PRESS A", $FF

PauseList:
    TXT 2, 2, StrStatus
    TXT 2, 4, StrItems
    TXT 2, 6, StrSkills
    TXT 2, 8, StrQuests
    TXT 2, 10, StrMap
    TXT 2, 12, StrBestiary
    TXT 2, 14, StrSave
    TXT 2, 16, StrOptions
    db $FF
StrStatus:   db "STATUS", $FF
StrItems:    db "ITEMS", $FF
StrSkills:   db "SKILLS", $FF
StrBestiary: db "BESTIARY", $FF
StrOptions:  db "OPTIONS", $FF
StrRetire:   db "RETIRE", $FF
StrMap:      db "MAP", $FF
StrQuests:   db "QUESTS", $FF
StrSave:     db "SAVE", $FF
StrContinue: db "LOAD GAME", $FF
StrNewGame:  db "NEW GAME", $FF
StrWorldMap: db "WORLD MAP", $FF
StrPage:     db "PAGE  /2", $FF

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
StrRooms:   db "BOSSES  /4", $FF

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
MsgGold:   db "GOLD!"
StrSmith2: db "", $FF
MsgFull:   db "FULL!"
MsgBoss:   db "BOSS!"
StrSealed: db "THE CRYPT IS SEALED", $FF

MapLabels:
    TXT 9, 2, MapN
    TXT 5, 15, MapS
    TXT 1, 8, MapW
    TXT 15, 8, MapE
    TXT 12, 14, MapC
    db $FF
MapN: db "ICE", $FF
MapS: db "MIRE", $FF
MapW: db "WOOD", $FF
MapE: db "DUNE", $FF
MapC: db "CRYPT", $FF
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
wLevel:        dw               ; --- saved block: progression ---
wXP:           dw
wAttr:
wStr:          dw
wDex:          dw
wCon:          dw
wInt:          dw
wWis:          dw
wVit:          dw
wSpi:          dw
wLck:          dw
wWil:          dw
wCha:          dw
wStatPts:      dw
wHP:           dw
wMaxHP:        dw
wMP:           dw
wMaxMP:        dw               ; --- end saved block ---
wATK:          dw
wMAG:          dw
wDEF:          dw
wHEAL:         dw
wACC:          dw
wEVA:          dw
wRES:          dw
wMACC:         dw
wMEVA:         dw
wCrit:         db
wCritDmg:      db
wBlockP:       db
wTen:          db
wSRes:         db
wCDR:          db
wAPen:         db
wMPen:         db
wDiscount:     db
wSpdRating:    db
wSecTick:      db
wFrameSec:     db
wTmpFx:        db
wSheetPage:    db
wApplyBurn:    db
wFxStart:                        ; --- effect timers (seconds) ---
wBuffPower:    db
wBuffHaste:    db
wBuffFort:     db
wBuffRegen:    db
wDebSlow:      db
wDebWeak:      db
wDebFrail:     db
wDebStun:      db
wDebBurn:      db
wDebPoison:    db
wFxTimersEnd:
wBurnPwr:      dw
wPoisonPwr:    dw
wFxEnd:
wAtkTime:      db
wMPRegenT:     db
wWpnBase:      db
wArmBase:      db
wTplDef:       db
wTplHp:        db
wTplAtk:       db
wTplXp:        db
wMHP:          dw
wMATK:         dw
wMDEF:         dw
wMXP:          dw
wTmpW:         dw
wAllocCur:     db
wSecondWind:   db
wClass:        db
wSTR:          db
wDEX:          db
wCON:          db
wINT:          db
wWIS:          db
wHD:           db
wWeapon:       db
wArmor:        db
wCastMod:      db
wSkill1:       db
wSkill2:       db
wBAction:      db
wRace:         db
wClassArch:    db
wRaceCur:      db
wClassTop:     db
wProf:         db
wAtk:          db
wAC:           db
wDmgN:         db
wDmgS:         db
wDmgB:         db
wWpnMagic:     db
wWpnFlags:     db
wArmFlags:     db
wSpellAtk:     db
wSlots:        db
wMaxSlots:     db
wCharge1:      db
wCharge2:      db
wSurgeT:       db
wShieldT:      db
wDodge:        db
wPoison:       db
wDashT:        db
wCastCD:       db
wInvCur:       db
wInvTop:       db
wTmpItem:      db
wTmpCount:     db
wTmpDmg:       db
wTmpSlot:      db
wTmpDist:      db
wTmpTarget:    db
wTmpSkill:     db
wCostPtr:      dw
wHitKX:        db
wHitKY:        db
wProjX:        db
wProjY:        db
wProjDX:       db
wProjDY:       db
wProjT:        db
wProjKind:     db
wShopSel:      db
wShopMode:     db
wShopCur:      db
wShopTop:      db
wDlgPtr:       dw
wDlgEnd:       dw
wClassCur:     db
wSlot:         db
wBagTab:       db
wGearCur:      db
wGearTop:      db
wGenLvl:       dw
wGenRar:       db
wGenSlot:      db
wTmpSet:       db
wInstRar:      db
wInstLvl:      dw
wInstUpg:      db
wAffTarget:    db
wCurInst:      dw
wSmithOre:     db
wNewItem:      ds 8
wDropItem:     ds 8
wGearCalc:                       ; --- recomputed by GearBonus ---
gAcc:          ds 25 * 2
gWpn:          dw
gWpnFlags:     db
gArmor:        dw
wAspects:      ds 2
wSetCount:     ds 8
wPowerSum:     dw
wPowerCnt:     db
wPowerLvl:     dw
wGearCalcEnd:
wEAttr:
wEStr:         dw
wEDex:         dw
wECon:         dw
wEInt:         dw
wEWis:         dw
wEVit:         dw
wESpi:         dw
wELck:         dw
wEWil:         dw
wECha:         dw
wSlotCur:      db
wSlotMode:     db
wQState:       ds 4
wQKill:        ds 4
wWasCrit:      db
wMsgT:         db
wMsgPtr:       dw
wRoom:         db
wSeen:         ds 2
wZone:         db
wLoadedZone:   db
wRoomFlags:    db
wBossFlags:    db
wGold:         dw
wRested:       db
wBannerT:      db
wBannerPending: db
wPickupType:   db
wPickupAmt:    db
wProjOn:       db
wBeastPage:    db
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

SECTION "Inventory RAM", WRAM0, ALIGN[5]
wInv:          ds INV_SLOTS * 2

SECTION "Gear RAM", WRAM0
wEquip:        ds 11 * 8
wGear:         ds 20 * 8

SECTION "HRAM", HRAM
hOAMDMA:     ds 16
hVBlankFlag: db
hKeys:       db
hNewKeys:    db
hFrame:      db
hRng:        db
