********************************
*
* APPLE II
* MONITOR II
*
* COPYRIGHT 1978 BY
* APPLE COMPUTER, INC.
*
* ALL RIGHTS RESERVED
*
* STEVE WOZNIAK
*
********************************
*
* MODIFIED NOV 1978
* BY JOHN A
*
********************************
        ORG $F800
        OBJ $2000
*******************************
LOC0    EQU $00
LOC1    EQU $01
WNDLFT  EQU $20
WNDWDTH EQU $21
WNDTOP  EQU $22
WNDBTM  EQU $23
CH      EQU $24
CV      EQU $25
GBASL   EQU $26
GBASH   EQU $27
BASL    EQU $28
BASH    EQU $29
BAS2L   EQU $2A
BAS2H   EQU $2B
H2      EQU $2C
LMNEM   EQU $2C
V2      EQU $2D
RMNEM   EQU $2D
MASK    EQU $2E
CHKSUM  EQU $2E
FORMAT  EQU $2E
LASTIN  EQU $2F
LENGTH  EQU $2F
SIGN    EQU $2F
COLOR   EQU $30
MODE    EQU $31
INVFLG  EQU $32
PROMPT  EQU $33
YSAV    EQU $34
YSAV1   EQU $35
CSWL    EQU $36
CSWH    EQU $37
KSWL    EQU $38
KSWH    EQU $39
PCL     EQU $3A
PCH     EQU $3B
A1L     EQU $3C
A1H     EQU $3D
A2L     EQU $3E
A2H     EQU $3F
A3L     EQU $40
A3H     EQU $41
A4L     EQU $42
A4H     EQU $43
A5L     EQU $44
A5H     EQU $45
ACC     EQU $45    ; NOTE OVERLAP WITH A5H!
XREG    EQU $46
YREG    EQU $47
STATUS  EQU $48
SPNT    EQU $49
RNDL    EQU $4E
RNDH    EQU $4F
PICK    EQU $95
IN      EQU $0200
BRKV    EQU $3F0   ; NEW VECTOR FOR BRK
SOFTEV  EQU $3F2   ; VECTOR FOR WARM START
PWREDUP EQU $3F4   ; THIS MUST = EOR #$A5 OF SOFTEV+1
AMPERV  EQU $3F5   ; APPLESOFT & EXIT VECTOR
USRADR  EQU $03F8
NMI     EQU $03FB
IRQLOC  EQU $3FE
LINE1   EQU $400
MSLOT   EQU $07F8
IOADR   EQU $C000
KBD     EQU $C000
KBDSTRB EQU $C010
TAPEOUT EQU $C020
SPKR    EQU $C030
TXTCLR  EQU $C050
TXTSET  EQU $C051
MIXCLR  EQU $C052
MIXSET  EQU $C053
LOWSCR  EQU $C054
HISCR   EQU $C055
LORES   EQU $C056
HIRES   EQU $C057
SETAN0  EQU $C058
CLRAN0  EQU $C059
SETAN1  EQU $C05A
CLRAN1  EQU $C05B
SETAN2  EQU $C05C
CLRAN2  EQU $C05D
SETAN3  EQU $C05E
CLRAN3  EQU $C05F
TAPEIN  EQU $C060
PADDL0  EQU $C064
PTRIG   EQU $C070
CLRROM  EQU $CFFF
BASIC   EQU $E000
BASIC2  EQU $E003
        PAGE
PLOT    LSR A
        PHP
        JSR GBASCALC
        PLP
        LDA #$0F
        BCC RTMASK
        ADC #$E0
RTMASK  STA MASK
PLOT1   LDA (GBASL),Y
        EOR COLOR
        AND MASK
        EOR (GBASL),Y
        STA (GBASL),Y
        RTS
HLINE   JSR PLOT
HLINE1  CPY H2
        BCS RTS1
        INY
        JSR PLOT1
        BCC HLINE1
VLINEZ  ADC #$01
VLINE   PHA
        JSR PLOT
        PLA
        CMP V2
        BCC VLINEZ
RTS1    RTS
CLRSCR  LDY #$2F
        BNE CLRSC2
CLRTOP  LDY #$27
CLRSC2  STY V2
        LDY #$27
