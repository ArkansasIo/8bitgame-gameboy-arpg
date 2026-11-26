; ============================================================================
;  GEAR - Diablo-IV-style equipment on the framework's 11 slots
;
;  Item instance (8 bytes):
;    0 base+1 (0 = empty)   1 rarity 0-5 (COMMON..MYTHIC), 6 = SET
;    2-3 item level         4 upgrade +0..+10
;    5 affix 1 (1-based)    6 affix 2 (1-based)
;    7 special: 1-63 legendary aspect, $40|n unique n, $80|n set n
;  Item Power = ilvl + 10*upgrade + 20*rarity.  Power Level = average IP worn.
; ============================================================================
SECTION "Gear", ROMX, BANK[1]

DEF GEAR_BAG   EQU 20
DEF INST       EQU 8
DEF SPECIAL_UNIQUE EQU $40
DEF SPECIAL_SET    EQU $80

RarityMult: db 4, 5, 6, 7, 8, 9, 7          ; quarters (set = epic tier)

; ---- small helpers ---------------------------------------------------------------
EquipPtr:                        ; a = slot -> hl = &wEquip[slot]
    add a, a
    add a, a
    add a, a
    ld e, a
    ld d, 0
    ld hl, wEquip
    add hl, de
    ret

GearPtr:                         ; a = bag index -> hl = &wGear[i]
    add a, a
    add a, a
    add a, a
    ld e, a
    ld d, 0
    ld hl, wGear
    add hl, de
    ret

BaseRow:                         ; a = base index -> hl = GearBases row (slot stat flags pad)
    add a, a
    add a, a
    ld e, a
    ld d, 0
    ld hl, GearBases
    add hl, de
    ret

InstSlot:                        ; hl = instance -> a = slot (instance kept in hl)
    push hl
    ld a, [hl]
    dec a
    call BaseRow
    ld a, [hl]
    pop hl
    ret

TableByte:                       ; hl = table, a = index -> a = [hl + a]
    add a, l
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, [hl]
    ret

TableWord:                       ; hl = table of dw, a = index -> hl = entry
    add a, a
    add a, l
    ld l, a
    jr nc, .nc
    inc h
.nc:
    jp LoadW

; ---- item generation -----------------------------------------------------------------
; wGenLvl = item level, a = rarity ($FF = roll), b = slot ($FF = random)
GenGear:
    ld [wGenRar], a
    ld a, b
    ld [wGenSlot], a
    ld hl, wNewItem
    ld bc, INST
    xor a
    call Memset
    ld a, [wGenRar]
    cp $FF
    call z, RollRarity
    ld [wGenRar], a
    ; set piece? (a quarter of epic drops)
    cp 3
    jr nz, .noSet
    call Rand
    and 3
    jr nz, .noSet
    call Rand
    ld c, NUM_SETS
    call ModC
    ld [wTmpSet], a
    ld b, a                      ; set row = SetTable + set * 10
    add a, a
    add a, a
    add a, b
    add a, a
    ld hl, SetTable
    call AddHLA
    push hl
    call Rand
    ld c, 6
    call ModC
    pop hl
    call TableByte
    inc a
    ld [wNewItem], a
    ld a, 6
    ld [wNewItem + 1], a
    ld a, [wTmpSet]
    or SPECIAL_SET
    ld [wNewItem + 7], a
    jr .lvl
.noSet:
    ld a, [wGenSlot]             ; slot, then a base in that slot
    cp $FF
    jr nz, .haveSlot
    call Rand
    ld c, NUM_GEAR_SLOTS
    call ModC
.haveSlot:
    add a, a
    ld hl, SlotBases
    call AddHLA
    ld a, [hl+]
    ld b, a
    ld c, [hl]
    call Rand
    call ModC
    add a, b
    inc a
    ld [wNewItem], a
    ld a, [wGenRar]
    ld [wNewItem + 1], a
    cp 4                         ; legendary / mythic: an aspect
    jr c, .lvl
    call Rand
    ld c, NUM_ASPECTS
    call ModC
    inc a
    ld [wNewItem + 7], a
.lvl:
    ld a, [wGenLvl]
    ld [wNewItem + 2], a
    ld a, [wGenLvl + 1]
    ld [wNewItem + 3], a
    ld a, [wNewItem + 1]         ; affixes: none / 1 / 2
    and a
    ret z
    call RandAffix
    ld [wNewItem + 5], a
    ld a, [wNewItem + 1]
    cp 1
    ret z
.again:
    call RandAffix
    ld b, a
    ld a, [wNewItem + 5]
    cp b
    jr z, .again
    ld a, b
    ld [wNewItem + 6], a
    ret

RandAffix:
    call Rand
    ld c, NUM_AFFIXES
    call ModC
    inc a
    ret

