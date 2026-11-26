; ============================================================================
;  COMBAT - damage rolls, kills + loot, projectiles (cantrips), class skills
; ============================================================================
SECTION "Combat", ROMX, BANK[1]

; b = 1 (hit) or 2 (critical: dice doubled) -> a = damage vs wCur
PlayerDamageRoll:
    push bc
    ld a, [wDmgN]
    ld c, a
    ld a, b
    cp 2
    ld a, c
    jr nz, .n
    add a, a
.n:
    ld b, a
    ld a, [wSurgeT]              ; Action Surge: twice the dice
    and a
    jr z, .ns
    sla b
.ns:
    ld a, [wDmgS]
    ld c, a
    call RollDice
    ld [wTmpDmg], a
    ld a, [wWpnFlags]            ; Flame Tongue: +2d6 fire
    and 2
    jr z, .nf
    pop bc
    push bc
    ld a, b
    add a, a
    ld b, a
    ld c, 6
    call RollDice
    call .add
.nf:
    ld a, [wClass]               ; Rogue Sneak Attack: +1d6 on a fresh foe
    cp 1
    jr nz, .nsa
    ld a, [wCur + E_TYPE]
    call GetTypeStats
    inc hl
    ld a, [wCur + E_HP]
    cp [hl]
    jr nz, .nsa
    ld c, 6
    call RollDie
    call .add
.nsa:
    ld a, [wPoison]              ; Poison Blade: +1d4
    and a
    jr z, .np
    dec a
    ld [wPoison], a
    ld c, 4
    call RollDie
    call .add
.np:
    ld a, [wTmpDmg]
    ld b, a
    ld a, [wDmgB]
    add a, b
    bit 7, a
    jr nz, .one
    and a
    jr nz, .ok
.one:
    ld a, 1
.ok:
    pop bc
    ret
.add:
    ld b, a
    ld a, [wTmpDmg]
    add a, b
    ld [wTmpDmg], a
    ret

; a = damage to wCur (knockback from wHitKX/KY). handles death, XP, loot
ApplyDamageCur:
    ld b, a
    ld a, [wCur + E_HP]
    sub b
    jr c, .kill
    jr z, .kill
    ld [wCur + E_HP], a
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
    ld a, [wCur + E_TYPE]
    call GetTypeStats
    push hl
    ld de, MS_XP
    add hl, de
    ld a, [hl+]
    ld e, a
    ld d, [hl]
    call AddXP
    pop hl
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

; a = enemy slot, b = damage: apply outside the enemy update loop
DamageSlot:
    push bc
    ld [wTmpSlot], a
    swap a                       ; *16
    ld e, a
    ld d, 0
    ld hl, wEnemies
    add hl, de
    push hl
    ld de, wCur
    ld bc, ENEMY_SIZE
    call Memcpy
    pop hl
    pop bc
    push hl
    ld a, b
    call ApplyDamageCur
    pop de
    ld a, [wGameState]
    cp STATE_WIN
    ret z
    ld hl, wCur
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
    jr c, .off
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
    ld a, [wProjKind]
    cp 2
    ld c, 10                     ; fire bolt 1d10, sacred flame 1d8
    jr nz, .die
    ld c, 8
.die:
    ld b, 1
    jp SpellAttackTarget
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

; spell attack roll vs wTmpTarget: b = dice count, c = sides
SpellAttackTarget:
    push bc
    ld a, [wTmpTarget]
    swap a
    ld e, a
    ld d, 0
    ld hl, wEnemies
    add hl, de
    ld a, [hl]
    call GetTypeStats
    pop bc
    xor a
    ld [wWasCrit], a
    push bc
    ld c, 20
    call RollDie
    pop bc
    cp 1
    jr z, .miss
    cp 20
    jr nz, .roll
    ld a, 1
    ld [wWasCrit], a
    sla b                        ; crit: double dice
    jr .hit
.roll:
    ld d, a
    ld a, [wSpellAtk]
    add a, d
    cp [hl]
    jr c, .miss
.hit:
    call RollDice
    ld b, a
    ld a, [wTmpTarget]
    jp DamageSlot
.miss:
    ld hl, MsgMiss
    call SetMsg
    jp SfxBlock

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
    ld a, [wMaxSlots]            ; SLOTS n/m for casters
    and a
    jr z, .noSlots
    ld hl, StrSlots
    ld b, 2
    ld c, 10
    call WinPrint
    ld a, [wSlots]
    add a, T_DIGIT0
    ld b, 8
    ld c, 10
    call WinPutTile
    ld a, "/"
    inc b
    call WinPutTile
    ld a, [wMaxSlots]
    add a, T_DIGIT0
    inc b
    call WinPutTile
.noSlots:
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
    call SkillKind
    pop de
    and a
    ret nz                       ; spell: shown as slots
    ld a, d
    and a
    ld hl, StrReady
    jr nz, .p
    ld hl, StrUsed
.p:
    jp WinPrint

SkillKind:                       ; a = skill id -> a = kind (0 charge, 1 slot)
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
    jr z, .charge
    ld hl, wSlots
.charge:
    ld a, [hl]
    and a
    jr nz, .pay
    ld hl, StrNoUses
    ld de, StrRestHint
    jr .msg
.pay:
    ld a, l
    ld [wCostPtr], a
    ld a, h
    ld [wCostPtr + 1], a
    ld a, [wTmpSkill]
    dec a
    ld hl, SkillEffects
    call JumpTableCall           ; carry set = could not use (keeps the charge)
    jr c, .msg
    push hl
    ld hl, wCostPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    dec [hl]
    pop hl
.msg:
    ld bc, BackToSkills
    jp ShowPanelMsg

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
    ld c, 10
    call RollDie
    ld b, a
    ld a, [wLevel]
    add a, b
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
    ld c, 8
    call RollDie
    ld b, a
    ld a, [wWIS]
    add a, b
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
    ld b, 3                      ; 3 darts of 1d4+1, auto-hit
    ld c, 4
    call RollDice
    add a, 3
    ld b, a
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
    ld b, 4                      ; 4d6 radiant, spell attack roll
    ld c, 6
    call SpellAttackTarget
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
    ld a, [wMaxHP]
    ld b, a
    ld a, [wHP]
    cp b
    ccf
    ld hl, StrHpFull
    ld de, StrEmpty
    ret

StrSkillsT:  db "SKILLS + SPELLS", $FF
StrReady:    db "READY", $FF
StrUsed:     db "USED", $FF
StrSlots:    db "SLOTS", $FF
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