CLRSC3  LDA #$00
        STA COLOR
        JSR VLINE
        DEY
        BPL CLRSC3
        RTS
        PAGE
GBASCALC PHA
        LSR A
        AND #$03
        ORA #$04
        STA GBASH
        PLA
        AND #$18
        BCC GBCALC
        ADC #$7F
GBCALC  STA GBASL
        ASL A
        ASL A
        ORA GBASL
        STA GBASL
        RTS
        LDA COLOR
        CLC
        ADC #$03
SETCOL  AND #$0F
        STA COLOR
        ASL A
        ASL A
        ASL A
        ASL A
        ORA COLOR
        STA COLOR
        RTS
SCRN    LSR A
        PHP
        JSR GBASCALC
        LDA (GBASL),Y
        PLP
SCRN2   BCC RTMSKZ
        LSR A
        LSR A
        LSR A
        LSR A
RTMSKZ  AND #$0F
        RTS
        PAGE
INSDS1  LDX PCL
        LDY PCH
        JSR PRYX2
        JSR PRBLNK
INSDS2  LDA (PCL,X)
        TAY
        LSR A
        BCC IEVEN
        ROR A
        BCS ERR
        CMP #$A2
        BEQ ERR
        AND #$87
IEVEN   LSR A
        TAX
        LDA FMT1,X
        JSR SCRN2
        BNE GETFMT
ERR     LDY #$80
        LDA #$00
GETFMT  TAX
        LDA FMT2,X
        STA FORMAT
        AND #$03
        STA LENGTH
        TYA
        AND #$8F
        TAX
        TYA
        LDY #$03
        CPX #$8A
        BEQ MNNDX3
MNNDX1  LSR A
        BCC MNNDX3
        LSR A
MNNDX2  LSR A
        ORA #$20
        DEY
        BNE MNNDX2
        INY
MNNDX3  DEY
        BNE MNNDX1
        RTS
        DFB $FF,$FF,$FF
        PAGE
INSTDSP JSR INSDS1
        PHA
PRNTOP  LDA (PCL),Y
        JSR PRBYTE
        LDX #$01
PRNTBL  JSR PRBL2
        CPY LENGTH
        INY
        BCC PRNTOP
        LDX #$03
        CPY #$04
        BCC PRNTBL
        PLA
        TAY
        LDA MNEML,Y
        STA LMNEM
        LDA MNEMR,Y
        STA RMNEM
NXTCOL  LDA #$00
        LDY #$05
PRMN2   ASL RMNEM
        ROL LMNEM
        ROL A
        DEY
        BNE PRMN2
        ADC #$BF
        JSR COUT
        DEX
        BNE NXTCOL
        JSR PRBLNK
        LDY LENGTH
        LDX #$06
PRADR1  CPX #$03
        BEQ PRADR5
PRADR2  ASL FORMAT
        BCC PRADR3
        LDA CHAR1-1,X
        JSR COUT
        LDA CHAR2-1,X
        BEQ PRADR3
        JSR COUT
PRADR3  DEX
        BNE PRADR1
        RTS
PRADR4  DEY
        BMI PRADR2
        JSR PRBYTE
PRADR5  LDA FORMAT
        CMP #$E8
        LDA (PCL),Y
        BCC PRADR4
        PAGE
RELADR  JSR PCADJ3
        TAX
        INX
        BNE PRNTYX
        INY
PRNTYX  TYA
PRNTAX  JSR PRBYTE
PRNTX   TXA
        JMP PRBYTE
PRBLNK  LDX #$03
PRBL2   LDA #$A0
PRBL3   JSR COUT
        DEX
        BNE PRBL2
        RTS
PCADJ   SEC
PCADJ2  LDA LENGTH
PCADJ3  LDY PCH
        TAX
        BPL PCADJ4
        DEY
PCADJ4  ADC PCL
        BCC RTS2
        INY
