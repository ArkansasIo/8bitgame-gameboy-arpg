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

; monster accuracy / evasion / resist from level (after CalcMonster)
CalcMonsterExtra:                ; de = level
    ld h, d
    ld l, e
    add hl, hl
    add hl, hl
    ld bc, 60
    add hl, bc
    ld a, l
    ld [wMACC], a
    ld a, h
    ld [wMACC + 1], a
    ld h, d
    ld l, e
    add hl, hl
    ld bc, 20
    add hl, bc
    ld a, l
    ld [wMEVA], a
    ld a, h
    ld [wMEVA + 1], a
    ret

; ---- player: class start + growth (framework attributes) ---------------------------
;               STR DEX CON INT WIS VIT SPI LCK WIL CHA
ClassStart: db  14, 11, 13,  6,  8, 13,  6,  6, 10,  8   ; fighter
            db   9, 14, 11,  9,  8, 10,  7, 12,  8, 10   ; rogue
            db   6, 10,  9, 15, 10,  8, 14,  8, 11,  9   ; wizard
            db  11,  8, 12,  7, 14, 11, 12,  7, 12, 10   ; cleric
ClassGrowth: db  2,  1,  2,  0,  0,  2,  0,  0,  1,  0
            db   1,  2,  1,  0,  0,  1,  0,  2,  0,  1
            db   0,  1,  1,  3,  1,  1,  2,  0,  1,  0
            db   1,  0,  1,  0,  3,  2,  1,  0,  1,  1
DEF NUM_ATTR EQU 10

ClassRow10:                      ; hl = table + class * 10
    ld a, [wClass]
    add a, a
    ld b, a
    add a, a
    add a, a
    add a, b
    add a, l
    ld l, a
    ret nc
    inc h
    ret

InitAttributes:                  ; level 1 character of wClass
    ld hl, ClassStart
    call ClassRow10
    ld de, wAttr
    ld c, NUM_ATTR
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
    call ClearEffects
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

; hl = [hl1]*a1 helper: AttrMul a = multiplier, hl = attribute address
AttrMul:
    push af
    call LoadW
    pop af
    jp MulHL_A

StoreW:                          ; [de] = hl
    ld a, l
    ld [de], a
    inc de
    ld a, h
    ld [de], a
    ret

; ---- derived sub-stats (framework section 3-6) ---------------------------------------
RecalcStats:
    call GearBonus
    ; MaxHP = VIT*8 + CON*5 + LV*4 + 40
    ld hl, wEVit
    ld a, 8
    call AttrMul
    push hl
    ld hl, wECon
    ld a, 5
    call AttrMul
    pop de
    call AddSat
    push hl
    ld hl, wLevel
    ld a, 4
    call AttrMul
    pop de
    call AddSat
    ld de, 40
    call AddSat
    ld de, gAcc + 26             ; + gear HP
    call AddAttr
    ld de, wMaxHP
    call StoreW
    ; MaxMP = INT*3 + SPI*4 + 10
    ld hl, wEInt
    ld a, 3
    call AttrMul
    push hl
    ld hl, wESpi
    ld a, 4
    call AttrMul
    pop de
    call AddSat
    ld de, 10
    call AddSat
    ld de, gAcc + 28             ; + gear MP
    call AddAttr
    ld de, wMaxMP
    call StoreW
    ld a, [gWpnFlags]
    ld [wWpnFlags], a
    ; ATK (physical power) = 2.5 * max(STR, DEX if finesse) + weapon + LV
    ld hl, wEStr
    call LoadW
    ld a, [wWpnFlags]
    and 1
    jr z, .str
    push hl
    ld hl, wEDex
    call LoadW
    ld d, h
    ld e, l
    pop hl
    call MaxHLDE
