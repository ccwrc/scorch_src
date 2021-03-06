;	@com.wudsn.ide.asm.mainsourcefile=program.asm


    .IF *>0
;----------------------------------------
; this module contains routines used in text mode
; like shop and start-up options
;----------------------------------------
;--------------------------------------------------
getkey .proc; waits for pressing a key and returns pressed value in A
;--------------------------------------------------
    pause 5
    lda SKSTAT
    cmp #$ff
    beq lopx01
    cmp #$f7
    bne getkey ; I guess it waits for RELEASING a key
	lda JSTICK0
	and #$0f
	cmp #$0f
	bne getkey ; waits for not moving the joy
	lda TRIG0
	beq getkey ; waits for releasing FIRE


lopx01 lda SKSTAT
    cmp #$ff
    beq checkJoyGetKey ; key not pressed, check Joy
    cmp #$f7
    beq checkJoyGetKey ; key not pressed, check Joy

    lda kbcode
    and #$3f ;CTRL and SHIFT ellimination
    rts
checkJoyGetKey
    ;------------JOY-------------
    ;happy happy joy joy
    ;check for joystick now
    lda JSTICK0
    and #$0f
    cmp #$0f
    beq notpressedJoyGetKey
    tay 
    lda joyToKeyTable,y
    rts
notpressedJoyGetKey
    ;fire
    lda TRIG0
    bne lopx01
    lda #$0c ;Return key
    rts
.endp
;--------------------------------------------------
getkeynowait .proc;
;--------------------------------------------------
    lda SKSTAT
    cmp #$ff
    beq getkeynowait
    cmp #$f7
    beq getkeynowait ; I guess it waits for RELEASING a key
    lda kbcode
    and #$3f ;CTRL and SHIFT ellimination
    rts
.endp
;--------------------------------------------------
Options .proc
;--------------------------------------------------
; start-up screen - options, etc.
; this function returns:
; - number of players (NumberOfPlayers)
; - money each player has on the beginning of the game (moneyL i moneyH)
; - and I am sure maxwind, gravity, ????

    mva #0 OptionsY

OptionsMainLoop

    jsr OptionsInversion
    jsr getkey
    cmp #$f ;cursor down
    bne OptionsNoDown
    inc:lda OptionsY
    cmp #maxoptions
    bne OptionsMainLoop
    mva #3 OptionsY
    jmp OptionsMainLoop

OptionsNoDown
    cmp #$e ;cursor up
    bne OptionsNoUp
    dec OptionsY
    bpl OptionsMainLoop
    mva #0 OptionsY
    jmp OptionsMainLoop

OptionsNoUp
    cmp #$6 ;cursor left
    bne OptionsNoLeft
    ldx OptionsY
    dec OptionsTable,X
    lda OptionsTable,X
    bpl OptionsMainLoop
    inc OptionsTable,X
    jmp OptionsMainLoop

OptionsNoLeft
    cmp #$7 ;cursor right
    bne OptionsNoRight

    ldx OptionsY
    inc OptionsTable,X
    lda OptionsTable,X
    cmp #5
    bne OptionsMainLoop
    dec OptionsTable,X
    jmp OptionsMainLoop

OptionsNoRight
    cmp #$c ;Return key
    bne OptionsNoReturn
    jmp OptionsFinished
OptionsNoReturn
    jmp OptionsMainLoop

OptionsFinished
    ;first option
    ldy OptionsTable
    iny
    iny
    sty NumberOfPlayers ;1=1 player (but minimum is 2)

    ;second option (cash)


    ldy OptionsTable+1
    ldx #0
skip10
    lda CashOptionL,y
    sta moneyL,x
    lda CashOptionH,y
    sta moneyH,x
    inx
    cpx NumberOfPlayers
    bne skip10

    ;third option (gravity)
    ldy OptionsTable+2
    lda GravityTable,y
    sta gravity

    ;fourth option (wind)

    ldy OptionsTable+3
    lda MaxWindTable,y
    sta MaxWind
    rts
;--------
; inversing choosed option (cursor)
;--------
OptionsInversion
    mwa #OptionsHere temp
    ldy #0
OptionsInversionLoop1
    lda (temp),y
    and #$7F
    sta (temp),y
    adw temp #1
    cpw temp #OptionsScreenEnd
    bne OptionsInversionLoop1
;here all past inversions are gone...

    mwa #OptionsHere temp
    mva #0 temp2  ;option number pointer
    adw temp  #11 ;offset of the first option=11
OptionsSetMainLoop
    ldx temp2
    lda OptionsTable,x
    asl
    asl
    adc OptionsTable,x  ;OptionsTable value * 5
    tay
    ldx #4
OptionSetLoop
    lda (temp),y
    ora #$80
    sta (temp),y
    iny
    dex
    bpl OptionSetLoop ;here option is highlighted
;
; next option
    adw temp  #40 ;jump to next line
    inc:lda temp2
    cmp #4 ;number of options
    bne OptionsSetMainLoop

;inversing the first few chars of the selected line (OptionsY)
    mva OptionsY temp
    mwa #0 temp+1
    asl temp
    rol temp+1
    asl temp
    rol temp+1
    asl temp
    rol temp+1
    mwa temp temp2 ;here is OptionsY*8
    asl temp
    rol temp+1
    asl temp
    rol temp+1
    ;here is 32*OptionsY
    adw temp  temp2
    ;in temp is 40*OptionsY
    adw temp #OptionsHere
    ;now in temp is adres of the line to be inversed
    ldy #7 ;8 letters to invers