RTS2    RTS
FMT1    DFB $04
        DFB $20
        DFB $54
        DFB $30
        DFB $0D
        DFB $80
        DFB $04
        DFB $90
        DFB $03
        DFB $22
        DFB $54
        DFB $33
        DFB $0D
        DFB $80
        DFB $04
        DFB $90
        DFB $04
        DFB $20
        DFB $54
        DFB $33
        DFB $0D
        DFB $80
        DFB $04
        DFB $90
        DFB $04
        DFB $20
        DFB $54
        DFB $3B
        DFB $0D
        DFB $80
        DFB $04
        DFB $90
        DFB $00
        DFB $22
        DFB $44
        DFB $33
        DFB $0D
        DFB $C8
        DFB $44
        DFB $00
        DFB $11
        DFB $22
        DFB $44
        DFB $33
        DFB $0D
        DFB $C8
        DFB $44
        DFB $A9
        DFB $01
        DFB $22
        DFB $44
        DFB $33
        DFB $0D
        DFB $80
        DFB $04
        DFB $90
        DFB $01
        DFB $22
        DFB $44
        DFB $33
        DFB $0D
        DFB $80
        DFB $04
        DFB $90
        DFB $26
        DFB $31
        DFB $87
        DFB $9A
FMT2    DFB $00
        DFB $21
        DFB $81
        DFB $82
        DFB $00
        DFB $00
        DFB $59
        DFB $4D
        DFB $91
        DFB $92
        DFB $86
        DFB $4A
        DFB $85
        DFB $9D
CHAR1   DFB $AC
        DFB $A9
        DFB $AC
        DFB $A3
        DFB $A8
        DFB $A4
CHAR2   DFB $D9
        DFB $00
        DFB $D8
        DFB $A4
        DFB $A4
        DFB $00
MNEML   DFB $1C
        DFB $8A
        DFB $1C
        DFB $23
        DFB $5D
        DFB $8B
        DFB $1B
        DFB $A1
        DFB $9D
        DFB $8A
        DFB $1D
        DFB $23
        DFB $9D
        DFB $8B
        DFB $1D
        DFB $A1
        DFB $00
        DFB $29
        DFB $19
        DFB $AE
        DFB $69
        DFB $A8
        DFB $19
        DFB $23
        DFB $24
        DFB $53
        DFB $1B
        DFB $23
        DFB $24
        DFB $53
        DFB $19
        DFB $A1
        DFB $00
        DFB $1A
        DFB $5B
        DFB $5B
        DFB $A5
        DFB $69
        DFB $24
        DFB $24
        DFB $AE
        DFB $AE
        DFB $A8
        DFB $AD
        DFB $29
        DFB $00
        DFB $7C
        DFB $00
        DFB $15
        DFB $9C
        DFB $6D
        DFB $9C
        DFB $A5
        DFB $69
        DFB $29
        DFB $53
        DFB $84
        DFB $13
        DFB $34
        DFB $11
        DFB $A5
        DFB $69
        DFB $23
        DFB $A0
MNEMR   DFB $D8
        DFB $62
        DFB $5A
        DFB $48
        DFB $26
        DFB $62
        DFB $94
        DFB $88
        DFB $54
        DFB $44
        DFB $C8
        DFB $54
        DFB $68
        DFB $44
        DFB $E8
        DFB $94
        DFB $00
        DFB $B4
        DFB $08
        DFB $84
        DFB $74
        DFB $B4
        DFB $28
        DFB $6E
        DFB $74
        DFB $F4
        DFB $CC
        DFB $4A
        DFB $72
        DFB $F2
        DFB $A4
        DFB $8A
        DFB $00
        DFB $AA
        DFB $A2
        DFB $A2
        DFB $74
        DFB $74
        DFB $74
        DFB $72
        DFB $44
        DFB $68
        DFB $B2
        DFB $32
        DFB $B2
        DFB $00
        DFB $22
        DFB $00
        DFB $1A
        DFB $1A
        DFB $26
        DFB $26
        DFB $72
        DFB $72
        DFB $88
        DFB $C8
        DFB $C4
        DFB $CA
        DFB $26
        DFB $48
        DFB $44
        DFB $44
        DFB $A2
        DFB $C8
        PAGE
IRQ     STA ACC
        PLA
        PHA
        ASL A
        ASL A
        ASL A
        BMI BREAK
        JMP (IRQLOC)
BREAK   PLP
        JSR SAV1
        PLA
        STA PCL
        PLA
        STA PCH
        JMP (BRKV) ;BRKV WRITTEN OVER BY DISK BOOT