ModC:                            ; a = a mod c
.l:
    cp c
    ret c
    sub c
    jr .l

AddHLA:
    add a, l
    ld l, a
    ret nc
    inc h
    ret

; rarity from a d100 + luck + item level
RollRarity:
    ld hl, wLck
    ld a, 40
    call AttrDiv
    ld a, h
    and a
    ld a, l
    jr z, .lk
    ld a, 99
.lk:
    ld [wTmpSel], a
    ld hl, wGenLvl
    call LoadW
    ld a, 120
    call DivHL_A
    ld a, [wTmpSel]
    add a, l
    ld [wTmpSel], a
    call Rand100
    ld b, a
    ld a, [wTmpSel]
    add a, b
    jr nc, .ok
    ld a, 255
.ok:
    cp 98
    jr c, .l
    ld a, [wGenLvl + 1]          ; mythics only from item level 256+
    and a
    ld a, 5
    ret nz
    ld a, 4
    ret
.l:
    cp 92
    ld b, 4
    jr nc, .r
    cp 80
    ld b, 3
    jr nc, .r
    cp 60
    ld b, 2
    jr nc, .r
    cp 30
    ld b, 1
    jr nc, .r
    ld b, 0
.r:
    ld a, b
    ret

; a = unique id, wGenLvl set -> wNewItem
GenUnique:
    ld [wTmpSet], a
    add a, a
    add a, a
    add a, a
    ld hl, UniqueTable
    call AddHLA
    ld a, [hl+]
    inc a
    ld [wNewItem], a
    ld a, [hl+]
    ld [wNewItem + 1], a
    ld a, [hl+]
    ld [wNewItem + 5], a
    ld a, [hl]
    ld [wNewItem + 6], a
    ld a, [wTmpSet]
    or SPECIAL_UNIQUE
    ld [wNewItem + 7], a
    xor a
    ld [wNewItem + 4], a
    ld a, [wGenLvl]
    ld [wNewItem + 2], a
    ld a, [wGenLvl + 1]
    ld [wNewItem + 3], a
    ret

; copy wNewItem into the bag -> carry if full
AddGear:
    ld hl, wGear
    ld b, GEAR_BAG
.l:
    ld a, [hl]
    and a
    jr z, .put
    ld de, INST
    add hl, de
    dec b
    jr nz, .l
    scf
    ret
.put:
    ld d, h
    ld e, l
    ld hl, wNewItem
    ld bc, INST
    call Memcpy
    or a
    ret

; ---- item numbers --------------------------------------------------------------------
; hl = instance -> wInstLvl, wInstRar, wInstUpg (helpers for value math)
LoadInst:
    push hl
    inc hl
    ld a, [hl+]
    ld [wInstRar], a
    ld a, [hl+]
    ld [wInstLvl], a
    ld a, [hl+]
    ld [wInstLvl + 1], a
    ld a, [hl]
    ld [wInstUpg], a
    pop hl
    ret

; hl = value -> scaled by rarity (quarters) and upgrade (+10% each)
ScaleInst:
    push hl
    ld a, [wInstRar]
    ld hl, RarityMult
    call TableByte
    pop hl
    call MulHL_A
    srl h
    rr l
    srl h
    rr l
    ld a, [wInstUpg]
    and a
    ret z
    ld b, a                      ; *(10+u)/10
    add a, a
    add a, a
    add a, b
    add a, a                     ; u*10
    jp IncreasePct

; main stat of instance hl (weapon damage or armor) -> hl
InstMainStat:
    call LoadInst
    ld a, [hl]
    dec a
    call BaseRow
    inc hl
    ld a, [hl]                   ; base stat
    and a
    jr z, .zero
    push af
    ld hl, wInstLvl              ; * (ilvl + 10) / 10
    call LoadW
    ld de, 10
    add hl, de
    pop af
    call MulHL_A
    ld a, 10
    call DivHL_A
    jp ScaleInst
.zero:
    ld hl, 0
    ret

; affix a (1-based) value for the loaded instance -> hl, b = target
AffixValue:
    dec a
    add a, a
    ld hl, AffixTable
    call AddHLA
    ld a, [hl+]
    ld [wAffTarget], a
    ld a, [hl]                   ; kind
    push af
    ld hl, wInstLvl
    call LoadW
    pop af
    and a
    jr nz, .k1
    ld a, 8                      ; attr: 2 + ilvl/8
    call DivHL_A
    inc hl
    inc hl
    jr .scale
.k1:
    cp 1
    jr nz, .k2
    ld a, 3                      ; big flat: 4 + ilvl/3
    call DivHL_A
    ld de, 4
    add hl, de
    jr .scale
.k2:
    cp 2
    jr nz, .k3
    ld de, 10                    ; HP: 10 + ilvl
    add hl, de
    jr .scale