OptionsYLoop
    lda (temp),y
    ora #$80
    sta (temp),y
    dey
    bpl OptionsYLoop


    rts
.endp

;-------------------------------------------
; call of the purchase screens for each tank
CallPurchaseForEveryTank
    mva #$2 colpf2s   ; set normal color
    mwa #PurchaseDL dlptrs
    lda dmactls
    and #$fc
    ora #$02     ; normal screen width
    sta dmactls

    mva #0 TankNr
loop03
    ldx TankNr
    lda SkillTable,x
    beq ManualPurchase
    jsr PurchaseAI
    jmp AfterManualPurchase

ManualPurchase
    jsr Purchase
AfterManualPurchase

    inc TankNr
    lda TankNr
    cmp NumberOfPlayers
    bne loop03
    rts

;--------------------------------------------------
Purchase ;
;--------------------------------------------------
; In tanknr there is a number of the tank (player)
; that is buying weapons now (from 0).
; Rest of the data is taken from appropriate tables
; and during the purchase these tables are modified.


    mwa #ListOfWeapons WeaponsListDL ;switch to the list of offensive weapons
    jsr PMoutofScreen

; we are clearing list of the weapons
    mva #$ff LastWeapon
    mva #$00 WhichList
    ; offensive weapon - 0, deffensive - 1

    ; there is a tank (player) number in tanknr
    ; we are displaying name of the player

    tay  ; from 0 to y
    lda tanknr
    asl
    asl
    asl ; 8 chars per name
    tax
NextChar03
    lda tanksnames,x
    sta textbuffer2+8,y
    inx
    iny
    cpy #$08
    bne NextChar03
    ; and we display cash of the given player

; here we must jump in after each purchase
; to generate again list of available weapons
AfterPurchase
    ldx tanknr
    lda moneyL,x
    sta decimal
    lda moneyH,x
    sta decimal+1
    mwa #textbuffer2+29 displayposition
    jsr displaydec

    ; in xbyte there is the address of the line that
    ; is being processed now
    mwa #ListOfWeapons xbyte
    ldx #$00  ; number of the checked weapon
    stx HowManyOnTheList1 ; amounts of weapons (shells, bullets) in both lists
    stx HowManyOnTheList2
    stx PositionOnTheList

; Creating full list of the available weapons for displaying
; in X there is a number of the weapon to be checked,
; in 'Xbyte' address of the first char in filled screen line

CreateList
    ; checking if the weapon of the given number is present
    lda WeaponUnits,x
    jeq NoWeapon
    ; checking if we can afford buying this weapon
    ldy tanknr
    lda moneyH,y
    cmp WeaponPriceH,x
    bne CheckWeapon01
    lda moneyL,y
    cmp WeaponPriceL,x