OLDBRK  JSR INSDS1
        JSR RGDSP1
        JMP MON
RESET   CLD        ;DO THIS FIRST THIS TIME
        JSR SETNORM
        JSR INIT
        JSR SETVID
        JSR SETKBD
INITAN  LDA SETAN0 ; AN0 = TTL HI
        LDA SETAN1 ; AN1 = TTL HI
        LDA CLRAN2 ; AN2 = TTL LO
        LDA CLRAN3 ; AN3 = TTL LO
        LDA CLRROM ; TURN OFF EXTNSN ROM
        BIT KBDSTRB ; CLEAR KEYBOARD
NEWMON  CLD
        JSR BELL   ; CAUSES DELAY IF KEY BOUNCES
        LDA SOFTEV+1 ;IS RESET HI
        EOR #$A5   ; A FUNNY COMPLEMENT OF THE
        CMP PWREDUP ; PWR UP BYTE ???
        BNE PWRUP  ; NO SO PRWUP
        LDA SOFTEV ; YES SEE IF COLD START
        BNE NOFIX  ; HAS BEEN DONE YET?
        LDA #$E0   ; ??
        CMP SOFTEV+1 ; ??
        BNE NOFIX  ; YES SO REENTER SYSTEM
FIXSEV  LDY #3     ; NO SO POINT AT WARM START
        STY SOFTEV ; FOR NEXT RESET
        JMP BASIC  ; AND DO THE COLD START
NOFIX   JMP (SOFTEV) ; SOFT ENTRY VECTOR
********************************
PWRUP   JSR APPLEII
SETPG3  EQU *      ; SET PAGE 3 VECTORS
        LDX #5
SETPLP  LDA PWRCON-1,X ; WITH CNTRL B ADRS
        STA BRKV-1,X ; OF CURRENT BASIC
        DEX
        BNE SETPLP
        LDA #$C8   ; LOAD HI SLOT +1
        STX LOC0   ; SETPG3 MUST RETURN X=0
        STA LOC1   ; SET PTR H
SLOOP   LDY #7     ; Y IS BYTE PTR
        DEC LOC1
        LDA LOC1
        CMP #$C0   ; AT LAST SLOT YET?
        BEQ FIXSEV ; YES AND IT CANT BE A DISK
        STA MSLOT
NXTBYT  LDA (LOC0),Y ; FETCH A SLOT BYTE
        CMP DISKID-1,Y ; IS IT A DISK ??
        BNE SLOOP  ; NO SO NEXT SLOT DOWN
        DEY
        DEY        ; YES SO CHECK NEXT BYTE
        BPL NXTBYT ; UNTIL 4 CHECKED
        JMP (LOC0)
        NOP
        NOP
* REGDSP MUST ORG $FAD7
REGDSP  JSR CROUT
RGDSP1  LDA #$45
        STA A3L
        LDA #$00
        STA A3H
        LDX #$FB
RDSP1   LDA #$A0
        JSR COUT
        LDA RTBL-251,X
        JSR COUT
        LDA #$BD
        JSR COUT
* LDA ACC+5,X
        DFB $B5,$4A
        JSR PRBYTE
        INX
        BMI RDSP1
        RTS
PWRCON  DW OLDBRK
        DFB $00,$E0,$45
DISKID  DFB $20,$FF,$00,$FF
        DFB $03,$FF,$3C
TITLE   DFB $C1,$D0,$D0
        DFB $CC,$C5,$A0
        DFB $DD,$DB
XLTBL   EQU *
        DFB $C4,$C2,$C1
        DFB $FF,$C3
        DFB $FF,$FF,$FF
*  MUST ORG $FB19
RTBL    DFB $C1,$D8,$D9
        DFB $D0,$D3
PREAD   LDA PTRIG
        LST ON
        LDY #$00
        NOP
        NOP
PREAD2  LDA PADDL0,X
        BPL RTS2D
        INY
        BNE PREAD2
        DEY
RTS2D   RTS
INIT    LDA #$00
        STA STATUS
        LDA LORES
        LDA LOWSCR
SETTXT  LDA TXTSET
        LDA #$00
        BEQ SETWND
