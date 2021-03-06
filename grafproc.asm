;	@com.wudsn.ide.asm.mainsourcefile=program.asm

    .IF *>0 ;this is a trick that prevents compiling this file alone


;--------------------------------------------------
draw .proc ;;fuxxing good draw :) 
;--------------------------------------------------
;creditz to Dr Jankowski / MIM U.W.
; (xi,yi)-----(xk,yk)
;20 DX=XK-XI
;30 DY=YK-YI
;40 DP=2*DY
;50 DD=2*(DY-DX)
;60 DI=2*DY-DX
;70 REPEAT
;80   IF DI>=0
;90     DI=DI+DD
;100     YI=YI+1
;110   ELSE
;120     DI=DI+DP
;130   ENDIF
;140   plot XI,YI
;150   XI=XI+1
;160 UNTIL XI=XK


    ; begin: xdraw,ydraw - end: xbyte,ybyte
    ; let's store starting coordinates
    ; will be needed, because everything is calculated relatively
    mwa #0 LineLength
    mwa xdraw xtempDRAW
    mwa ydraw ytempDRAW

    ; if line goes our of the screen we are not drawing it, but...

    cpw xdraw #screenwidth
    bcs DrawOutOfTheScreen
    cpw xbyte #screenwidth
    bcs DrawOutOfTheScreen
    ;cpw ydraw #screenheight
    ;bcs DrawOutOfTheScreen
    ;cpw ybyte #screenheight
    ;bcc DrawOnTheScreen
    lda ydraw+1
    bne DrawOutOfTheScreen
    lda ybyte+1
    beq DrawOnTheScreen
DrawOutOfTheScreen
    ;jsr DrawJumpPad
    rts
DrawOnTheScreen
    ; constant parameters
    ; XI=0 ,YI=0
    lda #0
    sta XI
    sta XI+1
    sta YI
    sta YI+1

    ; setting the direction controll bits
    cpw ydraw ybyte
    bcc LineDown
    ; here one line up
    ; we are setting bit 0
    mva #1 HowToDraw  ;here we can because it's first operation
    ; we are subctracting Yend from Ybegin (reverse order)
    ; DY=YI-YK
    sbw ydraw ybyte DY
    jmp CheckDirectionX
LineDown
    ; one line down here
    ; we are setting bit 0
    mva #0 HowToDraw  ;here we can because it's first operation
    ; substract Ybegin from Yend (normal order)
    ; DY=YK-YI
    sbw ybyte ydraw DY
CheckDirectionX
    cpw xdraw xbyte
    bcc LineRight
    ; here goes line to the left
    ; we set bit 1

    lda HowToDraw
    ora #$02
    sta HowToDraw
    ; substract Xend from Xbegin (reverse)
    ; DX=XI-XK
    sbw xdraw xbyte DX
    jmp CheckDirectionFactor
LineRight
    ; here goes one line to the right
    ; we clear bit 0
    ; we can do nothing because the bit is cleared!

    ;lda HowToDraw
    ;and #$FD
    ;sta HowToDraw

    ; substracting Xbegin from Xend (normal way)
    ; DX=XK-XI
    sbw xbyte xdraw DX
CheckDirectionFactor
    ; here we check Direction Factor
    ; I do not know if we are using proper English word
    ; but the meaning is 'a' in y=ax+b

    ; lda DX
    ; we already have DX in A
    cpw DX DY

    bcc SwapXY
    ; 'a' factor is fire, so we copy parameters
    ; XK=DX
    mwa DX XK
    ; i kasowanie bitu 2
    ; and bit 2 clear
    ; (is not needed because already cleared)
    ;lda HowToDraw
    ;and #$FB
    ;sta HowToDraw
    jmp LineParametersReady
SwapXY
    ; not this half of a quarter! - parameters must be swapped
    ; XK=DY
    ; DY=DX
    ; DX=XK  - because DY is there so DY and DX are swapped
    ; YK ... not used
    mwa DY XK
    mwa DX DY
    mwa XK DX

    ; and let's set bit 2
    lda HowToDraw
    ora #$04
    sta HowToDraw
LineParametersReady
    ; let's check if length is not zero
    lda DX
    ora DX+1
    ora DY
    ora DY+1
    jeq EndOfDraw

    ; here we have DX,DY,XK and we know which operations
    ; are to be performed with these factors when doing PLOT
    ; (accordingly to given bits of 'HowToDraw')
    ; Now we must calculate DP, DD and DI
    ; DP=2*DY
    ; DD=2*(DY-DX)
    ; DI=2*DY-DX

    mwa DY DP
    aslw DP

    sbw DY DX DD
    aslw DD

    mwa DY DI
    aslw DI
    sbw DI DX

