                1    ***********************
                2    *                     *
                3    *   APPLE-II PSEUDO   *
                4    * MACHINE INTERPRETER *
                5    *                     *
                6    *   COPYRIGHT 1977    *
                7    * APPLE COMPUTER INC  *
                8    *                     *
                9    * ALL RIGHTS RESERVED *
                10   *     S. WOZNIAK      *
                11   *                     *
                12   ***********************
                13                             ; TITLE "SWEET16 INTERPRETER"
                14   R0L      EQU   $0
                15   R0H      EQU   $1
                16   R14H     EQU   $1D
                17   R15L     EQU   $1E
                18   R15H     EQU   $1F
                19   SW16PAG  EQU   $F7
                20   SAVE     EQU   $FF4A
                21   RESTORE  EQU   $FF3F
                22            ORG   $F689
F689: 20 4A FF  23   SW16     JSR   SAVE       ;PRESERVE 6502 REG CONTENTS
F68C: 68        24            PLA
F68D: 85 1E     25            STA   R15L       ;INIT SWEET16 PC
F68F: 68        26            PLA              ;FROM RETURN
F690: 85 1F     27            STA   R15H       ;  ADDRESS
F692: 20 98 F6  28   SW16B    JSR   SW16C      ;INTERPRET AND EXECUTE
F695: 4C 92 F6  29            JMP   SW16B      ;ONE SWEET16 INSTR.
F698: E6 1E     30   SW16C    INC   R15L
F69A: D0 02     31            BNE   SW16D      ;INCR SWEET16 PC FOR FETCH
F69C: E6 1F     32            INC   R15H
F69E: A9 F7     33   SW16D    LDA   #SW16PAG
F6A0: 48        34            PHA              ;PUSH ON STACK FOR RTS
F6A1: A0 00     35            LDY   #$0
F6A3: B1 1E     36            LDA   (R15L),Y   ;FETCH INSTR
F6A5: 29 0F     37            AND   #$F        ;MASK REG SPECIFICATION
F6A7: 0A        38            ASL              ;DOUBLE FOR TWO BYTE REGISTERS
F6A8: AA        39            TAX              ;TO X REG FOR INDEXING
F6A9: 4A        40            LSR
F6AA: 51 1E     41            EOR   (R15L),Y   ;NOW HAVE OPCODE
F6AC: F0 0B     42            BEQ   TOBR       ;IF ZERO THEN NON-REG OP
F6AE: 86 1D     43            STX   R14H       ;INDICATE'PRIOR RESULT REG'
F6B0: 4A        44            LSR
F6B1: 4A        45            LSR              ;OPCODE*2 TO LSB'S
F6B2: 4A        46            LSR
F6B3: A8        47            TAY              ;TO Y REG FOR INDEXING
F6B4: B9 E1 F6  48            LDA   OPTBL-2,Y  ;LOW ORDER ADR BYTE
F6B7: 48        49            PHA              ;ONTO STACK
F6B8: 60        50            RTS              ;GOTO REG-OP ROUTINE
F6B9: E6 1E     51   TOBR     INC   R15L
F6BB: D0 02     52            BNE   TOBR2      ;INCR PC
F6BD: E6 1F     53            INC   R15H
F6BF: BD E4 F6  54   TOBR2    LDA   BRTBL,X    ;LOW ORDER ADR BYTE
F6C2: 48        55            PHA              ;ONTO STACK FOR NON-REG OP
F6C3: A5 1D     56            LDA   R14H       ;'PRIOR RESULT REG' INDEX
F6C5: 4A        57            LSR              ;PREPARE CARRY FOR BC, BNC.
F6C6: 60        58            RTS              ;GOTO NON-REG OP ROUTINE
F6C7: 68        59   RTNZ     PLA              ;POP RETURN ADDRESS
F6C8: 68        60            PLA
F6C9: 20 3F FF  61            JSR   RESTORE    ;RESTORE 6502 REG CONTENTS
F6CC: 6C 1E 00  62            JMP   (R15L)     ;RETURN TO 6502 CODE VIA PC
F6CF: B1 1E     63   SETZ     LDA   (R15L),Y   ;HIGH-ORDER BYTE OF CONSTANT
F6D1: 95 01     64            STA   R0H,X
F6D3: 88        65            DEY
F6D4: B1 1E     66            LDA   (R15L),Y   ;LOW-ORDER BYTE OF CONSTANT
F6D6: 95 00     67            STA   R0L,X
F6D8: 98        68            TYA              ;Y-REG CONTAINS 1
F6D9: 38        69            SEC
F6DA: 65 1E     70            ADC   R15L       ;ADD 2 TO PC
F6DC: 85 1E     71            STA   R15L
F6DE: 90 02     72            BCC   SET2
F6E0: E6 1F     73            INC   R15H
F6E2: 60        74   SET2     RTS
F6E3: 02        75   OPTBL    DFB   SET-1      ;1X
F6E4: F9        76   BRTBL    DFB   RTN-1      ;0
F6E5: 04        77            DFB   LD-1       ;2X
F6E6: 9D        78            DFB   BR-1       ;1
F6E7: 0D        79            DFB   ST-1       ;3X
F6E8: 9E        80            DFB   BNC-1      ;2
F6E9: 25        81            DFB   LDAT-1     ;4X
F6EA: AF        82            DFB   BC-1       ;3
F6EB: 16        83            DFB   STAT-1     ;5X
F6EC: B2        84            DFB   BP-1       ;4
F6ED: 47        85            DFB   LDDAT-1    ;6X
F6EE: B9        86            DFB   BM-1       ;5
F6EF: 51        87            DFB   STDAT-1    ;7X
F6F0: C0        88            DFB   BZ-1       ;6
F6F1: 2F        89            DFB   POP-1      ;8X
F6F2: C9        90            DFB   BNZ-1      ;7
F6F3: 5B        91            DFB   STPAT-1    ;9X
F6F4: D2        92            DFB   BM1-1      ;8
F6F5: 85        93            DFB   ADD-1      ;AX
F6F6: DD        94            DFB   BNM1-1     ;9
F6F7: 6E        95            DFB   SUB-1      ;BX
F6F8: 05        96            DFB   BK-1       ;A
F6F9: 33        97            DFB   POPD-1     ;CX
F6FA: E8        98            DFB   RS-1       ;B
F6FB: 70        99            DFB   CPR-1      ;DX
F6FC: 93        100           DFB   BS-1       ;C
F6FD: 1E        101           DFB   INR-1      ;EX
F6FE: E7        102           DFB   NUL-1      ;D
F6FF: 65        103           DFB   DCR-1      ;FX
F700: E7        104           DFB   NUL-1      ;E
F701: E7        105           DFB   NUL-1      ;UNUSED
F702: E7        106           DFB   NUL-1      ;F
F703: 10 CA     107  SET      BPL   SETZ       ;ALWAYS TAKEN
F705: B5 00     108  LD       LDA   R0L,X
                109  BK       EQU   *-1