SETGR   LDA TXTCLR
        LDA MIXSET
        JSR CLRTOP
        LDA #$14
SETWND  STA WNDTOP
        LDA #$00
        STA WNDLFT
        LDA #$28
        STA WNDWDTH
        LDA #$18
        STA WNDBTM
        LDA #$17
TABV    STA CV
        JMP VTAB
APPLEII JSR HOME   ; CLEAR THE SCRN
        LDY #8
STITLE  LDA TITLE-1,Y ; GET A CHAR
        STA LINE1+14,Y
        DEY
        BNE STITLE
        RTS
SETPWRC LDA SOFTEV+1
        EOR #$A5
        STA PWREDUP
        RTS
VIDWAIT EQU *      ; CHECK FOR A PAUSE
        CMP #$8D   ; ONLY WHEN I HAE A CR
        BNE NOWAIT ; NOT SO, DO REGULAR
        LDY KBD    ; IS KEY PRESSED?
        BPL NOWAIT ; NO
        CPY #$93   ; IS IT CTL S?
        BNE NOWAIT ; NO SO IGNORE
        BIT KBDSTRB ; CLEAR STROBE
KBDWAIT LDY KBD    ; WAIT TILL NEXT KEY TO RESUME
        BPL KBDWAIT ; WAIT FOR KEYPRESS
        CPY #$83   ; IS IT CONTROL C ?
        BEQ NOWAIT ; YES SO LEAVE IT
        BIT KBDSTRB ; CLR STROBE
NOWAIT  JMP VIDOUT ; DO AS BEFORE
        PAGE
ESCOLD  SEC        ; INSURE CARRY SET
        JMP ESC1
ESCNOW  TAY        ; USE CHAR AS INDEX
        LDA XLTBL-$C9,Y ; XLATE IJKM TO CBAD
        JSR ESCOLD ; DO THIS CURSOR MOTION
        JSR RDKEY  ; AND GET NEXT
ESCNEW  CMP #$CE   ; IS THIS AN N ?
        BCS ESCOLD ; N OR GREATER DO IT
        CMP #$C9   ; LESS THAN I ?
        BCC ESCOLD ; YES SO OLD WAY
        CMP #$CC   ; IS IT A L ?
        BEQ ESCOLD ; DO NORMAL
        BNE ESCNOW ; GO DO IT
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
*    MUST ORG $FBC1
BASCALC PHA
        LSR A
        AND #$03
        ORA #$04
        STA BASH
        PLA
        AND #$18
        BCC BASCLC2
        ADC #$7F
BASCLC2 STA BASL
        ASL A
        ASL A
        ORA BASL
        STA BASL
        RTS
BELL1   CMP #$87
        BNE RTS2B
        LDA #$40
        JSR WAIT
        LDY #$C0
BELL2   LDA #$0C
        JSR WAIT
        LDA SPKR
        DEY
        BNE BELL2
RTS2B   RTS
        PAGE
STORADV LDY CH
        STA (BASL),Y
ADVANCE INC CH
        LDA CH
        CMP WNDWDTH
        BCS CR
RTS3    RTS
VIDOUT  CMP #$A0
        BCS STORADV
        TAY
        BPL STORADV
        CMP #$8D
        BEQ CR
        CMP #$8A
        BEQ LF
        CMP #$88
        BNE BELL1
BS      DEC CH
        BPL RTS3
        LDA WNDWDTH
        STA CH
        DEC CH
UP      LDA WNDTOP
        CMP CV
        BCS RTS4
        DEC CV
VTAB    LDA CV
VTABZ   JSR BASCALC
        ADC WNDLFT
        STA BASL
RTS4    RTS
ESC1    EOR #$C0   ; ESC @ ?
        BEQ HOME   ; IF SO DO HOME AND CLEAR
        ADC #$FD   ; ESC-A OR B CHECK
        BCC ADVANCE ; A, ADVANCE
        BEQ BS     ; B, BACKSPACE
        ADC #$FD   ; ESC-C OR D CHECK
        BCC LF     ; C, DOWN
        BEQ UP     ; D GO UP
        ADC #$FD   ; ESC-E OR F CHECK
        BCC CLREOL ; E, CLEAR TO END OF LINE
        BNE RTS4   ; ELSE NOT F,RETURN
