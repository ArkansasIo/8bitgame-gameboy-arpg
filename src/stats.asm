; ============================================================================
;  STATS - MMO-style progression: levels 1-720, six attributes, sub-stats,
;  scaling monsters, damage formulas, HP/MP, character sheet + point spending
;
;  Attributes: STR DEX VIT INT FTH LCK  (16-bit, +3 free points per level
;              plus class growth)
;  Sub-stats:  MaxHP MaxMP ATK MAG DEF  CRIT% CRITDMG DODGE% BLOCK% SPEED
; ============================================================================
SECTION "Stats", ROMX, BANK[1]

DEF MAX_LVL      EQU 720
DEF PTS_PER_LVL  EQU 3

; ---- 16-bit math ----------------------------------------------------------------
; hl = hl * a (saturates at $FFFF). clobbers bc de
MulHL_A:
    ld b, a
    ld d, h
    ld e, l
    ld hl, 0
.l:
    srl b
    jr nc, .n
    add hl, de
    jr c, .sat
.n:
    ld a, b
    and a
    ret z
    sla e
    rl d
    jr nc, .l
.sat:
    ld hl, $FFFF
    ret

; hl = hl / a, a = remainder. clobbers bc
DivHL_A:
    ld c, a
    xor a
    ld b, 16
.l:
    add hl, hl
    rla
    jr c, .sub
    cp c
    jr c, .ns
.sub:
    sub c
    inc l
.ns:
    dec b
    jr nz, .l
    ret

; hl = hl - de, floored at 0
SubSat:
    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc a, d
    ld h, a
    ret nc
    ld hl, 0
    ret

; hl = hl + de, saturating
AddSat:
    add hl, de
    ret nc
    ld hl, $FFFF
    ret

; hl = max(hl, de)
MaxHLDE:
    ld a, l
    sub e
    ld a, h
    sbc a, d
    ret nc
    ld h, d
    ld l, e
    ret

Rand100:                         ; a = 0..99
    push bc
    ld c, 100
    call RollDie
    dec a
    pop bc
    ret

; a = random percent roll; carry set if roll < b (i.e. b% chance)
Chance:
    call Rand100
    cp b
    ret

LoadW:                           ; hl = [hl] (word)
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ret

; ---- monsters: stats from template x level ----------------------------------------
; a = type, de = level -> wMHP, wMATK, wMDEF, wMXP
CalcMonster:
    push de
    call GetTypeStats            ; hl -> AC HP ATK DN DS DB XPlo XPhi ...
    ld a, [hl+]
    ld [wTplDef], a
    ld a, [hl+]
    ld [wTplHp], a
    ld a, [hl+]
    ld b, a                      ; atk bonus
    ld a, [hl+]
    ld c, a                      ; dice
    ld a, [hl+]                  ; sides
    inc a
    srl a                        ; (sides+1)/2
    ld d, a
    xor a
.dm:
    add a, d
    dec c
    jr nz, .dm
    add a, b
    add a, [hl]                  ; + dmg bonus
    ld [wTplAtk], a
    inc hl
    ld a, [hl+]
    ld e, a
    ld d, [hl]
    ld h, d
    ld l, e
    ld a, 10
    call DivHL_A
    ld a, l
    cp 5
    jr nc, .xok
    ld a, 5
.xok:
    ld [wTplXp], a
    pop de
    ; HP = hp * (L + 7) / 2
    ld hl, 7
    add hl, de
    push de
    ld a, [wTplHp]
    call MulHL_A
    srl h
    rr l
    ld a, l
    ld [wMHP], a
    ld a, h
    ld [wMHP + 1], a
    pop de
    ; ATK = atk * (L + 9) / 2
    ld hl, 9
    add hl, de
    push de
    ld a, [wTplAtk]
    call MulHL_A
    srl h
    rr l
    ld a, l
    ld [wMATK], a
    ld a, h
    ld [wMATK + 1], a
    pop de
    ; DEF = ac * L / 4
    ld h, d
    ld l, e
    push de
    ld a, [wTplDef]
    call MulHL_A
    srl h
    rr l
    srl h
    rr l
    ld a, l
    ld [wMDEF], a
    ld a, h
    ld [wMDEF + 1], a
    pop de
    ; XP = xp * (L + 2) / 2
    ld hl, 2
    add hl, de
    ld a, [wTplXp]
    call MulHL_A
    srl h
    rr l
    ld a, l
    ld [wMXP], a
    ld a, h
    ld [wMXP + 1], a
    ret