.k3:
    cp 3
    jr nz, .k4
    srl h                        ; MP: 5 + ilvl/2
    rr l
    ld de, 5
    add hl, de
    jr .scale
.k4:
    cp 4
    jr nz, .k5
    ld a, 150                    ; percent: 2 + ilvl/150
    call DivHL_A
    inc hl
    inc hl
    jr .scale
.k5:
    ld hl, 1                     ; haste: 1 frame
    ret
.scale:
    call ScaleInst
    ld a, [wAffTarget]
    ld b, a
    ret

; Item Power of instance hl -> hl
ItemPower:
    call LoadInst
    ld hl, wInstLvl
    call LoadW
    ld a, [wInstUpg]
    ld b, a
    add a, a
    add a, a
    add a, b
    add a, a
    ld e, a
    ld d, 0
    add hl, de
    ld a, [wInstRar]
    cp 6
    jr c, .r
    ld a, 3
.r:
    ld b, a
    add a, a
    add a, a
    add a, b
    add a, a
    add a, a                     ; *20
    ld e, a
    ld d, 0
    add hl, de
    ret

; ---- totals from everything worn -------------------------------------------------------
; fills gAcc[25] (words, by affix target), gWpn, gWpnFlags, gArmor, wAspects, set counts,
; wPowerLvl, and wE* effective attributes = base + gear
GearBonus:
    ld hl, wGearCalc
    ld bc, wGearCalcEnd - wGearCalc
    xor a
    call Memset
    xor a
.slot:
    ld [wTmpSlot], a
    call EquipPtr
    ld a, [hl]
    and a
    jp z, .next
    ld a, l
    ld [wCurInst], a
    ld a, h
    ld [wCurInst + 1], a
    push hl                      ; power level sum
    call ItemPower
    ld a, [wPowerSum]
    add a, l
    ld [wPowerSum], a
    ld a, [wPowerSum + 1]
    adc a, h
    ld [wPowerSum + 1], a
    ld hl, wPowerCnt
    inc [hl]
    pop hl
    push hl                      ; main stat
    call InstMainStat
    ld a, [wTmpSlot]
    and a
    jr nz, .armor
    ld a, l
    ld [gWpn], a
    ld a, h
    ld [gWpn + 1], a
    pop hl
    push hl
    ld a, [hl]
    dec a
    call BaseRow
    inc hl
    inc hl
    ld a, [hl]
    ld [gWpnFlags], a
    jr .affixes
.armor:
    ld a, [gArmor]
    ld e, a
    ld a, [gArmor + 1]
    ld d, a
    call AddSat
    ld a, l
    ld [gArmor], a
    ld a, h
    ld [gArmor + 1], a
.affixes:
    pop hl
    call LoadInst
    push hl
    ld de, 5
    add hl, de
    ld a, [hl+]
    call AddAffixA
    pop hl
    push hl
    ld de, 6
    add hl, de
    ld a, [hl]
    call AddAffixA
    pop hl
    ld de, 7                     ; special
    add hl, de
    ld a, [hl]
    and a
    jr z, .next
    bit 7, a
    jr nz, .set
    bit 6, a
    jr nz, .unique
    call SetAspect
    jr .next
.set:
    and $3F
    ld hl, wSetCount
    call AddHLA
    inc [hl]
    jr .next
.unique:
    and $3F                      ; unique: third affix + its aspect
    add a, a
    add a, a
    add a, a
    ld hl, UniqueTable + 4
    call AddHLA
    ld a, [hl+]
    push hl
    call AddAffixA
    pop hl
    ld a, [hl]
    call SetAspect
.next:
    ld a, [wTmpSlot]
    inc a
    cp NUM_GEAR_SLOTS
    jp c, .slot
    ; set bonuses
    xor a
.sets:
    ld [wTmpSet], a
    ld hl, wSetCount
    call TableByte
    cp 2
    jr c, .ns
    push af
    ld a, [wTmpSet]              ; 2pc: target += value (scaled by level/50+1)
    ld b, a
    add a, a
    add a, a
    add a, b
    add a, a
    ld hl, SetTable + 6
    call AddHLA
    ld a, [hl+]
    ld [wAffTarget], a
    ld a, [hl+]
    ld c, [hl]                   ; 4pc aspect
    push bc
    ld l, a
    ld h, 0
    push hl
    ld hl, wLevel
    call LoadW
    ld a, 50
    call DivHL_A
    inc l
    ld a, l
    pop hl
    call MulHL_A
    ld a, [wAffTarget]
    ld b, a
    call AccAdd
    pop bc
    pop af
    cp 4
    jr c, .ns
    ld a, c
    call SetAspect
