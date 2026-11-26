; ============================================================================
;  COMBAT - damage rolls, kills + loot, projectiles (cantrips), class skills
; ============================================================================
SECTION "Combat", ROMX, BANK[1]

; hl = damage to wCur (knockback from wHitKX/KY). handles death, XP, loot
ApplyDamageCur:
    xor a
    ld [wCur + E_FRESH], a
    ld a, [wCur + E_HP]
    sub l
    ld e, a
    ld a, [wCur + E_HPHI]
    sbc a, h
    jr c, .kill
    ld d, a
    or e
    jr z, .kill
    ld a, e
    ld [wCur + E_HP], a
    ld a, d
    ld [wCur + E_HPHI], a
    ld a, 16
    ld [wCur + E_HURT], a
    ld a, [wHitKX]
    ld [wCur + E_KX], a
    ld a, [wHitKY]
    ld [wCur + E_KY], a
    ld a, [wWasCrit]
    and a
    jp nz, SfxCrit
    jp SfxHit
.kill:
    ld a, [wCur + E_TYPE]
    call QuestOnKill
    call CalcCurMonster          ; XP scales with the monster's level
    ld a, [wMXP]
    ld e, a
    ld a, [wMXP + 1]
    ld d, a
    call AddXP
    ld a, [wCur + E_TYPE]
    call GetTypeStats
    push hl
    ld de, MS_FLAGS
    add hl, de
    ld a, [hl]
    and a
    jr z, .notBoss
    bit 7, a
    jr z, .zoneBoss
    pop hl                       ; the Ogre falls: victory
    xor a
    ld [wCur + E_TYPE], a
    call SfxKill
    jp ShowWin
.zoneBoss:
    ld b, a
    ld a, [wBossFlags]
    or b
    ld [wBossFlags], a
    ld c, 0                      ; boss loot: bit index -> BossLoot
.bit:
    srl b
    jr c, .gotBit
    inc c
    jr .bit
.gotBit:
    ld hl, BossLoot
    ld a, l
    add a, c
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, [hl]
    call InvAdd
    ld hl, MsgLoot
    call SetMsg
.notBoss:
    pop hl
    ld a, [wPickupOn]
    and a
    jr nz, .noDrop
    call Rand                    ; 1 in 16: random gear / potion
    and 15
    jr nz, .noItem
    call Rand
    and 7
    ld hl, RandomLoot
    add a, l
    ld l, a
    jr nc, .nc2
    inc h
.nc2:
    ld a, [hl]
    ld [wPickupAmt], a
    ld a, 2
    jr .drop
.noItem:
    push hl
    ld a, [wCur + E_TYPE]
    call GetTypeStats
    ld de, MS_GOLD
    add hl, de
    ld a, [hl]
    pop hl
    and a
    jr z, .heartRoll
    ld c, a
    call Rand
    and 1
    jr z, .heartRoll
    call RollDie
    ld [wPickupAmt], a
    ld a, 1
    jr .drop
.heartRoll:
    call Rand
    and 3
    jr nz, .noDrop
    xor a
.drop:
    ld [wPickupType], a
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

; a = enemy slot, hl = damage (already final): apply outside the update loop
DamageSlot:
    ld [wTmpSlot], a
    ld a, l
    ld [wTmpW], a
    ld a, h
    ld [wTmpW + 1], a
    call SlotToCur
    ld hl, wTmpW
    call LoadW
    call ApplyDamageCur
    jr CurToSlot

; a = slot, hl = spell power: mitigated + crit, then applied
SpellOnSlot:
    ld [wTmpSlot], a
    ld a, l
    ld [wTmpW], a
    ld a, h
    ld [wTmpW + 1], a
    call SlotToCur
    ld hl, wTmpW
    call LoadW
    call SpellDamage
    call ApplyDamageCur
CurToSlot:
    ld a, [wGameState]
    cp STATE_WIN
    ret z
    ld a, [wTmpSlot]
    swap a
    ld e, a
    ld d, 0
    ld hl, wEnemies
    add hl, de
    ld d, h
    ld e, l
    ld hl, wCur
    ld bc, ENEMY_SIZE
    jp Memcpy

SlotToCur:
    ld a, [wTmpSlot]
    swap a
    ld e, a
    ld d, 0
    ld hl, wEnemies
    add hl, de
    ld de, wCur
    ld bc, ENEMY_SIZE
    jp Memcpy

; a = nearest living monster slot, or $FF
NearestEnemy:
    ld a, $FF
    ld [wTmpSlot], a
    ld a, $FF
    ld [wTmpDist], a
    ld hl, wEnemies
    ld c, 0