.str:
    ld a, 5
    call MulHL_A
    srl h
    rr l
    ld a, [gWpn]
    ld e, a
    ld a, [gWpn + 1]
    ld d, a
    call AddSat
    ld de, gAcc + 20             ; + gear ATK
    call AddAttr
    call AddLevel
    ld de, wATK
    call StoreW
    ; MAG (spell power) = 2.5 * INT + WIS + LV
    ld hl, wEInt
    ld a, 5
    call AttrMul
    srl h
    rr l
    ld de, wEWis
    call AddAttr
    call AddLevel
    ld de, gAcc + 22             ; + gear MAG
    call AddAttr
    ld de, wMAG
    call StoreW
    ; HEAL (healing power) = 2 * WIS + SPI
    ld hl, wEWis
    call LoadW
    add hl, hl
    ld de, wESpi
    call AddAttr
    ld de, wHEAL
    call StoreW
    ; ACC = 2*DEX + 2*LV + 50 ; EVA = DEX + LCK/2 + LV
    ld hl, wEDex
    call LoadW
    add hl, hl
    call AddLevel
    call AddLevel
    ld de, 50
    call AddSat
    ld de, gAcc + 36
    call AddAttr
    ld de, wACC
    call StoreW
    ld hl, wELck
    call LoadW
    srl h
    rr l
    ld de, wEDex
    call AddAttr
    call AddLevel
    ld de, gAcc + 38
    call AddAttr
    ld de, wEVA
    call StoreW
    ; ARMOR = gear + CON + VIT/2 + LV/2
    ld hl, wEVit
    call LoadW
    srl h
    rr l
    ld de, wECon
    call AddAttr
    ld a, [gArmor]
    ld e, a
    ld a, [gArmor + 1]
    ld d, a
    call AddSat
    ld de, gAcc + 24             ; + gear armor affixes
    call AddAttr
    push hl
    ld hl, wLevel
    call LoadW
    srl h
    rr l
    pop de
    call AddSat
    ld de, wDEF
    call StoreW
    ; RESIST = WIS + SPI/2 + WIL/2
    ld hl, wESpi
    call LoadW
    push hl
    ld hl, wEWil
    call LoadW
    pop de
    add hl, de
    srl h
    rr l
    ld de, wEWis
    call AddAttr
    ld de, gAcc + 48
    call AddAttr
    ld de, wRES
    call StoreW
    ; percentages ---------------------------------------------------
    ld hl, wEDex                  ; CRIT% = 5 + DEX/25 + LCK/20 (cap 60)
    ld a, 25
    call AttrDiv
    push hl
    ld hl, wELck
    ld a, 20
    call AttrDiv
    pop de
    add hl, de
    ld de, 5
    add hl, de
    ld de, gAcc + 30             ; + gear crit
    call AddAttr
    ld a, 60
    call CapHL
    ld [wCrit], a
    ld hl, wELck                  ; CRIT DMG% = 50 + LCK/10 (cap 250)
    ld a, 10
    call AttrDiv
    ld de, 50
    add hl, de
    ld de, gAcc + 32
    call AddAttr
    ld a, 250
    call CapHL
    ld [wCritDmg], a
    ld hl, wECon                  ; BLOCK% = CON/60 (cap 25)
    ld a, 60
    call AttrDiv
    ld de, gAcc + 34
    call AddAttr
    ld a, 40
    call CapHL
    ld [wBlockP], a
    ld hl, wEWil                  ; TENACITY% = WIL/20 (cap 50)
    ld a, 20
    call AttrDiv
    ld a, 50
    call CapHL
    ld [wTen], a
    ld hl, wEWil                  ; STATUS RESIST% = WIL/25 + CON/50 (cap 60)
    ld a, 25
    call AttrDiv
    push hl
    ld hl, wECon
    ld a, 50
    call AttrDiv
    pop de
    add hl, de
    ld a, 60
    call CapHL
    ld [wSRes], a
    ld hl, wEWis                  ; CDR% = WIS/50 (cap 30)
    ld a, 50
    call AttrDiv
    ld a, 30
    call CapHL
    ld [wCDR], a
    ld hl, wEStr                  ; ARMOR PEN% = STR/40, MAGIC PEN% = INT/40 (cap 40)
    ld a, 40
    call AttrDiv
    ld a, 40
    call CapHL
    ld [wAPen], a
    ld hl, wEInt
    ld a, 40
    call AttrDiv
    ld a, 40
    call CapHL
    ld [wMPen], a
    ld hl, wECha                  ; DISCOUNT% = CHA/20 (cap 30)
    ld a, 20
    call AttrDiv
    ld a, 30
    call CapHL
    ld [wDiscount], a
    ld hl, wEDex                  ; swing time 12 - DEX/150 - haste buff (min 5)
    ld a, 150
    call AttrDiv
    ld a, 6
    call CapHL
    ld b, a
    ld a, [gAcc + 46]            ; gear haste
    add a, b
    ld b, a
    ld a, [wBuffHaste]
    and a
    jr z, .nh
    inc b
    inc b
    inc b
.nh:
    ld a, b
    cp 8
    jr c, .hok
    ld b, 7
.hok:
    ld a, ATTACK_TIME
    sub b
    ld [wAtkTime], a
    ld b, a
    ld a, ATTACK_TIME + 1
    sub b
    ld [wSpdRating], a
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
    ld b, a
    ld a, [hl+]
    ld e, a
    ld a, [hl-]
    ld d, a
    ld a, c
    sub e
    ld a, b
    sbc a, d
    ret nc
    ld a, c
    ld [hl+], a
    ld [hl], b
    ret