CalcCurMonster:                  ; stats for wCur
    ld a, [wCur + E_LVL]
    ld e, a
    ld a, [wCur + E_LVL + 1]
    ld d, a
    ld a, [wCur + E_TYPE]
    jp CalcMonster

; ---- player: class start + growth ---------------------------------------------------
;                 STR DEX VIT INT FTH LCK
ClassStart:  db   14, 11, 13,  6,  8,  6   ; fighter
             db    9, 14, 11,  9,  8, 10   ; rogue
             db    6, 10,  9, 15, 10,  8   ; wizard
             db   11,  8, 12,  7, 14,  7   ; cleric
ClassGrowth: db    2,  1,  2,  0,  0,  0
             db    1,  2,  1,  0,  0,  1
             db    0,  1,  1,  3,  0,  0
             db    1,  0,  2,  0,  2,  0

ClassRow6:                       ; hl = table + class * 6
    ld a, [wClass]
    ld b, a
    add a, a
    add a, b
    add a, a
    add a, l
    ld l, a
    ret nc
    inc h
    ret

InitAttributes:                  ; level 1 character of wClass
    ld hl, ClassStart
    call ClassRow6
    ld de, wAttr
    ld c, 6
.l:
    ld a, [hl+]
    ld [de], a
    inc de
    xor a
    ld [de], a
    inc de
    dec c
    jr nz, .l
    ld a, 1
    ld [wLevel], a
    xor a
    ld [wLevel + 1], a
    ld [wXP], a
    ld [wXP + 1], a
    ld [wStatPts], a
    ld [wStatPts + 1], a
    call RecalcStats
    jp FullRestore

FullRestore:
    ld a, [wMaxHP]
    ld [wHP], a
    ld a, [wMaxHP + 1]
    ld [wHP + 1], a
    ld a, [wMaxMP]
    ld [wMP], a
    ld a, [wMaxMP + 1]
    ld [wMP + 1], a
    ret

; ---- derived sub-stats ----------------------------------------------------------------
RecalcStats:
    ; MaxHP = 40 + VIT*6 + LV*4
    ld hl, wVit
    call LoadW
    ld a, 6
    call MulHL_A
    push hl
    ld hl, wLevel
    call LoadW
    add hl, hl
    add hl, hl
    pop de
    call AddSat
    ld de, 40
    call AddSat
    ld a, l
    ld [wMaxHP], a
    ld a, h
    ld [wMaxHP + 1], a
    ; MaxMP = 10 + INT*3 + FTH*2
    ld hl, wInt
    call LoadW
    ld a, 3
    call MulHL_A
    push hl
    ld hl, wFth
    call LoadW
    add hl, hl
    pop de
    call AddSat
    ld de, 10
    call AddSat
    ld a, l
    ld [wMaxMP], a
    ld a, h
    ld [wMaxMP + 1], a
    ; weapon base = (n*(s+1)/2 + magic) * 4 (+28 fire)
    xor a
    ld [wWpnBase], a
    ld [wWpnFlags], a
    ld a, [wWeapon]
    and a
    jr z, .noW
    call GetItem
    ld de, 4
    add hl, de
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    inc a
    srl a
    ld b, a
    xor a
.wm:
    add a, b
    dec c
    jr nz, .wm
    add a, [hl]
    inc hl
    add a, a
    add a, a
    ld b, a
    ld a, [hl]
    ld [wWpnFlags], a
    and 2
    ld a, b
    jr z, .nf
    add a, 28
.nf:
    ld [wWpnBase], a
.noW:
    ; ATK = weapon + 2*max(STR, DEX if finesse) + LV
    ld hl, wStr
    call LoadW
    ld a, [wWpnFlags]
    and 1
    jr z, .str
    push hl
    ld hl, wDex
    call LoadW
    ld d, h
    ld e, l
    pop hl
    call MaxHLDE