CLREOP  LDY CH     ; ESC F IS CLR TO END OF PAGE
        LDA CV
CLEOP1  PHA
        JSR VTABZ
        JSR CLEOLZ
        LDY #$00
        PLA
        ADC #$00
        CMP WNDBTM
        BCC CLEOP1
        BCS VTAB
HOME    LDA WNDTOP
        STA CV
        LDY #$00
        STY CH
        BEQ CLEOP1
        PAGE
CR      LDA #$00
        STA CH
LF      INC CV
        LDA CV
        CMP WNDBTM
        BCC VTABZ
        DEC CV
SCROLL  LDA WNDTOP
        PHA
        JSR VTABZ
SCRL1   LDA BASL
        STA BAS2L
        LDA BASH
        STA BAS2H
        LDY WNDWDTH
        DEY
        PLA
        ADC #$01
        CMP WNDBTM
        BCS SCRL3
        PHA
        JSR VTABZ
SCRL2   LDA (BASL),Y
        STA (BAS2L),Y
        DEY
        BPL SCRL2
        BMI SCRL1
SCRL3   LDY #$00
        JSR CLEOLZ
        BCS VTAB
CLREOL  LDY CH
CLEOLZ  LDA #$A0
CLEOL2  STA (BASL),Y
        INY
        CPY WNDWDTH
        BCC CLEOL2
        RTS
WAIT    SEC
WAIT2   PHA
WAIT3   SBC #$01
        BNE WAIT3
        PLA
        SBC #$01
        BNE WAIT2
        RTS
NXTA4   INC A4L
        BNE NXTA1
        INC A4H
NXTA1   LDA A1L
        CMP A2L
        LDA A1H
        SBC A2H
        INC A1L
        BNE RTS4B
        INC A1H
RTS4B   RTS
        PAGE
HEADR   LDY #$4B
        JSR ZERDLY
        BNE HEADR
        ADC #$FE
        BCS HEADR
        LDY #$21
WRBIT   JSR ZERDLY
        INY
        INY
ZERDLY  DEY
        BNE ZERDLY
        BCC WRTAPE
        LDY #$32
ONEDLY  DEY
        BNE ONEDLY
WRTAPE  LDY TAPEOUT
        LDY #$2C
        DEX
        RTS
RDBYTE  LDX #$08
RDBYT2  PHA
        JSR RD2BIT
        PLA
        ROL A
        LDY #$3A
        DEX
        BNE RDBYT2
        RTS
RD2BIT  JSR RDBIT
RDBIT   DEY
        LDA TAPEIN
        EOR LASTIN
        BPL RDBIT
        EOR LASTIN
        STA LASTIN
        CPY #$80
        RTS
RDKEY   LDY CH
        LDA (BASL),Y
        PHA
        AND #$3F
        ORA #$40
        STA (BASL),Y
        PLA
        JMP (KSWL)
KEYIN   INC RNDL
        BNE KEYIN2
        INC RNDH
KEYIN2  BIT KBD    ; READ KEYBOARD
        BPL KEYIN
        STA (BASL),Y
        LDA KBD
        BIT KBDSTRB
        RTS
ESC     JSR RDKEY
        JSR ESCNEW
RDCHAR  JSR RDKEY
        CMP #$9B
        BEQ ESC
        RTS
        PAGE
NOTCR   LDA INVFLG
        PHA
        LDA #$FF
        STA INVFLG
        LDA IN,X
        JSR COUT
        PLA
        STA INVFLG
        LDA IN,X
        CMP #$88
        BEQ BCKSPC
        CMP #$98
        BEQ CANCEL
        CPX #$F8
        BCC NOTCR1
        JSR BELL
NOTCR1  INX
        BNE NXTCHAR
CANCEL  LDA #$DC
        JSR COUT
GETLNZ  JSR CROUT
GETLN   LDA PROMPT
        JSR COUT
        LDX #$01
BCKSPC  TXA
        BEQ GETLNZ
        DEX
NXTCHAR JSR RDCHAR
        CMP #$95
        BNE CAPTST
        LDA (BASL),Y
CAPTST  CMP #$E0
        BCC ADDINP
        AND #$DF   ; SHIFT TO UPPER CASE