AddLevel:                        ; hl += level
    push hl
    ld hl, wLevel
    call LoadW
    ld d, h
    ld e, l
    pop hl
    jp AddSat

AddAttr:                         ; hl += [de]
    ld a, [de]
    ld c, a
    inc de
    ld a, [de]
    ld d, a
    ld e, c
    jp AddSat

AttrDiv:                         ; hl = [hl] / a
    push af
    call LoadW
    pop af
    jp DivHL_A

CapHL:                           ; a = min(hl, a)
    ld b, a
    ld a, h
    and a
    ld a, b
    ret nz
    ld a, l
    cp b
    ret c
    ld a, b
    ret

; a = 100 * hl / (hl + de), using scaled 8-bit division
Ratio100:
.scale:
    push hl
    add hl, de
    ld a, h
    pop hl
    jr c, .shift
    and a
    jr z, .ok
.shift:
    srl h
    rr l
    srl d
    rr e
    jr .scale
.ok:
    push hl
    add hl, de
    ld a, l
    pop hl
    and a
    ret z                        ; 0/0
    push af
    ld a, 100
    call MulHL_A
    pop af
    jp DivHL_A                   ; result in l
.done:
    ret

; armor mitigation % = armor / (armor + 10 * attackerLevel), cap 70
; hl = armor, de = attacker level -> a = percent
Mitigation:
    push hl
    ld h, d
    ld l, e
    ld a, 10
    call MulHL_A
    ld d, h
    ld e, l
    pop hl
    call Ratio100
    ld a, l
    cp 70
    ret c
    ld a, 70
    ret

; hl = hl * (100 - a) / 100
ReducePct:
    ld b, a
    ld a, 100
    sub b
    push af
    srl h
    rr l
    srl h
    rr l                         ; /4
    pop af
    call MulHL_A
    ld a, 25
    jp DivHL_A

; hl = hl * (100 + a) / 100   (a <= 155)
IncreasePct:
    push hl
    srl h
    rr l
    srl h
    rr l
    call MulHL_A
    ld a, 25
    call DivHL_A
    pop de
    jp AddSat

; ---- XP and levels ---------------------------------------------------------------------
XpNeeded:                        ; de = 15 + LV*8 + (LV/8)^2
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

AddXP:                           ; de = XP gained (+ gear XP%)
    push de
    ld a, 22
    call GearPct
    pop hl
    push hl
    call ReducePctInv
    pop de
    add hl, de
    ld d, h
    ld e, l
    ld hl, wXP
    ld a, [hl]
    add a, e
    ld [hl+], a
    ld a, [hl]
    adc a, d
    ld [hl], a
    jr nc, CheckLevelUp
    ld a, $FF
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
    ret c
    ld [wXP + 1], a
    ld a, c
    ld [wXP], a
    ld hl, wLevel
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
    ld hl, ClassGrowth
    call ClassRow10
    ld de, wAttr
    ld c, NUM_ATTR
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

; ---- damage pipeline (framework section 38) ----------------------------------------
Spread:                          ; hl = hl * (90..110%)
    push hl
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    push hl
    call Rand
    pop de
    pop hl
    push de
    srl d
    rr e
    call SubSat
    pop de
    and $0F
    push hl
    ld h, d
    ld l, e
    call MulHL_A
    ld a, 16
    call DivHL_A
    pop de
    add hl, de
    ret

PlayerLevelDE:
    ld a, [wLevel]
    ld e, a
    ld a, [wLevel + 1]
    ld d, a
    ret

; does the hero hit wCur? (accuracy vs evasion, clamp 5..95) -> carry = hit
PlayerHitRoll:
    call CalcCurMonster
    ld a, [wCur + E_LVL]
    ld e, a
    ld a, [wCur + E_LVL + 1]
    ld d, a
    call CalcMonsterExtra
    ld hl, wACC
    call LoadW
    ld a, [wMEVA]
    ld e, a
    ld a, [wMEVA + 1]
    ld d, a
    call Ratio100
    ld a, l
    call Clamp595
    ld b, a
    jp Chance

Clamp595:
    cp 5
    jr nc, .lo
    ld a, 5
.lo:
    cp 95
    ret c
    ld a, 95
    ret

; hl = raw physical damage vs wCur -> after armor (with penetration), buffs, crit
PlayerMeleeDamage:
    ld hl, wATK
    call LoadW
    call Spread
    call OutgoingMods
    ld a, [wCur + E_FRESH]       ; rogue sneak attack +50% on a fresh foe
    and a
    jr z, .nsa
    ld a, [wClass]
    cp 1
    jr nz, .nsa
    ld a, 50
    call IncreasePct
