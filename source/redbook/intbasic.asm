    10   ORG $E000
    20   LST OFF
    30   XC OFF ;6502 only
    40   EXP ON ;print only macro call
    50   LSTDO OFF ;don't list conditional code
    60   TR OFF ;don't truncate listing to 3 bytes
    70   CYC OFF ;don't print cycle times
    80   USE MACROS
    90   LST ON
   100  *************************************************
   110  *                                               *
   120  *                 INTEGER BASIC                 *
   130  *                                               *
   140  *                      WOZ                      *
   150  *                                               *
   160  *************************************************
   170  *                                               *
   180  * "That BASIC, which we shipped with the first  *
   190  *  Apple II's, was never assembled -- ever.     *
   200  *  There was one handwritten copy, all          *
   210  *  handwritten, all hand assembled."            *
   220  *                                               *
   230  *              Steve Wozniak                    *
   240  *              Call-A.P.P.L.E., October 1986    *
   250  *                                               *
   260  *************************************************
   270
   280  * Computer  Apple II family
   290  * O/S       none needed, but usually DOS 3.3
   300  * Language  6502 assembly -- Merlin assembler
   310  * Disassembled by:
   320  *           Paul R. Santa-Maria
   330  *           P.O. Box 924
   340  *           Monroe  MI  48161
   350  * Revised   1 May 2000
   360  * Reference "What's Where in the Apple"; William F. Luebbert
   370  *           Peeking at Call-A.P.P.L.E.  Vol 2  1979; pp44-61
   380
   390  *************************************************
   400
   410  * zero-page
   420
   430  LOMEM = $004A ;ptr: start of vars
   440  HIMEM = $004C ;ptr: end of BASIC program
   450  NOUNSTKL = $0050 ;noun stack low bytes (80-87)
   460  SYNSTKH = $0058 ;syntax stack high byte
   470  NOUNSTKH = $0078 ;noun stack high bytes (78-97)
   480  SYNSTKL = $0080 ;syntax stack low bytes (80-9F)
   490  NOUNSTKC = $00A0 ;noun stack counter (A0-BF)
   500  TXTNDXSTK = $00A8 ;text index stack (A8-C7)
   510  TXTNDX = $00C8 ;text index val (OUTVAL)
   520  LEADBL = $00C9 ;leading blanks index (YTEMP)
   530  PP = $00CA ;ptr: start of program
   540  PV = $00CC ;ptr: end of vars
   550  ACC = $00CE ;word: main accumulator
   560  SRCH = $00D0 ;ptr to search var tbl
   570  TOKNDXSTK = $00D1 ;token index stack (D1-F0)
   580  SRCH2 = $00D2 ;second var search ptr
   590  IFFLAG = $00D4 ;IF/THEN fail flag
   600  CRFLAG = $00D5 ;carriage return flag
   610  VERBNOW = $00D6 ;verb currently in use
   620  PRFLAG = $00D7 ;print it now flag
   630  XSAVE = $00D8 ;temp Xreg save
   640  RUNFLAG = $00D9 ;run mode flag
   650  AUX = $00DA ;word: aux ctr
   660  PR = $00DC ;word: current line value
   670  *PN = $00DE ;ptr to current noun
   680  PX = $00E0 ;ptr to current verb
   690  P1 = $00E2 ;aux ptr 1 (delete line ptr)
   700  P2 = $00E4 ;aux ptr 2 ...
   710  *  (line num adr) (next line num) (general flag)
   720  P3 = $00E6 ;aux ptr 3 (next ptr)
   730  TOKNDX = $00F1 ;token index val
   740  PCON = $00F2 ;continue ptr (PRDEC low/high)
   750  AUTOINC = $00F4 ;auto line increment
   760  AUTOLN = $00F6 ;current auto line
   770  AUTOFLAG = $00F8 ;auto line mode flag ($FF = on)
   780  CHAR = $00F9 ;current char
   790  LEADZR = $00FA ;leading zeros index ($00,$A0,$B0)
   800  FORNDX = $00FB ;FOR-NEXT loop index
   810  GOSUBNDX = $00FC ;GOSUB index
   820  SYNSTKDX = $00FD ;syntax stack index val
   830  SYNPAG = $00FE ;ptr: syntax page
   840  *if SYNPAG+1 <> 0 then error condition exists
   850
   860  STACK = $0100 ;6502 STACK
   870
   880  *   GOSUB/RETURN usage
   890
   900  STK_00 = STACK+$00
   910  STK_10 = STACK+$10
   920  STK_20 = STACK+$20
   930  STK_30 = STACK+$30
   940
   950  *   FOR/NEXT/STEP usage
   960
   970  STK_40 = STACK+$40
   980  STK_50 = STACK+$50
   990  STK_60 = STACK+$60
  1000  STK_70 = STACK+$70
  1010  STK_80 = STACK+$80
  1020  STK_90 = STACK+$90
  1030  STK_A0 = STACK+$A0
  1040  STK_B0 = STACK+$B0
  1050  STK_C0 = STACK+$C0
  1060  STK_D0 = STACK+$D0
  1070
  1080  * I/O addresses
  1090
  1100  KBD = $C000
  1110  KBDSTRB = $C010
  1120
  1130  * Monitor zero page and low memory
  1140
  1150  WNDWDTH = $0021
  1160  CH = $0024
  1170  CV = $0025
  1180  GBAS = $0026
  1190  H2 = $002C
  1200  V2 = $002D
  1210  A1 = $003C
  1220  A2 = $003E
  1230  PROMPT = $0033
  1240  RNDL = $004E
  1250  RNDH = $004F
  1260
  1270  IN = $0200
  1280
  1290  * Monitor routines
  1300
  1310  PLOT = $F800
  1320  HLINE = $F819
  1330  VLINE = $F828
  1340  GBASCALC = $F847
  1350  SETCOL = $F864
  1360  PREAD = $FB1E
  1370  SETTXT = $FB39
  1380  SETGR = $FB40
  1390  VTAB = $FC22
  1400  WRITE = $FECD
  1410  WRITE0 = $FECF
  1420  READ = $FEFD
  1430  NXTCHAR = $FD75
  1440  CROUT = $FD8E
  1450  COUT = $FDED
  1460  INPORT = $FE8B
  1470  OUTPORT = $FE95
  1480  BELL = $FF3A
  1490
  1500  * ASCII (excess $8000 for xref listing)
  1510
  1520  ETX = $8003 ;CTRL-C
  1530  LF = $800A
  1540  CR = $800D
  1550  BLANK = $8020
  1560  DQT = $8022
  1570  SQT = $8027
  1580
  1590  **************************************************
  1600  * ;Z  = unreferenced area
  1610  * ;V  = referenced in verb table
  1620  * ;VO = referenced in verb table only
  1630  * ;solo = one reference only (could be in-line)
  1640
  1650   PUT PART1
  1660  BASIC JSR COLD
  1670  BASIC2 JMP WARM
  1680
  1690  SetPrompt ;solo
  1700    STA PROMPT
  1710    JMP COUT
  1720  *>
  1730
  1740    RTS ;Z
  1750  **
  1760
  1770  HE00C
  1780    TXA ;?print a trailing blank?
  1790    AND #$20
  1800    BEQ HE034 ;=>RTS
  1810  HE011 ;solo
  1820    LDA #BLANK+$80
  1830    STA P2
  1840    JMP COUT
  1850  *>
  1860
  1870  HE018 ;solo
  1880    LDA #32 ;check line length
  1890  HE01A
  1900    CMP CH
  1910    BCS NextByte ;=HS> line too short
  1920    LDA #CR+$80 ;print CR, then 7 blanks
  1930    LDY #7
  1940  *!LOOP
  1950      JSR COUT
  1960      LDA #BLANK+$80
  1970      DEY
  1980  *!UNTIL <EQ>
  1990
  2000  NextByte ;get next byte 16-bit ptr
  2010    LDY #0
  2020    LDA (P1),Y
  2030    INCW P1
  2040  HE034
  2050    RTS
  2060  **
  2070
  2080  * tkn $75 , (with tkn $74 LIST)
  2090  *   LIST 5,30
  2100
  2110  COMMA_LIST ;VO
  2120    JSR GET16BIT
  2130    JSR HE576
  2140  HE03B
  2150    CMPW P1;P3
  2160    BCS HE034 ;=>P1 <HS> P3, RTS
  2170    JSR UNPACK
  2180    JMP HE03B
  2190  *>
  2200
  2210
  2220  * tkn $76 LIST
  2230  *   list entire program
  2240
  2250  LIST ;VO
  2260    MOVW PP;P1
  2270    MOVW HIMEM;P3
  2280    BNE HE03B ;=>always
  2290
  2300  * tkn $74 LIST
  2310  *   specific line number or range of numbers
  2320  *   LIST 10: LIST 5,30
  2330
  2340  LISTNUM ;VO
  2350    JSR GET16BIT
  2360    JSR HE56D
  2370    MOVW P2;P1
  2380    BCS HE034 ;=>RTS
  2390  UNPACK ;unpack tokens to mnemonics
  2400    STX XSAVE
  2410    LDA #BLANK+$80
  2420    STA LEADZR
  2430    JSR NextByte
  2440    TYA
  2450  HE077
  2460    STA P2
  2470    JSR NextByte
  2480    TAX
  2490    JSR NextByte
  2500    JSR PRDEC
  2510  *!LOOP
  2520      JSR HE018
  2530      STY LEADZR
  2540      TAX
  2550      BPL HE0A3 ;=>
  2560      ASL
  2570      BPL HE077 ;=>
  2580      LDA P2
  2590  *!  IF <EQ>
  2600        JSR HE011
  2610  *!  ENDIF
  2620      TXA
  2630  *!  LOOP
  2640        JSR COUT
  2650  HE099
  2660        LDA #$25
  2670        JSR HE01A
  2680        TAX
  2690  *!  UNTIL <PL>
  2700      STA P2
  2710  HE0A3
  2720      CMP #$01
  2730  *!  IF <EQ>
  2740        LDX XSAVE
  2750        JMP CROUT
  2760  *!  ENDIF
  2770      PHA
  2780      STY ACC
  2790      LDX #>SYNTABL2
  2800      STX ACC+1
  2810      CMP #$51 ;END tkn
  2820  *!  IF <HS>
  2830        DEC ACC+1 ; in SYNTABL
  2840        SBC #$50 ;TAB tkn
  2850  *!  ENDIF
  2860  *!  LOOP
  2870        PHA
  2880        LDA (ACC),Y
  2890  *!    LOOP
  2900  *!      LOOP
  2910            TAX
  2920            DEY
  2930            LDA (ACC),Y
  2940  *!      UNTIL <MI>
  2950          CPX #$C0
  2960  *!    WHILE <LO>
  2970          CPX #0
  2980  *!    UNTIL <PL>
  2990        TAX
  3000        PLA
  3010        SBC #1 ;carry is set
  3020  *!  UNTIL <EQ>
  3030      BIT P2
  3040  *!  IF <PL>
  3050        JSR HEFF8
  3060  *!  ENDIF
  3070  *!  LOOP
  3080        LDA (ACC),Y
  3090  *!  WHILE <MI>
  3100        TAX
  3110        AND #$3F
  3120        STA P2
  3130        CLC
  3140        ADC #BLANK+$80
  3150        JSR COUT
  3160        DEY
  3170        CPX #$C0
  3180  *!  UNTIL <HS>
  3190      JSR HE00C
  3200      PLA
  3210      CMP #$5D ;93 ]
  3220      BEQ HE099 ;=>
  3230      CMP #$28 ;40 (
  3240  *!UNTIL <EQ>
  3250    BEQ HE099 ;=>always
  3260
  3270  * tkn $2A (
  3280  *   substring
  3290  *   PRINT A$(12,14)
  3300
  3310  PAREN_SUBSTR ;VO
  3320    JSR HE118
  3330    STA NOUNSTKL,X
  3340    CMP NOUNSTKH,X
  3350  HE102
  3360    BCC HE115 ;=LO>
  3370  HE104
  3380    LDY #ErrMsg05 ;"STRING"
  3390  HE106
  3400    JMP ERRMESS
  3410  *>
  3420
  3430  * tkn $23 ,
  3440  *   substring
  3450  *   PRINT A$(3,3)
  3460
  3470  COMMA_SUBSTR ;VO
  3480    JSR GETBYTE
  3490    CMP NOUNSTKL,X
  3500    BCC HE104 ;=LO>"STRING"
  3510    JSR HEFE4
  3520    STA NOUNSTKH,X
  3530  HE115
  3540    JMP HE823
  3550  *>
  3560
  3570  HE118
  3580    JSR GETBYTE
  3590    BEQ HE104 ;=>"STRING"
  3600    SEC
  3610    SBC #1
  3620    RTS
  3630  **
  3640
  3650  * tkn $42 (
  3660  *   string array is destination of the data
  3670  *   A$(1)="HELLO"
  3680
  3690  HE121 ;VO
  3700    JSR HE118
  3710    STA NOUNSTKL,X
  3720    CLC
  3730    SBC NOUNSTKH,X
  3740    JMP HE102
  3750  *>
  3760
  3770  HE12C
  3780    LDY #ErrMsg03 ;"MEM FULL"
  3790    BNE HE106 ;=>always
  3800
  3810  * tkn $43 ,
  3820  *   next var in DIM statement is string
  3830  *   DIM X(5),A$(5)
  3840
  3850  * tkn $4E DIM
  3860  *   string var.  uses tkn $22 (
  3870  *   DIM A$(5)
  3880
  3890  DIMSTR ;VO
  3900    JSR HE118
  3910    INX
  3920  HE134
  3930    LDA NOUNSTKL,X
  3940    STA AUX
  3950    ADC ACC
  3960    PHA
  3970    TAY
  3980    LDA NOUNSTKH,X
  3990    STA AUX+1
  4000    ADC ACC+1
  4010    PHA
  4020    CPY PP
  4030    SBC PP+1
  4040    BCS HE12C ;=HS>"MEM FULL" error
  4050    LDA AUX ;AUX := AUX-2
  4060    ADC #<0-2
  4070    STA AUX
  4080    LDA #>0-2
  4090    TAY
  4100    ADC AUX+1
  4110    STA AUX+1
  4120  *!LOOP
  4130      INY
  4140      LDA (AUX),Y
  4150      CMP PV,Y
  4160      BNE DimErr ;=>
  4170      TYA
  4180  *!UNTIL <NE>
  4190  *!LOOP
  4200      PLA
  4210      STA (AUX),Y
  4220      STA PV,Y
  4230      DEY
  4240  *!UNTIL <MI>
  4250    INX
  4260    RTS
  4270  **
  4280
  4290    NOP ;Z
  4300  DimErr
  4310    LDY #ErrMsg17 ;"DIM"
  4320  HE16F
  4330    BNE HE106 ;=>always
  4340
  4350  INPUTSTR ;input a string
  4360    LDA #0
  4370    JSR HE70A
  4380    LDY #$02
  4390    STY NOUNSTKH,X
  4400    JSR HE70A
  4410    STX XSAVE
  4420    TAX
  4430    INC PROMPT ;change '>' to '?'
  4440    JSR RDKEY
  4450    DEC PROMPT ;change '?' to '>'
  4460    TXA
  4470    LDX XSAVE
  4480    STA NOUNSTKH,X
  4490
  4500  * tkn $70 =
  4510  *   string - non-conditional
  4520  *   A$ = "HELLO"
  4530
  4540  HE18C ;VO
  4550    LDA NOUNSTKL+1,X
  4560    STA ACC
  4570    LDA NOUNSTKH+1,X
  4580    STA ACC+1
  4590    INX
  4600    INX
  4610    JSR HE1BC
  4620  *!LOOP
  4630      LDA NOUNSTKL-2,X
  4640      CMP NOUNSTKH-2,X
  4650  *!WHILE <LO>
  4660      INC NOUNSTKL-2,X
  4670      TAY
  4680      LDA (ACC),Y
  4690      LDY NOUNSTKL,X
  4700      CPY P2
  4710  *!  IF <HS>
  4720        LDY #ErrMsg18 ;"STR OVFL"
  4730        BNE HE16F ;=>always
  4740  *!  ENDIF
  4750      STA (AUX),Y
  4760      INC NOUNSTKL,X
  4770  *!UNTIL <CS>
  4780    LDY NOUNSTKL,X
  4790    TXA
  4800    STA (AUX),Y
  4810    JMP HF223
  4820  *>
  4830
  4840  HE1BC ;solo
  4850    LDA NOUNSTKL+1,X
  4860    STA AUX
  4870    SEC
  4880    SBC #2
  4890    STA P2
  4900    LDA NOUNSTKH+1,X
  4910    STA AUX+1
  4920    SBC #0
  4930    STA P2+1
  4940    LDY #0
  4950    LDA (P2),Y
  4960    CLC
  4970    SBC AUX
  4980    STA P2
  4990    RTS
  5000  **
  5010
  5020  * tkn $39 =
  5030  *   string logic op
  5040  *   IF A$ = "CAT" THEN END
  5050
  5060  HE1D7 ;V
  5070    LDA NOUNSTKL+3,X
  5080    STA ACC
  5090    LDA NOUNSTKH+3,X
  5100    STA ACC+1
  5110    LDA NOUNSTKL+1,X
  5120    STA AUX
  5130    LDA NOUNSTKH+1,X
  5140    STA AUX+1
  5150    INX
  5160    INX
  5170    INX
  5180    LDY #0
  5190    STY NOUNSTKH,X
  5200    STY NOUNSTKC,X
  5210    INY
  5220    STY NOUNSTKL,X
  5230  *!LOOP
  5240      LDA HIMEM+1,X
  5250      CMP NOUNSTKH-3,X
  5260      PHP
  5270      PHA
  5280      LDA NOUNSTKL-1,X
  5290      CMP NOUNSTKH-1,X
  5300  *!  IF <HS>
  5310        PLA
  5320        PLP
  5330  *!    IF <CC>
  5340  HE203
  5350          LSR NOUNSTKL,X
  5360  *!    ENDIF
  5370        RTS
  5380
  5390  *!  ENDIF
  5400      TAY
  5410      LDA (ACC),Y
  5420      STA P2
  5430      PLA
  5440      TAY
  5450      PLP
  5460      BCS HE203 ;=>EXIT LOOP
  5470      LDA (AUX),Y
  5480      CMP P2
  5490      BNE HE203 ;=>EXIT LOOP
  5500      INC NOUNSTKL-1,X
  5510      INC HIMEM+1,X
  5520  *!UNTIL <LO>
  5530  * always
  5540
  5550  * tkn $3A #
  5560  *   string logic op
  5570  *   IF A$ # "CAT" THEN END
  5580
  5590  HE21C ;VO
  5600    JSR HE1D7
  5610    JMP NOT
  5620  *>
  5630
  5640  * tkn $14 *
  5650  *   num math op
  5660  *   A = 27 * 2
  5670
  5680  MULT ;V
  5690    JSR HE254
  5700  *!LOOP
  5710      ASL ACC
  5720      ROL ACC+1 ;add partial product if C flag set
  5730  *!  IF <CS>
  5740        ADDW P3;AUX;P3
  5750  *!  ENDIF
  5760      DEY
  5770      BEQ HE244 ;=>EXIT LOOP
  5780      ASL P3
  5790      ROL P3+1
  5800  *!UNTIL <MI>
  5810    JMP HE77E
  5820  *>
  5830
  5840  HE244
  5850    LDA P3
  5860    JSR HE708
  5870    LDA P3+1
  5880    STA NOUNSTKC,X
  5890    ASL P2+1
  5900    BCC HE279 ;=>RTS
  5910    JMP NEGATE
  5920  *>
  5930
  5940  HE254
  5950    LDA #$55
  5960    STA P2+1
  5970    JSR HE25B
  5980  HE25B
  5990    MOVW ACC;AUX
  6000    JSR GET16BIT
  6010    STY P3 ;P3 := 0
  6020    STY P3+1
  6030    LDA ACC+1
  6040  *!IF <MI>
  6050      DEX
  6060      ASL P2+1
  6070      JSR NEGATE
  6080      JSR GET16BIT
  6090  *!ENDIF
  6100    LDY #$10
  6110  HE279
  6120    RTS
  6130  **
  6140
  6150  * tkn $1F MOD
  6160  *   num op
  6170  *   IF X MOD 13 THEN END
  6180
  6190  MOD ;V
  6200    JSR HEE6C
  6210    BEQ HE244 ;=>always
  6220
  6230    DB $FF ;Z
  6240
  6250  HE280 ;solo
  6260    INC PROMPT ;change '>' to '?'
  6270    LDY #0
  6280    JSR GETCMD
  6290    DEC PROMPT ;change '?' to '>'
  6300    RTS
  6310  **
  6320
  6330  * tkn $3D SCRN(
  6340  *   PRINT SCRN(X,Y)
  6350
  6360  SCRN ;VO
  6370    JSR GETBYTE
  6380    LSR ;Areg := Areg/2
  6390    PHP ;stash carry (lsb)
  6400    JSR GBASCALC
  6410    JSR GETBYTE
  6420    TAY
  6430    LDA (GBAS),Y ;get screen byte
  6440    PLP ;retrieve carry
  6450  *!IF <CS>
  6460      LSR ;odd, upper half
  6470      LSR
  6480      LSR
  6490      LSR
  6500  *!ENDIF
  6510    AND #$0F ;Areg := color number
  6520    LDY #0
  6530    JSR HE708
  6540    STY NOUNSTKC,X
  6550    DEY
  6560    STY PRFLAG ;PRFLAG := $FF
  6570
  6580  * tkn $3E ,
  6590  *   PRINT SCRN(X,Y)
  6600
  6610  COMMA_SCRN ;VO
  6620    RTS
  6630  **
  6640
  6650    DB $FF,$FF,$FF,$FF ;Z
  6660
  6670    JSR HEFD3 ;old 4K cold start ;Z
  6672
  6674  * Warm start
  6676
  6680  WARM ;main compile/execute code
  6690    JSR CROUT ;emit blank line
  6700  HE2B6
  6710    LSR RUNFLAG ;not running
  6720    LDA #">"
  6730    JSR SetPrompt ;set and print prompt char
  6740    LDY #0
  6750    STY LEADZR ;no leading zeros for AUTOLN
  6760    BIT AUTOFLAG ;AUTO?
  6762  * if AUTOLN active
  6770  *!IF <MI>
  6780      LDX AUTOLN ;yes, print line number
  6790      LDA AUTOLN+1
  6800      JSR PRDEC
  6810      LDA #BLANK+$80 ;and a blank
  6820      JSR COUT
  6830  *!ENDIF
  6840    LDX #$FF ;init Sreg
  6850    TXS
  6860    JSR GETCMD
  6870    STY TOKNDX
  6880    TXA
  6890    STA TXTNDX
  6900    LDX #$20
  6910    JSR HE491
  6920    LDA TXTNDX ;PX := TXTNDX+$0200+C flag
  6930    ADC #<$0200
  6940    STA PX
  6950    LDA #0
  6960    TAX
  6970    ADC #>$0200
  6980    STA PX+1
  6990    LDA (PX,X)
  7000    AND #$F0
  7010    CMP #"0"
  7020  *!IF <NE>
  7030      JMP HE883
  7040  *!ENDIF
  7050    LDY #2 ;move two bytes
  7060  *!LOOP
  7070      LDA (PX),Y
  7080      STA ACC-1,Y
  7090      DEY
  7100  *!UNTIL <EQ>
  7110    JSR HE38A
  7120    LDA TOKNDX
  7130    SBC TXTNDX
  7140    CMP #$04
  7150    BEQ HE2B6 ;=>
  7160    STA (PX),Y
  7170    LDA PP ;P2 := PP-(PX),Y
  7180    SBC (PX),Y
  7190    STA P2
  7200    LDA PP+1
  7210    SBC #0
  7220    STA P2+1
  7230    CMPW P2;PV
  7240    BCC MEMFULL ;=>P2 <LT> PV
  7250  *!LOOP
  7260      LDA PP ;P3 := PP-(PX),Y
  7270      SBC (PX),Y
  7280      STA P3
  7290      LDA PP+1
  7300      SBC #0
  7310      STA P3+1
  7320      LDA (PP),Y
  7330      STA (P3),Y
  7340      INCW PP
  7350      CMPW P1;PP
  7360  *!UNTIL <LO>
  7370  *!LOOP
  7380      LDA P2,X
  7390      STA PP,X
  7400      DEX
  7410  *!UNTIL <MI>
  7420    LDA (PX),Y
  7430    TAY
  7440  *!LOOP
  7450      DEY
  7460      LDA (PX),Y
  7470      STA (P3),Y
  7480      TYA
  7490  *!UNTIL <EQ>
  7500    BIT AUTOFLAG ;auto line?
  7510  *!IF <MI>
  7520  * yes
  7530  *!  LOOP
  7540        LDA AUTOLN+1,X ;AUTOLN := AUTOLN+AUTOINC
  7550        ADC AUTOINC+1,X
  7560        STA AUTOLN+1,X
  7570        INX
  7580  *!  UNTIL <NE>
  7590  *!ENDIF
  7600    BPL HE3E5 ;=>always
  7610
  7620    DB $00,$00,$00,$00 ;Z
  7630
  7640  MEMFULL
  7650    LDY #ErrMsg03 ;"MEM FULL"
  7660    BNE ERRMESS ;=>always
  7670
  7680  * tkn $0A ,
  7690  *   DEL 0,10
  7700
  7710  COMMA_DEL ;VO
  7720    JSR GET16BIT
  7730    MOVW P1;P3
  7740    JSR HE575
  7750    MOVW P1;P2
  7760    BNE HE395 ;=>always?
  7770
  7780  * tkn $09 DEL
  7790
  7800  DEL ;VO
  7810    JSR GET16BIT
  7820  HE38A
  7830    JSR HE56D
  7840    MOVW P3;P1
  7850  HE395
  7860    LDY #0
  7870  * memory move: P3<PP.P2 backwards
  7880  *!LOOP
  7890      CMPW PP;P2
  7900      BCS HE3B7 ;=>PP <HS> P2
  7910      DECW P2
  7920      DECW P3
  7930      LDA (P2),Y
  7940      STA (P3),Y
  7950  *!UNTIL <HS>
  7960  * always
  7970
  7980  HE3B7 ;solo
  7990    MOVW P3;PP
  8000    RTS
  8010  **
  8020
  8030  *!LOOP
  8040      JSR COUT ;print error message
  8050      INY
  8060  ERRORMESS ;print error message
  8070      LDA ErrorMsgs,Y ;routine entry point
  8080  *!UNTIL <PL>
  8090    ORA #$80
  8100    JMP COUT
  8110  *>
  8120
  8130  GETCMD
  8140    TYA
  8150    TAX
  8160    JSR NXTCHAR ;
  8170    TXA
  8180    TAY
  8190    LDA #"_" ;underline problem?
  8200    STA IN,Y
  8210    LDX #$FF
  8220    RTS
  8230  **
  8240
  8250    RTS ;Z
  8260  **
  8270
  8280  HE3DE
  8290    LDY #ErrMsg01 ;"TOO LONG"
  8300  ERRMESS ;print error message and goto mainline
  8310    JSR PRINTERR
  8320  *$E3E3 DOS 3.3 chains here when processing errors
  8330    BIT RUNFLAG
  8340  HE3E5
  8350  *!IF <PL>
  8360      JMP HE2B6
  8370  *!ENDIF
  8380    JMP HEB9A
  8390  *>
  8400
  8410  HE3ED ;solo
  8420    ROL
  8430    ADC #$A0
  8440    CMP IN,X
  8450    BNE HE448 ;=>
  8460    LDA (SYNPAG),Y
  8470    ASL
  8480  *!IF <PL>
  8490      DEY
  8500      LDA (SYNPAG),Y
  8510      BMI HE428 ;=>
  8520      INY
  8530  *!ENDIF
  8540    STX TXTNDX
  8550    TYA
  8560    PHA
  8570    LDX #0
  8580    LDA (SYNPAG,X)
  8590    TAX
  8600  *!LOOP
  8610      LSR
  8620      EOR #$40
  8630      ORA (SYNPAG),Y
  8640      CMP #$C0
  8650  *!  IF <HS>
  8660        INX
  8670  *!  ENDIF
  8680      INY
  8690  *!UNTIL <EQ>
  8700    PLA
  8710    TAY
  8720    TXA
  8730    JMP HF2F8
  8740  *>
  8750
  8760  HE41C
  8770    INC TOKNDX
  8780    LDX TOKNDX
  8790    BEQ HE3DE ;=>"TOO LONG"
  8800    STA IN,X
  8810  HE425
  8820    RTS
  8830  **
  8840
  8850  HE426 ;solo
  8860    LDX TXTNDX
  8870  HE428
  8880    LDA #BLANK+$80
  8890  *!LOOP
  8900      INX
  8910      CMP IN,X
  8920  *!UNTIL <LO>
  8930    LDA (SYNPAG),Y
  8940    AND #$3F
  8950    LSR
  8960    BNE HE3ED ;=>
  8970    LDA IN,X
  8980  *!IF <CC>
  8990      ADC #$3F
  9000      CMP #$1A
  9010      BCC HE4B1 ;=LO>
  9020  *!ENDIF
  9030    ADC #$4F
  9040    CMP #$0A
  9050    BCC HE4B1 ;=LO>
  9060  HE448
  9070    LDX SYNSTKDX
  9080  *!LOOP
  9090      INY
  9100      LDA (SYNPAG),Y
  9110      AND #$E0
  9120      CMP #$20
  9130      BEQ HE4CD ;=>
  9140      LDA TXTNDXSTK,X
  9150      STA TXTNDX
  9160      LDA TOKNDXSTK,X
  9170      STA TOKNDX
  9180  *!  LOOP
  9190        DEY
  9200        LDA (SYNPAG),Y
  9210        ASL ;dbl
  9220  *!  UNTIL <MI>
  9230      DEY
  9240      BCS HE49C ;=>
  9250      ASL ;dbl
  9260      BMI HE49C ;=>
  9270      LDY SYNSTKH,X
  9280      STY SYNPAG+1
  9290      LDY SYNSTKL,X
  9300      INX
  9310  *!UNTIL <MI>
  9320  HE470
  9330    BEQ HE425 ;=>RTS
  9340    CMP #$7E
  9350    BCS HE498 ;=HS>
  9360    DEX
  9370  *!IF <MI>
  9380      LDY #ErrMsg01 ;"TOO LONG"
  9390  * BUG FIX: ABOVE LINE SHOULD BE
  9400  *   LDY #ErrMsg04 ;"TOO MANY PARENS"
  9410  * REF: CALL-APPLE  MAR 1983  P.114
  9420      BPL HE4A6 ;=>always
  9430  *!ENDIF
  9440    STY SYNSTKL,X
  9450    LDY SYNPAG+1
  9460    STY SYNSTKH,X
  9470    LDY TXTNDX
  9480    STY TXTNDXSTK,X
  9490    LDY TOKNDX
  9500    STY TOKNDXSTK,X
  9510    AND #$1F
  9520    TAY
  9530    LDA SYNTABLNDX,Y
  9540  HE491
  9550    ASL ;dbl
  9560    TAY
  9570    LDA #>SYNTABL/2
  9580    ROL
  9590    STA SYNPAG+1
  9600  HE498
  9610  *!IF <EQ>
  9620      INY
  9630  *!ENDIF
  9640    INY
  9650  HE49C
  9660    STX SYNSTKDX
  9670    LDA (SYNPAG),Y
  9680    BMI HE426 ;=>
  9690  *!IF <EQ>
  9700      LDY #ErrMsg02 ;"SYNTAX"
  9710  HE4A6
  9720      JMP ERRMESS
  9730  *!ENDIF
  9740    CMP #$03
  9750    BCS HE470 ;=HS>
  9760    LSR ;half
  9770    LDX TXTNDX
  9780    INX
  9790  HE4B1
  9800    LDA IN,X
  9810    BCC HE4BA ;=>
  9820    CMP #DQT+$80
  9830    BEQ HE4C4 ;=>
  9840  HE4BA
  9850    CMP #"_" ;underline problem?
  9860    BEQ HE4C4 ;=>
  9870    STX TXTNDX
  9880  HE4C0
  9890  *!LOOP
  9900      JSR HE41C
  9910      INY
  9920  HE4C4
  9930      DEY
  9940      LDX SYNSTKDX
  9950  *!  LOOP
  9960        LDA (SYNPAG),Y
  9970        DEY
  9980        ASL
  9990        BPL HE49C ;=>
 10000  HE4CD
 10010        LDY SYNSTKH,X
 10020        STY SYNPAG+1
 10030        LDY SYNSTKL,X
 10040        INX
 10050        LDA (SYNPAG),Y
 10060        AND #%10011111
 10070  *!  UNTIL <EQ>
 10080      STA PCON
 10090      STA PCON+1
 10100      TYA
 10110      PHA
 10120      STX SYNSTKDX
 10130      LDY TOKNDXSTK-1,X
 10140      STY LEADBL
 10150      CLC
 10160  *!  LOOP
 10170        LDA #$0A
 10180        STA CHAR
 10190        LDX #0
 10200        INY
 10210        LDA IN,Y
 10220        AND #$0F
 10230  *!    LOOP
 10240          ADC PCON
 10250          PHA
 10260          TXA
 10270          ADC PCON+1
 10280          BMI HE517 ;=>
 10290          TAX
 10300          PLA
 10310          DEC CHAR
 10320  *!    UNTIL <EQ>
 10330        STA PCON
 10340        STX PCON+1
 10350        CPY TOKNDX
 10360  *!  UNTIL <EQ>
 10370      LDY LEADBL
 10380      INY
 10390      STY TOKNDX
 10400      JSR HE41C
 10410      PLA
 10420      TAY
 10430      LDA PCON+1
 10440  *!UNTIL <CC>
 10450  HE517
 10460    LDY #ErrMsg00 ;">32767"
 10470    BPL HE4A6 ;=>always
 10480
 10490  *-----------------------------
 10500  * Name      PRDEC
 10510  * Purpose   Print a 16-bit number in decimal.
 10520  * Input     Areg = high byte
 10530  *           Xreg = low byte
 10540  * Output
 10550  * Uses
 10560  * Calls
 10570  * Note
 10580
 10590  PRDEC
 10600    STA PCON+1
 10610    STX PCON
 10620    LDX #4
 10630    STX LEADBL
 10640  *!LOOP
 10650      LDA #"0"
 10660      STA CHAR
 10670  *!  LOOP
 10680        LDA PCON
 10690        CMP NUMLOW,X
 10700        LDA PCON+1
 10710        SBC NUMHI,X
 10720  *!  WHILE <HS>
 10730        STA PCON+1
 10740        LDA PCON
 10750        SBC NUMLOW,X
 10760        STA PCON
 10770        INC CHAR
 10780  *!  UNTIL <EQ>
 10790  *GETDIG
 10800      LDA CHAR
 10810      INX
 10820      DEX
 10830      BEQ PRDEC5 ;=>
 10840      CMP #"0"
 10850  *!  IF <NE>
 10860        STA LEADBL
 10870  *!  ENDIF
 10880  * if LEADBL is <MI> or LEADZR <NE> #0
 10890      BIT LEADBL
 10900      BMI PRDEC5 ;=>
 10910      LDA LEADZR
 10920      BEQ PRDEC6 ;=>
 10930  * then
 10940  PRDEC5 ;PRINT
 10950      JSR COUT
 10960      BIT AUTOFLAG ;auto line?
 10970  *!  IF <MI>
 10980        STA IN,Y
 10990        INY
 11000  *!  ENDIF
 11010  PRDEC6 ;NXTX
 11020      DEX
 11030  *!UNTIL <MI>
 11040    RTS
 11050  **
 11060
 11070  NUMLOW
 11080    DB 1
 11090    DB 10
 11100    DB 100
 11110    DB 1000
 11120    DB 10000
 11130
 11140  NUMHI
 11150    DB 1/$0100
 11160    DB 10/$0100
 11170    DB 100/$0100
 11180    DB 1000/$0100
 11190    DB 10000/$0100
 11200
 11210  HE56D
 11220    MOVW PP;P3
 11230  HE575
 11240    INX
 11250  HE576
 11260  *!LOOP
 11270  *   MOVW P3;P2
 11280      LDA P3+1 ;P2 := P3
 11290      STA P2+1
 11300      LDA P3
 11310      STA P2
 11320  *   CMPW P2;HIMEM
 11330      CMP HIMEM ;is P2 <HS> HIMEM?
 11340      LDA P2+1
 11350      SBC HIMEM+1
 11360  *!WHILE <LO>
 11370      LDY #1
 11380      LDA (P2),Y
 11390      SBC ACC
 11400      INY
 11410      LDA (P2),Y
 11420      SBC ACC+1
 11430  *!WHILE <LO>
 11440      LDY #0
 11450      LDA P3 ;P3 := P3.W + (P2).B
 11460      ADC (P2),Y
 11470      STA P3
 11480  *!  IF <CS>
 11490        INC P3+1
 11500        CLC
 11510  *!  ENDIF
 11520      INY
 11530      LDA ACC :is ACC+1 <HS> (P2),Y ?
 11540      SBC (P2),Y
 11550      INY
 11560      LDA ACC+1
 11570      SBC (P2),Y
 11580  *!UNTIL <LO>
 11590    RTS
 11600  **
 11610
 11620  * tkn $0B NEW
 11621  *   turn off AUTO
 11630  *   remove program
 11632  *   fall into CLR
 11640
 11650  NEW ;V
 11660    LSR AUTOFLAG ;manual
 11670    MOVW HIMEM;PP
 11680
 11690  * tkn $0C CLR
 11700  *   remove variables
 11702  *   remove FOR loops and GOSUBs
 11710
 11720  CLR ;V
 11730    MOVW LOMEM;PV
 11740    LDA #0
 11750    STA FORNDX ;no FORs
 11760    STA GOSUBNDX ;no GOSUBs
 11770    STA SYNPAG
 11780    LDA #0 ;Z
 11790    STA $1D ;Z
 11800    RTS
 11810  **
 11820
 11830    LDA SRCH ;Z
 11840  HE5CE
 11850    JMP MEMFULL
 11860  *>
 11870
 11880  *!LOOP
 11890  *!  LOOP
 11900        LDY #$FF
 11910  HE5D3
 11920        STY XSAVE
 11930  *!    LOOP
 11940          INY
 11950          LDA (PX),Y
 11960  *!      IF <PL>
 11970            CMP #$40
 11980            BNE HE646 ;=>EXIT LOOP
 11990            STA XSAVE
 12000  *!      ENDIF
 12010          CMP (SRCH),Y
 12020  *!    UNTIL <NE>
 12030  *!    LOOP
 12040          LDA (SRCH),Y
 12050  HE5E6
 12060          INY
 12070          LSR
 12080  *!    UNTIL <EQ>
 12090        LDA (SRCH),Y
 12100        PHA
 12110        INY
 12120        LDA (SRCH),Y
 12130        TAY
 12140        PLA
 12150  HE5F2
 12160        STA SRCH
 12170        STY SRCH+1
 12180        CMP PV
 12190  *!  UNTIL <EQ>
 12200      CPY PV+1
 12210  *!UNTIL <EQ>
 12220    LDY #0
 12230  *!LOOP
 12240  *!  LOOP
 12250        INY
 12260        LDA (PX),Y
 12270  *!  UNTIL <PL>
 12280      EOR #$40
 12290  *!UNTIL <NE>
 12300    TYA
 12310    ADC #$04
 12320    PHA
 12330    ADC SRCH
 12340    TAY
 12350    LDA SRCH+1
 12360    ADC #0
 12370    PHA
 12380    CPY PP
 12390    SBC PP+1
 12400    BCS HE5CE ;=HS>"MEM FULL" error
 12410    STY PV
 12420    PLA
 12430    STA PV+1
 12440    PLA
 12450    TAY
 12460    LDA #0
 12470    DEY
 12480    STA (SRCH),Y
 12490    DEY
 12500    STA (SRCH),Y
 12510    DEY
 12520    LDA PV+1
 12530    STA (SRCH),Y
 12540    DEY
 12550    LDA PV
 12560    STA (SRCH),Y
 12570    DEY
 12580    LDA #0
 12590  *!LOOP
 12600      STA (SRCH),Y
 12610      DEY
 12620      BMI HE5D3 ;=>
 12630      LDA (PX),Y
 12640  *!UNTIL <EQ>
 12650  HE640
 12660    LDA LOMEM
 12670    LDY LOMEM+1
 12680    BNE HE5F2 ;=>always
 12690
 12700  HE646
 12710    LDA (SRCH),Y
 12720    CMP #$40
 12730    BCS HE5E6 ;=HS>
 12740    STA NOUNSTKC-1,X
 12750    TYA
 12760    ADC #$03
 12770    PHA
 12780    ADC SRCH
 12790    JSR HE70A
 12800  *!LOOP
 12810      JSR GETVERB
 12820      DEY
 12830  *!UNTIL <EQ>
 12840    TYA
 12850    ADC SRCH+1
 12860    STA NOUNSTKH,X
 12870    PLA
 12880    BIT XSAVE
 12890    BMI HE684 ;=>
 12900    TAY
 12910    LDA #0
 12920    JSR HE70A
 12930    STA NOUNSTKH,X
 12940  *!LOOP
 12950      LDA (SRCH),Y
 12960      BPL HE682 ;=>EXIT LOOP
 12970      INC NOUNSTKH,X
 12980      INY
 12990  *!UNTIL <EQ>
 13000  * always
 13010
 13020    DB 9 ;Z
 13030
 13040  HE679 ;solo
 13050    LDA #0
 13060    STA IFFLAG ;pos
 13070    STA CRFLAG ;pos
 13080    LDX #$20
 13090  HE681
 13100    PHA
 13110  HE682
 13120    LDY #0
 13130  HE684
 13140    LDA (PX),Y
 13150  *!LOOP
 13160      BPL HE6A0 ;=>EXIT LOOP
 13170      ASL
 13180      BMI HE640 ;=>
 13190      JSR GETVERB
 13200      JSR HE708
 13210      JSR GETVERB
 13220      STA NOUNSTKC,X
 13230  HE696
 13240      BIT IFFLAG
 13250  *!  IF <MI>
 13260        DEX
 13270  *!  ENDIF
 13280  HE69B
 13290      JSR GETVERB
 13300  *!UNTIL <CC>
 13310  HE6A0
 13320    CMP #$28
 13330  *!IF <EQ>
 13340      LDA PX
 13350      JSR HE70A
 13360      LDA PX+1
 13370      STA NOUNSTKH,X
 13380      BIT IFFLAG
 13390      BMI HE6BC ;=>
 13400      LDA #$01
 13410      JSR HE70A
 13420      LDA #0
 13430      STA NOUNSTKH,X
 13440  *!  LOOP
 13450        INC NOUNSTKH,X
 13460  HE6BC
 13470        JSR GETVERB
 13480  *!  UNTIL <PL>
 13490      BCS HE696 ;=>
 13500  *!ENDIF
 13510    BIT IFFLAG
 13520  *!IF <MI>
 13530      CMP #$04
 13540      BCS HE69B ;=HS>
 13550      LSR IFFLAG ;pos
 13560  *!ENDIF
 13570    TAY
 13580    STA VERBNOW
 13590    LDA HE980,Y
 13600    AND #%01010101 ;even bits only
 13610    ASL
 13620    STA PRFLAG ;temp
 13630  HE6D8
 13640    PLA
 13650    TAY
 13660    LDA HE980,Y
 13670    AND #%10101010 ;odd bits only
 13680    CMP PRFLAG
 13690  *!IF <LO>
 13700      TYA
 13710      PHA
 13720      JSR HF3EB
 13730      LDA VERBNOW
 13740      BCC HE681 ;=LT> always
 13750  *!ENDIF
 13760
 13770  * BRANCH: get high/low then JSR
 13780
 13790    LDA VERBADRL,Y
 13800    STA ACC
 13810    LDA VERBADRH,Y
 13820    STA ACC+1
 13830    JSR HE6FC
 13840    JMP HE6D8
 13850  *>
 13860
 13870  HE6FC
 13880    JMP (ACC)
 13890  *>
 13900
 13910  GETVERB ;get next verb to use
 13920    INCW PX
 13930    LDA (PX),Y
 13940    RTS
 13950  **
 13960
 13970  HE708
 13980    STY NOUNSTKH-1,X
 13990  HE70A
 14000    DEX
 14010  *!IF <PL>
 14020      STA NOUNSTKL,X
 14030      RTS
 14040  *!ENDIF
 14050
 14060    LDY #$66 ;"PPED AT" ;Z?
 14070  HE712
 14080    JMP ERRMESS
 14090  *>
 14100
 14110  *---------
 14120  * Output    Yreg := 0
 14130
 14140  GET16BIT ;get a 16 bit value
 14150    LDY #0
 14160    LDA NOUNSTKL,X
 14170    STA ACC
 14180    LDA NOUNSTKC,X
 14190    STA ACC+1
 14200    LDA NOUNSTKH,X
 14210  *!IF <NE>
 14220      STA ACC+1
 14230      LDA (ACC),Y ;ACC := (ACC),Y
 14240      PHA ;save low byte
 14250      INY ;Yreg := 1
 14260      LDA (ACC),Y
 14270      STA ACC+1
 14280      PLA ;restore low byte
 14290      STA ACC
 14300      DEY ;Yreg := 0
 14310  *!ENDIF
 14320    INX
 14330    RTS
 14340  **
 14350
 14360  * tkn $16 =
 14370  *   num var logic op
 14380  *   IF X = 13 THEN END
 14390
 14400  HE733 ;VO
 14410    JSR HE74A
 14420
 14430  * tkn $37 NOT
 14440  *   numeric
 14450  *   IF NOT X THEN END
 14460
 14470  NOT ;V
 14480    JSR GET16BIT
 14490    TYA ;Areg := 0
 14500    JSR HE708
 14510    STA NOUNSTKC,X
 14520    CMP ACC
 14530  *!IF <EQ>
 14540      CMP ACC+1
 14550  *!  IF <EQ>
 14560        INC NOUNSTKL,X
 14570  *!  ENDIF
 14580  *!ENDIF
 14590    RTS
 14600  **
 14610
 14620  * tkn $17 #
 14630  *   num var logic op
 14640  *   IF X # 13 THEN END
 14650
 14660  * tkn $1B <>
 14670  *   num var logic op
 14680  *   IF X <> 13 THEN END
 14690
 14700  HE74A ;V
 14710    JSR SUBTRACT
 14720    JSR SGN
 14730
 14740  * tkn $31 ABS
 14750
 14760  ABS ;VO
 14770    JSR GET16BIT
 14780    BIT ACC+1
 14790    BMI HE772 ;=>
 14800  HE757 ;solo
 14810    DEX
 14820  HE758
 14830    RTS
 14840  **
 14850
 14860  * tkn $30 SGN
 14870
 14880  SGN ;V
 14890    JSR GET16BIT
 14900    LDA ACC+1 ;is ACC zero?
 14910  *!IF <EQ>
 14920      LDA ACC
 14930      BEQ HE757 ;=>yes
 14940  *!ENDIF
 14950    LDA #$FF
 14960    JSR HE708
 14970    STA NOUNSTKC,X
 14980    BIT ACC+1
 14990    BMI HE758 ;=>RTS
 15000
 15010  * tkn $36 -
 15020  *   unary sign of number
 15030  *   X = -5
 15040
 15050  NEGATE ;V
 15060    JSR GET16BIT
 15070  HE772
 15080    TYA ;Areg := 0
 15090    SEC
 15100    SBC ACC
 15110    JSR HE708
 15120    TYA
 15130    SBC ACC+1
 15140    BVC HE7A1 ;=>
 15150  HE77E
 15160    LDY #ErrMsg00 ;">32767"
 15170    BPL HE712 ;=>always
 15180
 15190  * tkn $13 -
 15200  *   num op
 15210  *   X=27-2
 15220
 15230  SUBTRACT ;V
 15240    JSR NEGATE ;negate, then add
 15250
 15260  * tkn $12 +
 15270  *   num op
 15280  *   X=27+2
 15290
 15300  ADDITION ;VO
 15310    JSR GET16BIT
 15320    MOVW ACC;AUX
 15330    JSR GET16BIT
 15340  HE793
 15350    CLC
 15360    LDA ACC
 15370    ADC AUX
 15380    JSR HE708
 15390    LDA ACC+1
 15400    ADC AUX+1
 15410    BVS HE77E ;=>
 15420  HE7A1
 15430    STA NOUNSTKC,X
 15440
 15450  * tkn $35 +
 15460  *   unary sign of number
 15470  *   X = +5
 15480
 15490  POSITIVE ;VO
 15500    RTS
 15510  **
 15520
 15530  * tkn $50 TAB
 15540
 15550  TAB ;VO
 15560    JSR GETBYTE
 15570    TAY
 15580  *!IF <EQ>
 15590      JMP HEECB ;range error?
 15600  *!ENDIF
 15610    DEY
 15620  HE7AE ;solo
 15630    JMP HF3F4
 15640  *>
 15650
 15660  * comma tab to next tab posn (every 8 spaces)
 15670
 15680  HE7B1
 15690    LDA CH ;get horiz posn
 15700    ORA #$07 ;set bits 0-2
 15710    TAY
 15720    INY ;incr, is it zero?
 15730  HE7B7 ;Z
 15740    BNE HE7AE ;=>no, adjust CH
 15750    INY ;yes, go to next tab posn
 15760    BNE HE7B1 ;=>always
 15770    BCS HE7B7 ;=>;Z
 15780    RTS ;Z
 15790  **
 15800
 15810    DB 0,0 ;Z
 15820
 15830  * tkn $49 ,
 15840  *   num print follows
 15850  *   PRINT A$,X
 15860
 15870  HE7C1 ;VO
 15880    JSR HE7B1
 15890
 15900  * tkn $46 ;
 15910  *   num print follows
 15920  *   PRINT A$ ; X
 15930
 15940  * tkn $62 PRINT
 15950  *   num value
 15960  *   PRINT 123: PRINT X: PRINT ASC(A$)
 15970
 15980  PRNTNUM ;VO branch
 15990    JSR GET16BIT
 16000  HE7C7 ;solo
 16010    LDA ACC+1 ;is it positive?
 16020  *!IF <MI>
 16030      LDA #"-" ;no, print minus sign
 16040      JSR COUT
 16050      JSR HE772
 16060      BVC PRNTNUM ;=>always
 16070  *!ENDIF
 16080    DEY ;Yreg := $FF
 16090    STY CRFLAG ;CRFLAG := $FF
 16100    STX ACC+1 ;save Xreg
 16110    LDX ACC
 16120    JSR PRDEC
 16130    LDX ACC+1 ;restore Xreg
 16140    RTS
 16150  **
 16160
 16170  * tkn $0D AUTO
 16180
 16190  AUTO ;VO
 16200    JSR GET16BIT
 16210    MOVW ACC;AUTOLN
 16220    DEY
 16230    STY AUTOFLAG ;AUTOFLAG := $FF
 16240    INY
 16250    LDA #10 ;default increment
 16260  HE7F3
 16270    STA AUTOINC
 16280    STY AUTOINC+1
 16290    RTS
 16300  **
 16310
 16320  * tkn $0E ,
 16330  *   AUTO 10,20
 16340
 16350  COMMA_AUTO ;VO
 16360    JSR GET16BIT
 16370    LDA ACC
 16380    LDY ACC+1
 16390    BPL HE7F3 ;=>always
 16400
 16410  * tkn $56 =
 16420  *   FOR X = 5 TO 10
 16430
 16440  * tkn $71 =
 16450  *   num - non-conditional
 16460  *   X = 5
 16470
 16480  HE801 ;V
 16490    JSR GET16BIT
 16500    LDA NOUNSTKL,X
 16510    STA AUX
 16520    LDA NOUNSTKH,X
 16530    STA AUX+1
 16540    LDA ACC
 16550    STA (AUX),Y
 16560    INY
 16570    LDA ACC+1
 16580    JMP HF207
 16590  *>
 16600
 16610  * tkn $25 THEN
 16620  *   IF X = 3 THEN Y = 5
 16630
 16640  * tkn $5E LET
 16650
 16660  LET ;VO
 16670    RTS
 16680  **
 16690
 16700  * tkn $00
 16710  *   internal begin-of-line
 16720
 16730  BEGIN_LINE ;VO
 16740    PLA
 16750    PLA
 16760
 16770  * tkn $03 :
 16780  *   statement separation
 16790  *   X = 5: A$ = "HELLO"
 16800
 16810  COLON ;VO
 16820    BIT CRFLAG
 16830    BPL HE822 ;=>RTS
 16840
 16850  * tkn $63 PRINT
 16860  *   dummy print
 16870  *   PRINT: PRINT
 16880
 16890  PRINT_CR ;VO
 16900    JSR CROUT
 16910
 16920  * tkn $47 ;
 16930  *   end of print statement
 16940  *   PRINT A$;
 16950
 16960  HE820 ;VO
 16970    LSR CRFLAG ;pos
 16980  HE822
 16990    RTS
 17000  **
 17010
 17020  * tkn $22 (
 17030  *   string DIM
 17040  *   DIM A$(X)
 17050
 17060  * tkn $34 (
 17070  *   num DIM
 17080  *   DIM X(5)
 17090
 17100  * tkn $38 (
 17110  *   logic statements and num operations
 17120  *   IF C AND (A=14 OR B=12) THEN X=(27+3)/13
 17130
 17140  * tkn $3F (
 17150  *   used after PEEK, RND, SGN, ABS, and PDL
 17160
 17170  HE823 ;V
 17180    LDY #$FF
 17190    STY PRFLAG ;PRFLAG := $FF
 17200
 17210  * tkn $72 )
 17220  *   the only right parenthesis token
 17230
 17240  RIGHT_PAREN ;VO
 17250    RTS
 17260  **
 17270
 17280  * tkn $60 IF
 17290
 17300  IF ;VO
 17310    JSR HEFCD
 17320  *!IF <NE>
 17330      LDA #$25 ;THEN token?
 17340      STA VERBNOW
 17350      DEY
 17360      STY IFFLAG
 17370  *!ENDIF
 17380    INX
 17390    RTS
 17400  **
 17410
 17420  * RUN without CLR
 17430  *   DOS 3.3 chains here to run a program
 17440
 17450  RUNWARM ;solo
 17460    LDA PP
 17470    LDY PP+1
 17480    BNE HE896 ;=>always
 17490
 17500  * tkn $5C GOSUB
 17510
 17520  GOSUB ;VO
 17530    LDY #ErrMsg08 ;"16 GOSUBS"
 17540    LDA GOSUBNDX
 17550    CMP #16 ;sixteen GOSUBs?
 17560    BCS HE8A2 ;=HS> yes, error
 17570    TAY
 17580    INC GOSUBNDX
 17590
 17600    LDA PX
 17610    STA STK_00,Y
 17620    LDA PX+1
 17630    STA STK_10,Y
 17640
 17650    LDA PR
 17660    STA STK_20,Y
 17670    LDA PR+1
 17680    STA STK_30,Y
 17690
 17700  * tkn $24 THEN
 17710  *   followed by a line number
 17720  *   IF X=3 THEN 10
 17730
 17740  * tkn $5F GOTO
 17750
 17760  GOTO ;V
 17770    JSR GET16BIT
 17780    JSR HE56D
 17790  *!IF <CS>
 17800      LDY #ErrMsg07 ;"BAD BRANCH"
 17810      BNE HE8A2 ;=>always
 17820  *!ENDIF
 17830    LDA P2
 17840    LDY P2+1
 17850
 17860  * main loop for running Integer BASIC programs
 17870
 17880  *!LOOP
 17890  *!  LOOP
 17900        STA PR
 17910        STY PR+1
 17920        CLC
 17930        ADC #$03
 17940  *!    IF <CS>
 17950          INY
 17960  *!    ENDIF
 17970  GETNEXT ;fetch next statement from text source
 17980        LDX #$FF
 17990        STX RUNFLAG ;neg
 18000        TXS
 18010        STA PX
 18020        STY PX+1
 18030        JSR HF02E ;test for ctrl-C & TRACE mode
 18040        LDY #0
 18050  HE883
 18060        JSR HE679 ;execute statement
 18070        BIT RUNFLAG
 18080        BPL END ;=>
 18090        CLC
 18100        LDY #0
 18110        LDA PR
 18120        ADC (PR),Y
 18130        LDY PR+1
 18140  *!    IF <CS>
 18150          INY
 18160  *!    ENDIF
 18170  HE896
 18180        CMP HIMEM
 18190  *!  UNTIL <EQ>
 18200      CPY HIMEM+1
 18210  *!UNTIL <EQ>
 18220    LDY #ErrMsg06 ;"NO END"
 18230    LSR RUNFLAG ;pos
 18240  HE8A2
 18250    JMP ERRMESS
 18260  *>
 18270
 18280  * tkn $5B RETURN
 18290
 18300  RETURN ;V
 18310    LDY #ErrMsg09 ;"BAD RETURN"
 18320    LDA GOSUBNDX
 18330    BEQ HE8A2 ;=>
 18340    DEC GOSUBNDX
 18350    TAY
 18360    LDA STK_20-1,Y
 18370    STA PR
 18380    LDA STK_30-1,Y
 18390    STA PR+1
 18400    LDX: STK_00-1,Y
 18410    LDA STK_10-1,Y
 18420  HE8BE
 18430    TAY
 18440    TXA
 18450    JMP GETNEXT
 18460  *>
 18470
 18480  STOPPED_AT
 18490    LDY #ErrMsg12 ;"STOPPED AT "
 18500    JSR ERRORMESS
 18510    LDY #1
 18520    LDA (PR),Y
 18530    TAX
 18540    INY
 18550    LDA (PR),Y
 18560    JSR PRDEC
 18570
 18580  * tkn $51 END
 18590
 18600  END ;V
 18610    JMP WARM
 18620  *>
 18630
 18640  *!LOOP
 18650  *!  LOOP
 18660        DEC FORNDX
 18670
 18680  * tkn $59 NEXT
 18690
 18700  * tkn $5A ,
 18710  *   NEXT X,Y
 18720
 18730  NEXT ;VO
 18740        LDY #ErrMsg11 ;"BAD NEXT"
 18750        LDA FORNDX
 18760  HE8DC
 18770        BEQ HE8A2 ;=>no more FORs
 18780        TAY
 18790        LDA NOUNSTKL,X
 18800        CMP STK_40-1,Y
 18810  *!  UNTIL <EQ>
 18820      LDA NOUNSTKH,X
 18830      CMP STK_50-1,Y
 18840  *!UNTIL <EQ>
 18850
 18860    LDA STK_60-1,Y
 18870    STA AUX
 18880    LDA STK_70-1,Y
 18890    STA AUX+1
 18900
 18910    JSR GET16BIT
 18920    DEX
 18930    JSR HE793
 18940    JSR HE801
 18950    DEX
 18960    LDY FORNDX
 18970    LDA STK_D0-1,Y
 18980    STA NOUNSTKC-1,X
 18990    LDA STK_C0-1,Y
 19000    LDY #0
 19010    JSR HE708
 19020    JSR SUBTRACT
 19030    JSR SGN
 19040    JSR GET16BIT
 19050    LDY FORNDX
 19060    LDA ACC
 19070  *!IF <NE>
 19080      EOR STK_70-1,Y
 19090      BPL HE937 ;=>
 19100  *!ENDIF
 19110
 19120    LDA STK_80-1,Y
 19130    STA PR
 19140    LDA STK_90-1,Y
 19150    STA PR+1
 19160
 19170    LDX STK_A0-1,Y
 19180    LDA STK_B0-1,Y
 19190    BNE HE8BE ;=>
 19200  HE937
 19210    DEC FORNDX
 19220    RTS
 19230  **
 19240
 19250  * tkn $55 FOR
 19260
 19270  FOR ;VO
 19280    LDY #ErrMsg10 ;"16 FORS"
 19290    LDA FORNDX
 19300    CMP #16 ;sixteen FORs?
 19310    BEQ HE8DC ;=>yes, error
 19320    INC FORNDX
 19330    TAY
 19340    LDA NOUNSTKL,X
 19350    STA STK_40,Y
 19360    LDA NOUNSTKH,X
 19370    JMP HF288
 19380  *>
 19390
 19400    RTS ;Z
 19410  **
 19420
 19430  * tkn $57 TO
 19440
 19450  TO ;VO
 19460    JSR GET16BIT
 19470    LDY FORNDX
 19480
 19490    LDA ACC
 19500    STA STK_C0-1,Y
 19510    LDA ACC+1
 19520    STA STK_D0-1,Y
 19530
 19540    LDA #<$0001
 19550    STA STK_60-1,Y
 19560    LDA #>$0001
 19570  HE966 ;solo
 19580    STA STK_70-1,Y
 19590
 19600    LDA PR
 19610    STA STK_80-1,Y
 19620    LDA PR+1
 19630    STA STK_90-1,Y
 19640
 19650    LDA PX
 19660    STA STK_A0-1,Y
 19670    LDA PX+1
 19680    STA STK_B0-1,Y
 19690    RTS
 19700  **
 19710
 19720   DB $20,$15 ;Z
 19730
 19740
 19750   PUT TABLE1
 19760  HE980
 19770   DB $00,$00,$00,$AB,$03,$03,$03,$03
 19780   DB $03,$03,$03,$03,$03,$03,$03,$03
 19790   DB $03,$03,$3F,$3F,$C0,$C0,$3C,$3C
 19800   DB $3C,$3C,$3C,$3C,$3C,$30,$0F,$C0
 19810   DB $C3,$FF,$55,$00,$AB,$AB,$03,$03
 19820   DB $FF,$FF,$55,$FF,$FF,$55,$CF,$CF
 19830   DB $CF,$CF,$CF,$FF,$55,$C6,$C6,$C6
 19840   DB $55,$F0,$F0,$CF,$CF,$55,$01,$55
 19850   DB $FF,$FF,$55,$03,$03,$03,$03,$03
 19860   DB $03,$03,$03,$03,$03,$03,$03,$03
 19870   DB $03,$03,$03,$03,$03,$03,$03,$03
 19880   DB $03,$03,$03,$03,$03,$00,$AB,$03
 19890   DB $57,$03,$03,$03,$03,$07,$03,$03
 19900   DB $03,$03,$03,$03,$03,$03,$03,$03
 19910   DB $03,$03,$AA,$FF,$03,$03,$03,$03
 19920   DB $03,$03,$03,$03,$03,$03,$03,$03
 19930
 19940  * token address tables (verb dispatch tables)
 19950
 19960  VERBADRL
 19970   DB <BEGIN_LINE,<$FFFF,<$FFFF,<COLON
 19980   DB <LOAD,<SAVE,<CON,<RUNNUM
 19990   DB <RUN,<DEL,<COMMA_DEL,<NEW
 20000   DB <CLR,<AUTO,<COMMA_AUTO,<MAN
 20010   DB <VHIMEM,<VLOMEM,<ADDITION,<SUBTRACT
 20020   DB <MULT,<DIVIDE,<HE733,<HE74A
 20030   DB <HF25B,<HF24E,<HF253,<HE74A
 20040   DB <HF249,<VAND,<VOR,<MOD
 20050   DB <EXP,<$FFFF,<HE823,<COMMA_SUBSTR
 20060   DB <GOTO,<LET,<HEFB6,<HEBCB
 20070   DB <$FFFF,<$FFFF,<PAREN_SUBSTR,<$FFFF
 20080   DB <$FFFF,<HEF24,<PEEK,<RND
 20090   DB <SGN,<ABS,<PDL,<$FFFF
 20100   DB <HE823,<POSITIVE,<NEGATE,<NOT
 20110   DB <HE823,<HE1D7,<HE21C,<LEN
 20120   DB <ASC,<SCRN,<COMMA_SCRN,<HE823
 20130   DB <$FFFF,<$FFFF,<HE121,<DIMSTR
 20140   DB <DIMNUM,<PRNTSTR,<PRNTNUM,<HE820
 20150   DB <HEE00,<HE7C1,<HF3BA,<SETTXT
 20160   DB <SETGR,<CALL,<DIMSTR,<DIMNUM
 20170   DB <TAB,<END,<HEFB6,<INPUT_PROMPT
 20180   DB <HEBAA,<FOR,<HE801,<TO
 20190   DB <STEP,<NEXT,<NEXT,<RETURN
 20200   DB <GOSUB,<$FFFF,<LET,<GOTO
 20210   DB <IF,<PRNTSTR,<PRNTNUM,<PRINT_CR
 20220   DB <POKE,<GETVAL255,<COLOR,<GETVAL255
 20230   DB <COMMA_PLOT,<GETVAL255,<COMMA_HLIN,<AT_HLIN
 20240   DB <GETVAL255,<COMMA_VLIN,<AT_VLIN,<IVTAB
 20250   DB <HE18C,<HE801,<RIGHT_PAREN,<$FFFF
 20260   DB <LISTNUM,<COMMA_LIST,<LIST,<POP
 20270   DB <NODSP_STR,<NODSP_NUM,<NOTRACE,<DSP_NUM
 20280   DB <DSP_STR,<TRACE,<PRSLOT,<INSLOT
 20290
 20300  VERBADRH
 20310   DB >BEGIN_LINE,>$FFFF,>$FFFF,>COLON
 20320   DB >LOAD,>SAVE,>CON,>RUNNUM
 20330   DB >RUN,>DEL,>COMMA_DEL,>NEW
 20340   DB >CLR,>AUTO,>COMMA_AUTO,>MAN
 20350   DB >VHIMEM,>VLOMEM,>ADDITION,>SUBTRACT
 20360   DB >MULT,>DIVIDE,>HE733,>HE74A
 20370   DB >HF25B,>HF24E,>HF253,>HE74A
 20380   DB >HF249,>VAND,>VOR,>MOD
 20390   DB >EXP,>$FFFF,>HE823,>COMMA_SUBSTR
 20400   DB >GOTO,>LET,>HEFB6,>HEBCB
 20410   DB >$FFFF,>$FFFF,>PAREN_SUBSTR,>$FFFF
 20420   DB >$FFFF,>HEF24,>PEEK,>RND
 20430   DB >SGN,>ABS,>PDL,>$FFFF
 20440   DB >HE823,>POSITIVE,>NEGATE,>NOT
 20450   DB >HE823,>HE1D7,>HE21C,>LEN
 20460   DB >ASC,>SCRN,>COMMA_SCRN,>HE823
 20470   DB >$FFFF,>$FFFF,>HE121,>DIMSTR
 20480   DB >DIMNUM,>PRNTSTR,>PRNTNUM,>HE820
 20490   DB >HEE00,>HE7C1,>HF3BA,>SETTXT
 20500   DB >SETGR,>CALL,>DIMSTR,>DIMNUM
 20510   DB >TAB,>END,>HEFB6,>INPUT_PROMPT
 20520   DB >HEBAA,>FOR,>HE801,>TO
 20530   DB >STEP,>NEXT,>NEXT,>RETURN
 20540   DB >GOSUB,>$FFFF,>LET,>GOTO
 20550   DB >IF,>PRNTSTR,>PRNTNUM,>PRINT_CR
 20560   DB >POKE,>GETVAL255,>COLOR,>GETVAL255
 20570   DB >COMMA_PLOT,>GETVAL255,>COMMA_HLIN,>AT_HLIN
 20580   DB >GETVAL255,>COMMA_VLIN,>AT_VLIN,>IVTAB
 20590   DB >HE18C,>HE801,>RIGHT_PAREN,>$FFFF
 20600   DB >LISTNUM,>COMMA_LIST,>LIST,>POP
 20610   DB >NODSP_STR,>NODSP_NUM,>NOTRACE,>DSP_NUM
 20620   DB >DSP_STR,>TRACE,>PRSLOT,>INSLOT
 20630
 20640  ErrorMsgs
 20650
 20660  ErrMsg00 = *-ErrorMsgs+$8100 ;00
 20670   DCI ">32767"
 20680
 20690  ErrMsg01 = *-ErrorMsgs+$8100 ;06
 20700   DCI "TOO LONG"
 20710
 20720  ErrMsg02 = *-ErrorMsgs+$8100 ;0E
 20730   DCI "SYNTAX"
 20740
 20750  ErrMsg03 = *-ErrorMsgs+$8100 ;14
 20760   DCI "MEM FULL"
 20770
 20780  ErrMsg04 = *-ErrorMsgs+$8100 ;1C
 20790   DCI "TOO MANY PARENS"
 20800
 20810  ErrMsg05 = *-ErrorMsgs+$8100 ;2B
 20820   DCI "STRING"
 20830
 20840  ErrMsg06 = *-ErrorMsgs+$8100 ;31
 20850   DCI "NO END"
 20860
 20870  ErrMsg07 = *-ErrorMsgs+$8100 ;37
 20880   DCI "BAD BRANCH"
 20890
 20900  ErrMsg08 = *-ErrorMsgs+$8100 ;41
 20910   DCI "16 GOSUBS"
 20920
 20930  ErrMsg09 = *-ErrorMsgs+$8100 ;4A
 20940   DCI "BAD RETURN"
 20950
 20960  ErrMsg10 = *-ErrorMsgs+$8100 ;54
 20970   DCI "16 FORS"
 20980
 20990  ErrMsg11 = *-ErrorMsgs+$8100 ;5B
 21000   DCI "BAD NEXT"
 21010
 21020  ErrMsg12 = *-ErrorMsgs+$8100 ;63
 21030   DCI "STOPPED AT "
 21040

 21050  ErrMsg13 = *-ErrorMsgs+$8100 ;6E
 21060   DCI "*** "
 21070
 21080  ErrMsg14 = *-ErrorMsgs+$8100 ;72
 21090   ASC " ERR"
 21100   DB  CR
 21110
 21120  ErrMsg15 = *-ErrorMsgs+$8100 ;77
 21130   DCI ">255"
 21140
 21150  ErrMsg16 = *-ErrorMsgs+$8100 ;7B
 21160   DCI "RANGE"
 21170
 21180  ErrMsg17 = *-ErrorMsgs+$8100 ;80
 21190   DCI "DIM"
 21200
 21210  ErrMsg18 = *-ErrorMsgs+$8100 ;83
 21220   DCI "STR OVFL"
 21230
 21240   ASC "\" ;8B
 21250   DB  CR
 21260
 21270  ErrMsg20 = *-ErrorMsgs+$8100 ;8D
 21280   ASC "RETYPE LINE"
 21290   DB  CR+$80
 21300
 21310  ErrMsg21 = *-ErrorMsgs+$8100 ;99
 21320   ASC '?'
 21330
 21340   PUT PART2
 21350
 21360  *continue run w/o deleting vars?
 21370
 21380  HEB9A ;solo
 21390    LSR RUNFLAG ;pos
 21400  *!IF <CS>
 21410      JMP STOPPED_AT
 21420  *!ENDIF
 21430    LDX ACC+1
 21440    TXS
 21450    LDX ACC
 21460    LDY #ErrMsg20 ;"RETYPE LINE",CR,"?"
 21470    BNE HEBAC ;=>always
 21480
 21490  * tkn $54 INPUT
 21500  *   num with no prompt
 21510  *   INPUT X
 21520
 21530  HEBAA ;VO branch
 21540    LDY #ErrMsg21 ;'?' for INPUT
 21550  HEBAC
 21560    JSR ERRORMESS
 21570    STX ACC
 21580    TSX
 21590    STX ACC+1
 21600    JSR HF366
 21610    STY TOKNDX
 21620    LDA #$FF
 21630    STA TXTNDX
 21640    ASL
 21650    STA RUNFLAG ;neg
 21660    LDX #$20
 21670    LDA #$15
 21680    JSR HE491
 21690    INC RUNFLAG
 21700    LDX ACC
 21710
 21720  * tkn $27 ,
 21730  *   num inputs
 21740  *   INPUT "QUANTITY",Q
 21750
 21760  HEBCB ;VO
 21770    LDY TXTNDX
 21780    ASL
 21790  *!LOOP
 21800      STA ACC
 21810      INY
 21820      LDA IN,Y
 21830      CMP #$80
 21840      BEQ HEBAA ;=>end of input?
 21850      EOR #"0"
 21860      CMP #10
 21870  *!UNTIL <LO>
 21880    INY
 21890    INY
 21900    STY TXTNDX
 21910    LDA IN,Y
 21920    PHA
 21930    LDA IN-1,Y
 21940    LDY #0
 21950    JSR HE708
 21960    PLA
 21970    STA NOUNSTKC,X
 21980    LDA ACC
 21990    CMP #$33
 22000  *!IF <EQ>
 22010      JSR NEGATE
 22020  *!ENDIF
 22030    JMP HE801
 22040  *>
 22050
 22060
 22070
 22080   DB $FF,$FF,$FF ;Z
 22090
 22100   PUT TABLE2
 22110  * token/syntax table
 22120
 22130  SYNTABL
 22140   DB $50
 22150
 22160   DB $20,$4F,$C0 ;Z
 22170   DB "T"+32,"A"-32 ;Z
 22180   DB "D"+32,"O"-32,"M"-32 ;Z
 22190   DB "R"+32,"O"-32 ;Z
 22200   DB "D"+32,"N"-32,"A"-32 ;Z
 22210   DB "P"+32,"E"-32,"T"-32,"S"-32 ;Z
 22220   DB "O"+32,"T"-32 ;Z
 22230   DB "N"+32,"E"-32,"H"-32,"T"-32 ;Z
 22240
 22250   DB $5C,$80,$00,$40
 22260   DB $60,$8D,$60,$8B,$7F,$1D,$20,$7E
 22270   DB $8C,$33,$00,$00,$60,$03,$BF,$12
 22280
 22290   DB $47,"#"-32,"N"-32,"I"-32 ;IN#
 22300   DB $67,"#"-32,"R"-32,"P"-32 ;PR#
 22310   DB "E"+32,"C"-32,"A"-32,"R"-32,"T"-32 ;TRACE
 22320   DB $79,"P"-32,"S"-32,"D"-32 ;DSP
 22330   DB $69,"P"-32,"S"-32,"D"-32 ;DSP
 22340   DB "E"+32,"C"-32,"A"-32,"R"-32,"T"-32,"O"-32,"N"-32 ;NOTRACE
 22350   DB $79,"P"-32,"S"-32,"D"-32,"O"-32,"N"-32 ;NODSP
 22360   DB $69,"P"-32,"S"-32,"D"-32,"O"-32,"N"-32 ;NODSP
 22370   DB "P"+32,"O"-32,"P"-32 ;POP
 22380   DB "T"+32,"S"-32,"I"-32,"L"-32 ;LIST
 22390   DB $60,","-32 ;
 22400   DB $20,"T"-32,"S"-32,"I"-32,"L"-32 ;LIST
 22410   DB 0
 22420   DB $40,$89
 22430   DB ")"+32 ;
 22440   DB $47,"="-32 ;
 22450   DB $17,$68,"="-32 ;
 22460   DB $0A,$58,$7B,$67,"B"-32,"A"-32,"T"-32,"V"-32 ;VTAB
 22470   DB $67,"T"-32,"A"-32 ;AT
 22480   DB $07,","-32 ;
 22490   DB $07,"N"-32,"I"-32,"L"-32,"V"-32 ;VLIN
 22500   DB $67,"T"-32,"A"-32 ;AT
 22510   DB $07,","-32 ;
 22520   DB $07,"N"-32,"I"-32,"L"-32,"H"-32 ;HLIN
 22530   DB $67,","-32 ;
 22540   DB $07,"T"-32,"O"-32,"L"-32,"P"-32 ;PLOT
 22550   DB $67,"="-32,"R"-32,"O"-32,"L"-32,"O"-32,"C"-32 ;COLOR=
 22560   DB $67,","-32 ;
 22570   DB $07,"E"-32,"K"-32,"O"-32,"P"-32 ;POKE
 22580   DB "T"+32,"N"-32,"I"-32,"R"-32,"P"-32 ;PRINT
 22590   DB $7F,$0E,$27,"T"-32,"N"-32,"I"-32,"R"-32,"P"-32 ;PRINT
 22600   DB $7F,$0E,$28,"T"-32,"N"-32,"I"-32,"R"-32,"P"-32 ;PRINT
 22610   DB $64,$07,"F"-32,"I"-32 ;IF
 22620   DB $67,"O"-32,"T"-32,"O"-32,"G"-32 ;GOTO
 22630   DB $78,"T"-32,"E"-32,"L"-32 ;LET
 22640   DB $6B,$7F,$02,"M"-32,"E"-32,"R"-32 ;REM
 22650   DB $67,"B"-32,"U"-32,"S"-32,"O"-32,"G"-32 ;GOSUB
 22660   DB "N"+32,"R"-32,"U"-32,"T"-32,"E"-32,"R"-32 ;RETURN
 22670   DB $7E,","-32 ;
 22680   DB $39,"T"-32,"X"-32,"E"-32,"N"-32 ;NEXT
 22690   DB $67,"P"-32,"E"-32,"T"-32,"S"-32 ;STEP
 22700   DB $27,"O"-32,"T"-32 ;TO
 22710   DB $07,"="-32 ;
 22720   DB $19,"R"-32,"O"-32,"F"-32 ;FOR
 22730   DB $7F,$05,$37,"T"-32,"U"-32,"P"-32,"N"-32,"I"-32 ;INPUT
 22740   DB $7F,$05,$28,"T"-32,"U"-32,"P"-32,"N"-32,"I"-32 ;INPUT
 22750   DB $7F,$05,$2A,"T"-32,"U"-32,"P"-32,"N"-32,"I"-32 ;INPUT
 22760   DB "D"+32,"N"-32,"E"-32 ;END (tkn $51)
 22770
 22780  SYNTABL2
 22790   DB 0
 22800   DB $47,"B"-32,"A"-32,"T"-32 ;TAB (tkn $50)
 22810   DB $7F,$0D,$30,"M"-32,"I"-32,"D"-32 ;DIM
 22820   DB $7F,$0D,$23,"M"-32,"I"-32,"D"-32 ;DIM
 22830   DB $67,"L"-32,"L"-32,"A"-32,"C"-32 ;CALL
 22840   DB "R"+32,"G"-32 ;GR
 22850   DB "T"+32,"X"-32,"E"-32,"T"-32 ;TEXT
 22860   DB 0 ;above are statements
 22870   DB $4D,","+32 ;
 22880   DB $67,","-32 ;
 22890   DB $68,","-32 ;
 22900   DB ";"+32 ;
 22910   DB $67,";"-32 ;
 22920   DB $68,";"-32 ;
 22930   DB $50,","-32 ;
 22940   DB $63,","-32 ;
 22950   DB $7F,$01,$51,$07,"("-32 ;
 22960   DB $29,$84
 22970   DB $80,"$"+32 ;
 22980   DB $19,$57,$71,$07,"("-32 ;
 22990   DB $14,$71,$07,","-32 ;
 23000   DB $07,"("-32,"N"-32,"R"-32,"C"-32,"S"-32 ;SCRN(
 23010   DB $71,$08,"("-32,"C"-32,"S"-32,"A"-32 ;ASC(
 23020   DB $71,$08,"("-32,"N"-32,"E"-32,"L"-32 ;LEN(
 23030   DB $68,"#"-32 ;
 23040   DB $08,$68,"="-32 ;
 23050   DB $08,$71,$07,"("-32 ;
 23060   DB $60,$75,"T"-32,"O"-32,"N"-32 ;NOT
 23070   DB $75,"-"-32 ;
 23080   DB $75,"+"-32 ;
 23090   DB $51,$07,"("-32,$19 ;
 23100   DB "X"-32,"D"-32,"N"-32,"R"-32
 23110   DB "L"+32,"D"-32,"P"-32 ;PDL
 23120   DB "S"+32,"B"-32,"A"-32 ;ABS
 23130   DB "N"+32,"G"-32,"S"-32 ;SGN
 23140   DB "D"+32,"N"-32,"R"-32 ;RND
 23150   DB "K"+32,"E"-32,"E"-32,"P"-32 ;PEEK
 23160   DB $51,$07,"("-32 ;
 23170   DB $39,$81,$C1,$4F,$7F,$0F,$2F
 23180   DB 0 ;above are functions
 23190   DB $51,$06,"("-32 ;
 23200   DB $29,"""+32 ;open quote
 23210   DB $0C,"""-32 ;close quote
 23220   DB $57,","-32 ;
 23230   DB $6A,","-32 ;
 23240   DB $42,"N"-32,"E"-32,"H"-32,"T"-32 ;THEN
 23250   DB $60,"N"-32,"E"-32,"H"-32,"T"-32 ;THEN
 23260   DB $4F,$7E,$1E,$35,","-32 ;
 23270   DB $27,$51,$07,"("-32 ;
 23280   DB $09,"+"-32
 23290   DB "^"+32 ;exponent
 23300   DB "D"+32,"O"-32,"M"-32 ;MOD
 23310   DB "R"+32,"O"-32 ;OR
 23320   DB "D"+32,"N"-32,"A"-32 ;AND
 23330   DB "<"+32 ;less than
 23340   DB ">"+32,"<"-32 ;not equal
 23350   DB "="+32,"<"-32 ;less or equal
 23360   DB ">"+32 ;greater than
 23370   DB "="+32,">"-32 ;greater or equal
 23380   DB "#"+32 ;not equal
 23390   DB "="+32 ;equal
 23400   DB "/"+32 ;divide
 23410   DB "*"+32 ;multiply
 23420   DB "-"+32 ;subtract
 23430   DB "+"+32 ;add
 23440   DB 0 ;above 4 are num ops
 23450   DB $47,":"-32,"M"-32,"E"-32,"M"-32,"O"-32,"L"-32 ;LOMEM:
 23460   DB $67,":"-32,"M"-32,"E"-32,"M"-32,"I"-32,"H"-32 ;HIMEM:
 23470   DB "N"+32,"A"-32,"M"-32 ;MAN
 23480   DB $60,","-32 ;comma for AUTO
 23490   DB $20,"O"-32,"T"-32,"U"-32,"A"-32 ;AUTO
 23500   DB "R"+32,"L"-32,"C"-32 ;CLR
 23510   DB "W"+32,"E"-32,"N"-32 ;NEW
 23520   DB $60,","-32 ;comma for DEL
 23530   DB $20,"L"-32,"E"-32,"D"-32 ;DEL
 23540   DB "N"+32,"U"-32,"R"-32 ;RUN
 23550   DB $60,"N"-32,"U"-32,"R"-32 ;RUN
 23560   DB "N"+32,"O"-32,"C"-32 ;CON
 23570   DB "E"+32,"V"-32,"A"-32,"S"-32 ;SAVE
 23580   DB "D"+32,"A"-32,"O"-32,"L"-32 ;LOAD
 23590  *above are commands
 23600   DB $7A,$7E,$9A,$22,$20
 23610   DB $00,$60,$03,$BF,$60,$03,$BF,$1F
 23620
 23630
 23640   PUT PART3
 23650  * tkn $48 ,
 23660  *   string prints
 23670  *   PRINT T,A$
 23680
 23690  HEE00 ;VO
 23700    JSR HE7B1
 23710
 23720  * tkn $45 ;
 23730  *   string prints
 23740  *   PRINT anytype ; string
 23750
 23760  * tkn $61 PRINT
 23770  *   string var or literal
 23780  *   PRINT A$: PRINT "HELLO"
 23790
 23800  PRNTSTR ;V
 23810    INX
 23820    INX
 23830    LDA NOUNSTKL-1,X
 23840    STA AUX
 23850    LDA NOUNSTKH-1,X
 23860    STA AUX+1
 23870    LDY NOUNSTKL-2,X
 23880  HEE0F ;*!LOOP
 23890      TYA
 23900      CMP NOUNSTKH-2,X
 23910      BCS HEE1D ;=HS>exit loop
 23920      LDA (AUX),Y
 23930      JSR COUT
 23940      INY
 23950      JMP HEE0F ;*!loop always
 23960  HEE1D
 23970    LDA #$FF
 23980    STA CRFLAG ;CRFLAG := $FF
 23990    RTS
 24000  **
 24010
 24020  * tkn $3B LEN(
 24030
 24040  LEN ;VO
 24050    INX
 24060    LDA #0
 24070    STA NOUNSTKH,X
 24080    STA NOUNSTKC,X
 24090    LDA NOUNSTKH-1,X
 24100    SEC
 24110    SBC NOUNSTKL-1,X
 24120    STA NOUNSTKL,X
 24130    JMP HE823
 24140  *>
 24150
 24160    DB $FF ;Z
 24170
 24180  GETBYTE
 24190    JSR GET16BIT
 24200    LDA ACC+1
 24210    BNE HI255ERR ;=>">255" error
 24220    LDA ACC
 24230    RTS
 24240  **
 24250
 24260  * tkn $68 ,
 24270  *   PLOT 20,15
 24280
 24290  COMMA_PLOT ;VO
 24300    JSR GETBYTE
 24310    LDY TXTNDX
 24320    CMP #48
 24330    BCS RANGERR ;=HS>
 24340    CPY #40
 24350    BCS RANGERR ;=HS>
 24360    JMP PLOT
 24370  *>
 24380
 24390  * tkn $66 COLOR=
 24400
 24410  COLOR ;VO
 24420    JSR GETBYTE
 24430    JMP SETCOL
 24440  *>
 24450
 24460  * tkn $0F MAN
 24470
 24480  MAN
 24490    LSR AUTOFLAG ;manual
 24500    RTS
 24510  **
 24520
 24530  * tkn $6F VTAB
 24540
 24550  IVTAB ;VO
 24560    JSR HF3B3
 24570    CMP #24
 24580    BCS RANGERR ;=HS>
 24590    STA CV
 24600    JMP VTAB
 24610  *>
 24620
 24630  HI255ERR
 24640    LDY #ErrMsg15 ;">255"
 24650  HEE65
 24660    JMP ERRMESS
 24670  *>
 24680
 24690  RANGERR
 24700    LDY #ErrMsg16 ;"RANGE"
 24710    BNE HEE65 ;=>always
 24720
 24730  * divide routine
 24740
 24750  HEE6C
 24760    JSR HE254
 24770    LDA AUX ;is AUX zero?
 24780  *!IF <EQ>
 24790      LDA AUX+1
 24800  *!  IF <EQ>
 24810      JMP HE77E ;yes, ">32767" error
 24820  *!  ENDIF
 24830  *!ENDIF
 24840  *!LOOP
 24850      ASL ACC
 24860      ROL ACC+1
 24870      ROL P3
 24880      ROL P3+1
 24890      CMPW P3;AUX
 24900  *!  IF <HS>
 24910        STA P3+1 ;P3 := P3-AUX
 24920        LDA P3
 24930        SBC AUX
 24940        STA P3
 24950        INC ACC
 24960  *!  ENDIF
 24970      DEY
 24980  *!UNTIL <EQ>
 24990    RTS
 25000  **
 25010
 25020    DB $FF,$FF,$FF,$FF,$FF,$FF ;Z
 25030
 25040  * tkn $4D CALL
 25050
 25060  CALL ;VO
 25070    JSR GET16BIT
 25080    JMP (ACC)
 25090  *>
 25100
 25110  * tkn $6A ,
 25120  *   HLIN 10,20 AT 30
 25130
 25140  COMMA_HLIN ;VO
 25150    JSR GETBYTE
 25160    CMP TXTNDX
 25170    BCC RANGERR ;=LO>
 25180    STA H2
 25190    RTS
 25200  **
 25210
 25220  * tkn $6B AT
 25230  *   HLIN 10,20 AT 30
 25240
 25250  AT_HLIN ;VO
 25260    JSR GETBYTE
 25270    CMP #48
 25280    BCS RANGERR ;=HS>
 25290    LDY TXTNDX
 25300    JMP HLINE
 25310  *>
 25320
 25330  * tkn $6D ,
 25340  *   VLIN 10,20 AT 30
 25350
 25360  COMMA_VLIN ;VO
 25370    JSR GETBYTE
 25380    CMP TXTNDX
 25390    BCC RANGERR ;=LO>
 25400    STA V2
 25410    RTS
 25420  **
 25430
 25440  * tkn $6E AT
 25450  *   VLIN 10,20 AT 30
 25460
 25470  AT_VLIN ;VO
 25480    JSR GETBYTE
 25490    CMP #40
 25500  HEECB
 25510    BCS RANGERR ;=HS>
 25520    TAY
 25530    LDA TXTNDX
 25540    JMP VLINE
 25550  *>
 25560
 25570  PRINTERR
 25580    TYA
 25590    TAX
 25600    LDY #ErrMsg13 ;"*** "
 25610    JSR ERRORMESS
 25620    TXA
 25630    TAY
 25640    JSR ERRORMESS
 25650    LDY #ErrMsg14 ;" ERR"
 25660    JMP PRTERR
 25670  *>
 25680
 25690  HEEE4
 25700    JSR HF23F
 25710  *!LOOP
 25720      ASL ACC
 25730      ROL ACC+1
 25740  *!UNTIL <PL>
 25750    BCS HEECB ;=>"RANGE" error
 25760  *!IF <EQ>
 25770      CMP ACC
 25780      BCS HEECB ;=HS>"RANGE" error
 25790  *!ENDIF
 25800    RTS
 25810  **
 25820
 25830  * tkn $2E PEEK
 25840  *   uses tkn $3F (
 25850
 25860  PEEK ;VO
 25870    JSR GET16BIT
 25880    LDA (ACC),Y
 25890    STY NOUNSTKC-1,X
 25900    JMP HE708
 25910  *>
 25920
 25930  * tkn $65 ,
 25940  *   POKE 20000,5
 25950
 25960  * tkn $67 PLOT
 25970
 25980  * tkn $69 HLIN
 25990
 26000  * tkn $6C VLIN
 26010
 26020  GETVAL255 ;VO
 26030    JSR GETBYTE
 26040    LDA ACC
 26050    STA TXTNDX
 26060    RTS
 26070  **
 26080
 26090  * tkn $64 POKE
 26100
 26110  POKE ;VO
 26120    JSR GET16BIT
 26130    LDA TXTNDX
 26140    STA (ACC),Y
 26150    RTS
 26160  **
 26170
 26180  * tkn $15 /
 26190  *   num op.  uses $38 (
 26200  *   A = 27 / 2
 26210
 26220  DIVIDE ;VO
 26230    JSR HEE6C
 26240    MOVW ACC;P3
 26250    JMP HE244
 26260  *>
 26270
 26280  * tkn $44 ,
 26290  *   next var in DIM is num
 26300  *   DIM X(5),A(5)
 26310
 26320  * tkn $4F DIM
 26330  *   num var.  uses tkn $22 (
 26340  *   DIM A(5)
 26350
 26360  DIMNUM ;VO
 26370    JSR HEEE4
 26380    JMP HE134
 26390  *>
 26400
 26410  * tkn $2D (
 26420  *   var array
 26430  *   X(12)
 26440
 26450  HEF24 ;VO
 26460    JSR HEEE4
 26470    LDY NOUNSTKH,X
 26480    LDA NOUNSTKL,X
 26490    ADC #$FE
 26500  *!IF <CC>
 26510      DEY
 26520  *!ENDIF
 26530    STA AUX
 26540    STY AUX+1
 26550    CLC
 26560    ADC ACC
 26570    STA NOUNSTKL,X
 26580    TYA
 26590    ADC ACC+1
 26600    STA NOUNSTKH,X
 26610    LDY #0
 26620    LDA NOUNSTKL,X
 26630    CMP (AUX),Y
 26640    INY
 26650    LDA NOUNSTKH,X
 26660    SBC (AUX),Y
 26670    BCS HEECB ;=HS>"RANGE" error
 26680    JMP HE823
 26690  *>
 26700
 26710  * tkn $2F RND
 26720  *   uses tkn $3F (
 26730
 26740  RND ;VO
 26750    JSR GET16BIT
 26760    LDA RNDL
 26770    JSR HE708
 26780    LDA RNDH
 26790  *!IF <EQ>
 26800      CMP RNDL
 26810      ADC #0
 26820  *!ENDIF
 26830    AND #$7F
 26840    STA RNDH
 26850    STA NOUNSTKC,X
 26860    LDY #$11
 26870  *!LOOP
 26880      LDA RNDH
 26890      ASL
 26900      CLC
 26910      ADC #$40
 26920      ASL
 26930      ROL RNDL
 26940      ROL RNDH
 26950      DEY
 26960  *!UNTIL <EQ>
 26970    LDA ACC
 26980    JSR HE708
 26990    LDA ACC+1
 27000    STA NOUNSTKC,X
 27010    JMP MOD
 27020  *>
 27030
 27040    JSR GET16BIT ;Z
 27050    LDY ACC ;is ACC <LO> LOMEM?
 27060    CPY LOMEM
 27070    LDA ACC+1
 27080    SBC LOMEM+1
 27090    BCC HEFAB ;=LO>yes
 27100    STY HIMEM ;HIMEM := ACC
 27110    LDA ACC+1
 27120    STA HIMEM+1
 27130  HEF93 ;Z
 27140    JMP NEW
 27150  *>
 27160
 27170    JSR GET16BIT ;Z
 27180    LDY ACC ;is ACC <HS> LOMEM?
 27190    CPY HIMEM
 27200    LDA ACC+1
 27210    SBC HIMEM+1
 27220    BCS HEFAB ;=HS>yes
 27230    STY LOMEM ;LOMEM := ACC
 27240    LDA ACC+1
 27250    STA LOMEM+1
 27260    BCC HEF93 ;=LO>always
 27270
 27280  HEFAB ;Z
 27290    JMP HEECB ;range error?
 27300  *>
 27310
 27320    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ;Z
 27330
 27340  * tkn $26 ,
 27350  *   string inputs
 27360  *   INPUT "WHO",W$
 27370
 27380  * tkn $52 INPUT
 27390  *   string with no prompt
 27400  *   INPUT S$
 27410
 27420  HEFB6 ;VO
 27430    JSR INPUTSTR
 27440    JMP HEFBF
 27450  *>
 27460
 27470  * tkn $53 INPUT
 27480  *   string or num with prompt
 27490  *   INPUT "WHO",W$: INPUT "QUANTITY",Q
 27500
 27510  INPUT_PROMPT ;VO
 27520    JSR PRNTSTR
 27530  HEFBF
 27540    LDA #$FF
 27550    STA TXTNDX
 27560    LDA #$80
 27570    STA IN
 27580    RTS
 27590  **
 27600
 27610  HEFC9
 27620    JSR NOT
 27630    INX
 27640  HEFCD ;solo
 27650    JSR NOT
 27660    LDA NOUNSTKL,X
 27670    RTS
 27680  **
 27690
 27700  * old 4K cold start
 27710
 27720  HEFD3 ;Z
 27730    LDA #0
 27740    STA LOMEM ;LOMEM := $0800
 27750    STA HIMEM ;HIMEM := $1000
 27760    LDA #>$0800
 27770    STA LOMEM+1
 27780    LDA #>$1000
 27790    STA HIMEM+1
 27800    JMP NEW
 27810  *>
 27820
 27830  HEFE4 ;solo
 27840    CMP NOUNSTKH,X
 27850  *!IF <EQ>
 27860      CLC
 27870  *!ENDIF
 27880    JMP HE102
 27890  *>
 27900
 27910  * tkn $08 RUN
 27920  *   run from first line of program
 27930
 27940  RUN ;VO
 27950    JSR CLR
 27960    JMP RUNWARM
 27970  *>
 27980
 27990  * tkn $07 RUN
 28000  *   RUN 100
 28010
 28020  RUNNUM ;VO
 28030    JSR CLR
 28040    JMP GOTO
 28050  *>
 28060
 28070  HEFF8 ;solo
 28080    CPX #$80
 28090  *!IF <EQ>
 28100      DEY
 28110  *!ENDIF
 28120    JMP HE00C
 28130  *>
 28140
 28142  * Cold start
 28150  *   set LOMEM, find HIMEM
 28152  *   fall into NEW
 28160
 28170  COLD
 28180    LDY #<$0800
 28190    STY NOUNSTKC
 28200    STY LOMEM ;LOMEM := $0800
 28210    STY HIMEM ;HIMEM := $0800
 28220    LDA #>$0800
 28230    STA LOMEM+1
 28240    STA HIMEM+1
 28250  *!LOOP
 28260      INC HIMEM+1 ;find top of RAM
 28270      LDA (HIMEM),Y
 28280      EOR #$FF
 28290      STA (HIMEM),Y
 28300      CMP (HIMEM),Y
 28310  *!WHILE <EQ>
 28320      EOR #$FF
 28330      STA (HIMEM),Y
 28340      CMP (HIMEM),Y
 28350  *!UNTIL <NE>
 28360    JMP NEW
 28370  *>
 28380
 28390  HF025 ;solo
 28400    JMP HF179
 28410  *>
 28420
 28430    JSR HF032 ;Z
 28440    JMP HE8BE ;Z
 28450  *>
 28460
 28470  HF02E ;solo
 28480    LDX PX
 28490    LDA PX+1
 28500  HF032 ;Z
 28510    LDY KBD ;get keypress
 28520    CPY #ETX+$80 ;is it ctrl-C?
 28530    BNE HF025 ;=>no
 28540    BIT KBDSTRB ;yes, clear keypress
 28550    STX NOUNSTKL
 28560    STA NOUNSTKL+1
 28570    MOVW PR;NOUNSTKH
 28580    JMP STOPPED_AT
 28590  *>
 28600
 28610    DB $FF,$FF ;Z
 28620
 28630  * tkn $10 HIMEM:
 28640
 28650  VHIMEM ;VO
 28660    JSR GET16BIT
 28670    STX XSAVE
 28680    LDX #0-2
 28690    SEC
 28700
 28710  *   MOVW ACC;P2
 28720  *   SUBW HIMEM;ACC;AUX
 28730
 28740  *!LOOP
 28750      LDA ACC+2,X
 28760      STA P2+2,X
 28770      LDA HIMEM+2,X
 28780      SBC ACC+2,X
 28790      STA AUX+2,X
 28800      INX
 28810  *!UNTIL <EQ>
 28820    BCC HF0AF ;=>
 28830    DEX ;Xreg := $FF
 28840
 28850  *   MOVW PP;P3
 28860  *   SUBW PP;AUX;P2
 28870
 28880  *!LOOP
 28890      LDA PP+1,X
 28900      STA P3+1,X
 28910      SBC AUX+1,X
 28920      STA P2+1,X
 28930      INX
 28940  *!UNTIL <NE>
 28950  *!IF <HS>
 28960      CMPW PV;P2
 28970      BCC HF08F ;=>PV <LO> P2
 28980  *!ENDIF
 28990  HF07C
 29000    JMP MEMFULL
 29010  *>
 29020
 29030  *!LOOP
 29040      LDA (P3),Y
 29050      STA (P2),Y
 29060      INCW P2
 29070      INCW P3
 29080  HF08F ;solo
 29090      CMPW P3;HIMEM
 29100  *!UNTIL <HS>
 29110  HF099 ;solo
 29120    LDX #0-2
 29130
 29140  *   MOVW P2;HIMEM
 29150  *   SUBW PP;AUX;PP
 29160
 29170  *!LOOP
 29180      LDA P2+2,X
 29190      STA HIMEM+2,X
 29200      LDA PP+2,X
 29210      SBC AUX+2,X
 29220      STA PP+2,X
 29230      INX
 29240  *!UNTIL <EQ>
 29250    LDX XSAVE
 29260    RTS
 29270  **
 29280
 29290  *!LOOP
 29300      LDA (HIMEM),Y
 29310      STA (ACC),Y
 29320  HF0AF ;solo
 29330      DECW ACC
 29340      DECW HIMEM
 29350      CMP PP ;is PP <LO> HIMEM?
 29360      LDA HIMEM+1
 29370      SBC PP+1
 29380  *!UNTIL <HS>
 29390    BCS HF099 ;=HS> always
 29400
 29410  * tkn $11 LOMEM:
 29420
 29430  VLOMEM ;VO
 29440    JSR GET16BIT
 29450    LDY ACC ;is ACC <HS> PP?
 29460    CPY #PP
 29470  * BUG FIX: ABOVE LINE SHOULD BE
 29480  *   CPY PP
 29490  * REF: NONE.  FOUND BY INSPECTION.
 29500    LDA ACC+1
 29510    SBC PP+1
 29520  HF0D4
 29530    BCS HF07C ;=HS> yes, MEM FULL error
 29540    STY LOMEM ;LOMEM := ACC
 29550    LDA ACC+1
 29560    STA LOMEM+1
 29570    JMP CLR
 29580  *>
 29590
 29600  * tkn $04 LOAD
 29610
 29620  LOAD ;VO
 29630    STX XSAVE
 29640    JSR SETHDR
 29650    JSR READ
 29660    LDX #$FF
 29670    SEC
 29680  *!LOOP
 29690      LDA HIMEM+1,X ;AUX := HIMEM-ACC
 29700      SBC ACC+1,X
 29710      STA AUX+1,X
 29720      INX
 29730  *!UNTIL <NE>
 29740    BCC HF07C ;=LO>MEM FULL error
 29750    CMPW PV;AUX
 29760    BCS HF0D4 ;=>PV <HS> AUX, MEM FULL error
 29770    LDA ACC ;is ACC zero?
 29780  *!IF <EQ>
 29790      LDA ACC+1
 29800      BEQ HF118 ;=>yes
 29810  *!ENDIF
 29820    MOVW AUX;PP
 29830    JSR SETPRG
 29840    JSR READ
 29850  HF115 ;solo
 29860    LDX XSAVE
 29870    RTS
 29880  **
 29890
 29900  HF118 ;solo
 29910    JSR BELL
 29920    JMP HF115
 29930  *>
 29940
 29950  SETHDR
 29960    LDY #$CE
 29970    STY A1 ;A1 := $00CE
 29980    INY
 29990    STY A2 ;A2 := $00CD
 30000    LDY #0
 30010    STY A1+1
 30020    STY A2+1
 30030    RTS
 30040  **
 30050
 30060  SETPRG
 30070  *!LOOP
 30080      LDA PP,X
 30090      STA A1,X
 30100      LDY HIMEM,X
 30110      STY A2,X
 30120      DEX
 30130  *!UNTIL <MI>
 30140    DECW A2
 30150    RTS
 30160  **
 30170
 30180    STX XSAVE ;Z
 30190
 30200  * tkn $05 SAVE
 30210
 30220  SAVE ;VO
 30230    SEC ;ACC := HIMEM-PP
 30240    LDX #0-1
 30250  *!LOOP
 30260      LDA HIMEM+1,X
 30270      SBC PP+1,X
 30280      STA ACC+1,X
 30290      INX
 30300  *!UNTIL <NE>
 30310    JSR SETHDR
 30320    JSR WRITE
 30330    LDX #$01
 30340    JSR SETPRG
 30350    LDA #$1A
 30360    JSR WRITE0
 30370    LDX XSAVE
 30380    RTS
 30390  **
 30400
 30410  PRTERR
 30420    JSR ERRORMESS
 30430    JMP BELL
 30440  *>
 30450
 30460  * tkn $77 POP
 30470
 30480  POP ;VO
 30490    LDA GOSUBNDX
 30500  *!IF <EQ>
 30510      JMP RETURN ;force error
 30520  *!ENDIF
 30530    DEC GOSUBNDX
 30540    RTS
 30550  **
 30560
 30570  * tkn $7D TRACE
 30580
 30590  TRACE ;VO
 30600    LDA #$FF
 30610    STA NOUNSTKC
 30620    RTS
 30630  **
 30640
 30650  * tkn $7A NOTRACE
 30660
 30670  NOTRACE ;VO
 30680    LSR NOUNSTKC ;clear bit 7
 30690    RTS
 30700  **
 30710
 30720  HF179 ;solo
 30730    BIT NOUNSTKC ;trace mode?
 30740  *!IF <MI>
 30750  HF17D
 30760  *yes, print line number
 30770      LDA #"#"
 30780      JSR COUT
 30790      LDY #1
 30800      LDA (PR),Y
 30810      TAX
 30820      INY
 30830      LDA (PR),Y
 30840      JSR PRDEC
 30850      LDA #BLANK+$80
 30860      JMP COUT
 30870  *>
 30880      LDA PR ;Z
 30890      LDY PR+1 ;Z
 30900  *!ENDIF
 30910    RTS
 30920  **
 30930
 30940
 30950
 30960  SYNTABLNDX ;indices into SYNTABL
 30970   DB $C1,$00,$7F,$D1,$CC,$C7,$CF,$CE
 30980   DB $C5,$9A,$98,$8D,$96,$95,$93,$BF
 30990   DB $B2,$32,$12,$0F,$BC,$B0,$AC,$BE
 31000   DB $35,$0C,$61,$30,$10,$0B,$DD,$FB
 31010
 31020
 31030
 31040  HF1B7 ;solo
 31050    LDY #0
 31060    JSR HE7C7
 31070    LDA #BLANK+$80
 31080    JMP COUT
 31090  *>
 31100
 31110    DB $00,$00,$00,$00,$00,$00,$00,$00 ;Z
 31120
 31130  HF1C9
 31140    LDY LOMEM
 31150    LDA LOMEM+1
 31160  *!LOOP
 31170      PHA
 31180      CPY AUX ;is LOMEM <HS> AUX?
 31190      SBC AUX+1
 31200      BCS HF1F0 ;=HS> yes, exit repeat
 31210      PLA
 31220      STY SRCH ;SRCH := LOMEM
 31230      STA SRCH+1
 31240      LDY #$FF
 31250  *!  LOOP
 31260  *!    LOOP
 31270          INY
 31280          LDA (SRCH),Y
 31290  *!    UNTIL <PL>
 31300        CMP #$40
 31310  *!  UNTIL <NE>
 31320      INY
 31330      INY
 31340      LDA (SRCH),Y
 31350      PHA
 31360      DEY
 31370      LDA (SRCH),Y
 31380      TAY
 31390      PLA
 31400  *!UNTIL <EQ>
 31410  HF1F0
 31420    PLA
 31430    LDY #0
 31440  *!LOOP
 31450      LDA (SRCH),Y
 31460      BMI HF1FC ;=>
 31470      LSR
 31480      BEQ HF202 ;=>
 31490      LDA #"$"
 31500  HF1FC
 31510      JSR COUT
 31520      INY
 31530  *!UNTIL <EQ>
 31540  HF202
 31550    LDA #"="
 31560    JMP COUT
 31570  *>
 31580
 31590  HF207 ;solo
 31600    STA (AUX),Y
 31610    INX
 31620    LDA NOUNSTKC-1,X
 31630    BEQ HF23E ;=>RTS
 31640    JMP HF3D5
 31650  *>
 31660
 31670    DB $A0 ;Z
 31680
 31690  HF212 ;solo
 31700  *!IF <PL>
 31710      LDA PR
 31720      LDY PR+1
 31730      JSR HF17D
 31740  *!ENDIF
 31750    JSR HF1C9
 31760    LDX XSAVE
 31770    JMP HF1B7
 31780  *>
 31790
 31800  HF223 ;solo
 31810    INX
 31820    INX
 31830    LDA NOUNSTKC-1,X
 31840    BEQ HF248 ;=>RTS
 31850    JMP HF3E0
 31860  *>
 31870
 31880  HF22C ;solo
 31890  *!IF <PL>
 31900      LDA PR
 31910      LDY PR+1
 31920      JSR HF17D
 31930  *!ENDIF
 31940    JSR HF1C9
 31950    LDX XSAVE
 31960    JMP HF409
 31970  *>
 31980
 31990    INX ;Z
 32000  HF23E
 32010    RTS
 32020  **
 32030
 32040  HF23F ;solo
 32050    JSR GET16BIT
 32060    INCW ACC
 32070  HF248
 32080    RTS
 32090  **
 32100
 32110  * tkn $1C <
 32120  *   IF X < 13 THEN END
 32130
 32140  HF249 ;V
 32150    JSR HF25B
 32160    BNE HF263 ;=>NOT
 32170
 32180  * tkn $19 >
 32190  *   IF X > 13 THEN END
 32200
 32210  HF24E ;VO
 32220    JSR HF253
 32230    BNE HF263 ;=>NOT
 32240
 32250  * tkn $1A <=
 32260  *   IF X <= 13 THEN END
 32270
 32280  HF253 ;V
 32290    JSR SUBTRACT
 32300    JSR NEGATE
 32310    BVC HF25E ;=>
 32320
 32330  * tkn $18 >=
 32340  *   IF X >= 13 THEN END
 32350
 32360  HF25B ;V
 32370    JSR SUBTRACT
 32380  HF25E
 32390    JSR SGN
 32400    LSR NOUNSTKL,X
 32410  HF263
 32420    JMP NOT
 32430  *>
 32440
 32450  * tkn $1D AND
 32460
 32470  VAND ;VO
 32480    JSR HEFC9
 32490    ORA NOUNSTKL-1,X
 32500    BPL HF272 ;=>always?
 32510
 32520  * tkn $1E OR
 32530
 32540  VOR ;VO
 32550    JSR HEFC9
 32560    AND NOUNSTKL-1,X
 32570  HF272 ;solo
 32580    STA NOUNSTKL,X
 32590    BPL HF263 ;=>NOT
 32600    JMP HEFC9
 32610  *>
 32620
 32630  * tkn $58 STEP
 32640
 32650  STEP ;VO
 32660    JSR GET16BIT
 32670    LDY FORNDX
 32680    LDA ACC
 32690    STA STK_60-1,Y
 32700    LDA ACC+1
 32710    JMP HE966
 32720  *>
 32730
 32740  HF288 ;solo
 32750    STA STK_50,Y
 32760  *!LOOP
 32770  *!  LOOP
 32780        DEY
 32790        BMI HF2DF ;=>RTS
 32800        LDA STK_40,Y
 32810        CMP NOUNSTKL,X
 32820  *!  UNTIL <EQ>
 32830      LDA STK_50,Y
 32840      CMP NOUNSTKH,X
 32850  *!UNTIL <EQ>
 32860    DEC FORNDX
 32870  *!LOOP
 32880      LDA STK_40+1,Y
 32890      STA STK_40,Y
 32900      LDA STK_50+1,Y
 32910      STA STK_50,Y
 32920      LDA STK_C0+1,Y
 32930      STA STK_C0,Y
 32940      LDA STK_D0+1,Y
 32950      STA STK_D0,Y
 32960      LDA STK_60+1,Y
 32970      STA STK_60,Y
 32980      LDA STK_70+1,Y
 32990      STA STK_70,Y
 33000      LDA STK_80+1,Y
 33010      STA STK_80,Y
 33020      LDA STK_90+1,Y
 33030      STA STK_90,Y
 33040      LDA STK_A0+1,Y
 33050      STA STK_A0,Y
 33060      LDA STK_A0+1,Y
 33070      STA STK_A0,Y
 33080  * BUG FIX: ABOVE TWO LINES SHOULD BE
 33090  *   LDA STK_B0+1,Y
 33100  *   STA STK_B0,Y
 33110  * REF: CHANGED IN DISK VERSION
 33120      INY
 33130      CPY FORNDX
 33140  *!UNTIL <HS>
 33150  HF2DF
 33160    RTS
 33170  **
 33180
 33190  * tkn $78 NODSP
 33200  *   string var
 33210
 33220  NODSP_STR ;VO
 33230    INX
 33240
 33250  * tkn $79 NODSP
 33260  *   num var
 33270
 33280  NODSP_NUM ;VO
 33290    LDA #0
 33300  HF2E3
 33310    PHA
 33320    LDA NOUNSTKL,X
 33330    SEC
 33340    SBC #$03
 33350    STA ACC
 33360    LDA NOUNSTKH,X
 33370    SBC #0
 33380    STA ACC+1
 33390    PLA
 33400    LDY #0
 33410    STA (ACC),Y
 33420    INX
 33430    RTS
 33440  **
 33450
 33460  HF2F8 ;solo
 33470    CMP #$85
 33480  *!IF <LO>
 33490      JMP HE4C0
 33500  *!ENDIF
 33510    LDY #$02
 33520    JMP HE448
 33530  *>
 33540
 33550  * tkn $7B DSP
 33560  *   string var
 33570
 33580  DSP_NUM ;VO
 33590    INX
 33600
 33610  * tkn $7C DSP
 33620  *   num var
 33630
 33640  DSP_STR ;VO
 33650    LDA #$01
 33660    BNE HF2E3 ;=>always
 33670
 33680    INX ;Z
 33690
 33700  * tkn $06 CON
 33710
 33720  CON ;VO
 33730    MOVW NOUNSTKH;PR
 33740    LDA NOUNSTKL
 33750    LDY NOUNSTKL+1
 33760    JMP GETNEXT
 33770  *>
 33780
 33790    LDA #$01 ;Z
 33800    BNE HF2E3 ;=>always
 33810
 33820  * tkn $3C ASC(
 33830
 33840  ASC ;VO
 33850    LDA NOUNSTKL,X
 33860    CMP NOUNSTKH,X
 33870  *!IF <HS>
 33880      JMP RANGERR
 33890  *!ENDIF
 33900    TAY
 33910    LDA NOUNSTKL+1,X
 33920    STA ACC
 33930    LDA NOUNSTKH+1,X
 33940    STA ACC+1
 33950    LDA (ACC),Y
 33960    LDY #0
 33970    INX
 33980    INX
 33990    JSR HE708
 34000    JMP HF404
 34010  *>
 34020
 34030  * tkn $32 PDL
 34040
 34050  PDL ;VO
 34060    JSR GETBYTE
 34070    STX XSAVE
 34080    AND #$03
 34090    TAX
 34100    JSR PREAD
 34110    LDX XSAVE
 34120    TYA
 34130    LDY #0
 34140    JSR HE708
 34150    STY NOUNSTKC,X
 34160    RTS
 34170  **
 34180
 34190  RDKEY ;solo
 34200    JSR NXTCHAR
 34210  HF354 ;solo
 34220    TXA
 34230    PHA
 34240  *!LOOP
 34250      LDA IN,X
 34260      CMP #ETX+$80 ;is it ctrl-C?
 34270  *!  IF <EQ>
 34280        JMP BASIC2
 34290  *!  ENDIF
 34300      DEX
 34310  *!UNTIL <MI>
 34320    PLA
 34330    TAX
 34340    RTS
 34350  **
 34360
 34370  HF366 ;solo
 34380    JSR HE280
 34390    TYA
 34400    TAX
 34410    JSR HF354
 34420    TXA
 34430    TAY
 34440    RTS
 34450  **
 34460
 34470  * tkn $20 ^
 34480
 34490  EXP ;VO
 34500    JSR GET16BIT
 34510    LDA ACC+1
 34520  *!IF <MI>
 34530      TYA ;Areg := 0
 34540      DEX
 34550      JSR HE708
 34560      STY NOUNSTKC,X
 34570  HF37F
 34580      RTS
 34590  *!ENDIF
 34600    STA SRCH+1 ;SRCH := ACC
 34610    LDA ACC
 34620    STA SRCH
 34630    JSR GET16BIT
 34640    MOVW ACC;SRCH2
 34650    LDA #$01
 34660    JSR HE708
 34670    STY NOUNSTKC,X
 34680  HF398 ;*!LOOP
 34690    LDA SRCH ;SRCH := SRCH-1
 34700  *!IF <EQ>
 34710      DEC SRCH+1 ;is SRCH negative?
 34720      BMI HF37F ;=>yes, RTS
 34730  *!ENDIF
 34740    DEC SRCH
 34750    LDA SRCH2
 34760    LDY #0
 34770    JSR HE708
 34780    LDA SRCH2+1
 34790    STA NOUNSTKC,X
 34800    JSR MULT
 34810    JMP HF398 ;*!loop forever
 34820  *>
 34830
 34840  HF3B3 ;solo
 34850    JSR GETBYTE
 34860    CLC ;Areg := Areg-1
 34870    ADC #$FF
 34880  HF3B9
 34890    RTS
 34900  **
 34910
 34920  * tkn $4A ,
 34930  *   end of PRINT statement
 34940  *   PRINT A$,
 34950
 34960  HF3BA ;VO
 34970    JSR HE7B1
 34980    LSR CRFLAG ;pos
 34990    RTS
 35000  **
 35010
 35020    STX RUNFLAG ;Z
 35030    TXS
 35040    JSR HF02E
 35050    JMP HE883
 35060  *>
 35070
 35080  * tkn $7E PR#
 35090
 35100  PRSLOT ;VO
 35110    JSR GETBYTE
 35120    STX XSAVE
 35130    JSR OUTPORT
 35140    LDX XSAVE
 35150    RTS
 35160  **
 35170
 35180    DB $FE ;Z
 35190
 35200  HF3D5 ;solo
 35210    BIT RUNFLAG
 35220    BPL HF3B9 ;=>RTS
 35230    STX XSAVE
 35240    BIT NOUNSTKC
 35250    JMP HF212
 35260  *>
 35270
 35280  HF3E0 ;solo
 35290    BIT RUNFLAG
 35300    BPL HF3B9 ;=>RTS
 35310    STX XSAVE
 35320    BIT NOUNSTKC
 35330    JMP HF22C
 35340  *>
 35350
 35360  HF3EB ;solo
 35370    LDY #0
 35380    JMP GETVERB
 35390  *>
 35400
 35410  *!LOOP
 35420      TAY
 35430      JSR CROUT
 35440  HF3F4 ;solo
 35450      TYA
 35460      SEC
 35470      SBC WNDWDTH
 35480  *!UNTIL <LO>
 35490    STY CH
 35500    RTS
 35510  **
 35520
 35530    DB $00,$00,$00 ;Z
 35540    DB $FF,$FF,$FF,$FF ;Z
 35550
 35560  HF404 ;solo
 35570    STY NOUNSTKC,X
 35580    JMP HE823
 35590  *>
 35600
 35610  HF409 ;solo
 35620    LDY #0
 35630    BEQ HF411 ;=>always
 35640  *!LOOP
 35650      JSR COUT
 35660      INY
 35670  HF411
 35680      LDA (AUX),Y
 35690  *!UNTIL <PL>
 35700    LDA #$FF
 35710    STA CRFLAG ;CRFLAG := $FF
 35720    RTS
 35730  **
 35740
 35750  * tkn $7F IN#
 35760
 35770  INSLOT ;VO
 35780    JSR GETBYTE
 35790    STX XSAVE
 35800    JSR INPORT
 35810    LDX XSAVE
 35820    RTS
 35830  **
 35840   LST OFF