ADDINP  STA IN,X
        CMP #$8D
        BNE NOTCR
        JSR CLREOL
CROUT   LDA #$8D
        BNE COUT
PRA1    LDY A1H
        LDX A1L
PRYX2   JSR CROUT
        JSR PRNTYX
        LDY #$00
        LDA #$AD
        JMP COUT
        PAGE
XAMB    LDA A1L
        ORA #$07
        STA A2L
        LDA A1H
        STA A2H
MOD8CHK LDA A1L
        AND #$07
        BNE DATAOUT
XAM     JSR PRA1
DATAOUT LDA #$A0
        JSR COUT
        LDA (A1L),Y
        JSR PRBYTE
        JSR NXTA1
        BCC MOD8CHK
RTS4C   RTS
XAMPM   LSR A
        BCC XAM
        LSR A
        LSR A
        LDA A2L
        BCC ADD
        EOR #$FF
ADD     ADC A1L
        PHA
        LDA #$BD
        JSR COUT
        PLA
PRBYTE  PHA
        LSR A
        LSR A
        LSR A
        LSR A
        JSR PRHEXZ
        PLA
PRHEX   AND #$0F
PRHEXZ  ORA #$B0
        CMP #$BA
        BCC COUT
        ADC #$06
COUT    JMP (CSWL)
COUT1   CMP #$A0
        BCC COUTZ
        AND INVFLG
COUTZ   STY YSAV1
        PHA
        JSR VIDWAIT ; GO CHECK FOR PAUSE
        PLA
        LDY YSAV1
        RTS
        PAGE
BL1     DEC YSAV
        BEQ XAMB
BLANK   DEX
        BNE SETMDZ
        CMP #$BA
        BNE XAMPM
STOR    STA MODE
        LDA A2L
        STA (A3L),Y
        INC A3L
        BNE RTS5
        INC A3H
RTS5    RTS
SETMODE LDY YSAV
        LDA IN-1,Y
SETMDZ  STA MODE
        RTS
LT      LDX #$01
LT2     LDA A2L,X
        STA A4L,X
        STA A5L,X
        DEX
        BPL LT2
        RTS
MOVE    LDA (A1L),Y
        STA (A4L),Y
        JSR NXTA4
        BCC MOVE
        RTS
VFY     LDA (A1L),Y
        CMP (A4L),Y
        BEQ VFYOK
        JSR PRA1
        LDA (A1L),Y
        JSR PRBYTE
        LDA #$A0
        JSR COUT
        LDA #$A8
        JSR COUT
        LDA (A4L),Y
        JSR PRBYTE
        LDA #$A9
        JSR COUT
VFYOK   JSR NXTA4
        BCC VFY
        RTS
LIST    JSR A1PC
        LDA #$14
LIST2   PHA
        JSR INSTDSP
        JSR PCADJ
        STA PCL
        STY PCH
        PLA
        SEC
        SBC #$01
        BNE LIST2
        RTS
        PAGE
A1PC    TXA
        BEQ A1PCRTS
A1PCLP  LDA A1L,X
        STA PCL,X
        DEX
        BPL A1PCLP
A1PCRTS RTS
SETINV  LDY #$3F
        BNE SETIFLG
SETNORM LDY #$FF
SETIFLG STY INVFLG
        RTS
SETKBD  LDA #$00
INPORT  STA A2L
INPRT   LDX #KSWL
        LDY #KEYIN
        BNE IOPRT
SETVID  LDA #$00
OUTPORT STA A2L
OUTPRT  LDX #CSWL
        LDY #COUT1
IOPRT   LDA A2L
        AND #$0F
        BEQ IOPRT1
        ORA #IOADR/256
        LDY #$00
        BEQ IOPRT2
IOPRT1  LDA #COUT1/256
IOPRT2  EQU *
        STY LOC0,X ; $94,$00
        STA LOC1,X ; $95,$01
        RTS
        NOP
        NOP
XBASIC  JMP BASIC
BASCONT JMP BASIC2
GO      JSR A1PC
        JSR RESTORE
        JMP (PCL)
REGZ    JMP REGDSP
TRACE   RTS
* TRACE IS GONE
        NOP