DrawLoop
    ; REPEAT
    ;   IF DI>=0
    lda DI+1
    bmi DINegative
    ;     DI=DI+DD
    ;     YI=YI+1
    adw DI DD
    adw YI #1
    jmp drplot
DINegative
    ;   ELSE
    ;     DI=DI+DP
    adw DI DP

drplot ; Our plot that checks how to calculate pixels.
    ; In xtempDRAW and ycircle there are begin coordinates
    ; of our line
    ; First we check the 'a' factor (like in y=ax+b)
    ; If necessary we swap XI and YI
    ; (as we can not change XI and YI we move XI to temp2
    ;  and YI to temp)


    lda HowToDraw
    and #$04
    bne SwappedXY
    mwa XI temp
    mwa YI temp2
    jmp CheckPlotY
SwappedXY
    mwa XI temp2
    mwa YI temp
CheckPlotY
    lda HowToDraw
    and #01
    bne LineGoesUp
    ; here we know that line goes down and we are not changing Y
    adw temp2 ytempDRAW ydraw ; YI
    jmp CheckPlotX
LineGoesUp
    ; line goes up here - we are reversing Y
    sbw ytempDRAW temp2 ydraw ; YI
CheckPlotX
    lda HowToDraw
    and #02
    bne LineGoesLeft
    ; here we know that line goes right and we are not changing X
    adw temp xtempDRAW xdraw ; XI
    jmp PutPixelinDraw
LineGoesLeft
    ; line goes left - we are reversing X
    sbw xtempDRAW temp xdraw ; XI
PutPixelinDraw
    jsr DrawJumpPad
; end of the special PLOT for DRAW

    ; XI=XI+1
    ; UNTIL XI=XK
    adw XI #1
    cpw XI XK
    jne DrawLoop

EndOfDraw
    mwa xtempDRAW xdraw
    mva ytempDRAW ydraw
    rts
.endp

DrawJumpPad
    jmp (DrawJumpAddr)
Drawplot
    jmp plot
DrawLen
    adw LineLength #1
    rts
    
DrawCheck .proc
;    lda SmokeTracerFlag
;	bne yestrace	; jakie to g�upie....
	lda tracerflag
	ora SmokeTracerFlag
yestrace
	beq notrace
	jsr plot
notrace
;aftertrace
    lda HitFlag
    bne StopHitChecking

CheckCollisionDraw
    ; checking collision!
    lda ydraw+1
    bne StopHitChecking

    jsr CheckCollisionWithTank
    lda HitFlag
    bne StopHitChecking

    mwa xdraw temp
    ;adw temp --- it does not work!!!!!!!! and should? OMC ??? #mountaintable
    clc
    lda temp
    adc #<mountaintable
    sta temp
    lda temp+1
    adc #>mountaintable
    sta temp+1

    ldy #0
    lda ydraw
    cmp (temp),y
    bcc StopHitChecking

    mva #1 HitFlag
    mwa xdraw XHit
    mwa ydraw YHit


StopHitChecking
    rts
.endp 

;--------------------------------------------------
circle .proc ;fxxxing good circle drawing :) 
;--------------------------------------------------
;Turbo Basic source
; R=30
; XC=0:YC=R
; FX=0:FY=8*R:FS=4*R+3
; WHILE FX<FY
;   splot8    //splot8 are eight plotz around the circle
;   XC=XC+1
;   FX=FX+8
;   IF FS>0
;     FS=FS-FX-4
;   ELSE
;     YC=YC-1
;     FY=FY-8
;     FS=FS-FX-4+FY
;   ENDIF
; WEND
; splot8

    mwa xdraw xcircle
    mva ydraw ycircle

    mwa #0 xc
    mva radius yc
    mva #0 fx
    mva radius fy
    asl FY
    asl FY
    mva FY FS
    asl FY
    clc
    lda FS
    adc #3
    sta FS

circleloop
    lda FX
    cmp FY
    bcs endcircleloop
    jsr splot8
    inc XC

    clc
    lda FX
    adc #8
    sta FX

    lda FS
    beq else01
    bmi else01
    sec
    sbc FX
    sbc #4
    sta FS
    jmp endif01