.l:
    ld a, [hl]
    and a
    jr z, .next
    cp NPC_BASE
    jr nc, .next
    push hl
    inc hl
    ld a, [wPlayerX]
    ld b, a
    ld a, [hl+]
    call AbsDiff
    ld d, a
    ld a, [wPlayerY]
    ld b, a
    ld a, [hl]
    call AbsDiff
    srl a
    srl d
    add a, d                     ; rough distance / 2
    ld b, a
    ld a, [wTmpDist]
    cp b
    jr c, .far
    ld a, b
    ld [wTmpDist], a
    ld a, c
    ld [wTmpSlot], a
.far:
    pop hl
.next:
    ld de, ENEMY_SIZE
    add hl, de
    inc c
    ld a, c
    cp MAX_ENEMIES
    jr nz, .l
    ld a, [wTmpSlot]
    ret

; ---- per-frame timers + B action ------------------------------------------------
ClassTick:
    ld hl, wSurgeT
    call .dec
    ld hl, wShieldT
    call .dec
    ld hl, wDashT
    call .dec
    ld hl, wCastCD
.dec:
    ld a, [hl]
    and a
    ret z
    dec [hl]
    ret

; B button: 1 fire bolt, 2 sacred flame, 3 dash. returns nz if it handled B
ClassBAction:
    ld a, [wBAction]
    and a
    ret z
    cp 3
    jr z, .dash
    ld a, [wCastCD]
    and a
    jr nz, .busy
    ld a, [wProjOn]
    and a
    jr nz, .busy
    ld a, 30
    ld [wCastCD], a
    ld a, [wBAction]
    ld [wProjKind], a
    ld a, [wPlayerDir]
    add a, a
    ld e, a
    ld d, 0
    ld hl, DirVec
    add hl, de
    ld a, [hl+]
    ld b, a
    add a, a
    add a, b                     ; speed 3
    ld [wProjDX], a
    ld a, [hl]
    ld b, a
    add a, a
    add a, b
    ld [wProjDY], a
    ld a, [wPlayerX]
    add a, 4
    ld [wProjX], a
    ld a, [wPlayerY]
    add a, 6
    ld [wProjY], a
    ld a, 40
    ld [wProjT], a
    ld a, 1
    ld [wProjOn], a
    call SfxCrit
    or 1
    ret
.dash:
    ld a, [wCastCD]
    and a
    jr nz, .busy
    ld a, 24
    ld [wDashT], a
    ld a, 60
    ld [wCastCD], a
    call SfxSwing
.busy:
    or 1
    ret

UpdateProjectile:
    ld a, [wProjOn]
    and a
    ret z
    ld hl, wProjT
    dec [hl]
    jp z, .off
    ld a, [wProjDX]
    ld b, a
    ld a, [wProjX]
    add a, b
    ld [wProjX], a
    cp 160
    jp nc, .off
    ld a, [wProjDY]
    ld b, a
    ld a, [wProjY]
    add a, b
    ld [wProjY], a
    cp 144
    jp nc, .off
    ld a, [wProjX]               ; walls stop it
    add a, 4
    ld b, a
    ld a, [wProjY]
    add a, 4
    ld c, a
    call IsSolidAt
    jp c, .off
    ld a, [wProjX]               ; hit test vs monsters
    ld [wRectA + 0], a
    ld a, [wProjY]
    ld [wRectA + 1], a
    ld a, 8
    ld [wRectA + 2], a
    ld [wRectA + 3], a
    xor a
    ld [wTmpSlot], a
.l:
    ld a, [wTmpSlot]
    swap a
    ld e, a
    ld d, 0
    ld hl, wEnemies
    add hl, de
    ld a, [hl+]
    and a
    jr z, .next
    cp NPC_BASE
    jr nc, .next
    ld a, [hl+]
    add a, 2
    ld [wRectB + 0], a
    ld a, [hl]
    add a, 3
    ld [wRectB + 1], a
    ld a, 12
    ld [wRectB + 2], a
    ld [wRectB + 3], a
    call RectOverlap
    jr c, .hit
.next:
    ld hl, wTmpSlot
    inc [hl]
    ld a, [hl]
    cp MAX_ENEMIES
    jr nz, .l
    ret
.hit:
    xor a
    ld [wProjOn], a
    ld a, [wTmpSlot]
    ld [wTmpTarget], a
    ld a, [wProjDX]              ; knockback along the flight path
    call Sign
    ld [wHitKX], a
    ld a, [wProjDY]
    call Sign
    ld [wHitKY], a
    ld hl, wMAG                  ; fire bolt: MAG*1.5   sacred flame: MAG+FTH
    call LoadW
    ld a, [wProjKind]
    cp 2
    jr z, .flame
    ld d, h
    ld e, l
    srl d
    rr e
    jr .fire
.flame:
    ld a, [wFth]
    ld e, a
    ld a, [wFth + 1]
    ld d, a
.fire:
    call AddSat
    ld a, [wTmpTarget]
    jp SpellOnSlot