CheckWeapon01
    jcc TooLittleCash

    ; we have enough cash and the weapon can be
    ; added to the list
    stx temp ; number of weapon will be necessary later

    ; first parentheses and other special chars
    ; (it's easier this way)
    ldy #22
    lda #08 ; "("
    STA (XBYTE),y
    ldy #32
    lda #09 ; ")"
    sta (xbyte),y
    ldy #25
    lda #15 ; "/"
    sta (xbyte),y
    iny
    lda #04 ; "$"
    sta (xbyte),y
    ldy #31
    lda #16 ; "0"
    sta (xbyte),y

    ; now symbol of the weapon
    lda WeaponSymbols,x
    ldy #$4  ; 4 chars from the beginning of the line
    sta (xbyte),y

    ;now number of purchased units (bullets)
    clc
    lda xbyte
    adc #23  ; 23 chars from the beginning of the line
    sta displayposition
    lda xbyte+1
    adc #$00
    sta displayposition+1
    lda WeaponUnits,x
    sta decimal
    jsr displaybyte
    ldx temp ;getting back number of the weapon

    ; and now price of the weapon
    clc
    lda xbyte
    adc #27  ; 27 chars from the beginning of the line
    sta displayposition
    lda xbyte+1
    adc #$00
    sta displayposition+1
    lda WeaponPriceL,x
    sta decimal
    lda WeaponPriceH,x
    sta decimal+1
    jsr displaydec

    lda temp ;getting back number of the weapon
    pha  ;and saving it on the stack

    jsr HowManyBullets
    sta decimal

    pla
    sta temp ; let's store weapon number again

    clc
    lda xbyte
    adc #1  ; 1 char from the beginning of the screen
    sta displayposition
    lda xbyte+1
    adc #$00
    sta displayposition+1
    jsr displaybyte

    ; and now name of the weapon and finisheeeedd !!!!
    ldx temp ;weapon number
    mva #0 temp+1  ; this number is only in X
    ; times 16 (it's length of the names of weapons)
    ldy #3 ; Rotate 4 times
Rotate02
    asl temp
    rol temp+1
    dey
    bpl Rotate02
    ; Hmmm..... Interesting why there is no CLC here?

    adw temp #NamesOfWeapons modify
    sbw modify  #6 ; from 6th char

    ldy #6 ; from 6th char

modyf1
    lda (modify),y
    sta (xbyte),y
    iny
    cpy #(16+6)
    bne modyf1


    ; in X there is what we need

    ; If on screen after the purchase there is still
    ; present the weapon purchased recently,
    ; the pointer must point to it.

    cpx LastWeapon
    bne NotTheSameAsLastTime
    lda WhichList
    bne ominx06
    lda HowManyOnTheList1
    sta PositionOnTheList
    jmp NotTheSameAsLastTime
ominx06
    lda HowManyOnTheList2
    sta PositionOnTheList
NotTheSameAsLastTime
    ; increase appropriate counter
    txa
    cpx #$30
    bcs SecondList
    ldy HowManyOnTheList1
    sta NubersOfWeaponsL1,y
    inc HowManyOnTheList1
    bne NextLineOfTheList
SecondList
    ldy HowManyOnTheList2
    sta NubersOfWeaponsL2,y
    inc HowManyOnTheList2
    ; If everything is copied then next line
NextLineOfTheList
    clc
    lda xbyte
    adc #40
    sta xbyte
    bcc TooLittleCash
    inc xbyte+1
TooLittleCash
NoWeapon

    ; next weapon. If no more weapons then finish!
    inx
    cpx #$30
    bne NoDefense

; if we got to the defense weapons,
; we switch address to the second table.
    mwa #ListOfDefensiveWeapons xbyte
NoDefense
    cpx #$40
    jne CreateList

    ; offset may be only too big
    ; (because after purchase list will never be longer)
    ; check it and modify if necessary.
    ; If offset is larger than position of the pointer,
    ; it must be equal.
    lda PositionOnTheList
    cmp OffsetDL1
    bcs WeHaveOffset ; do not modify offset
    sta OffsetDL1
WeHaveOffset

    ; now we have to erase empty position of both lists.

    ; Multiply number on list 1 by 40 and set address
    ; of the first erased char.
    ; (multiplying taken from book of Ruszczyc 'Assembler 6502'

    lda HowManyOnTheList1
    sta xbyte+1 ; multiplier (temporarily here, it will be erased anyway)
    lda #$00 ; higher byte of the Result
    sta xbyte ; lower byte of the Result
    ldx #$08
Rotate04
    lsr xbyte+1
    bcc DoNotAddX01
    clc
    adc #40
DoNotAddX01
    ror
    ror xbyte
    dex
    bne Rotate04
    sta xbyte+1

    ; add to the address of the list
    clc
    lda xbyte
    adc #<ListOfWeapons
    tay
    lda xbyte+1
    adc #>ListOfWeapons
    sta xbyte+1
    stx xbyte
    txa ; now there is zero here
ClearList1
    sta (xbyte),y
    iny
    bne DoNotIncHigher1
    inc xbyte+1
DoNotIncHigher1
    cpy #<ListOfWeapons1End
    bne ClearList1
    ldx xbyte+1
    cpx #>ListOfWeapons1End
    bne ClearList1

    ; And the same we do with the second list

    ; Multiply number on list 1 by 40 and set address
    ; of the first erased char.
    lda HowManyOnTheList2
    sta xbyte+1 ; multiplier
    lda #$00 ; higher byte of the Result
    sta xbyte ; lower byte of the Result
    ldx #$08
Rotate05
    lsr xbyte+1
    bcc DoNotAddX02
    clc
    adc #40
DoNotAddX02
    ror
    ror xbyte
    dex
    bne Rotate05
    sta xbyte+1

    ; add to the address of the list
    clc
    lda xbyte
    adc #<ListOfDefensiveWeapons
    tay
    lda xbyte+1
    adc #>ListOfDefensiveWeapons
    sta xbyte+1
    stx xbyte
    txa ; now there is zero here
ClearList2
    sta (xbyte),y
    iny
    bne DoNotIncHigher2
    inc xbyte+1
DoNotIncHigher2
    cpy #<ListOfDefensiveWeaponsEnd
    bne ClearList2
    ldx xbyte+1
    cpx #>ListOfDefensiveWeaponsEnd
    bne ClearList2

; here we have pretty cool lists and there is no brute force
; screen clearing at each list refresh
; (it was very ugly - I checked it :)


; Here we have all we need
; So choose the weapon for purchase ......
;--------------------------------------------------
ChoosingItemForPurchase
;--------------------------------------------------
    jsr PutLitteChar ; Places pointer at the right position
    jsr getkey
    cmp #$2c ; Tab
    jeq ListChange
    cmp #$0c ; Return
    beq EndOfPurchase
    cmp #$e
    beq PurchaseKeyUp
    cmp #$f
    beq PurchaseKeyDown
    cmp #$21 ; Space
    bne ChoosingItemForPurchase
    jmp PurchaseWeaponNow
EndOfPurchase
    rts
PurchaseKeyUp
    lda WhichList
    beq GoUp1
    dec PositionOnTheList
    bpl EndUpX
    lda #$00
    sta PositionOnTheList
    jmp ChoosingItemForPurchase
GoUp1
    dec PositionOnTheList
    bpl MakeOffsetUp
    lda #$00
    sta PositionOnTheList

MakeOffsetUp
    ; If offset is larger than pointer position,
    ; it must be equal then.
    lda PositionOnTheList
    cmp OffsetDL1
    bcs EndUpX ; do not modify the offset
    sta OffsetDL1
EndUpX
    jmp ChoosingItemForPurchase
PurchaseKeyDown
    lda WhichList
    beq GoDown1
    inc PositionOnTheList
    lda PositionOnTheList
    cmp HowManyOnTheList2
    bne EndGoDownX
    ldy HowManyOnTheList2
    dey
    sty PositionOnTheList
    jmp ChoosingItemForPurchase
GoDown1
    inc PositionOnTheList
    lda PositionOnTheList
    cmp HowManyOnTheList1
    bne MakeOffsetDown
    ldy HowManyOnTheList1
    dey
    sty PositionOnTheList
MakeOffsetDown
    lda OffsetDL1
    clc
    adc #15
    ;if offset+16 is lower than the position then it must =16
    cmp PositionOnTheList
    bcs EndGoDownX
    sec
    lda PositionOnTheList
    sbc #15
    sta OffsetDL1
EndGoDownX
    jmp ChoosingItemForPurchase

; swapping the displayed list and setting pointer to position 0
ListChange
    lda WhichList
    eor #$01
    sta WhichList
    bne SecondSelected
    mwa #ListOfWeapons WeaponsListDL
    jmp dalejx01
SecondSelected
    mwa #ListOfDefensiveWeapons WeaponsListDL
dalejx01
    lda #$00
    sta PositionOnTheList
    sta OffsetDL1
    jmp ChoosingItemForPurchase

; weapon purchase routne increases number of possessed bullets
; decreases cash and jumps to screen refresh
;--------------------------------------------------
PurchaseWeaponNow
;--------------------------------------------------
    lda WhichList
    bne PurchaseDeffensive

    ; here we purchase the offensive weapon
    ldy PositionOnTheList
    lda NubersOfWeaponsL1,y
    jmp PurchaseAll
PurchaseDeffensive
    ldy PositionOnTheList
    lda NubersOfWeaponsL2,y
PurchaseAll
    ; after getting weapon number the routine is common for all
    ldx tanknr
    tay  ; weapon number is in Y
    sec
    lda moneyL,x ; substracting from posessed money
    sbc WeaponPriceL,y ; of price of the given weapon
    sta moneyL,x
    lda moneyH,x
    sbc WeaponPriceH,y
    sta moneyH,x
    ; now we have get address of
    ; the table of the weapon of the tank
    ; and add appropriate number of bullets
    stx temp ;we will multiply by 64
    mva #0 temp+1
    ; times 64
    ; (because it is the lenght of one record in weapon table)
    ldx #5 ; Rotate 6 times
    ; (in Y there is a weapon number, we do not touch it!!!)
Rotate03
    asl temp
    rol temp+1
    dex
    bpl Rotate03
    lda #<TanksWeapon1
    adc temp
    sta temp
    lda #>TanksWeapon1
    adc temp+1
    sta temp+1

    lda (temp),y  ; and we have number of posessed bullets of the weapon
    adc WeaponUnits,y
    sta (temp),y ; and we added appropriate number of bullets
    cmp #100 ; but there should be no more than 99 bullets
    bcc LessThan100
    lda #99
    sta (temp),y
LessThan100
    sty LastWeapon ; store last purchased weapon
    ; because we must put screen pointer next to it
    jmp AfterPurchase


PutLitteChar
    ; first let's cleat both lists from little chars
    mwa #ListOfWeapons xbyte
    ldx #52 ; there are 52 lines total
    ldy #$00
EraseLoop
    lda #$00
    sta (xbyte),y
    clc
    lda xbyte
    adc #40
    sta xbyte
    bcc ominx02
    inc xbyte+1
ominx02
    dex
    bpl EraseLoop
    ; now let's check which list is active now
    lda WhichList
    beq CharToList1
    ; we are on the second list (deffensive)
    ; so there is no problem with scrolling
    mwa #ListOfDefensiveWeapons xbyte
    ldx PositionOnTheList
    beq SelectList2 ; if there is 0 we add nothing
AddLoop2
    clc
    lda xbyte
    adc #40
    sta xbyte
    bcc ominx03
    inc xbyte+1
ominx03
    dex
    bne AddLoop2
SelectList2
    lda #$7f ; little char (tab) - this is the pointer
    sta (xbyte),y
    ; now we clear flags of presence of list "out of screen"
    ; unfortunately I am now sure what it means... :(
    ldx #<EmptyLine
    ldy #>EmptyLine
    stx MoreUpdl
    sty MoreUpdl+1
    stx MoreDowndl
    sty MoreDowndl+1
    rts
CharToList1
    ; we putchar on list 1
    ; and later set-up list itself
    mwa #ListOfWeapons xbyte
    ldx PositionOnTheList
    beq SelectList1 ; if there is 0 we add nothing
AddLoop1
    clc
    lda xbyte
    adc #40
    sta xbyte
    bcc ominx04
    inc xbyte+1
ominx04
    dex
    bne AddLoop1
SelectList1
    lda #$7f ; pointer = little char = (tab)
    sta (xbyte),y
    ; now moving the window basing on given offset
    mwa #ListOfWeapons xbyte
    ldx OffsetDL1
    beq SetWindowList1 ; if zero then add nothing
LoopWindow1
    clc
    lda xbyte
    adc #40
    sta xbyte
    bcc ominx05
    inc xbyte+1
ominx05
    dex
    bne LoopWindow1
SetWindowList1
    mwa xbyte WeaponsListDL  ; and we change Display List

    ; we show screen line with arrows meaning that
    ; you can scroll the list up
    ldx #<EmptyLine
    ldy #>EmptyLine
    lda OffsetDL1
    beq NoArrowUp
    ldx #<MoreUp
    ldy #>MoreUp
NoArrowUp
    stx MoreUpdl
    sty MoreUpdl+1
    ; the same, bu scrolling down
    lda HowManyOnTheList1
    ldx #<EmptyLine
    ldy #>EmptyLine
    sec
    sbc #17
    bmi NoArrowDown
    cmp OffsetDL1
    bcc NoArrowDown
    ldx #<MoreDown
    ldy #>MoreDown
NoArrowDown
    stx MoreDowndl
    sty MoreDowndl+1
    rts

; -----------------------------------------------------
EnterPlayerName
; in: TankNr
; Out: TanksNames, SkillTable

; this little thing is for choosing Player's skill (if computer)
; and entering his name
; If no name entered, there should be name "1st Tank", etc.
; Default tanks names are in table TanksNamesDefault
; -----------------------------------------------------

    jsr PMoutofScreen
    ; display tank number
    ldx tanknr
    inx
    stx decimal
    mwa #(NameScreen+41) displayposition
    jsr displaybyte
    jsr SelectLevel ; setting choosen level of the opponent (Moron, etc)
    ; clear the name and place cursor at position 0
    lda #0
    sta PositionInName
    ldx #$08 ; one more because cursor could be there
LoopName01
    sta NameAdr,x
    dex
    bne LoopName01
    lda #$80 ; place cursor on the beginning
    sta NameAdr
CheckKeys
    jsr getkey
    ; is if the char to be recorded?
    ldx #37 ; table is 38 chars long
IsLetter
    cmp keycodes,x
    beq YesLetter
    dex
    bpl IsLetter
    bmi CheckFurtherX01 ; if not in the table
    ; we check cursors and (Return)
YesLetter
    lda scrcodes,x ; we have screen code of the char
    ldx PositionInName
    bne NotFirstLetter
    and #$3f ; First letter should be Capital letter
    ; (nice trick does not affect digits)
NotFirstLetter
    sta NameAdr,x
    inx
    lda #$80 ; cursor behind the char
    sta NameAdr,x
    cpx #$08 ; is there 8 characters?
    beq CheckKeys  ; if so, nothing increased
    stx PositionInName ; if not, we store
    ; position incremented by 1

    jmp CheckKeys
CheckFurtherX01 ; here we check Tab, Return and Del
    cmp #$0c ; Return
    beq EndOfNick
    cmp #$2c ; Tab
    beq ChangeOfLevelUp
    cmp #$7 ;cursor right
    beq ChangeOfLevelUp
    cmp #$6 ;cursor left
    beq ChangeOfLevelDown
    cmp #$f ;cursor down
    beq ChangeOfLevel3Up

    cmp #$34 ; Backspace (del)
    bne CheckKeys
    ; handling backing one char
    ldx PositionInName
    beq FirstChar
    dex
FirstChar
    lda #$80
    sta NameAdr,x
    lda #$00
    sta NameAdr+1,x
    sta NameAdr+2,x
    stx PositionInName
    jmp CheckKeys
ChangeOfLevelUp ; change difficulty level of computer opponent
    inc:lda DifficultyLevel
    cmp #9  ; 9 levels are possible
    bne DoNotLoopLevelUp
    mva #$0 DifficultyLevel
DoNotLoopLevelUp
    jsr SelectLevel
    jmp CheckKeys
;----
ChangeOfLevelDown
    dec:lda DifficultyLevel
    bpl DoNotLoopLevelDown
    mva #$8 DifficultyLevel
DoNotLoopLevelDown
    jsr SelectLevel
    jmp CheckKeys
;----
ChangeOfLevel3Up
    ;adw DifficultyLevel #3
    clc
    lda DifficultyLevel
    adc #3
    sta DifficultyLevel

    cmp #9
    bcc DoNotLoopLevel3Up

    sbw DifficultyLevel #9

DoNotLoopLevel3Up
    jsr SelectLevel
    jmp CheckKeys
;----
EndOfNick
    ; storing name of the player and its level

    ; level of the computer opponent goes to
    ; the table of levels (difficulties)
    ldx tanknr
    lda DifficultyLevel
    sta skilltable,x
    ; storing name of the tank in the right space
    ; (without cursor!)
    ldy #$00
    txa    ; ldx TankNr
    asl
    asl
    asl ; 8 chars per name
    tax  ; in X where to put new name

    lda NameAdr ; check if first char is " "
    and #$7F  ; remove inverse (Cursor)
    beq MakeDefaultName

nextchar04
    lda NameAdr,y
    and #$7f ; remove inverse (Cursor)
    sta tanksnames,x
    inx
    iny
    cpy #$08
    bne nextchar04
    rts
MakeDefaultName
nextchar05
    lda tanksnamesDefault,x
    sta tanksnames,x
    inx
    iny
    cpy #$08
    bne nextchar05
    rts




SelectLevel
    ; this routine highlights the choosen
    ; level of the computer opponent
    ldx #$9 ; 9 possible levels
CheckNextLevel01
    lda LevelNameBeginL,x ; address on the screen
    sta temp
    lda LevelNameBeginH,x
    sta temp+1
    ldy #9 ; flip 10 chars to inverse video
    cpx DifficultyLevel ; is it the choosen level?
    bne NotThisLevel
    ; change to inverse, because it is it!
InverseFurther
    lda (temp),y
    ora #$80
    sta (temp),y
    dey
    bpl InverseFurther
    bmi CheckNextLevel ; Check Next Level
NotThisLevel
    lda (temp),y
    and #$7f
    sta (temp),y
    dey
    bpl NotThisLevel
CheckNextLevel
    dex
    bpl CheckNextLevel01
    rts
;--------------------------------------------------
displaydec ;decimal (word), displayposition  (word)
;--------------------------------------------------
; displays decimal number as in parameters (in text mode)
; leading zeores are removed
; the range is (0000..9999 - two bytes)

    ldy #3  ; there will be 4 digits
NextDigit
    ldx #16 ; 16-bit dividee so Rotate 16 times
    lda #$00
Rotate000
    aslw decimal
    rol  ; scroll dividee
    ; (as highest byte - additional - byte is A)
    cmp #10  ; divider
    bcc TooLittle000 ; if A is smaller than divider
    ; there is nothing to substract
    sbc #10  ; divider
    inc decimal     ; lowest bit set to 1
    ; because it is 0 and this is the fastest way
TooLittle000 dex
    bne Rotate000 ; and Rotate 16 times, Result will be in decimal
    tax  ; and the rest in A
    ; (and it goes to X because
    ; it is our decimal digit)
    lda digits,x
    sta decimalresult,y
    dey
    bpl NextDigit ; Result again /10 and we have next digit


rightnumber
; now cut leading zeroes (002 goes   2)
    lda decimalresult
    cmp zero
    bne decimalend
    lda space
    sta decimalresult

    lda decimalresult+1
    cmp zero
    bne decimalend
    lda space
    sta decimalresult+1

    lda decimalresult+2
    cmp zero
    bne DecimalEnd
    lda space
    sta decimalresult+2

DecimalEnd
    ; displaying
    mwa displayposition modify
    ldy #3
displayloop
    lda decimalresult,y
    sta (modify),y
    dey
    bpl displayloop

    rts


;--------------------------------------------------
displaybyte ;decimal (byte), displayposition  (word)
;--------------------------------------------------
; displays decimal number as in parameters (in text mode)
; leading zeores are removed
; the range is (00..99 - one byte)

    ldy #1 ; there will be 2 digits
NextDigit2
    ldx #8 ; 8-bit dividee so Rotate 8 times
    lda #$00
Rotate001
    asl decimal
    rol  ; scroll dividee
    ; (as highest byte - additional - byte is A)
    cmp #10  ; divider
    bcc TooLittle001 ; if A is smaller than divider
    ; there is nothing to substract
    sbc #10  ; divider
    inc decimal     ; because it is 0 and this is the fastest way
TooLittle001 dex
    bne Rotate001 ; and Rotate 8 times, Result will be in decimal
    tax  ; and the rest in A
    ; (and it goes to X because
    ; it is our decimal digit)
    lda digits,x
    sta decimalresult,y
    dey
    bpl NextDigit2 ; Result again /10 and we have next digit

; now cut leading zeroes (02 goes   2)
    lda decimalresult
    cmp zero
    bne decimalend1
    lda space
    sta decimalresult

decimalend1
    ; displaying
    mwa displayposition modify
    ldy #1
displayloop1
    lda decimalresult,y
    sta (modify),y
    dey
    bpl displayloop1

    rts
;-------decimal constans
digits   dta d"0123456789"
zero     dta d"0"
nineplus ;.sbyte ('9+1)
    dta d"9"+1
space    dta d" "

;--------------------------------------------------------
DisplayOffensiveTextNr ;
    ;This routine displays texts using PutChar4x4
    ;pretty cool, eh
    ;parameters are:
    ;Y - number of tank above which text is displayed
    ;TextNumber - number of offensive text to display

    ;lets calculate position of the text first!
    ;that's easy because we have number of tank
    ;and xtankstableL and H keep X position of a given tank

    lda xtankstableL,y
    sta temp
    lda xtankstableH,y
    sta temp+1
    ;now we should substract length of the text
    ldx TextNumberOff
    lda talk.OffensiveTextLengths,x
    asl
    sta temp2
    mva #0 temp2+1
    ;here we assume max length of text
    ;to display is 127 chars!

    ;now we have HALF length in pixels
    ;stored in temp2
    sbw temp  temp2 ; here begin of the text is in TEMP !!!!
    ;now we should check overflows
    lda temp+1
    bpl DOTNnotLessThanZero
    ;less than zero, so should be zero
    mwa #0 temp
    beq DOTNnoOverflow

DOTNnotLessThanZero
    ;so check if end larger than screenwidth


    lda talk.OffensiveTextLengths,x
    asl
    asl
    ;length in pixels -
    ;text length max 63 chars !!!!!!!!


    clc
    adc temp
    sta temp2
    lda #0
    adc temp+1
    sta temp2+1
    ;now in temp2 is end of the text in pixels
    ;so check if not greater than screenwitdth
    cpw temp2 #screenwidth
    bcc DOTNnoOverflow
    ;if end is greater than screenwidth
    ;then screenwidth - length is fine


    lda talk.OffensiveTextLengths,x
    asl
    asl
    sta temp

    sec
    lda #<(screenwidth-1)
    sbc temp
    sta temp
    lda #>(screenwidth-1)
    sbc temp+1
    sta temp+1
DOTNnoOverflow
    ;here in temp we have really good x position of text

    mwa temp TextPositionX

    ;now let's get y position
    ;we will try to put text as low as possible
    ;just above mountains (so mountaintable will be checked)
    lda talk.OffensiveTextLengths,x
    asl
    asl
    tay
    ;in temp there still is X position of text
    ;if we add temp and Y we will get end of the text
    ;so, lets go through mountaintable and look for
    ;the lowest value within
    ;Mountaitable+temp and Mountaitable+temp+Y

    adw temp #MountainTable

    mva #screenheight temp2 ;initialisation of the lowest value

DOTLowestMountainValueLoop
    lda (temp),y
    cmp temp2
    bcs DOTOldLowestValue  ;old lowest value
    ;new lowest value
    sta temp2
DOTOldLowestValue
    dey
    cpy #$ff
    bne DOTLowestMountainValueLoop



    sec
    lda temp2
    sbc #(4+9) ;9 pixels above ground (and tanks...)
    sta TextPositionY


    lda talk.OffensiveTextTableL,x
    sta TextAddress
    lda talk.OffensiveTextTableH,x
    sta TextAddress+1
    mva #0 TextCounter
DOTNcharloop
    mwa TextAddress temp
    ldy TextCounter

    lda (temp),y
    SEC
    sbc #32 ;conversion from ASCII to .sbyte

    sta CharCode4x4
    lda TextCounter
    asl
    asl
    clc
    adc TextPositionX
    sta Xdraw
    lda #0
    adc TextPositionX+1
    sta Xdraw+1
    lda TextPositionY
    sta ydraw
    jsr PutChar4x4

    inc TextCounter
    ldx TextNumberOff
    lda talk.OffensiveTextLengths,x
    cmp TextCounter
    bne DOTNcharloop

    rts

;-------------------------------
TypeLine4x4 ;
;-------------------------------
    ;this routine prints line ending with $ff
    ;address in LineAddress4x4
    ;starting from LineXdraw, LineYdraw

    ldy #0
    sty LineCharNr


TypeLine4x4Loop
    ldy LineCharNr


    mwa LineAddress4x4 temp
    lda (temp),y
    cmp #$ff
    beq EndOfTypeLine4x4

    sta CharCode4x4
    mwa LineXdraw Xdraw
    mva LineYdraw Ydraw
    jsr PutChar4x4FULL ;type empty pixels as well!
    adw LineXdraw #4
    inc LineCharNr
    jmp TypeLine4x4Loop

EndOfTypeLine4x4
    rts

;--------------------------------
DisplayResults ;
;displays results of the round
;using 4x4 font

    ;centering the result screen
    mwa #((ScreenWidth/2)-(7*4)) ResultX
    mva #((ScreenHeight/2)-(8*4)) ResultY


    ;upper frame
    mwa #LineTop LineAddress4x4
    mwa ResultX LineXdraw
    mva ResultY LineYdraw
    mva #1 plot4x4color
    jsr TypeLine4x4

    adw ResultY  #4 ;next line

    ;Header1
    ;Displays round number
    lda CurrentRoundNr
    sta decimal
    mwa #RoundNrDisplay displayposition
    jsr displaybyte ;decimal (byte), displayposition  (word)

    mwa #LineHeader1 LineAddress4x4
    mwa ResultX LineXdraw
    mva ResultY LineYdraw
    mva #1 plot4x4color
    jsr TypeLine4x4

    adw ResultY  #4 ;next line

    ;Empty line
    mwa #LineEmpty LineAddress4x4
    mwa ResultX LineXdraw
    mva ResultY LineYdraw
    mva #1 plot4x4color
    jsr TypeLine4x4

    adw ResultY  #2 ;next line


    ;Header2
    mwa #LineHeader2 LineAddress4x4
    mwa ResultX LineXdraw
    mva ResultY LineYdraw
    mva #1 plot4x4color
    jsr TypeLine4x4

    adw ResultY  #4 ;next line

    ;Empty line
    mwa #LineEmpty LineAddress4x4
    mwa ResultX LineXdraw
    mva ResultY LineYdraw
    mva #1 plot4x4color
    jsr TypeLine4x4

    sbw ResultY  #2 ;next line (was empty)

    ldx NumberOfPlayers  ;we start from the highest (best) tank
    dex   ;and it is the last one
    stx ResultOfTankNr  ;in TankSequence table

    mwa #TanksNames tempXROLLER

ResultOfTheNextPlayer
    ldx ResultOfTankNr ;we are after a round, so we can use TankNr
    lda TankSequence,x ;and we keep here real number if the tank
    sta TankNr   ;for which we are displaying results




    adw ResultY  #4 ;next line

    ;there are at least 2 players, so we can safely
    ;start displaying the result

    ldx #0
    lda #3 ;it means |
    sta ResultLineBuffer,x


    lda TankNr
    asl
    asl ; times 8, because it is lengtgh
    asl ; of the names of the tanks
    tay

TankNameCopyLoop
    lda (tempXROLLER),y  ;XROLLER is not working now
    and #$3f ;always CAPITAL letters
    inx
    sta ResultLineBuffer,x
    iny
    cpx #8 ; end of name
    bne TankNameCopyLoop

    inx
    lda #26 ;it means ":"
    sta ResultLineBuffer,x

    ldy TankNr
    lda ResultsTable,y
    sta decimal
    mwa #(ResultLineBuffer+10) displayposition
    jsr displaybyte ;decimal (byte), displayposition  (word)

    ldx #12 ;justafter the digits
    lda #3 ;it means |
    sta ResultLineBuffer,x

    inx
    lda #$ff ;it means end of line
    sta ResultLineBuffer,x



    ;result line display
    mwa #ResultLineBuffer LineAddress4x4
    mwa ResultX LineXdraw
    mva ResultY LineYdraw
    mva #1 plot4x4color
    jsr TypeLine4x4

    adw ResultY  #4 ;next line

    ;Empty line
    mwa #LineEmpty LineAddress4x4
    mwa ResultX LineXdraw
    mva ResultY LineYdraw
    mva #1 plot4x4color
    jsr TypeLine4x4



    dec ResultOfTankNr

    bmi FinishResultDisplay

    sbw ResultY  #2 ;distance between lines is smaller

    jmp ResultOfTheNextPlayer

FinishResultDisplay

    ;bottom of the frame
    mwa #LineBottom LineAddress4x4
    mwa ResultX LineXdraw
    mva ResultY LineYdraw
    mva #1 plot4x4color
    jsr TypeLine4x4
    rts


;-------------------------------------------------
DisplayingSymbols
;-------------------------------------------------

    ;---------------------
    ;displaying symbol of the weapon
    ;---------------------
    ;display name and symbol of the weapon
    ;textbuffer+18  - symbol (1 char)
    ;textbuffer+20  - quantity left
    ;textbuffer+23  - name



    ;ldx TankNr
    ldy ActiveWeapon,x
    lda WeaponSymbols,y
    sta TextBuffer+18

    ;---------------------
    ;displaying the energy of a tank
    ;---------------------

    lda Energy,x

    sta decimal
    mwa #textbuffer+40 displayposition
    jsr displaybyte
    ;---------------------
    ;displaying quantity of the given weapon
    ;---------------------
    ldx TankNr
    lda ActiveWeapon,x
    jsr HowManyBullets
    sta decimal
    mwa #textbuffer+20 displayposition
    jsr displaybyte

    ;---------------------
    ;displaying name of the weapon
    ;---------------------
    ldx TankNr
    lda ActiveWeapon,x
    sta temp ;get back number of the weapon
    mva #0 temp+1
    ; times 16 (because this is length of weapon name)
    ldy #3 ; rotate 4 times
RotateDISP02
    aslw temp
    dey
    bpl RotateDISP02
    adw temp #NamesOfWeapons
    ldy #6 ; from 6th character

    ldy #15
loop06
    lda (temp),y
    sta textbuffer+23,y
    dey
    bpl loop06

    ;=========================
    ;display Force
    ;=========================
    ldx TankNr
    lda EnergyTableL,x
    sta decimal
    lda EnergyTableH,x
    sta decimal+1
    mwa #textbuffer+63 displayposition
    jsr displaydec

    ;=========================
    ;display Angle
    ;=========================
    ; additionally we are getting charcode of the tank
    ; (for future display)
    ldx TankNr
    lda AngleTable,x
    bmi AngleToLeft
    lda #$7f  ; (tab) character
    sta textbuffer+52
    lda #0  ;space
    sta textbuffer+49
    lda #90
    sec
    sbc AngleTable,x
    sta decimal
    tay
    lda BarrelTableR,y
    sta CharCode
    jmp AngleDisplay ;like jp, because code always <>0
AngleToLeft
    sec
    sbc #(255-90)
    sta decimal
    tay
    lda BarrelTableL,y
    sta CharCode
    lda #$7e  ;(del) char
    sta textbuffer+49
    lda #0 ;space
    sta textbuffer+52

AngleDisplay
    mwa #textbuffer+50 displayposition
    jsr displaybyte


    ;=========================
    ;display Wind
    ;=========================
    lda WindOrientation
    bne DisplayLeftWind
    lda #$7f  ; (tab) char
    sta textbuffer+79
    lda #0  ;space
    sta textbuffer+76
    beq DisplayWindValue
DisplayLeftWind
    lda #$7e  ;(del) char
    sta textbuffer+76
    lda #0 ;space
    sta textbuffer+79
DisplayWindValue
    mwa Wind temp
    lsrw temp ;divide by 16 to have
    lsrw temp ;a nice view on a screen
    lsrw temp
    lsrw temp
    lda temp
    sta decimal
    mwa #textbuffer+77 displayposition
    jsr displaybyte
    rts
;-------------------------------------------------
PutTankNameOnScreen
; puts name of the tan on the screen
    ldy #$00
    lda tanknr
    asl
    asl
    asl ; 8 chars per name
    tax
NextChar02
    lda tanksnames,x
    sta textbuffer+7,y
    inx
    iny
    cpy #$08
    bne NextChar02
    rts
;-------------------------------------------------

.endif