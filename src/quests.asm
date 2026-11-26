; ============================================================================
;  QUESTS - (phase 3 placeholder)
; ============================================================================
SECTION "Quests", ROMX, BANK[1]
QuestOnKill:
    ret
TalkElder:
TalkGuard:
    ld hl, DlgHello
    ld de, 0
    jp OpenDialog
MenuQuests:
    jp ReturnToPause
DlgHello:
    dw .a, .b
    dw 0
.a: db "WELCOME TO", $FF
.b: db "OAKHOLLOW.", $FF