else01
    dec YC
    sec
    lda FY
    sbc #8
    sta FY

    lda FS
    sec
    sbc FX
    sbc #4
    clc
    adc FY
    sta FS
endif01
    jmp circleloop
endcircleloop

    jsr splot8

    mwa xcircle xdraw
    mva ycircle ydraw
    rts
.endp
;----
splot8 .proc
; plot xcircle+XC,ycircle+YC
; plot xcircle+XC,ycircle-YC
; plot xcircle-XC,ycircle-YC
; plot xcircle-XC,ycircle+YC

; plot xcircle+YC,ycircle+XC
; plot xcircle+YC,ycircle-XC
; plot xcircle-YC,ycircle-XC
; plot xcircle-YC,ycircle+XC

    clc
    lda xcircle
    adc XC
    sta xdraw
    lda xcircle+1
    adc #0
    sta xdraw+1
    ;clc
    lda ycircle
    adc YC
    sta ydraw
    sta tempcir
    jsr plot

    sec
    lda ycircle
    sbc YC
    sta ydraw
    jsr plot

    sec
    lda xcircle
    sbc XC
    sta xdraw
    lda xcircle+1
    sbc #0
    sta xdraw+1
    jsr plot

    lda tempcir
    sta ydraw
    jsr plot
;---
    clc
    lda xcircle
    adc yC
    sta xdraw
    lda xcircle+1
    adc #0
    sta xdraw+1
    ;clc
    lda ycircle
    adc xC
    sta ydraw
    sta tempcir
    jsr plot

    sec
    lda ycircle
    sbc xC
    sta ydraw
    jsr plot

    sec
    lda xcircle
    sbc yC
    sta xdraw
    lda xcircle+1
    sbc #0
    sta xdraw+1
    jsr plot

    lda tempcir
    sta ydraw
    jsr plot

    RTS
.endp

;--------------------------------------------------
WaitForKeyRelease .proc
;--------------------------------------------------
    lda SKSTAT
    cmp #$ff
    beq KeyIsReleased
    cmp #$f7
    bne WaitForKeyRelease
KeyIsReleased
    rts
.endp

;--------------------------------------------------
clearscreen .proc
;--------------------------------------------------
    lda #0
    tax
Loopi1
    sta display,x
    sta display+$100,x
    sta display+$200,x
    sta display+$300,x
    sta display+$400,x
    sta display+$500,x
    sta display+$600,x
    sta display+$700,x
    sta display+$800,x
    sta display+$900,x
    sta display+$a00,x
    sta display+$b00,x
    sta display+$c00,x
    sta display+$d00,x
    sta display+$e00,x
    sta display+$f00,x
    sta display+$1000,x
    sta display+$1100,x
    sta display+$1200,x
    sta display+$1300,x
    sta display+$1400,x
    sta display+$1500,x
    sta display+$1600,x
    sta display+$1700,x
    sta display+$1800,x
    sta display+$1900,x
    sta display+$1a00,x
    sta display+$1b00,x
    sta display+$1c00,x
    sta display+$1d00,x
    sta display+$1e00,x
    sta display+$1f00,x
    inx
    bne Loopi1
    rts
.endp
;-------------------------------*------------------
placetanks .proc
;--------------------------------------------------
    ldx #(MaxPlayers-1)   ;maxNumberOfPlayers-1
    lda #0
skip09
    ; clearing the tables with coordinates of the tank
    ; it is necessary, because randomizing checks
    ; if the given tank is already placed
    ; after check if its position is not (0,0)

    ; I will be honest with you - I have no idea
    ; what the above comment was intending to mean :)

    sta XtankstableL,x
    sta XtankstableH,x
    sta Ytankstable,x
    dex
    bpl skip09


    mwa #0 temptankX
    mva #0 temptankNr ;player number
StillRandomize
    ldx NumberOfPlayers
    lda random
    and #$07
    tay
    cpy NumberOfPlayers
    bcs StillRandomize
    lda xtankstableL,y
    bne StillRandomize
    lda xtankstableH,y
    bne StillRandomize
    ; here we know that we got a random number
    ; of the tank that is not in use
    ; this number is in Y

    clc
    lda temptankX
    adc disktance,x
    sta temptankX
    sta xtankstableL,y
    bcc NotHigherByte03
    inc temptankX+1
NotHigherByte03
    lda temptankX+1
    sta xtankstableH,y
    INC temptankNr
    ldx temptankNr
    Cpx NumberOfPlayers
    bne StillRandomize

; getting random displacements relative to even positions
    ldx #$00