.nsa:
    push hl
    ld hl, wMDEF                 ; monster armor, reduced by armor pen
    call LoadW
    ld a, [wAPen]
    call ReducePct
    call PlayerLevelDE
    call Mitigation
    pop hl
    call ReducePct
    jp RollCrit

OutgoingMods:                    ; power buff +25%, weakness -25%
    ld a, [wBuffPower]
    and a
    jr z, .np
    ld a, 25
    call IncreasePct
.np:
    ld a, [wDebWeak]
    and a
    ret z
    ld a, 25
    jp ReducePct

RollCrit:                        ; hl = damage -> maybe + crit damage %
    xor a
    ld [wWasCrit], a
    ld a, [wCrit]
    ld b, a
    call Chance
    jr nc, .min1
    ld a, 1
    ld [wWasCrit], a
    ld a, [wCritDmg]
    cp 156
    jr c, .one
    push af                      ; > 155%: apply in two steps
    ld a, 100
    call IncreasePct
    pop af
    sub 100
.one:
    call IncreasePct
    push hl
    ld hl, MsgCrit
    call SetMsg
    pop hl
.min1:
    ld a, h
    or l
    ret nz
    inc l
    ret

; spell damage vs wCur: hl = power -> resist mitigation (magic pen) + crit
SpellDamage:
    push hl
    call CalcCurMonster
    pop hl
    call Spread
    call OutgoingMods
    push hl
    ld hl, wMDEF                 ; monster resist = armor / 2, minus magic pen
    call LoadW
    srl h
    rr l
    ld a, [wMPen]
    call ReducePct
    call PlayerLevelDE
    call Mitigation
    pop hl
    call ReducePct
    jp RollCrit

; monster in wCur attacks the hero (hit roll, armor, block, crit, on-hit debuff)
EnemyAttack:
    call CalcCurMonster
    ld a, [wCur + E_LVL]
    ld e, a
    ld a, [wCur + E_LVL + 1]
    ld d, a
    call CalcMonsterExtra
    ld hl, wMACC                 ; hit chance: monster ACC vs hero EVA
    call LoadW
    ld a, [wEVA]
    ld e, a
    ld a, [wEVA + 1]
    ld d, a
    call Ratio100
    ld a, l
    call Clamp595
    ld b, a
    call Chance
    jp nc, .dodged
    ld hl, wMATK
    call LoadW
    call Spread
    ld a, [wDebFrail]            ; frailty: +25% damage taken
    and a
    jr z, .nfr
    ld a, 25
    call IncreasePct
.nfr:
    push hl
    ld hl, wDEF
    call LoadW
    ld a, [wBuffFort]            ; fortified: +50% armor
    and a
    jr z, .nfo
    ld a, 50
    call IncreasePct
.nfo:
    ld a, [wCur + E_LVL]
    ld e, a
    ld a, [wCur + E_LVL + 1]
    ld d, a
    call Mitigation
    pop hl
    call ReducePct
    ld a, [wArmFlags]            ; 5% monster crit (+50%) unless adamantine
    and 4
    jr nz, .nc
    ld b, 5
    call Chance
    jr nc, .nc
    ld a, 50
    call IncreasePct
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
    ld a, 11                     ; BULWARK: blocking heals 3%
    call HasAspect
    jr z, .nbw
    ld a, 1
    call HpFraction
    srl h
    rr l
    call HealQuiet
.nbw:
    pop hl
    call SfxBlock
.nb:
    push hl
    call OnHeroHurt              ; THORNS
    pop hl
    push hl
    call MonsterOnHit            ; maybe inflict this monster's debuff
    pop hl
    jp PlayerTakeDamage
.dodged:
    ld a, 30
    ld [wPlayerInv], a
    call KnockFromCur
    ld hl, MsgDodge
    call SetMsg
    jp SfxBlock

PlayerTakeDamage:                ; hl = damage to the hero
    ld a, [wDodge]               ; Uncanny Dodge halves it
    and a
    jr z, .nd
    dec a
    ld [wDodge], a
    srl h
    rr l
.nd:
    call LoseHP
    ret z
    ld a, 60
    ld [wPlayerInv], a
    call KnockFromCur
    jp SfxHurt

LoseHP:                          ; hl = damage; z set if the hero died (game over shown)
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
    or 1
    ret
.dead:
    xor a
    ld [wHP], a
    ld [wHP + 1], a
    call SfxHurt
    call ShowGameOver
    xor a
    ret

HealPlayer:                      ; hl = HP to restore (capped)
    ld a, [wHP]
    ld e, a
    ld a, [wHP + 1]
    ld d, a
    call AddSat
    ld de, wHP
    call StoreW
    ld hl, wHP
    ld de, wMaxHP
    call ClampWord
    jp SfxPickup