.ns:
    ld a, [wTmpSet]
    inc a
    cp NUM_SETS
    jr c, .sets
    ; power level
    ld a, [wPowerCnt]
    and a
    jr z, .eff
    ld hl, wPowerSum
    call LoadW
    ld a, [wPowerCnt]
    call DivHL_A
    ld a, l
    ld [wPowerLvl], a
    ld a, h
    ld [wPowerLvl + 1], a
.eff:
    jp EffAttrs

; ---- (rewritten effective-attribute loop: simple and safe) ----
EffAttrs:
    ld c, 0
.l:
    ld a, c
    add a, a
    ld e, a
    ld d, 0
    ld hl, wAttr
    add hl, de
    push hl
    ld hl, gAcc
    add hl, de
    call LoadW
    ld d, h
    ld e, l
    pop hl
    push hl
    call LoadW
    call AddSat
    pop de                       ; de = &wAttr[c] -> target = wEAttr + 2c
    ld a, c
    add a, a
    push hl
    ld hl, wEAttr
    call AddHLA
    ld d, h
    ld e, l
    pop hl
    ld a, l
    ld [de], a
    inc de
    ld a, h
    ld [de], a
    inc c
    ld a, c
    cp NUM_ATTR
    jr nz, .l
    ret

; a = affix id (1-based, 0 = none) for the loaded instance -> accumulate
AddAffixA:
    and a
    ret z
    call AffixValue
AccAdd:                          ; b = target, hl = value -> gAcc[b] += value
    push hl
    ld a, b
    add a, a
    ld hl, gAcc
    call AddHLA
    pop de
    ld a, [hl]
    add a, e
    ld [hl+], a
    ld a, [hl]
    adc a, d
    ld [hl], a
    ret nc
    ld a, $FF
    ld [hl-], a
    ld [hl], a
    ret

SetAspect:                       ; a = aspect id 1..16 -> wAspects bit
    and a
    ret z
    dec a
    cp 8
    jr nc, .hi
    call RoomBit
    ld hl, wAspects
    or [hl]
    ld [hl], a
    ret
.hi:
    sub 8
    call RoomBit
    ld hl, wAspects + 1
    or [hl]
    ld [hl], a
    ret

HasAspect:                       ; a = aspect id -> nz if worn
    dec a
    cp 8
    jr nc, .hi
    call RoomBit
    ld hl, wAspects
    and [hl]
    ret
.hi:
    sub 8
    call RoomBit
    ld hl, wAspects + 1
    and [hl]
    ret

GearPct:                         ; a = gAcc target -> a = value (capped 255)
    add a, a
    ld hl, gAcc
    call AddHLA
    ld a, [hl+]
    ld b, [hl]
    inc b
    dec b
    ret z
    ld a, $FF
    ret

; ---- legendary power hooks --------------------------------------------------------------
; after the hero's hit on wCur (hl = damage dealt, preserved)
OnHeroHit:
    push hl
    ld a, 20                     ; lifesteal %
    call GearPct
    and a
    jr z, .nls
    pop hl
    push hl
    call ReducePctInv            ; hl = damage * a / 100
    call HealQuiet
.nls:
    ld a, 4                      ; LEECH: heal 1/16 of damage
    call HasAspect
    jr z, .nlh
    pop hl
    push hl
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    call HealQuiet
.nlh:
    ld a, 8                      ; FOCUS: +3 MP
    call HasAspect
    jr z, .nf
    ld hl, 3
    ld a, [wMP]
    ld e, a
    ld a, [wMP + 1]
    ld d, a
    call AddSat
    ld de, wMP
    call StoreW
    ld hl, wMP
    ld de, wMaxMP
    call ClampWord
.nf:
    ld a, 1                      ; EMBERS: 20% burn
    call HasAspect
    jr z, .ne
    ld b, 20
    call Chance
    jr nc, .ne
    call AtkFifth
    ld a, FX_BURN
    ld b, 3
    call DebuffCur
.ne:
    ld a, 2                      ; VENOM: 20% poison
    call HasAspect
    jr z, .nv
    ld b, 20
    call Chance
    jr nc, .nv
    call AtkFifth
    ld a, FX_POISON
    ld b, 4
    call DebuffCur
.nv:
    ld a, 3                      ; THUNDER: 10% stun
    call HasAspect
    jr z, .nt
    ld b, 10
    call Chance
    jr nc, .nt
    ld a, FX_STUN
    ld b, 1
    call DebuffCur
.nt:
    pop hl
    ret

AtkFifth:                        ; de = ATK / 5
    ld hl, wATK
    call LoadW
    ld a, 5
    call DivHL_A
    ld d, h
    ld e, l
    ret

ReducePctInv:                    ; hl = hl * a / 100
    push af
    srl h
    rr l
    srl h
    rr l
    pop af
    call MulHL_A
    ld a, 25
    jp DivHL_A