StillRandomize02
    lda random
    and #$1f ; maximal displacement is 31 pixels

    clc
    adc xtankstableL,x
    sta xtankstableL,x
    bcc NotHigherByte02
    inc xtankstableH,x
NotHigherByte02
; and we deduct 15 to make the displacement work two ways
    sec
    lda xtankstableL,x
    sbc #$0f
    sta xtankstableL,x
    bcs NotHigherByte01
    dec xtankstableH,x
NotHigherByte01

; and clear lowest bit to be sure that the X coordinate is even
; (this is to have P/M background look nice)
    lda xtankstableL,x
    and #$fe
    sta xtankstableL,x
    inx
    Cpx NumberOfPlayers
    bne StillRandomize02
    rts

; during calculating heights of thw mountains
; check if the tank is not somewhere around
; if so, make horizontal line 8 pixels long
CheckTank
    ldx NumberOfPlayers
    dex
CheckNextTank
    lda xtankstableL,x
    cmp xdraw
    bne UnequalTanks
    lda xtankstableH,x
    cmp xdraw+1
    bne UnequalTanks
    lda ydraw
    ;sec
    ;sbc #$01 ; minus 1, because it was 1 pixel too high
    sta ytankstable,x     ; what's the heck is that????!!!!
    mva #7 deltaX
    mwa #0 delta
UnequalTanks
    dex
    bpl CheckNextTank
    rts
.endp
;-------------------------------------------------
drawtanks
;-------------------------------------------------


    lda tanknr
    pha
    ldx #$00
    stx tanknr

DrawNextTank
    jsr drawtanknr
    inc tanknr
    ldx tanknr
    Cpx NumberOfPlayers
    bne DrawNextTank

    pla
    sta tankNr

    rts
;---------
drawtanknr
    ldx tanknr
    ; let's check the energy
    lda eXistenZ,x
    bne SkipRemovigPM ; if energy=0 then no tank

    ; hide P/M
    lda #0
    sta hposp0,x
    jmp DoNotDrawTankNr
SkipRemovigPM


    lda AngleTable,x
    bmi AngleToLeft01
    lda #90
    sec
    sbc AngleTable,x
    tay
    lda BarrelTableR,y
    jmp CharacterAlreadyKnown
AngleToLeft01
    sec
    sbc #(255-90)
    tay
    lda BarrelTableL,y
CharacterAlreadyKnown
    sta CharCode
DrawTankNrX
    ldx tanknr
    lda xtankstableL,x
    sta xdraw
    lda xtankstableH,x
    sta xdraw+1
    lda ytankstable,x
    sta ydraw

    jsr TypeChar

    ; now P/M graphics on the screen (only for 5 tanks)
    ; horizontal position
    mwa xdraw xbyte
    ldx tanknr
    cpx #$5
    bcs NoPlayerMissile
    rorw xbyte ; divide by 2 (carry does not matter)
    lda xbyte
    clc
    adc #$24 ; P/M to graphics offser
    cpx #$4 ; 5th tank are joined missiles and offset is defferent
    bne NoMissile
    clc
    adc #$0C
NoMissile
    sta hposp0,x
    ; vertical position
    lda pmtableL,x
    sta xbyte
    lda pmtableH,x
    sta xbyte+1

    ; calculate start position of the tank
    lda ydraw
    clc
    adc #$25 ; P/M to graphics offset
    sta temp
    ; clear sprite and put 3 lines on the tank at the same time
    ldy #$00
    tya
ClearPM     cpy temp
    bne ZeroesToGo
    lda #$03 ; (2 bits set) we set on two pixels in three lines
    sta (xbyte),y
    dey
    sta (xbyte),y
    dey
    sta (xbyte),y
    dey
    lda #$00
ZeroesToGo
    sta (xbyte),y
    dey
    bne ClearPM

NoPlayerMissile
DoNotDrawTankNr
    rts

;--------------------------------------------------
drawmountains .proc
;--------------------------------------------------
    mwa #0 xdraw
    mwa #mountaintable modify


drawmountainsloop
    ldy #0
    lda (modify),y
    sta ydraw
    jsr DrawLine
    adw modify #1
    adw xdraw #1
    cpw xdraw #screenwidth
    bne drawmountainsloop

    rts
;--------------------------------------------------
drawmountainspixel
;--------------------------------------------------
    mwa #0 xdraw
    mwa #mountaintable modify