.str:
    add hl, hl
    ld a, [wWpnBase]
    ld e, a
    ld d, 0
    call AddSat
    push hl
    ld hl, wLevel
    call LoadW
    ld d, h
    ld e, l
    pop hl
    call AddSat
    ld a, l
    ld [wATK], a
    ld a, h
    ld [wATK + 1], a
    ; MAG = INT*2 + FTH + LV
    ld hl, wInt
    call LoadW
    add hl, hl
    push hl
    ld hl, wFth
    call LoadW
    ld d, h
    ld e, l
    pop hl
    call AddSat
    push hl
    ld hl, wLevel
    call LoadW
    ld d, h
    ld e, l
    pop hl
    call AddSat
    ld a, l
    ld [wMAG], a
    ld a, h
    ld [wMAG + 1], a
    ; armor base = (AC + magic) * 2, flags
    xor a
    ld [wArmBase], a
    ld [wArmFlags], a
    ld a, [wArmor]
    and a
    jr z, .noA
    call GetItem
    ld de, 4
    add hl, de
    ld a, [hl+]
    inc hl
    add a, [hl]
    inc hl
    add a, a
    ld [wArmBase], a
    ld a, [hl]
    ld [wArmFlags], a
.noA:
    ; DEF = armor + VIT + LV/2
    ld hl, wVit
    call LoadW
    ld a, [wArmBase]
    ld e, a
    ld d, 0
    call AddSat
    push hl
    ld hl, wLevel
    call LoadW
    srl h
    rr l
    ld d, h
    ld e, l
    pop hl
    call AddSat
    ld a, l
    ld [wDEF], a
    ld a, h
    ld [wDEF + 1], a
    ; CRIT% = 5 + DEX/40 + LCK/30   (cap 50)
    ld hl, wDex
    call LoadW
    ld a, 40
    call DivHL_A
    push hl
    ld hl, wLck
    call LoadW
    ld a, 30
    call DivHL_A
    pop de
    add hl, de
    ld de, 5
    add hl, de
    ld a, 50
    call CapHL
    ld [wCrit], a
    ; CRITDMG in eighths = 12 + LCK/60  (150% .. 300%)
    ld hl, wLck
    call LoadW
    ld a, 60
    call DivHL_A
    ld de, 12
    add hl, de
    ld a, 24
    call CapHL
    ld [wCrit8], a
    ; DODGE% = DEX/50 (cap 25), BLOCK% = VIT/80 (cap 25)
    ld hl, wDex
    call LoadW
    ld a, 50
    call DivHL_A
    ld a, 25
    call CapHL
    ld [wDodgeP], a
    ld hl, wVit
    call LoadW
    ld a, 80
    call DivHL_A
    ld a, 25
    call CapHL
    ld [wBlockP], a
    ; SPEED: swing time 12 - DEX/150 (min 6)
    ld hl, wDex
    call LoadW
    ld a, 150
    call DivHL_A
    ld a, 6
    call CapHL
    ld b, a
    ld a, ATTACK_TIME
    sub b
    ld [wAtkTime], a
    ; clamp current HP/MP
    ld hl, wHP
    ld de, wMaxHP
    call ClampWord
    ld hl, wMP
    ld de, wMaxMP
    ; fall through
ClampWord:                       ; [hl] = min([hl], [de])
    ld a, [de]
    ld c, a
    inc de
    ld a, [de]
    ld b, a                      ; bc = max
    ld a, [hl+]
    ld e, a
    ld a, [hl-]
    ld d, a                      ; de = value
    ld a, c
    sub e
    ld a, b
    sbc a, d
    ret nc
    ld a, c
    ld [hl+], a
    ld [hl], b
    ret

CapHL:                           ; a = min(hl, a)
    ld b, a
    ld a, h
    and a
    ld a, b
    ret nz
    ld a, l
    cp b
    ret nc
    ret

; ---- XP and levels ---------------------------------------------------------------------
; de = XP needed for the next level: 15 + LV*8 + LV*LV/64
XpNeeded:
    ld hl, wLevel
    call LoadW
    push hl
    ld a, 8
    call MulHL_A
    ld de, 15
    add hl, de
    ld d, h
    ld e, l
    pop hl
    push de
    ld a, h                      ; LV*LV/64 = (LV/8)^2 approx
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    ld a, l
    call MulHL_A
    pop de
    add hl, de
    ld d, h
    ld e, l
    ret

; de = XP gained
AddXP:
    ld hl, wXP
    ld a, [hl]
    add a, e
    ld [hl+], a
    ld a, [hl]
    adc a, d
    ld [hl], a
    jr nc, CheckLevelUp
    ld a, $FF                    ; overflow guard
    ld [hl-], a
    ld [hl], a