HpFraction:                      ; hl = MaxHP * a / 16
    push af
    ld hl, wMaxHP
    call LoadW
    ld a, 16
    call DivHL_A
    pop af
    jp MulHL_A

HpIsFull:
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

SpendMP:                         ; a = cost -> carry if not enough
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

MPTick:                          ; MP: 1 + MaxMP/64 per second (+SPI/40)
    ld a, [wSecTick]
    and a
    ret z
    ld hl, wMaxMP
    call LoadW
    ld a, 64
    call DivHL_A
    inc hl
    push hl
    ld hl, wSpi
    ld a, 40
    call AttrDiv
    pop de
    add hl, de
    ld a, [wMP]
    ld e, a
    ld a, [wMP + 1]
    ld d, a
    call AddSat
    ld de, wMP
    call StoreW
    ld hl, wMP
    ld de, wMaxMP
    jp ClampWord

; ---- HUD:  H12345 M1234 [msg or effect icons] L720 ----------------------------------
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
    jr z, .icons
    ld hl, wMsgPtr
    call LoadW
    ld de, wHudBuf + 11
    ld c, 5
    call CopyC
    jr .lvl
.icons:
    ld de, wHudBuf + 11          ; up to 5 active effect icons
    ld hl, EffectIcons
    ld a, NUM_EFFECTS
    ld [wTmp], a
    xor a
    ld [wTmp + 1], a
.ic:
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld b, a                      ; bc = timer address
    ld a, [bc]
    and a
    ld a, [hl+]                  ; icon (flags kept)
    jr z, .skip
    ld [de], a
    inc de
    ld a, [wTmp + 1]
    inc a
    ld [wTmp + 1], a
    cp 5
    jr z, .lvl
.skip:
    ld a, [wTmp]
    dec a
    ld [wTmp], a
    jr nz, .ic
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
CopyC:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, CopyC
    ret

; ============================================================================
;  EFFECTS - buffs / debuffs (framework sections 13-17)
;  Each effect is a seconds timer; DoTs carry a per-second power.
;  Stacking: re-applying refreshes to the longer duration (ReplaceStronger).
;  Debuffs on the hero: status resist may block them, tenacity shortens them.
; ============================================================================
DEF FX_SLOW   EQU 1
DEF FX_WEAK   EQU 2
DEF FX_FRAIL  EQU 3
DEF FX_STUN   EQU 4
DEF FX_BURN   EQU 5
DEF FX_POISON EQU 6

; timer address + HUD icon, buffs first
EffectIcons:
    dw wBuffPower
    db "P"
    dw wBuffHaste
    db "H"
    dw wBuffFort
    db "F"
    dw wBuffRegen
    db "R"
    dw wDebStun
    db "Z"
    dw wDebSlow
    db "S"
    dw wDebWeak
    db "W"
    dw wDebFrail
    db "V"
    dw wDebBurn
    db "B"
    dw wDebPoison
    db "T"
DEF NUM_EFFECTS EQU 10

ClearEffects:
    ld hl, wFxStart
    ld bc, wFxEnd - wFxStart
    xor a
    jp Memset

; per frame: count seconds; once a second tick every timer and DoT/HoT
EffectsTick:
    xor a
    ld [wSecTick], a
    ld hl, wFrameSec
    inc [hl]
    ld a, [hl]
    cp 60
    ret c
    ld [hl], 0
    ld a, 1
    ld [wSecTick], a
    ld a, [wBuffHaste]
    push af
    ld hl, wFxStart              ; every timer counts down
    ld c, wFxTimersEnd - wFxStart
.t:
    ld a, [hl]
    and a
    jr z, .n
    dec [hl]
.n:
    inc hl
    dec c
    jr nz, .t
    pop af                       ; haste ended: restore swing speed
    and a
    jr z, .dots
    ld a, [wBuffHaste]
    and a
    call z, RecalcStats
.dots:
    ld a, [wDebBurn]             ; burn / poison tick (ignore armor)
    and a
    jr z, .np1
    ld hl, wBurnPwr
    call LoadW
    call LoseHP
    ret z
.np1:
    ld a, [wDebPoison]
    and a
    jr z, .np2
    ld hl, wPoisonPwr
    call LoadW
    call LoseHP
    ret z
.np2:
    ld a, [wBuffRegen]           ; regeneration: 1/16 max HP per second
    and a
    jr z, .nr
    ld a, 1
    call HpFraction
    call HealQuiet
.nr:
    ld hl, wCon                  ; natural regen: CON/50 per second
    ld a, 50
    call AttrDiv
    ld a, h
    or l
    ret z
    jp HealQuiet