; damage bonuses from powers: hl = damage vs wCur
PowerDamageMods:
    ld a, 5                      ; SLAYING: +30% vs bosses
    call HasAspect
    jr z, .ns
    ld a, [wCur + E_PAL]
    cp 7
    jr nz, .ns
    ld a, 30
    call IncreasePct
.ns:
    ld a, [wWasCrit]             ; WRATH: crits +50%
    and a
    ret z
    ld a, 10
    call HasAspect
    ret z
    ld a, 50
    jp IncreasePct

; on kill: RENEWAL heals, HASTE buff
OnHeroKill:
    ld a, 7
    call HasAspect
    jr z, .nr
    ld a, 1
    call HpFraction
    call HealQuiet
.nr:
    ld a, 12
    call HasAspect
    ret z
    ld a, 4
    ld hl, wBuffHaste
    call GiveBuff
    jp RecalcStats

; hero took hl damage from wCur: THORNS reflects 20%
OnHeroHurt:
    ld a, 6
    call HasAspect
    ret z
    ld a, 20
    call ReducePctInv
    xor a
    ld [wHitKX], a
    ld [wHitKY], a
    jp ApplyDamageCur

; ---- drops -------------------------------------------------------------------------------
; called on a kill: maybe drop gear at the monster (pickup type 3)
MaybeDropGear:
    ld a, [wCur + E_PAL]
    cp 7
    jr z, .boss
    ld hl, wLck                  ; 8% + LCK/50
    ld a, 50
    call AttrDiv
    ld a, l
    add a, 8
    ld b, a
    call Chance
    ret nc
    call MonsterLevelToGen
    ld a, $FF
    ld b, $FF
    call GenGear
    jr .drop
.boss:                           ; bosses always drop a unique
    call MonsterLevelToGen
    call Rand
    ld c, NUM_UNIQUES
    call ModC
    call GenUnique
.drop:
    ld hl, wNewItem
    ld de, wDropItem
    ld bc, INST
    call Memcpy
    ld a, 3
    ld [wPickupType], a
    ld a, 1
    ld [wPickupOn], a
    ld a, [wCur + E_X]
    ld [wPickupX], a
    ld a, [wCur + E_Y]
    ld [wPickupY], a
    scf
    ret

MonsterLevelToGen:
    ld a, [wCur + E_LVL]
    ld [wGenLvl], a
    ld a, [wCur + E_LVL + 1]
    ld [wGenLvl + 1], a
    ret

PickupGear:                      ; hero walked over a gear drop
    ld hl, wDropItem
    ld de, wNewItem
    ld bc, INST
    call Memcpy
    call AddGear
    ld hl, MsgFull
    jr c, .m
    ld a, [wDropItem + 1]        ; rarity flash
    cp 4
    ld hl, MsgLoot
    jr c, .m
    ld hl, MsgLegend
.m:
    call SetMsg
    jp SfxPickup

GiveStartingGear:
    ld hl, wEquip
    ld bc, NUM_GEAR_SLOTS * INST
    xor a
    call Memset
    ld hl, wGear
    ld bc, GEAR_BAG * INST
    xor a
    call Memset
    ld a, [wClass]
    call GetClassRow
    inc hl                       ; kit: main-hand base, chest base
    ld a, [hl+]
    inc a
    ld [wEquip], a               ; main hand
    ld a, 1
    ld [wEquip + 2], a
    ld a, [hl]
    inc a
    ld [wEquip + 3 * INST], a    ; chest
    ld a, 1
    ld [wEquip + 3 * INST + 2], a
    ret

; ---- names / display ------------------------------------------------------------------
; hl = instance -> print rarity char + name at b,c
PutInstName:
    ld a, [hl]
    and a
    jr nz, .some
    push hl
    ld hl, StrEmptyGear
    call WinPrint
    pop hl
    ret
.some:
    push hl
    inc hl
    ld a, [hl]                   ; rarity char
    push hl
    ld hl, RarityChars
    call TableByte
    pop hl
    call WinPutTile
    inc b
    inc b
    pop hl
    push hl
    ld de, 7
    add hl, de
    ld a, [hl]
    pop hl
    push hl
    bit 6, a
    jr z, .base
    bit 7, a
    jr nz, .base
    and $3F                      ; unique name
    ld hl, UniqueNames
    call TableWord
    jr .print
.base:
    ld a, [hl]
    dec a
    ld hl, BaseNames
    call TableWord
.print:
    call WinPrint
    pop hl
    ret