CheckLevelUp:
    ld hl, wLevel
    call LoadW
    ld de, MAX_LVL
    ld a, l
    sub e
    ld a, h
    sbc a, d
    ret nc
    call XpNeeded
    ld hl, wXP
    call LoadW
    ld a, l
    sub e
    ld c, a
    ld a, h
    sbc a, d
    ret c                        ; not enough yet
    ld [wXP + 1], a
    ld a, c
    ld [wXP], a
    ld hl, wLevel                ; level up!
    inc [hl]
    jr nz, .nc
    inc hl
    inc [hl]
.nc:
    ld hl, wStatPts
    ld a, [hl]
    add a, PTS_PER_LVL
    ld [hl+], a
    jr nc, .nc2
    inc [hl]
.nc2:
    ld hl, ClassGrowth           ; class growth
    call ClassRow6
    ld de, wAttr
    ld c, 6
.g:
    ld a, [de]
    add a, [hl]
    ld [de], a
    inc de
    ld a, [de]
    adc a, 0
    ld [de], a
    inc de
    inc hl
    dec c
    jr nz, .g
    call RecalcStats
    call FullRestore
    ld hl, MsgLvUp
    call SetMsg
    call SfxWin
    jr CheckLevelUp

; ---- damage ---------------------------------------------------------------------------
; hl = value -> hl = value * (90..110%)
Spread:
    push hl
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l                         ; hl/8
    push hl
    call Rand
    pop de                       ; de = v/8
    pop hl
    push de
    srl d
    rr e                         ; v/16
    call SubSat                  ; v - v/16
    pop de                       ; v/8
    and $0F                      ; 0..15/16 of v/8
    push hl
    ld h, d
    ld l, e
    call MulHL_A
    ld a, 16
    call DivHL_A
    pop de
    add hl, de
    ret

; hl = attack, de = defense -> hl = max(atk - def/2, atk/8, 1)
Mitigate:
    push hl
    srl d
    rr e
    call SubSat
    pop de                       ; de = atk
    srl d
    rr e
    srl d
    rr e
    srl d
    rr e
    call MaxHLDE
    ld a, h
    or l
    ret nz
    inc l
    ret

; damage vs wCur from the hero's weapon. sets wWasCrit. hl = damage
PlayerMeleeDamage:
    call CalcCurMonster
    ld hl, wATK
    call LoadW
    call Spread
    ld a, [wSurgeT]              ; Action Surge: x2
    and a
    jr z, .ns
    add hl, hl
    jr nc, .ns
    ld hl, $FFFF
.ns:
    ld a, [wCur + E_FRESH]       ; Rogue sneak attack: +50% on a fresh foe
    and a
    jr z, .nsa
    ld a, [wClass]
    cp 1
    jr nz, .nsa
    ld d, h
    ld e, l
    srl d
    rr e
    call AddSat
.nsa:
    ld a, [wPoison]              ; Poison Blade: +25%
    and a
    jr z, .np
    dec a
    ld [wPoison], a
    ld d, h
    ld e, l
    srl d
    rr e
    srl d
    rr e
    call AddSat
.np:
    ld a, [wMDEF]
    ld e, a
    ld a, [wMDEF + 1]
    ld d, a
    call Mitigate
    ; fall through: crit roll
RollCrit:                        ; hl = damage -> maybe x crit multiplier
    xor a
    ld [wWasCrit], a
    ld a, [wCrit]
    ld b, a
    call Chance
    ret nc
    ld a, 1
    ld [wWasCrit], a
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    ld a, [wCrit8]
    call MulHL_A
    push hl
    ld hl, MsgCrit
    call SetMsg
    pop hl
    ret

; spell damage vs wCur: hl = base power -> hl after DEF/2 mitigation + crit
SpellDamage:
    push hl
    call CalcCurMonster
    pop hl
    call Spread
    ld a, [wMDEF]
    ld e, a
    ld a, [wMDEF + 1]
    ld d, a
    srl d                        ; magic ignores half of armour
    rr e
    call Mitigate
    jp RollCrit

; monster in wCur attacks the hero
EnemyAttack:
    ld a, [wDodgeP]              ; dodge
    ld b, a
    call Chance
    jr c, .dodged
    call CalcCurMonster
    ld hl, wMATK
    call LoadW
    call Spread
    ld a, [wDEF]
    ld e, a
    ld a, [wDEF + 1]
    ld d, a
    ld a, [wShieldT]             ; Shield spell: +50% DEF
    and a
    jr z, .nsh
    push hl
    ld h, d
    ld l, e
    srl d
    rr e
    call AddSat
    ld d, h
    ld e, l
    pop hl