HealQuiet:                       ; heal without the pickup sound
    ld a, [wHP]
    ld e, a
    ld a, [wHP + 1]
    ld d, a
    call AddSat
    ld de, wHP
    call StoreW
    ld hl, wHP
    ld de, wMaxHP
    jp ClampWord

; give the hero a buff: a = seconds, hl = timer address
GiveBuff:
    cp [hl]
    ret c
    ld [hl], a
    ret

; inflict a debuff on the hero: a = effect, b = seconds, de = power (DoTs)
DebuffHero:
    ld [wTmpFx], a
    push de
    push bc
    ld a, [wSRes]                ; status resist
    ld b, a
    call Chance
    pop bc
    pop de
    ret c
    push de
    ld a, [wTen]                 ; tenacity shortens it
    ld c, a
    ld l, b
    ld h, 0
    call ReducePct
    ld a, l
    and a
    jr nz, .ok
    inc a
.ok:
    ld b, a
    pop de
    ld a, [wTmpFx]
    dec a
    ld hl, DebuffAddrs
    add a, a
    add a, l
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, b
    cp [hl]
    jr c, .keep
    ld [hl], a
.keep:
    ld a, [wTmpFx]
    cp FX_BURN
    jr nz, .nb
    ld hl, wBurnPwr
    jr .pw
.nb:
    cp FX_POISON
    ret nz
    ld hl, wPoisonPwr
.pw:
    ld a, e
    ld [hl+], a
    ld [hl], d
    ret

DebuffAddrs: dw wDebSlow, wDebWeak, wDebFrail, wDebStun, wDebBurn, wDebPoison

; monster wCur hit the hero: 25% chance of its signature debuff
MonsterOnHit:
    ld a, [wCur + E_TYPE]
    dec a
    ld hl, MonsterDebuff
    add a, l
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, [hl]
    and a
    ret z
    ld [wTmpFx], a
    ld b, 25
    call Chance
    ret nc
    ld hl, wMATK                 ; DoT power = monster ATK / 8
    call LoadW
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    ld d, h
    ld e, l
    ld a, [wTmpFx]
    ld b, 4                      ; base 4 seconds (stun 1)
    cp FX_STUN
    jr nz, .s
    ld b, 1
.s:
    jp DebuffHero

; signature debuff per monster type (0 none)
; GOBLIN BAT SKEL OGRE WOLF SPIDER LIZARD GNOLL MUMMY FROG ZOMBIE LIZFOLK TOAD WWOLF
MonsterDebuff: db FX_POISON, 0, FX_FRAIL, FX_STUN, FX_POISON, FX_POISON, 0
               db FX_POISON, FX_WEAK, FX_SLOW, FX_WEAK, FX_POISON, FX_SLOW, FX_SLOW

; ---- debuffs on monsters (stored in the enemy struct) ---------------------------------
; a = effect (FX_BURN / FX_POISON / FX_SLOW / FX_STUN), b = seconds, de = DoT power
DebuffCur:
    cp FX_STUN
    jr nz, .ns
    ld a, b
    ld [wCur + E_STUN], a
    ret
.ns:
    cp FX_SLOW
    jr nz, .nsl
    ld a, b
    ld [wCur + E_SLOW], a
    ret
.nsl:
    ld a, b
    ld [wCur + E_DOT], a
    ld a, e
    ld [wCur + E_DOTPWR], a
    ld a, d
    ld [wCur + E_DOTPWR + 1], a
    ret

; once a second for wCur: count timers, apply DoT. -> carry if it died
MonsterEffectsTick:
    ld a, [wSecTick]
    and a
    ret z
    ld hl, wCur + E_STUN
    ld a, [hl]
    and a
    jr z, .a
    dec [hl]
.a:
    ld hl, wCur + E_SLOW
    ld a, [hl]
    and a
    jr z, .b
    dec [hl]
.b:
    ld hl, wCur + E_DOT
    ld a, [hl]
    and a
    ret z
    dec [hl]
    ld a, [wCur + E_DOTPWR]
    ld l, a
    ld a, [wCur + E_DOTPWR + 1]
    ld h, a
    xor a
    ld [wHitKX], a
    ld [wHitKY], a
    ld [wWasCrit], a
    jp ApplyDamageCur

; ---- character sheet (2 pages: attributes / combat stats) --------------------------
OpenStatus:
    ld a, M_STATUS
    ld [wMenu], a
    xor a
    ld [wSheetPage], a
    call RecalcStats
    call DrawSheet
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

PutWord:                         ; hl -> word, 5 digits at b,c
    push bc
    call LoadW
    ld d, h
    ld e, l
    call Num16ToStr
    pop bc
    ld hl, wNumBuf
    jp WinPrint