; 3-line detail in the bottom panel (rows 14-16) for instance hl
PutInstDetail:
    ld a, [hl]
    and a
    ret z
    ld a, l
    ld [wCurInst], a
    ld a, h
    ld [wCurInst + 1], a
    inc hl                       ; row 14: rarity  slot
    ld a, [hl]
    ld hl, RarityNames6
    call TableWord
    ld b, 1
    ld c, 14
    call WinPrint
    ld hl, wCurInst
    call LoadW
    call InstSlot
    ld hl, SlotNames
    call TableWord
    ld b, 11
    ld c, 14
    call WinPrint
    ld hl, wCurInst              ; row 15: IP nnn  DMG/ARM nnnn  +u
    call LoadW
    call ItemPower
    ld a, l
    ld [wTmpW], a
    ld a, h
    ld [wTmpW + 1], a
    ld hl, StrIP
    ld b, 1
    ld c, 15
    call WinPrint
    ld hl, wTmpW
    ld b, 3
    ld c, 15
    call PutWord
    ld hl, wCurInst
    call LoadW
    call InstMainStat
    ld a, l
    ld [wTmpW], a
    ld a, h
    ld [wTmpW + 1], a
    or l
    jr z, .noMain
    ld hl, wCurInst
    call LoadW
    call InstSlot
    and a
    ld hl, StrDMG
    jr z, .dm
    ld hl, StrDEF
.dm:
    ld b, 9
    ld c, 15
    call WinPrint
    ld hl, wTmpW
    ld b, 12
    ld c, 15
    call PutWord
.noMain:
    ld hl, wCurInst
    call LoadW
    ld de, 4
    add hl, de
    ld a, [hl]
    and a
    jr z, .noUp
    push af
    ld a, "+"
    ld b, 17
    ld c, 15
    call WinPutTile
    pop af
    inc b
    call WinPutNum2
.noUp:
    ld hl, wCurInst              ; row 16: affix words / set / power name
    call LoadW
    ld de, 7
    add hl, de
    ld a, [hl]
    and a
    jr z, .affs
    bit 7, a
    jr nz, .setn
    bit 6, a
    jr z, .asp
    and $3F
    add a, a
    add a, a
    add a, a
    ld hl, UniqueTable + 5
    call AddHLA
    ld a, [hl]
.asp:
    dec a
    ld hl, AspectNames
    call TableWord
    jr .p16
.setn:
    and $3F
    ld hl, SetNames
    call TableWord
    push hl
    ld hl, StrSetWord
    ld b, 12
    ld c, 16
    call WinPrint
    pop hl
.p16:
    ld b, 1
    ld c, 16
    jp WinPrint
.affs:
    ld hl, wCurInst
    call LoadW
    ld de, 5
    add hl, de
    ld a, [hl+]
    push hl
    and a
    jr z, .a2
    dec a
    ld hl, AffixNames
    call TableWord
    ld b, 1
    ld c, 16
    call WinPrint
.a2:
    pop hl
    ld a, [hl]
    and a
    ret z
    dec a
    ld hl, AffixNames
    call TableWord
    ld b, 10
    ld c, 16
    jp WinPrint

StrEmptyGear: db "-", $FF
StrIP:      db "IP", $FF
StrSetWord: db "SET", $FF
MsgLegend:  db "EPIC!"

; ---- gear screens (tabs: GEAR bag / EQUIPPED / ITEMS) --------------------------------------
OpenGearTab:                     ; a = tab (0 bag, 1 equipped)
    ld [wBagTab], a
    ld a, M_GEAR
    ld [wMenu], a
    call DrawGear
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

DrawTabs:                        ; row 1: GEAR  WORN  ITEMS with a marker
    ld hl, TabList
    call WinPrintList
    ld a, [wBagTab]
    ld b, a
    add a, a
    add a, b
    add a, a                     ; *6
    inc a
    ld b, a
    ld c, 1
    ld a, T_CUR
    jp WinPutTile

TabList:
    TXT 2, 1, StrTabGear
    TXT 8, 1, StrTabWorn
    TXT 14, 1, StrTabItems
    db $FF
StrTabGear:  db "GEAR", $FF
StrTabWorn:  db "WORN", $FF
StrTabItems: db "ITEMS", $FF

GearCount:                       ; a = entries in the current tab
    ld a, [wBagTab]
    and a
    ld a, NUM_GEAR_SLOTS
    ret nz
    ld a, GEAR_BAG
    ret

TabInst:                         ; a = index -> hl = instance for the current tab
    ld b, a
    ld a, [wBagTab]
    and a
    ld a, b
    jp nz, EquipPtr
    jp GearPtr

DrawGear:
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
    call DrawTabs
    ld a, [wGearCur]             ; scroll: 10 rows visible (rows 2-11)
    ld b, a
    ld a, [wGearTop]
    cp b
    jr c, .s1
    jr z, .s1
    ld a, b
    ld [wGearTop], a