.nsh:
    call Mitigate
    ld a, [wArmFlags]            ; 5% monster crit unless adamantine
    and 4
    jr nz, .nc
    ld b, 5
    call Chance
    jr nc, .nc
    ld d, h
    ld e, l
    srl d
    rr e
    call AddSat
.nc:
    ld a, [wBlockP]              ; block halves
    ld b, a
    call Chance
    jr nc, .nb
    srl h
    rr l
    push hl
    ld hl, MsgBlock
    call SetMsg
    pop hl
    call SfxBlock
.nb:
    jp PlayerTakeDamage
.dodged:
    ld a, 30
    ld [wPlayerInv], a
    call KnockFromCur
    ld hl, MsgDodge
    call SetMsg
    jp SfxBlock

; hl = damage to the hero
PlayerTakeDamage:
    ld a, [wDodge]               ; Uncanny Dodge halves it
    and a
    jr z, .nd
    dec a
    ld [wDodge], a
    srl h
    rr l
.nd:
    ld a, h
    or l
    jr nz, .some
    inc l
.some:
    ld d, h
    ld e, l
    ld a, [wHP]
    sub e
    ld l, a
    ld a, [wHP + 1]
    sbc a, d
    jr c, .dead
    ld h, a
    or l
    jr z, .dead
    ld a, l
    ld [wHP], a
    ld a, h
    ld [wHP + 1], a
    ld a, 60
    ld [wPlayerInv], a
    call KnockFromCur
    jp SfxHurt
.dead:
    xor a
    ld [wHP], a
    ld [wHP + 1], a
    call SfxHurt
    jp ShowGameOver

; hl = HP to restore (capped)
HealPlayer:
    ld a, [wHP]
    ld e, a
    ld a, [wHP + 1]
    ld d, a
    call AddSat
    ld a, l
    ld [wHP], a
    ld a, h
    ld [wHP + 1], a
    ld hl, wHP
    ld de, wMaxHP
    call ClampWord
    jp SfxPickup

; hl = MaxHP * a / 16
HpFraction:
    push af
    ld hl, wMaxHP
    call LoadW
    ld a, 16
    call DivHL_A
    pop af
    jp MulHL_A

HpIsFull:                        ; z if HP == MaxHP
    ld a, [wHP]
    ld b, a
    ld a, [wMaxHP]
    cp b
    ret nz
    ld a, [wHP + 1]
    ld b, a
    ld a, [wMaxHP + 1]
    cp b
    ret

; a = MP cost -> carry set if not enough (nothing spent)
SpendMP:
    ld e, a
    ld a, [wMP]
    sub e
    ld l, a
    ld a, [wMP + 1]
    sbc a, 0
    ret c
    ld [wMP + 1], a
    ld a, l
    ld [wMP], a
    or a
    ret

; MP regeneration: 1 + MaxMP/64 every second
MPTick:
    ld hl, wMPRegenT
    inc [hl]
    ld a, [hl]
    cp 60
    ret c
    ld [hl], 0
    ld hl, wMaxMP
    call LoadW
    ld a, 64
    call DivHL_A
    inc hl
    ld a, [wMP]
    ld e, a
    ld a, [wMP + 1]
    ld d, a
    call AddSat
    ld a, l
    ld [wMP], a
    ld a, h
    ld [wMP + 1], a
    ld hl, wMP
    ld de, wMaxMP
    jp ClampWord

; ---- HUD:  H12345 M1234 MSG.. L720 ------------------------------------------------------
BuildHUD:
    ld hl, wHudBuf
    ld bc, 20
    xor a
    call Memset
    ld a, "H"
    ld [wHudBuf + 0], a
    ld a, [wHP]
    ld e, a
    ld a, [wHP + 1]
    ld d, a
    call Num16ToStr
    ld hl, wNumBuf
    ld de, wHudBuf + 1
    ld c, 5
    call CopyC
    ld a, "M"
    ld [wHudBuf + 6], a
    ld a, [wMP]
    ld e, a
    ld a, [wMP + 1]
    ld d, a
    call Num16ToStr
    ld hl, wNumBuf + 1
    ld de, wHudBuf + 7
    ld c, 4
    call CopyC
    ld a, [wMsgT]
    and a
    jr z, .lvl
    ld hl, wMsgPtr
    call LoadW
    ld de, wHudBuf + 11
    ld c, 5
    call CopyC