drawmountainspixelloop
    ldy #0
    lda (modify),y
    sta ydraw
    jsr plot
    adw modify #1
    adw xdraw #1
    cpw xdraw #screenwidth
    bne drawmountainspixelloop

    rts
.endp
;--------------------------------------------------
SoilDown2 .proc
;--------------------------------------------------

; how it is supposed to work:
; first loop is looking for the highest pixels
; and fills with their Y coordinates both temporary tables
;
; second (main) loop works this way:
; sets end-of-soil-fall-down-flag to 1 ( IsEndOfTheFallFlag=1 )
;  goes through the horizontal line checking if
;  Y coordinate from the first table equals to height of the peak
;    if so, it goes further
;  if not:
;    sets end-of-soil-fall-down-flag to 0
;    increases Y from the first table
;       if there is no pixel there it plots here and
; zeroes pixel from the second table and after that
;              increases Y of the second table
;       repeats with next pixels au to the end of the line
;  if the flag is 0 then repeat the main loop
; and that's it :)
;
; I am sorry but after these 4 years I have no idea
; how it works. I have just translated Polish comment
; but I do not understand a word of it :)
; If you know how it works, please write here :))))

    jsr PMoutofscreen

; First we look for highest pixels and fill with their coordinates
; both tables

    mwa RangeLeft xdraw
    adw RangeLeft #mountaintable2 tempor2
    adw RangeLeft #mountaintable3 tempor3

NextColumn1
    mva #0 ydraw
NextPoint1
    jsr point
    beq StillNothing
    ldy #0
    lda ydraw
    sta (tempor2),y
    sta (tempor3),y
    jmp FoundPeek1
StillNothing
    inc ydraw
    lda ydraw
    cmp #screenheight
    bne NextPoint1
FoundPeek1
    adw tempor2 #1
    adw tempor3 #1
    adw xdraw #1
    ;vcmp xdraw,screenwidth,NextColumn1
    cpw xdraw RangeRight
    bcc NextColumn1
    beq NextColumn1
; we have both tables filled with starting values

; main loop starts here
MainFallout2
    mwa RangeLeft xdraw
    adw RangeLeft #mountaintable temp
    adw RangeLeft #mountaintable2 tempor2
    adw RangeLeft #mountaintable3 tempor3

    mwa #1 IsEndOfTheFallFlag
FalloutOfLine
    ldy #0

    ; is Y coordinate from the first table
    ; equal to peak height, if so, go ahead
    lda (tempor2),y
    cmp #screenheight-1 ;cmp (temp),y
    bcs ColumnIsReady
    ; in the other case there are things to be done
    sty IsEndOfTheFallFlag   ; flag to 0
    ; we are increasing Y in the first table
    ;lda (tempor2),y
    clc
    adc #1
    sta (tempor2),y
    ; and checking if there is a pixel there
    sta ydraw
    jsr point
    bne ThereIsPixelHere
    ; if no pixel we plot it
    mva #1 color
    jsr plot.MakePlot
    ; zeroing pixel from the second table
    ; and increase Y in second table
    ldy #0
    lda (tempor3),y
    sta ydraw
    lda (tempor3),y
    clc
    adc #1
    sta (tempor3),y
    sty color
    jsr plot.MakePlot

ThereIsPixelHere
ColumnIsReady
    adw temp #1
    adw tempor2 #1
    adw tempor3 #1
    adw xdraw #1
    ;vcmp xdraw,screenwidth,FalloutOfLine
    cpw xdraw RangeRight
    bcc FalloutOfLine
    beq FalloutOfLine

    lda IsEndOfTheFallFlag
; we repeat untill at some point first table reaches
; level of the mountains
    jeq MainFallout2
; now correct heights are in the second temporary table
; so we copy
    mwa RangeLeft xdraw
    adw RangeLeft #mountaintable temp
    adw RangeLeft #mountaintable3 tempor3

    ldy #0
CopyHeights
    lda (tempor3),y
    sta (temp),y
    adw temp #1
    adw tempor3 #1
    adw xdraw #1
    ;vcmp xdraw,screenwidth,CopyHeights
    cpw xdraw RangeRight
    bcc CopyHeights
    beq CopyHeights
    mva #1 color
    rts
.endp
;--------------------------------------------------
calculatemountains .proc
;--------------------------------------------------
    mwa #0 xdraw

; starting point
getrandomY   ;getting random Y coordinate
    sec
    lda random
    cmp #screenheight-(margin*4) ;it means that max line=199
    bcs getrandomY
    clc
    adc #(margin*2)
    sta ydraw
    sta yfloat+1
    mva #0 yfloat ;yfloat equals to e.g. 140.0