.s1:
    ld a, [wGearTop]
    add a, 9
    cp b
    jr nc, .s2
    ld a, b
    sub 9
    ld [wGearTop], a
.s2:
    xor a
    ld [wTmp + 1], a
.row:
    call GearCount
    ld b, a
    ld a, [wGearTop]
    ld c, a
    ld a, [wTmp + 1]
    add a, c
    cp b
    jr nc, .done
    call TabInst
    ld a, [wTmp + 1]
    add a, 2
    ld c, a
    ld b, 2
    push hl
    call PutInstName
    pop hl
    ld a, [hl]
    and a
    jr z, .nextRow
    push bc
    call ItemPower               ; IP on the right
    ld a, l
    ld [wTmpW], a
    ld a, h
    ld [wTmpW + 1], a
    pop bc
    ld hl, wTmpW
    ld b, 15
    call PutWord
.nextRow:
    ld hl, wTmp + 1
    inc [hl]
    ld a, [hl]
    cp 10
    jr c, .row
.done:
    call GearCursor
    ld a, [wGearCur]
    call TabInst
    jp PutInstDetail

GearCursor:
    ld a, [wGearTop]
    ld b, a
    ld a, [wGearCur]
    sub b
    ld [wTmpSel], a
    ld c, 2
    ld e, 0
.l:
    ld a, [wTmpSel]
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
    cp 10
    jr nz, .l
    ret

; left/right on any bag tab cycles GEAR -> WORN -> ITEMS
BagTabSwitch:                    ; b = new keys -> nz if switched (handled)
    bit 4, b
    jr nz, .right
    bit 5, b
    ret z
    ld a, [wBagTab]
    and a
    jr nz, .dec
    ld a, 2
    jr .go
.dec:
    dec a
    jr .go
.right:
    ld a, [wBagTab]
    inc a
    cp 3
    jr c, .go
    xor a
.go:
    ld [wBagTab], a
    xor a
    ld [wGearCur], a
    ld [wGearTop], a
    call SfxMenu
    ld a, [wBagTab]
    cp 2
    jr z, .items
    call OpenGearTab
    or 1
    ret
.items:
    call OpenItems
    or 1
    ret

MenuGear:
    ldh a, [hNewKeys]
    ld b, a
    call BagTabSwitch
    ret nz
    call GearCount
    ld b, a
    ld hl, wGearCur
    call ListNav
    jp c, DrawGear
    ldh a, [hNewKeys]
    and PAD_B
    jr z, .nb
    call SfxMenu
    call RecalcStats
    jp ReturnToPause
.nb:
    ldh a, [hNewKeys]
    and PAD_A
    ret z
    ld a, [wGearCur]
    call TabInst
    ld a, [hl]
    and a
    jp z, SfxBlock
    ld a, [wBagTab]
    and a
    jr nz, .unequip
    call SfxMenu                 ; bag item: EQUIP / SALVAGE choice
    ld a, M_GEARSUB
    ld [wMenu], a
    xor a
    ld [wSubCur], a
    ld b, 0
    ld c, 13
    ld d, 20
    ld e, 5
    call DrawBox
    ld hl, StrEquip
    ld b, 3
    ld c, 15
    call WinPrint
    ld hl, StrSalvage
    ld b, 11
    ld c, 15
    call WinPrint
    jp SubCursor
.unequip:                        ; worn item -> bag
    push hl
    ld hl, wNewItem
    pop de
    push de
    ld h, d
    ld l, e
    ld de, wNewItem
    ld bc, INST
    call Memcpy
    call AddGear
    pop hl
    jr c, .full
    ld bc, INST
    xor a
    call Memset
    call RecalcStats
    call SfxMenu
    jp DrawGear
.full:
    call SfxBlock
    ld hl, MsgFull
    jp SetMsg

MenuGearSub:
    ldh a, [hNewKeys]
    and $F0
    jr z, .nm
    ld a, [wSubCur]
    xor 1
    ld [wSubCur], a
    call SfxMenu
    jp SubCursor
.nm:
    ldh a, [hNewKeys]
    and PAD_B
    jr z, .nb
    call SfxMenu
    jr .back
.nb:
    ldh a, [hNewKeys]
    and PAD_A
    ret z
    ld a, [wGearCur]
    call GearPtr
    ld a, [wSubCur]
    and a
    jr nz, .salvage
    call EquipFromBag
    call RecalcStats
    call SfxPickup
    jr .back
.salvage:                        ; ore = rarity+1, gold = ilvl/4
    push hl
    call LoadInst
    ld a, [wInstRar]
    cp 6
    jr c, .r
    ld a, 3
.r:
    inc a
    ld c, a