STEPZ   RTS        ; STEP IS GONE
        NOP
        NOP
        NOP
        NOP
        NOP
USR     JMP USRADR
        PAGE
WRITE   LDA #$40
        JSR HEADR
        LDY #$27
WR1     LDX #$00
        EOR (A1L,X)
        PHA
        LDA (A1L,X)
        JSR WRBYTE
        JSR NXTA1
        LDY #$1D
        PLA
        BCC WR1
        LDY #$22
        JSR WRBYTE
        BEQ BELL
WRBYTE  LDX #$10
WRBYT2  ASL A
        JSR WRBIT
        BNE WRBYT2
        RTS
CRMON   JSR BL1
        PLA
        PLA
        BNE MONZ
READ    JSR RD2BIT
        LDA #$16
        JSR HEADR
        STA CHKSUM
        JSR RD2BIT
RD2     LDY #$24
        JSR RDBIT
        BCS RD2
        JSR RDBIT
        LDY #$3B
RD3     JSR RDBYTE
        STA (A1L,X)
        EOR CHKSUM
        STA CHKSUM
        JSR NXTA1
        LDY #$35
        BCC RD3
        JSR RDBYTE
        CMP CHKSUM
        BEQ BELL
PRERR   LDA #$C5
        JSR COUT
        LDA #$D2
        JSR COUT
        JSR COUT
BELL    LDA #$87
        JMP COUT
        PAGE
RESTORE LDA STATUS
        PHA
        LDA A5H
REST1   LDX XREG
        LDY YREG
        PLP
        RTS
SAVE    STA A5H
SAV1    STX XREG
        STY YREG
        PHP
        PLA
        STA STATUS
        TSX
        STX SPNT
        CLD
        RTS
OLDRST  JSR SETNORM
        JSR INIT
        JSR SETVID
        JSR SETKBD
        PAGE
MON     CLD
        JSR BELL
MONZ    LDA #$AA
        STA PROMPT
        JSR GETLNZ
        JSR ZMODE
NXTITM  JSR GETNUM
        STY YSAV
        LDY #$17
CHRSRCH DEY
        BMI MON
        CMP CHRTBL,Y
        BNE CHRSRCH
        JSR TOSUB
        LDY YSAV
        JMP NXTITM
DIG     LDX #$03
        ASL A
        ASL A
        ASL A
        ASL A
NXTBIT  ASL A
        ROL A2L
        ROL A2H
        DEX
        BPL NXTBIT
NXTBAS  LDA MODE
        BNE NXTBS2
*
        LDA A2H,X
*
        STA A1H,X
*
        STA A3H,X
NXTBS2  INX
        BEQ NXTBAS
        BNE NXTCHR
GETNUM  LDX #$00
        STX A2L
        STX A2H
NXTCHR  LDA IN,Y
        INY
        EOR #$B0
        CMP #$0A
        BCC DIG
        ADC #$88
        CMP #$FA
        BCS DIG
        RTS
TOSUB   LDA #GO/256
        PHA
        LDA SUBTBL,Y
        PHA
        LDA MODE
ZMODE   LDY #$00
        STY MODE
        RTS
        PAGE
CHRTBL  DFB $BC
        DFB $B2
        DFB $BE
        DFB $B2    ; T CMD NOW LIKE USR
        DFB $EF
        DFB $C4
        DFB $B2    ; S CMD NOW LIKE USR
        DFB $A9
        DFB $BB
        DFB $A6
        DFB $A4
        DFB $06
        DFB $95
        DFB $07
        DFB $02
        DFB $05
        DFB $F0
        DFB $00
        DFB $EB
        DFB $93
        DFB $A7
        DFB $C6
        DFB $99
SUBTBL  DFB $B2
        DFB $C9
        DFB $BE
        DFB $C1
        DFB $35
        DFB $8C
        DFB $C4
        DFB $96
        DFB $AF
        DFB $17
        DFB $17
        DFB $2B
        DFB $1F
        DFB $83
        DFB $7F
        DFB $5D
        DFB $CC
        DFB $B5
        DFB $FC
        DFB $17
        DFB $17
        DFB $F5
        DFB $03
        DW  NMI
        DW  RESET
        DW  IRQ

ENDASM