PutPct:                          ; a = 0..255 percent "nnn%" at b,c
    push bc
    ld l, a
    ld h, 0
    ld d, h
    ld e, l
    call Num16ToStr
    pop bc
    ld hl, wNumBuf + 2
    call WinPrint
    ld a, b
    add a, 3
    ld b, a
    ld a, "%"
    jp WinPutTile

PutList:                         ; hl -> {db col,row ; dw addr ; db kind}* $FF  kind 0 word, 1 pct
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
    ld a, [hl+]
    push hl
    and a
    jr nz, .pct
    ld h, d
    ld l, e
    call PutWord
    pop hl
    jr PutList
.pct:
    ld a, [de]
    call PutPct
    pop hl
    jr PutList

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
    ld hl, wLevel
    ld b, 14
    ld c, 1
    call PutWord
    ld hl, StrLV
    ld b, 11
    ld c, 1
    call WinPrint
    ld a, [wSheetPage]
    and a
    jr nz, .page2
    ld hl, Sheet1Labels
    call WinPrintList
    ld hl, Sheet1Values
    call PutList
    call XpNeeded
    ld a, e
    ld [wTmpW], a
    ld a, d
    ld [wTmpW + 1], a
    ld hl, wTmpW
    ld b, 13
    ld c, 4
    call PutWord
    ld hl, StrSheetHint1
    ld b, 1
    ld c, 16
    jp WinPrint
.page2:
    ld hl, Sheet2Labels
    call WinPrintList
    ld hl, Sheet2Values
    call PutList
    ld hl, StrSheetHint2
    ld b, 1
    ld c, 16
    jp WinPrint

Sheet1Labels:
    TXT 1, 2, StrHP
    TXT 12, 2, StrSlash
    TXT 1, 3, StrMP
    TXT 12, 3, StrSlash
    TXT 1, 4, StrXPLabel
    TXT 12, 4, StrSlash
    TXT 1, 6, StrSTR
    TXT 10, 6, StrDEX
    TXT 1, 7, StrCON
    TXT 10, 7, StrINT
    TXT 1, 8, StrWIS
    TXT 10, 8, StrVIT
    TXT 1, 9, StrSPI
    TXT 10, 9, StrLCK
    TXT 1, 10, StrWIL
    TXT 10, 10, StrCHA
    TXT 1, 12, StrPTS
    TXT 1, 13, StrGoldL
    TXT 10, 12, StrPWR
    db $FF
StrPWR: db "PWR", $FF
Sheet1Values:
    db 6, 2
    dw wHP
    db 0
    db 13, 2
    dw wMaxHP
    db 0
    db 6, 3
    dw wMP
    db 0
    db 13, 3
    dw wMaxMP
    db 0
    db 6, 4
    dw wXP
    db 0
    db 4, 6
    dw wEStr
    db 0
    db 14, 6
    dw wEDex
    db 0
    db 4, 7
    dw wECon
    db 0
    db 14, 7
    dw wEInt
    db 0
    db 4, 8
    dw wEWis
    db 0
    db 14, 8
    dw wEVit
    db 0
    db 4, 9
    dw wESpi
    db 0
    db 14, 9
    dw wELck
    db 0
    db 4, 10
    dw wEWil
    db 0
    db 14, 10
    dw wECha
    db 0
    db 5, 12
    dw wStatPts
    db 0
    db 5, 13
    dw wGold
    db 0
    db 14, 12
    dw wPowerLvl
    db 0
    db $FF
Sheet2Labels:
    TXT 1, 2, StrATK
    TXT 10, 2, StrMAG
    TXT 1, 3, StrHEALl
    TXT 10, 3, StrDEF
    TXT 1, 4, StrACCl
    TXT 10, 4, StrEVAl
    TXT 1, 5, StrRESl
    TXT 1, 7, StrCRT
    TXT 10, 7, StrCDM
    TXT 1, 8, StrBLK
    TXT 10, 8, StrTENl
    TXT 1, 9, StrSRSl
    TXT 10, 9, StrCDRl
    TXT 1, 10, StrAPNl
    TXT 10, 10, StrMPNl
    TXT 1, 11, StrDSCl
    TXT 10, 11, StrSPD
    TXT 1, 13, StrEffects
    db $FF
Sheet2Values:
    db 4, 2
    dw wATK
    db 0
    db 14, 2
    dw wMAG
    db 0
    db 4, 3
    dw wHEAL
    db 0
    db 14, 3
    dw wDEF
    db 0
    db 4, 4
    dw wACC
    db 0
    db 14, 4
    dw wEVA
    db 0
    db 4, 5
    dw wRES
    db 0
    db 4, 7
    dw wCrit
    db 1
    db 14, 7
    dw wCritDmg
    db 1
    db 4, 8
    dw wBlockP
    db 1
    db 14, 8
    dw wTen
    db 1
    db 4, 9
    dw wSRes
    db 1
    db 14, 9
    dw wCDR
    db 1
    db 4, 10
    dw wAPen
    db 1
    db 14, 10
    dw wMPen
    db 1
    db 4, 11
    dw wDiscount
    db 1
    db 14, 11
    dw wSpdRating
    db 1
    db $FF