.lvl:
    ld a, "L"
    ld [wHudBuf + 16], a
    ld a, [wLevel]
    ld e, a
    ld a, [wLevel + 1]
    ld d, a
    call Num16ToStr
    ld hl, wNumBuf + 2
    ld de, wHudBuf + 17
    ld c, 3
    ; fall through
CopyC:                           ; copy c bytes hl -> de
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, CopyC
    ret

; ---- character sheet --------------------------------------------------------------------
OpenStatus:
    ld a, M_STATUS
    ld [wMenu], a
    call RecalcStats
    call DrawSheet
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

PutWord:                         ; hl -> word, print 5-digit number at b,c
    push bc
    call LoadW
    ld d, h
    ld e, l
    call Num16ToStr
    pop bc
    ld hl, wNumBuf
    jp WinPrint

PutPct:                          ; a = percent at b,c  "nn%"
    push bc
    call Dec2
    pop bc
    ld a, d
    call WinPutTile
    inc b
    ld a, e
    call WinPutTile
    inc b
    ld a, "%"
    jp WinPutTile

DrawSheet:
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
    call LoadW
    ld b, 1
    ld c, 1
    call WinPrint
    ld hl, SheetLabels
    call WinPrintList
    ld hl, wLevel
    ld b, 14
    ld c, 1
    call PutWord
    ld hl, wHP
    ld b, 4
    ld c, 3
    call PutWord
    ld hl, wMaxHP
    ld b, 10
    ld c, 3
    call PutWord
    ld hl, wMP
    ld b, 4
    ld c, 4
    call PutWord
    ld hl, wMaxMP
    ld b, 10
    ld c, 4
    call PutWord
    ld hl, wXP
    ld b, 4
    ld c, 5
    call PutWord
    call XpNeeded
    ld a, e
    ld [wTmpW], a
    ld a, d
    ld [wTmpW + 1], a
    ld hl, wTmpW
    ld b, 10
    ld c, 5
    call PutWord
    ld hl, wStr
    ld b, 4
    ld c, 7
    call PutWord
    ld hl, wDex
    ld b, 14
    ld c, 7
    call PutWord
    ld hl, wVit
    ld b, 4
    ld c, 8
    call PutWord
    ld hl, wInt
    ld b, 14
    ld c, 8
    call PutWord
    ld hl, wFth
    ld b, 4
    ld c, 9
    call PutWord
    ld hl, wLck
    ld b, 14
    ld c, 9
    call PutWord
    ld hl, wATK
    ld b, 4
    ld c, 11
    call PutWord
    ld hl, wMAG
    ld b, 14
    ld c, 11
    call PutWord
    ld hl, wDEF
    ld b, 4
    ld c, 12
    call PutWord
    ld a, [wCrit]
    ld b, 15
    ld c, 12
    call PutPct
    ld a, [wDodgeP]
    ld b, 5
    ld c, 13
    call PutPct
    ld a, [wBlockP]
    ld b, 15
    ld c, 13
    call PutPct
    ld a, [wCrit8]               ; crit damage % = eighths * 12.5
    ld l, a
    ld h, 0
    ld a, 25
    call MulHL_A
    srl h
    rr l
    ld a, l
    ld [wTmpW], a
    ld a, h
    ld [wTmpW + 1], a
    ld hl, wTmpW
    ld b, 4
    ld c, 14
    call PutWord
    ld a, "%"
    ld b, 9
    ld c, 14
    call WinPutTile
    ld a, ATTACK_TIME + 1        ; speed rating = 13 - swing frames
    ld b, a
    ld a, [wAtkTime]
    ld c, a
    ld a, b
    sub c
    ld b, 16
    ld c, 14
    call WinPutNum2
    ld hl, wStatPts
    ld b, 4
    ld c, 15
    call PutWord
    ld hl, wGold
    ld b, 14
    ld c, 15
    call PutWord
    ld hl, StrSpendHint
    ld b, 1
    ld c, 16
    jp WinPrint