; how to make nice looking mountains?
; randomize points and join them with lines
; Here we do it simpler way - we randomize X (or deltaX)
; and "delta" (change of Y coordinate)

NextPart
    lda random
    sta delta ; it is after the dot (xxx.delta)
    lda random
    and #$03 ;(max delta)
    sta delta+1 ; before the dot (delta+1.delta)

    lda random
    and #$01 ;random sign (+/- or up/down)
    sta UpNdown

    ; theoretically we have here ready
    ; fixed-point delta value
    ; (-1*(UpNdown))*(delta+1.delta)

    ;loop drawing one line

ChangingDirection
    lda random ;length of the line
    and #$0f   ;max line length
    tax
    inx
    inx
    inx
    stx deltaX

OnePart
    jsr placeTanks.CheckTank
    ; checks if at a given X coordinate
    ; is any tank and if so
    ; changes parameters of drawing
    ; to generate flat 8 pixels
    ; (it will be the place for the tank)
    ; it also stores Y position of the tank
    adw xdraw #mountaintable modify

    lda ydraw
    ldy #0
    sta (modify),y

    ; Up or Down
    lda UpNdown
    beq ToBottom

ToTop  ;it means substracting

    sbw yfloat delta
    lda yfloat+1
    cmp #margin
    bcs Skip01
    ; if smaller than 10
    ldx #$00
    stx UpNdown
    jmp Skip01

ToBottom
    adw yfloat delta
    lda yfloat+1
    cmp #screenheight-margin
    bcc Skip01
    ; if higher than screen
    ldx #$01
    stx UpNdown
Skip01
    sta ydraw

    adw xdraw #1

    cpw xdraw #screenwidth
    beq EndDrawing

    dec deltaX
    bne OnePart

    jmp NextPart
EndDrawing

    rts
.endp
; -----------------------------------------
unPlot .proc
; -----------------------------------------
    ldx #0 ; only one pixel
unPlotAfterX
    stx WhichUnPlot

    ; first remake the oldie
    lda oldplotL,x
    sta oldplot
    lda oldplotH,x
    sta oldplot+1

    lda oldply,x
    tay
    lda oldora,x
    sta (oldplot),y


    ; is it not out of the screen ????
    cpw ydraw #screenheight
    jcs EndOfUnPlot
CheckX
    cpw xdraw #screenwidth
    jcs EndOfUnPlot
MakeUnPlot
    ; let's count coordinates taken from xdraw and ydraw
    mwa xdraw xbyte

    lda xbyte
    and #$7
    sta ybit

    lsrw xbyte
    rorw xbyte
    rorw xbyte
;---
    ldy xbyte

    ldx WhichUnPlot
    tya
    sta oldply,x


    ldx ydraw
    lda linetableL,x
    sta xbyte
    sta oldplot
    lda linetableH,x
    sta xbyte+1
    sta oldplot+1
    ldx ybit


    lda color
    beq ClearUnPlot

    lda (xbyte),y
    sta OldOraTemp
    ora bittable,x
    sta (xbyte),y
    jmp ContinueUnPlot
ClearUnPlot
    lda (xbyte),y
    sta OldOraTemp
    and bittable2,x
;    sta (xbyte),y
ContinueUnPlot
    ldx WhichUnPlot
    lda OldOraTemp
    sta oldora,x
    lda oldplot
    sta oldplotL,x
    lda oldplot+1
    sta oldplotH,x
    ; and now we must solve the problem of several plots
    ; in one byte
    ldx #4
    ldy WhichUnPlot
LetsCheckOverlapping
    cpx WhichUnPlot
    beq SkipThisPlot
    lda oldplotL,x
    cmp oldplotL,y
    bne NotTheSamePlot
    lda oldplotH,x
    cmp oldplotH,y
    bne NotTheSamePlot
    lda oldply,x
    cmp oldply,y
    bne NotTheSamePlot
    ; the pixel is in the same byte so let's take correct contents
    lda oldora,x
    sta oldora,y
NotTheSamePlot
SkipThisPlot
    dex
    bpl LetsCheckOverlapping
EndOfUnPlot
    rts
.endp
; -----------------------------------------
plot .proc ;plot (xdraw, ydraw)
; this is one of the most important routines in the whole
; game. If you are going to speed up the game, start with
; plot - it is used by every single effect starting from explosions
; through line drawing and small text output!!!
; We tried to keep it clear and therefore it is far from
; optimal speed.