.off:
    xor a
    ld [wProjOn], a
    ret

Sign:                            ; a signed -> -1 / 0 / +1
    and a
    ret z
    bit 7, a
    ld a, 1
    ret z
    ld a, $FF
    ret

DrawProjectile:
    ld a, [wProjOn]
    and a
    ret z
    ld a, [wProjX]
    ld b, a
    ld a, [wProjY]
    ld c, a
    ld a, [wProjKind]
    cp 2
    ld d, T_FIREBOLT
    ld e, OP_HEART
    jr nz, .d
    ld d, T_SPARK
    ld e, OP_SWORD
.d:
    jp DrawSprite8

; ---- skills menu (two class skills) ------------------------------------------
OpenSkills:
    ld a, M_SKILLS
    ld [wMenu], a
    call DrawSkills
    ld a, 7
    ld b, 0
    ld c, 144
    call SetWindow
    call ShowFresh
    jp ClearOAM

DrawSkills:
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
    ld hl, StrSkillsT
    ld b, 2
    ld c, 1
    call WinPrint
    ld a, [wSkill1]
    ld b, 2
    ld c, 3
    call PutSkillName
    ld a, [wSkill2]
    ld b, 2
    ld c, 5
    call PutSkillName
    ld hl, StrCancel
    ld b, 2
    ld c, 7
    call WinPrint
    ld a, [wCharge1]             ; READY / USED for charge skills
    ld b, 15
    ld c, 3
    ld e, 0
    call PutCharge
    ld a, [wCharge2]
    ld b, 15
    ld c, 5
    ld e, 1
    call PutCharge
    ld hl, StrMP                 ; MP cur / max
    ld b, 2
    ld c, 10
    call WinPrint
    ld hl, wMP
    ld b, 5
    ld c, 10
    call PutWord
    ld a, "/"
    ld b, 10
    ld c, 10
    call WinPutTile
    ld hl, wMaxMP
    ld b, 11
    ld c, 10
    call PutWord
    call SkillCursorDesc
    ret

PutSkillName:                    ; a = skill id at b,c
    dec a
    add a, a
    ld e, a
    ld d, 0
    ld hl, SkillNames
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp WinPrint

PutCharge:                       ; a = charge, e = which skill (0/1)
    push af
    ld a, e
    and a
    ld a, [wSkill1]
    jr z, .s
    ld a, [wSkill2]
.s:
    push af
    call SkillCost
    ld [wTmpCount], a
    pop af
    call SkillKind
    pop de
    and a
    jr z, .charge
    ld hl, StrMP                 ; spell: "MP nn"
    call WinPrint
    ld a, [wTmpCount]
    ld b, 18
    jp WinPutNum2
.charge:
    ld a, d
    and a
    ld hl, StrReady
    jr nz, .p
    ld hl, StrUsed
.p:
    jp WinPrint

SkillCost:                       ; a = skill id -> a = MP cost
    dec a
    ld hl, SkillMPCost
    add a, l
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, [hl]
    ret
SkillMPCost: db 0, 0, 0, 0, 15, 10, 12, 20

SkillKind:                       ; a = skill id -> a = kind (0 charge, 1 MP)
    dec a
    ld hl, SkillKinds
    add a, l
    ld l, a
    jr nc, .nc
    inc h
.nc:
    ld a, [hl]
    ret

SkillCursorDesc:
    ld b, 1
    ld c, 3
    ld d, 3
    ld a, [wSkillCur]
    ld e, a
    ld a, T_CUR
    call DrawListCursor
    ld b, 0                      ; description in the bottom panel
    ld c, 13
    ld d, 20
    ld e, 5
    call DrawBox
    ld a, [wSkillCur]
    cp 2
    ret nc
    and a
    ld a, [wSkill1]
    jr z, .s
    ld a, [wSkill2]
.s:
    dec a
    add a, a
    add a, a
    ld e, a
    ld d, 0
    ld hl, SkillDescs
    add hl, de
    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a
    push hl
    ld h, d
    ld l, e
    ld b, 1
    ld c, 14
    call WinPrint
    pop hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld b, 1
    ld c, 16
    jp WinPrint

MenuSkills:
    ld hl, wSkillCur
    ld b, 3
    call ListNav
    jp c, SkillCursorDesc
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
    cp 2
    jp z, ReturnToPause
    ; can we pay? charge or spell slot
    and a
    ld hl, wCharge1
    ld a, [wSkill1]
    jr z, .s
    ld hl, wCharge2
    ld a, [wSkill2]
.s:
    ld [wTmpSkill], a
    push hl
    call SkillKind
    pop hl
    and a
    jr nz, .mp
    ld a, [hl]                   ; class charge
    and a
    jr z, .none
    push hl
    call .run
    pop bc
    jr c, .msg
    ld a, [bc]
    dec a
    ld [bc], a
    jr .msg