.ore:
    push bc
    ld a, ITEM_IRON_ORE
    call InvAdd
    pop bc
    dec c
    jr nz, .ore
    ld hl, wInstLvl
    call LoadW
    srl h
    rr l
    srl h
    rr l
    ld d, h
    ld e, l
    inc de
    call AddGold16
    pop hl
    ld bc, INST
    xor a
    call Memset
    call SfxKill
.back:
    ld a, M_GEAR
    ld [wMenu], a
    jp DrawGear

; hl = bag instance -> swap into its slot
EquipFromBag:
    push hl
    call InstSlot
    call EquipPtr                ; hl = worn slot
    pop de                       ; de = bag
    ld c, INST
.sw:
    ld a, [de]
    ld b, [hl]
    ld [hl+], a
    ld a, b
    ld [de], a
    inc de
    dec c
    jr nz, .sw
    ret

StrSalvage: db "SALVAGE", $FF

; ---- smith: upgrade worn gear +1..+10 for gold + ore --------------------------------------
OpenSmith:
    ld a, M_SMITH
    ld [wMenu], a
    xor a
    ld [wGearCur], a
    ld [wGearTop], a
    ld a, 1
    ld [wBagTab], a              ; list the worn slots
DrawSmith:
    call DrawGear
    ld hl, StrSmith
    ld b, 1
    ld c, 1
    call WinPrint
    ld hl, StrSmithPad
    ld b, 6
    ld c, 1
    call WinPrint
    ld a, [wGearCur]             ; cost line replaces the detail row 16
    call EquipPtr
    ld a, [hl]
    and a
    ret z
    ld b, 1
    ld c, 16
    ld d, 18
    xor a
    call WinFillRow
    call SmithCost
    ld hl, StrCost
    ld b, 1
    ld c, 16
    call WinPrint
    ld hl, wTmpW
    ld b, 6
    ld c, 16
    call PutWord
    ld hl, StrOreX
    ld b, 12
    ld c, 16
    call WinPrint
    ld a, [wSmithOre]
    ld b, 16
    ld c, 16
    jp WinPutNum2

SmithCost:                       ; for the selected worn item -> wTmpW gold, wSmithOre
    ld a, [wGearCur]
    call EquipPtr
    call LoadInst
    ld a, [wInstUpg]
    inc a
    ld [wSmithOre], a
    ld l, a                      ; 30*(u+1) + ilvl/2
    ld h, 0
    ld a, 30
    call MulHL_A
    push hl
    ld hl, wInstLvl
    call LoadW
    srl h
    rr l
    pop de
    add hl, de
    ld a, l
    ld [wTmpW], a
    ld a, h
    ld [wTmpW + 1], a
    ret

MenuSmith:
    ld b, NUM_GEAR_SLOTS
    ld hl, wGearCur
    call ListNav
    jp c, DrawSmith
    ldh a, [hNewKeys]
    and PAD_B
    jr z, .nb
    call SfxMenu
    call RecalcStats
    jp CloseMenu
.nb:
    ldh a, [hNewKeys]
    and PAD_A
    ret z
    ld a, [wGearCur]
    call EquipPtr
    ld a, [hl]
    and a
    jp z, SfxBlock
    ld de, 4
    add hl, de
    ld a, [hl]
    cp 10
    jp nc, SfxBlock              ; already +10
    call SmithCost
    ld a, [wSmithOre]            ; enough ore?
    ld b, a
    call OreCount
    cp b
    jr c, .poor
    ld a, [wTmpW]
    ld e, a
    ld a, [wTmpW + 1]
    ld d, a
    call SpendGold
    jr c, .poor
    ld a, [wSmithOre]
    ld c, a
.use:
    push bc
    call OreSlot
    call InvRemove
    pop bc
    dec c
    jr nz, .use
    ld a, [wGearCur]
    call EquipPtr
    ld de, 4
    add hl, de
    inc [hl]
    call RecalcStats
    call SfxWin
    jp DrawSmith
.poor:
    call SfxBlock
    ld hl, MsgPoor
    jp SetMsg

OreSlot:                         ; a = bag slot holding ore ($FF none)
    ld hl, wInv
    ld c, 0
.l:
    ld a, [hl]
    cp ITEM_IRON_ORE
    jr z, .f
    inc hl
    inc hl
    inc c
    ld a, c
    cp INV_SLOTS
    jr nz, .l
    ld a, $FF
    ret
.f:
    ld a, c
    ret

OreCount:                        ; a = ore owned
    push bc
    call OreSlot
    pop bc
    cp $FF
    jr nz, .have
    xor a
    ret
.have:
    add a, a
    ld hl, wInv + 1
    call AddHLA
    ld a, [hl]
    ret

StrSmithPad: db "             ", $FF
StrCost:     db "COST", $FF
StrOreX:     db "ORE", $FF
MsgPoor:     db "POOR!"