StrMP:   db "MP", $FF
StrCON:  db "CON", $FF
StrWIS:  db "WIS", $FF
StrVIT:  db "VIT", $FF
StrSPI:  db "SPI", $FF
StrLCK:  db "LCK", $FF
StrWIL:  db "WIL", $FF
StrCHA:  db "CHA", $FF
StrMAG:  db "MAG", $FF
StrDEF:  db "ARM", $FF
StrHEALl: db "HEA", $FF
StrACCl: db "ACC", $FF
StrEVAl: db "EVA", $FF
StrRESl: db "RES", $FF
StrCRT:  db "CRT", $FF
StrCDM:  db "CDM", $FF
StrBLK:  db "BLK", $FF
StrTENl: db "TEN", $FF
StrSRSl: db "SRS", $FF
StrCDRl: db "CDR", $FF
StrAPNl: db "APN", $FF
StrMPNl: db "MPN", $FF
StrDSCl: db "DSC", $FF
StrSPD:  db "SPD", $FF
StrPTS:  db "PTS", $FF
StrEffects: db "EFFECTS ON HUD", $FF
StrSheetHint1: db "A:SPEND  RIGHT:PG2", $FF
StrSheetHint2: db "LEFT:PG1  B:BACK", $FF
MsgDodge: db "MISS!"

MenuStatus:
    ldh a, [hNewKeys]
    and $30                      ; left / right: page
    jr z, .np
    ld a, [wSheetPage]
    xor 1
    ld [wSheetPage], a
    call SfxMenu
    call DrawSheet
    jp ShowFresh
.np:
    ldh a, [hNewKeys]
    and PAD_A
    jr nz, OpenAlloc
    ldh a, [hNewKeys]
    and PAD_B | PAD_START
    ret z
    call SfxMenu
    jp ReturnToPause

; ---- spend attribute points (10 attributes, one row each) ---------------------------
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
    ld hl, StrPointsLeft
    ld b, 1
    ld c, 1
    call WinPrint
    ld hl, wStatPts
    ld b, 9
    ld c, 1
    call PutWord
    ld c, 0
.v:
    push bc
    ld a, c
    add a, a
    ld e, a
    ld d, 0
    ld hl, AttrNames
    add hl, de
    call LoadW
    ld a, c
    add a, 3
    ld c, a
    ld b, 3
    push bc
    call WinPrint
    pop bc
    pop de
    push de
    ld a, e
    add a, a
    ld e, a
    ld d, 0
    ld hl, wAttr
    add hl, de
    ld b, 14
    call PutWord
    pop bc
    inc c
    ld a, c
    cp NUM_ATTR
    jr nz, .v
    ld hl, StrAllocHint1
    ld b, 1
    ld c, 15
    call WinPrint
    ld hl, StrAllocHint2
    ld b, 1
    ld c, 16
    call WinPrint
    call AllocCursor
    jp ShowFresh

AllocCursor:                     ; single-step cursor, rows 3-12
    ld c, 3
    ld e, 0
.l:
    ld a, [wAllocCur]
    cp e
    ld a, T_BLANK
    jr nz, .p
    ld a, T_CUR
.p:
    ld b, 1
    call WinPutTile
    inc c
    inc e
    ld a, e
    cp NUM_ATTR
    jr nz, .l
    ret

MenuAlloc:
    ld hl, wAllocCur
    ld b, NUM_ATTR
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
    ld hl, wStatPts
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

AttrNames: dw StrSTRn, StrDEXn, StrCONn, StrINTn, StrWISn, StrVITn, StrSPIn, StrLCKn, StrWILn, StrCHAn
StrSTRn: db "STRENGTH", $FF
StrDEXn: db "DEXTERITY", $FF
StrCONn: db "CONSTITUTION", $FF
StrINTn: db "INTELLECT", $FF
StrWISn: db "WISDOM", $FF
StrVITn: db "VITALITY", $FF
StrSPIn: db "SPIRIT", $FF
StrLCKn: db "LUCK", $FF
StrWILn: db "WILLPOWER", $FF
StrCHAn: db "CHARISMA", $FF
StrPointsLeft: db "POINTS:", $FF
StrAllocHint1: db "A: +1 POINT", $FF
StrAllocHint2: db "B: DONE", $FF