.mp:
    ld a, [wTmpSkill]
    call SkillCost
    ld b, a
    ld a, [wMP + 1]
    and a
    jr nz, .enough
    ld a, [wMP]
    cp b
    jr c, .noMP
.enough:
    call .run
    jr c, .msg
    push hl
    push de
    ld a, [wTmpSkill]
    call SkillCost
    call SpendMP
    pop de
    pop hl
    jr .msg
.noMP:
    ld hl, StrNoMP
    ld de, StrEmpty
    jr .msg
.none:
    ld hl, StrNoUses
    ld de, StrRestHint
.msg:
    ld bc, BackToSkills
    jp ShowPanelMsg
.run:
    ld a, [wTmpSkill]
    dec a
    ld hl, SkillEffects
    jp JumpTableCall

BackToSkills:
    ld a, M_SKILLS
    ld [wMenu], a
    jp DrawSkills

JumpTableCall:                   ; call [hl + a*2]
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

; each effect returns hl/de = message lines; carry set = not used
SkillEffects:
    dw FxSecondWind, FxActionSurge, FxDodge, FxPoison
    dw FxMissile, FxShield, FxCure, FxGuiding

FxSecondWind:
    call HpFullCheck
    ret c
    ld a, 4                      ; 25% of max HP
    call HpFraction
    call HealPlayer
    ld hl, StrSecondWind
    ld de, StrRecovered
    or a
    ret
FxActionSurge:
    ld a, 240
    ld [wSurgeT], a
    call SfxWin
    ld hl, StrSurge1
    ld de, StrSurge2
    or a
    ret
FxDodge:
    ld a, 3
    ld [wDodge], a
    ld hl, StrDodge1
    ld de, StrDodge2
    or a
    ret
FxPoison:
    ld a, 6
    ld [wPoison], a
    ld hl, StrPoison1
    ld de, StrPoison2
    or a
    ret
FxShield:
    ld a, 240
    ld [wShieldT], a
    call SfxPickup
    ld hl, StrShield1
    ld de, StrShield2
    or a
    ret
FxCure:
    call HpFullCheck
    ret c
    ld hl, wFth                  ; FTH*3 + 20 + 1/8 max HP
    call LoadW
    ld a, 3
    call MulHL_A
    ld de, 20
    call AddSat
    push hl
    ld a, 2
    call HpFraction
    pop de
    call AddSat
    call HealPlayer
    ld hl, StrCure1
    ld de, StrRecovered
    or a
    ret
FxMissile:
    call NearestEnemy
    cp $FF
    jr z, NoTarget
    ld [wTmpTarget], a
    xor a
    ld [wWasCrit], a
    ld [wHitKX], a
    ld [wHitKY], a
    ld hl, wMAG                  ; 3 darts: MAG*2, ignores armour
    call LoadW
    add hl, hl
    ld a, [wTmpTarget]
    call DamageSlot
    ld hl, StrMissile1
    ld de, StrMissile2
    or a
    ret
FxGuiding:
    call NearestEnemy
    cp $FF
    jr z, NoTarget
    ld [wTmpTarget], a
    xor a
    ld [wHitKX], a
    ld [wHitKY], a
    ld hl, wMAG                  ; MAG*3 radiant
    call LoadW
    ld a, 3
    call MulHL_A
    ld a, [wTmpTarget]
    call SpellOnSlot
    ld hl, StrGuiding1
    ld de, StrEmpty
    or a
    ret
NoTarget:
    ld hl, StrNoTarget
    ld de, StrEmpty
    scf
    ret

HpFullCheck:                     ; carry + message if HP is already full
    call HpIsFull
    ld hl, StrHpFull
    ld de, StrEmpty
    scf
    ret z
    or a
    ret

StrSkillsT:  db "SKILLS + SPELLS", $FF
StrReady:    db "READY", $FF
StrUsed:     db "USED", $FF
StrNoMP:     db "NOT ENOUGH MP.", $FF
StrSurge1:   db "ACTION SURGE!", $FF
StrSurge2:   db "DOUBLE DICE.", $FF
StrDodge1:   db "YOU READY YOUR", $FF
StrDodge2:   db "GUARD.", $FF
StrPoison1:  db "YOUR BLADE DRIPS", $FF
StrPoison2:  db "WITH POISON.", $FF
StrShield1:  db "A SHIMMERING", $FF
StrShield2:  db "WARD. AC +5!", $FF
StrCure1:    db "CURE WOUNDS!", $FF
StrMissile1: db "MAGIC MISSILE!", $FF
StrMissile2: db "3 DARTS STRIKE.", $FF
StrGuiding1: db "GUIDING BOLT!", $FF
StrNoTarget: db "NO TARGET HERE.", $FF
MsgLoot:     db "LOOT!"