SheetLabels:
    TXT 11, 1, StrLV
    TXT 1, 3, StrHP
    TXT 9, 3, StrSlash
    TXT 1, 4, StrMP
    TXT 9, 4, StrSlash
    TXT 1, 5, StrXPLabel
    TXT 9, 5, StrSlash
    TXT 1, 7, StrSTR
    TXT 11, 7, StrDEX
    TXT 1, 8, StrVIT
    TXT 11, 8, StrINT
    TXT 1, 9, StrFTH
    TXT 11, 9, StrLCK
    TXT 1, 11, StrATK
    TXT 11, 11, StrMAG
    TXT 1, 12, StrDEF
    TXT 11, 12, StrCRT
    TXT 1, 13, StrDGE
    TXT 11, 13, StrBLK
    TXT 1, 14, StrCDM
    TXT 11, 14, StrSPD
    TXT 1, 15, StrPTS
    TXT 11, 15, StrGoldL
    db $FF
StrMP:  db "MP", $FF
StrVIT: db "VIT", $FF
StrFTH: db "FTH", $FF
StrLCK: db "LCK", $FF
StrMAG: db "MAG", $FF
StrDEF: db "DEF", $FF
StrCRT: db "CRT", $FF
StrDGE: db "DGE", $FF
StrBLK: db "BLK", $FF
StrCDM: db "CDM", $FF
StrSPD: db "SPD", $FF
StrPTS: db "PTS", $FF
StrSpendHint: db "A: SPEND POINTS", $FF
MsgDodge: db "DODGE"

MenuStatus:
    ldh a, [hNewKeys]
    and PAD_A
    jr nz, OpenAlloc
    ldh a, [hNewKeys]
    and PAD_B | PAD_START
    ret z
    call SfxMenu
    jp ReturnToPause

; ---- spend attribute points ------------------------------------------------------------
OpenAlloc:
    call SfxMenu
    ld a, M_ALLOC
    ld [wMenu], a
    xor a
    ld [wAllocCur], a
DrawAlloc:
    call WinClearAll
    ld b, 0
    ld c, 0
    ld d, 20
    ld e, 18
    call DrawBox
    ld hl, AllocLabels
    call WinPrintList
    ld hl, wStatPts
    ld b, 11
    ld c, 1
    call PutWord
    ld c, 0
.v:
    push bc
    ld a, c
    add a, a
    ld e, a
    ld d, 0
    ld hl, wAttr
    add hl, de
    ld a, c
    add a, a
    add a, 3
    ld c, a
    ld b, 8
    call PutWord
    pop bc
    inc c
    ld a, c
    cp 6
    jr nz, .v
    call AllocCursor
    jp ShowFresh

AllocCursor:
    ld b, 1
    ld c, 3
    ld d, 6
    ld a, [wAllocCur]
    ld e, a
    ld a, T_CUR
    jp DrawListCursor

MenuAlloc:
    ld hl, wAllocCur
    ld b, 6
    call ListNav
    jp c, AllocCursor
    ldh a, [hNewKeys]
    and PAD_B
    jr z, .notB
    call SfxMenu
    call RecalcStats
    ld a, M_STATUS
    ld [wMenu], a
    call DrawSheet
    jp ShowFresh
.notB:
    ldh a, [hNewKeys]
    and PAD_A
    ret z
    ld a, [wStatPts]
    ld b, a
    ld a, [wStatPts + 1]
    or b
    jp z, SfxBlock
    ld hl, wStatPts              ; spend one point
    ld a, [hl]
    sub 1
    ld [hl+], a
    jr nc, .n
    dec [hl]
.n:
    ld a, [wAllocCur]
    add a, a
    ld e, a
    ld d, 0
    ld hl, wAttr
    add hl, de
    inc [hl]
    jr nz, .n2
    inc hl
    inc [hl]
.n2:
    call RecalcStats
    call SfxPickup
    jp DrawAlloc

AllocLabels:
    TXT 1, 1, StrPointsLeft
    TXT 3, 3, StrSTRl
    TXT 3, 5, StrDEXl
    TXT 3, 7, StrVITl
    TXT 3, 9, StrINTl
    TXT 3, 11, StrFTHl
    TXT 3, 13, StrLCKl
    TXT 1, 15, StrAllocHint1
    TXT 1, 16, StrAllocHint2
    db $FF
StrPointsLeft: db "POINTS:", $FF
StrSTRl: db "STR", $FF
StrDEXl: db "DEX", $FF
StrVITl: db "VIT", $FF
StrINTl: db "INT", $FF
StrFTHl: db "FTH", $FF
StrLCKl: db "LCK", $FF
StrAllocHint1: db "A: +1 POINT", $FF
StrAllocHint2: db "B: DONE", $FF