; -----------------------------------------
    ; is it not over the screen ???
    cpw ydraw #(screenheight+1); changed for one additional line. cpw ydraw #(screenheight-1)
    bcs unPlot.EndOfUnPlot
CheckX02
    cpw xdraw #screenwidth
    bcs EndOfPlot ;nearest RTS
MakePlot
    ; let's calculate coordinates from xdraw and ydraw
    mwa xdraw xbyte


    lda xbyte
    and #$7
    sta ybit

    ;xbyte = xbyte/8
    lda xbyte
    lsr xbyte+1
    ror ;just one bit over 256. Max screenwidht = 512!!!
    lsr  
    lsr
    tay ;save
;---
     



    ldx ydraw
    lda linetableL,x
    sta xbyte
    lda linetableH,x
    sta xbyte+1

    ldx ybit
    lda color
    beq ClearPlot

    lda (xbyte),y
    ora bittable,x
    sta (xbyte),y
EndOfPlot
    rts
ClearPlot
    lda (xbyte),y
    and bittable2,x
    sta (xbyte),y
    rts
.endp
; -----------------------------------------
point .proc
; -----------------------------------------
    ; checks state of the pixel (coordinates in xdraw and ydraw)
    ; result is in A (zero or appropriate bit is set)


    ; let's calculate coordinates from xdraw and ydraw
    mwa xdraw xbyte


    lda xbyte
    and #$7
    sta ybit

    ;xbyte = xbyte/8
    lda xbyte
    lsr xbyte+1
    ror ;just one bit over 256. Max screenwidht = 512!!!
    lsr  
    lsr
    tay ;save

;---

    ldx ydraw
    lda linetableL,x
    sta xbyte
    lda linetableH,x
    sta xbyte+1

    ldx ybit

    lda (xbyte),y
    and bittable,x
    rts
.endp

; -----------------------------------------
PlotPointer .proc
; -----------------------------------------
; draws pointer that shows where is the bullet
; when it is over the screen
; (it is on the top of the screen)

   
	mwa xdraw tempCir
	
	mva #0 color
	mwa #screenHeight ydraw	
	mwa oldPlotPointerX xdraw
	jsr plot
	
	
	mwa tempCir xdraw
	
	mva #1 color
	mwa #screenHeight ydraw	
	jsr plot
	
	mwa xdraw oldPlotPointerX

    rts

.endp
;--------------------------------------------------
DrawLine .proc
;--------------------------------------------------
    mva #0 ydraw+1
    lda #screenheight
    sec
    sbc ydraw
    sta tempbyte01
    jsr plot
    ;rts
    jmp IntoDraw    ; jumps inside Draw routine
    ; because one pixel is already plotted


loopdraw

    lda (xbyte),y
    ora bittable,x
    sta (xbyte),y
IntoDraw   adw xbyte #screenBytes

    dec tempbyte01
    bne loopdraw
    rts
.endp
;
; ------------------------------------------
TypeChar .proc
; puts char on the graphics screen
; in: CharCode
; in: left LOWER corner of the char coordinates (xdraw, ydraw)
;--------------------------------------------------
    ; char to the table
    lda CharCode
    sta fontind
    lda #$00
    sta fontind+1
    ; char intex times 8
    aslw fontind
    rolw fontind
    rolw fontind

    adw fontind #TankFont

    ; and 8 bytes to the table
    ldy #7
CopyChar
    lda (fontind),y
    sta char1,y
    lda #$00
    sta char2,y
    dey
    bpl CopyChar
    ; and 8 subsequent bytes as a mask
    adw fontind #8
    ldy #7
CopyMask
    lda (fontind),y
    sta mask1,y
    lda #$ff
    sta mask2,y
    dey
    bpl CopyMask

    ; calculating coordinates from xdraw and ydraw
    mwa xdraw xbyte

    lda xbyte
    and #$7
    sta ybit

    lsrw xbyte
    rorw xbyte
    rorw xbyte

;---
    ldy xbyte

    ldx ydraw
    .rept 7
    dex
    .endr

    lda linetableL,x
    sta xbyte
    lda linetableH,x
    sta xbyte+1
    ; mask preparation and character shifting
    ldx ybit
    beq MaskOK00