F707: 85 00     110           STA   R0L
F709: B5 01     111           LDA   R0H,X      ;MOVE RX TO R0
F70B: 85 01     112           STA   R0H
F70D: 60        113           RTS
F70E: A5 00     114  ST       LDA   R0L
F710: 95 00     115           STA   R0L,X      ;MOVE R0 TO RX
F712: A5 01     116           LDA   R0H
F714: 95 01     117           STA   R0H,X
F716: 60        118           RTS
F717: A5 00     119  STAT     LDA   R0L
F719: 81 00     120  STAT2    STA   (R0L,X)    ;STORE BYTE INDIRECT
F71B: A0 00     121           LDY   #$0
F71D: 84 1D     122  STAT3    STY   R14H       ;INDICATE R0 IS RESULT NEG
F71F: F6 00     123  INR      INC   R0L,X
F721: D0 02     124           BNE   INR2       ;INCR RX
F723: F6 01     125           INC   R0H,X
F725: 60        126  INR2     RTS
F726: A1 00     127  LDAT     LDA   (R0L,X)    ;LOAD INDIRECT (RX)
F728: 85 00     128           STA   R0L        ;TO R0
F72A: A0 00     129           LDY   #$0
F72C: 84 01     130           STY   R0H        ;ZERO HIGH-ORDER R0 BYTE
F72E: F0 ED     131           BEQ   STAT3      ;ALWAYS TAKEN
F730: A0 00     132  POP      LDY   #$0        ;HIGH ORDER BYTE = 0
F732: F0 06     133           BEQ   POP2       ;ALWAYS TAKEN
F734: 20 66 F7  134  POPD     JSR   DCR        ;DECR RX
F737: A1 00     135           LDA   (R0L,X)    ;POP HIGH ORDER BYTE @RX
F739: A8        136           TAY              ;SAVE IN Y-REG
F73A: 20 66 F7  137  POP2     JSR   DCR        ;DECR RX
F73D: A1 00     138           LDA   (R0L,X)    ;LOW-ORDER BYTE
F73F: 85 00     139           STA   R0L        ;TO R0
F741: 84 01     140           STY   R0H
F743: A0 00     141  POP3     LDY   #$0        ;INDICATE R0 AS LAST RESULT REG
F745: 84 1D     142           STY   R14H
F747: 60        143           RTS
F748: 20 26 F7  144  LDDAT    JSR   LDAT       ;LOW-ORDER BYTE TO R0, INCR RX
F74B: A1 00     145           LDA   (R0L,X)    ;HIGH-ORDER BYTE TO R0
F74D: 85 01     146           STA   R0H
F74F: 4C 1F F7  147           JMP   INR        ;INCR RX
F752: 20 17 F7  148  STDAT    JSR   STAT       ;STORE INDIRECT LOW-ORDER
F755: A5 01     149           LDA   R0H        ;BYTE AND INCR RX.  THEN
F757: 81 00     150           STA   (R0L,X)    ;STORE HIGH-ORDER BYTE.
F759: 4C 1F F7  151           JMP   INR        ;INCR RX AND RETURN
F75C: 20 66 F7  152  STPAT    JSR   DCR        ;DECR RX
F75F: A5 00     153           LDA   R0L
F761: 81 00     154           STA   (R0L,X)    ;STORE R0 LOW BYTE @RX
F763: 4C 43 F7  155           JMP   POP3       ;INDICATE R0 AS LAST RSLT REG
F766: B5 00     156  DCR      LDA   R0L,X
F768: D0 02     157           BNE   DCR2       ;DECR RX
F76A: D6 01     158           DEC   R0H,X
F76C: D6 00     159  DCR2     DEC   R0L,X
F76E: 60        160           RTS
F76F: A0 00     161  SUB      LDY   #$0        ;RESULT TO R0
F771: 38        162  CPR      SEC              ;NOTE Y-REG = 13*2 FOR CPR
F772: A5 00     163           LDA   R0L
F774: F5 00     164           SBC   R0L,X
F776: 99 00 00  165           STA   R0L,Y      ;R0-RX TO RY
F779: A5 01     166           LDA   R0H
F77B: F5 01     167           SBC   R0H,X
F77D: 99 01 00  168  SUB2     STA   R0H,Y
F780: 98        169           TYA              ;LAST RESULT REG*2
F781: 69 00     170           ADC   #$0        ;CARRY TO LSB
F783: 85 1D     171           STA   R14H
F785: 60        172           RTS
F786: A5 00     173  ADD      LDA   R0L
F788: 75 00     174           ADC   R0L,X
F78A: 85 00     175           STA   R0L        ;R0+RX TO R0
F78C: A5 01     176           LDA   R0H
F78E: 75 01     177           ADC   R0H,X
F790: A0 00     178           LDY   #$0        ;R0 FOR RESULT
F792: F0 E9     179           BEQ   SUB2       ;FINISH ADD
F794: A5 1E     180  BS       LDA   R15L       ;NOTE X-REG IS 12*2!
F796: 20 19 F7  181           JSR   STAT2      ;PUSH LOW PC BYTE VIA R12
F799: A5 1F     182           LDA   R15H
F79B: 20 19 F7  183           JSR   STAT2      ;PUSH HIGH-ORDER PC BYTE
F79E: 18        184  BR       CLC
F79F: B0 0E     185  BNC      BCS   BNC2       ;NO CARRY TEST
F7A1: B1 1E     186  BR1      LDA   (R15L),Y   ;DISPLACEMENT BYTE
F7A3: 10 01     187           BPL   BR2
F7A5: 88        188           DEY
F7A6: 65 1E     189  BR2      ADC   R15L       ;ADD TO PC
F7A8: 85 1E     190           STA   R15L
F7AA: 98        191           TYA
F7AB: 65 1F     192           ADC   R15H
F7AD: 85 1F     193           STA   R15H
F7AF: 60        194  BNC2     RTS
F7B0: B0 EC     195  BC       BCS   BR
F7B2: 60        196           RTS
F7B3: 0A        197  BP       ASL              ;DOUBLE RESULT-REG INDEX
F7B4: AA        198           TAX              ;TO X REG FOR INDEXING
F7B5: B5 01     199           LDA   R0H,X      ;TEST FOR PLUS
F7B7: 10 E8     200           BPL   BR1        ;BRANCH IF SO
F7B9: 60        201           RTS
F7BA: 0A        202  BM       ASL              ;DOUBLE RESULT-REG INDEX
F7BB: AA        203           TAX
F7BC: B5 01     204           LDA   R0H,X      ;TEST FOR MINUS
F7BE: 30 E1     205           BMI   BR1
F7C0: 60        206           RTS
F7C1: 0A        207  BZ       ASL              ;DOUBLE RESULT-REG INDEX
F7C2: AA        208           TAX
F7C3: B5 00     209           LDA   R0L,X      ;TEST FOR ZERO
F7C5: 15 01     210           ORA   R0H,X      ;(BOTH BYTES)
F7C7: F0 D8     211           BEQ   BR1        ;BRANCH IF SO
F7C9: 60        212           RTS
F7CA: 0A        213  BNZ      ASL              ;DOUBLE RESULT-REG INDEX
F7CB: AA        214           TAX
F7CC: B5 00     215           LDA   R0L,X      ;TEST FOR NON-ZERO
F7CE: 15 01     216           ORA   R0H,X      ;(BOTH BYTES)
F7D0: D0 CF     217           BNE   BR1        ;BRANCH IF SO
F7D2: 60        218           RTS
F7D3: 0A        219  BM1      ASL              ;DOUBLE RESULT-REG INDEX
F7D4: AA        220           TAX
F7D5: B5 00     221           LDA   R0L,X      ;CHECK BOTH BYTES
F7D7: 35 01     222           AND   R0H,X      ;FOR $FF (MINUS 1)
F7D9: 49 FF     223           EOR   #$FF
F7DB: F0 C4     224           BEQ   BR1        ;BRANCH IF SO
F7DD: 60        225           RTS
F7DE: 0A        226  BNM1     ASL              ;DOUBLE RESULT-REG INDEX
F7DF: AA        227           TAX
F7E0: B5 00     228           LDA   R0L,X
F7E2: 35 01     229           AND   R0H,X      ;CHECK BOTH BYTES FOR NO $FF
F7E4: 49 FF     230           EOR   #$FF
F7E6: D0 B9     231           BNE   BR1        ;BRANCH IF NOT MINUS 1
F7E8: 60        232  NUL      RTS
F7E9: A2 18     233  RS       LDX   #$18       ;12*2 FOR R12 AS STACK POINTER
F7EB: 20 66 F7  234           JSR   DCR        ;DECR STACK POINTER
F7EE: A1 00     235           LDA   (R0L,X)    ;POP HIGH RETURN ADDRESS TO PC
F7F0: 85 1F     236           STA   R15H
F7F2: 20 66 F7  237           JSR   DCR        ;SAME FOR LOW-ORDER BYTE
F7F5: A1 00     238           LDA   (R0L,X)
F7F7: 85 1E     239           STA   R15L
F7F9: 60        240           RTS
F7FA: 4C C7 F6  241  RTN      JMP   RTNZ