MakeMask00
    sec
    ror mask1
    ror mask2
    sec
    ror mask1+1
    ror mask2+1
    sec
    ror mask1+2
    ror mask2+2
    sec
    ror mask1+3
    ror mask2+3
    sec
    ror mask1+4
    ror mask2+4
    sec
    ror mask1+5
    ror mask2+5
    sec
    ror mask1+6
    ror mask2+6
    sec
    ror mask1+7
    ror mask2+7
    lsr char1
    ror char2
    ror char1+1
    ror char2+1
    ror char1+2
    ror char2+2
    ror char1+3
    ror char2+3
    ror char1+4
    ror char2+4
    ror char1+5
    ror char2+5
    ror char1+6
    ror char2+6
    ror char1+7
    ror char2+7
    dex
    bne MakeMask00
MaskOK00
    ; here x=0
    lda Erase
    beq CharLoopi  ; it works, because x=0
    lda #0
    ldx #7
EmptyChar
    sta char1,x
    sta char2,x
    dex
    bpl EmptyChar
    ldx #0
CharLoopi
    lda (xbyte),y
    and mask1,x
    ora char1,x
    sta (xbyte),y
    iny
    lda (xbyte),y
    and mask2,x
    ora char2,x
    sta (xbyte),y
    dey
    adw xbyte #screenBytes
    inx
    cpx #8
    bne CharLoopi
    rts
.endp
; ------------------------------------------
PutChar4x4 .proc ;puts 4x4 pixels char on the graphics screen
; in: xdraw, ydraw (upper left corner of the char)
; in: CharCode4x4 (.sbyte)
;--------------------------------------------------
    lda plot4x4color
    sta color


; calculating address of the first byte
    mva #4 LoopCounter4x4
    lda CharCode4x4
    and #1
    sta nibbler4x4
    lda CharCode4x4
    ror
    ; in carry there is which nibble of the byte is to be taken
    clc
    adc #(3*32)
    sta y4x4
nextline4x4
    mva #4 Xcounter4x4
    ldy y4x4
    lda font4x4,y ;there was a problem with OMC here, but it works now

    ldx nibbler4x4
    beq uppernibble

    asl
    asl
    asl
    asl
uppernibble
    rol
    sta StoreA4x4
    bcs EmptyPixel ; the font I drawn is in inverse ...
    ;lda plot4x4color  ;these lines are not necessary
    ;sta color  ;if a plots are one color only
    jsr plot
    ;jmp Loop4x4Continued
EmptyPixel
    ;lda #1   ;reverse color (color==1-color)
    ;sec
    ;sbc plot4x4color
    ;sta color
    ;jsr plot
    ;this is turned off for speed
    ;anyway we assume the text is being drawn
    ;over an empty space
Loop4x4Continued
    adw xdraw #1
    lda StoreA4x4
    dec Xcounter4x4
    ldx Xcounter4x4
    bne uppernibble
    ; here we have on screen one line of the char
    adw ydraw #1
    sbw xdraw #4
    sbw y4x4 #32
    dec:lda LoopCounter4x4
    bne nextline4x4

    rts
.endp
; ------------------------------------------
PutChar4x4FULL .proc;
;this routine works just like PutChar4x4,
;but this time all pixels are being drawn
;(empty and not empty)
;--------------------------------------------------
    lda plot4x4color
    sta color

; calculating address of the first byte
    mva #4 LoopCounter4x4
    lda CharCode4x4
    and #1
    sta nibbler4x4
    lda CharCode4x4
    ror
    ; in carry there is which nibble of the byte is to be taken clc
    clc
    adc #(3*32)
    sta y4x4
nextline4x4FULL
    mva #4 Xcounter4x4
    ldy y4x4
    lda font4x4,y

    ldx nibbler4x4
    beq uppernibbleFULL

    asl
    asl
    asl
    asl
uppernibbleFULL
    rol
    sta StoreA4x4
    bcs EmptyPixelFULL
    lda plot4x4color  ;these lines are not necessary
    sta color  ;if a plots are one color only
    jsr plot
    jmp Loop4x4ContinuedFULL
EmptyPixelFULL
    lda #1   ;reverse color (color==1-color)
    sec
    sbc plot4x4color
    sta color
    jsr plot
    ;this is turned on now
    ;of course it is slower

Loop4x4ContinuedFULL
    adw xdraw #1
    lda StoreA4x4
    dec Xcounter4x4
    ldx Xcounter4x4
    bne uppernibbleFULL
    ; here we have on screen one line of the char
    adw ydraw #1
    sbw xdraw #4
    sbw y4x4 #32
    dec:lda LoopCounter4x4
    bne nextline4x4FULL

    rts
.endp

.endif