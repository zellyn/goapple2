                ***********************
                *                     *
                *  APPLE-II FLOATING  *
                *   POINT ROUTINES    *
                *                     *
                *  COPYRIGHT 1977 BY  *
                * APPLE COMPUTER INC. *
                *                     *
                * ALL RIGHTS RESERVED *
                *                     *
                *     S. WOZNIAK      *
                *                     *
                ***********************
                 TITLE "FLOATING POINT ROUTINES"
                SIGN      EPZ  $F3
                X2        EPZ  $F4
                M2        EPZ  $F5
                X1        EPZ  $F8
                M1        EPZ  $F9
                E         EPZ  $FC
                OVLOC     EQU  $3F5
                          ORG  $F425
F425: 18        ADD       CLC           CLEAR CARRY
F426: A2 02               LDX  #$2      INDEX FOR 3-BYTE ADD.
F428: B5 F9     ADD1      LDA  M1,X
F42A: 75 F5               ADC  M2,X     ADD A BYTE OF MANT2 TO MANT1
F42C: 95 F9               STA  M1,X
F42E: CA                  DEX           INDEX TO NEXT MORE SIGNIF. BYTE.
F42F: 10 F7               BPL  ADD1     LOOP UNTIL DONE.
F431: 60                  RTS           RETURN
F432: 06 F3     MD1       ASL  SIGN     CLEAR LSB OF SIGN.
F434: 20 37 F4            JSR  ABSWAP   ABS VAL OF M1, THEN SWAP WITH M2
F437: 24 F9     ABSWAP    BIT  M1       MANT1 NEGATIVE?
F439: 10 05               BPL  ABSWAP1  NO, SWAP WITH MANT2 AND RETURN.
F43B: 20 A4 F4            JSR  FCOMPL   YES, COMPLEMENT IT.
F43E: E6 F3               INC  SIGN     INCR SIGN, COMPLEMENTING LSB.
F440: 38        ABSWAP1   SEC           SET CARRY FOR RETURN TO MUL/DIV.
F441: A2 04     SWAP      LDX  #$4      INDEX FOR 4 BYTE SWAP.
F443: 94 FB     SWAP1     STY  E-1,X
F445: B5 F7               LDA  X1-1,X   SWAP A BYTE OF EXP/MANT1 WITH
F447: B4 F3               LDY  X2-1,X   EXP/MANT2 AND LEAVE A COPY OF
F449: 94 F7               STY  X1-1,X   MANT1 IN E (3 BYTES).  E+3 USED
F44B: 95 F3               STA  X2-1,X
F44D: CA                  DEX           ADVANCE INDEX TO NEXT BYTE
F44E: D0 F3               BNE  SWAP1    LOOP UNTIL DONE.
F450: 60                  RTS           RETURN
F451: A9 8E     FLOAT     LDA  #$8E     INIT EXP1 TO 14,
F453: 85 F8               STA  X1       THEN NORMALIZE TO FLOAT.
F455: A5 F9     NORM1     LDA  M1       HIGH-ORDER MANT1 BYTE.
F457: C9 C0               CMP  #$C0     UPPER TWO BITS UNEQUAL?
F459: 30 0C               BMI  RTS1     YES, RETURN WITH MANT1 NORMALIZED
F45B: C6 F8               DEC  X1       DECREMENT EXP1.
F45D: 06 FB               ASL  M1+2
F45F: 26 FA               ROL  M1+1     SHIFT MANT1 (3 BYTES) LEFT.
F461: 26 F9               ROL  M1
F463: A5 F8     NORM      LDA  X1       EXP1 ZERO?
F465: D0 EE               BNE  NORM1    NO, CONTINUE NORMALIZING.
F467: 60        RTS1      RTS           RETURN.
F468: 20 A4 F4  FSUB      JSR  FCOMPL   CMPL MANT1,CLEARS CARRY UNLESS 0
F46B: 20 7B F4  SWPALGN   JSR  ALGNSWP  RIGHT SHIFT MANT1 OR SWAP WITH
F46E: A5 F4     FADD      LDA  X2
F470: C5 F8               CMP  X1       COMPARE EXP1 WITH EXP2.
F472: D0 F7               BNE  SWPALGN  IF #,SWAP ADDENDS OR ALIGN MANTS.
F474: 20 25 F4            JSR  ADD      ADD ALIGNED MANTISSAS.
F477: 50 EA     ADDEND    BVC  NORM     NO OVERFLOW, NORMALIZE RESULT.
F479: 70 05               BVS  RTLOG    OV: SHIFT M1 RIGHT, CARRY INTO SIGN
F47B: 90 C4     ALGNSWP   BCC  SWAP     SWAP IF CARRY CLEAR,
                *       ELSE SHIFT RIGHT ARITH.
F47D: A5 F9     RTAR      LDA  M1       SIGN OF MANT1 INTO CARRY FOR
F47F: 0A                  ASL           RIGHT ARITH SHIFT.
F480: E6 F8     RTLOG     INC  X1       INCR X1 TO ADJUST FOR RIGHT SHIFT
F482: F0 75               BEQ  OVFL     EXP1 OUT OF RANGE.
F484: A2 FA     RTLOG1    LDX  #$FA     INDEX FOR 6:BYTE RIGHT SHIFT.
F486: 76 FF     ROR1      ROR  E+3,X
F488: E8                  INX           NEXT BYTE OF SHIFT.
F489: D0 FB               BNE  ROR1     LOOP UNTIL DONE.
F48B: 60                  RTS           RETURN.
F48C: 20 32 F4  FMUL      JSR  MD1      ABS VAL OF MANT1, MANT2
F48F: 65 F8               ADC  X1       ADD EXP1 TO EXP2 FOR PRODUCT EXP
F491: 20 E2 F4            JSR  MD2      CHECK PROD. EXP AND PREP. FOR MUL
F494: 18                  CLC           CLEAR CARRY FOR FIRST BIT.
F495: 20 84 F4  MUL1      JSR  RTLOG1   M1 AND E RIGHT (PROD AND MPLIER)
F498: 90 03               BCC  MUL2     IF CARRY CLEAR, SKIP PARTIAL PROD
F49A: 20 25 F4            JSR  ADD      ADD MULTIPLICAND TO PRODUCT.
F49D: 88        MUL2      DEY           NEXT MUL ITERATION.
F49E: 10 F5               BPL  MUL1     LOOP UNTIL DONE.
F4A0: 46 F3     MDEND     LSR  SIGN     TEST SIGN LSB.
F4A2: 90 BF     NORMX     BCC  NORM     IF EVEN,NORMALIZE PROD,ELSE COMP
F4A4: 38        FCOMPL    SEC           SET CARRY FOR SUBTRACT.
F4A5: A2 03               LDX  #$3      INDEX FOR 3 BYTE SUBTRACT.
F4A7: A9 00     COMPL1    LDA  #$0      CLEAR A.
F4A9: F5 F8               SBC  X1,X     SUBTRACT BYTE OF EXP1.
F4AB: 95 F8               STA  X1,X     RESTORE IT.
F4AD: CA                  DEX           NEXT MORE SIGNIFICANT BYTE.
F4AE: D0 F7               BNE  COMPL1   LOOP UNTIL DONE.
F4B0: F0 C5               BEQ  ADDEND   NORMALIZE (OR SHIFT RT IF OVFL).
F4B2: 20 32 F4  FDIV      JSR  MD1      TAKE ABS VAL OF MANT1, MANT2.
F4B5: E5 F8               SBC  X1       SUBTRACT EXP1 FROM EXP2.
F4B7: 20 E2 F4            JSR  MD2      SAVE AS QUOTIENT EXP.
F4BA: 38        DIV1      SEC           SET CARRY FOR SUBTRACT.
F4BB: A2 02               LDX  #$2      INDEX FOR 3-BYTE SUBTRACTION.
F4BD: B5 F5     DIV2      LDA  M2,X
F4BF: F5 FC               SBC  E,X      SUBTRACT A BYTE OF E FROM MANT2.
F4C1: 48                  PHA           SAVE ON STACK.
F4C2: CA                  DEX           NEXT MORE SIGNIFICANT BYTE.
F4C3: 10 F8               BPL  DIV2     LOOP UNTIL DONE.
F4C5: A2 FD               LDX  #$FD     INDEX FOR 3-BYTE CONDITIONAL MOVE
F4C7: 68        DIV3      PLA           PULL BYTE OF DIFFERENCE OFF STACK
F4C8: 90 02               BCC  DIV4     IF M2<E THEN DON'T RESTORE M2.
F4CA: 95 F8               STA  M2+3,X
F4CC: E8        DIV4      INX           NEXT LESS SIGNIFICANT BYTE.
F4CD: D0 F8               BNE  DIV3     LOOP UNTIL DONE.
F4CF: 26 FB               ROL  M1+2
F4D1: 26 FA               ROL  M1+1     ROLL QUOTIENT LEFT, CARRY INTO LSB
F4D3: 26 F9               ROL  M1
F4D5: 06 F7               ASL  M2+2
F4D7: 26 F6               ROL  M2+1     SHIFT DIVIDEND LEFT
F4D9: 26 F5               ROL  M2
F4DB: B0 1C               BCS  OVFL     OVFL IS DUE TO UNNORMED DIVISOR
F4DD: 88                  DEY           NEXT DIVIDE ITERATION.
F4DE: D0 DA               BNE  DIV1     LOOP UNTIL DONE 23 ITERATIONS.
F4E0: F0 BE               BEQ  MDEND    NORM. QUOTIENT AND CORRECT SIGN.
F4E2: 86 FB     MD2       STX  M1+2
F4E4: 86 FA               STX  M1+1     CLEAR MANT1 (3 BYTES) FOR MUL/DIV.
F4E6: 86 F9               STX  M1
F4E8: B0 0D               BCS  OVCHK    IF CALC. SET CARRY,CHECK FOR OVFL
F4EA: 30 04               BMI  MD3      IF NEG THEN NO UNDERFLOW.
F4EC: 68                  PLA           POP ONE RETURN LEVEL.
F4ED: 68                  PLA
F4EE: 90 B2               BCC  NORMX    CLEAR X1 AND RETURN.
F4F0: 49 80     MD3       EOR  #$80     COMPLEMENT SIGN BIT OF EXPONENT.
F4F2: 85 F8               STA  X1       STORE IT.
F4F4: A0 17               LDY  #$17     COUNT 24 MUL/23 DIV ITERATIONS.
F4F6: 60                  RTS           RETURN.
F4F7: 10 F7     OVCHK     BPL  MD3      IF POSITIVE EXP THEN NO OVFL.
F4F9: 4C F5 03  OVFL      JMP  OVLOC
                          ORG  $F63D
F63D: 20 7D F4  FIX1      JSR  RTAR
F640: A5 F8     FIX       LDA  X1
F642: 10 13               BPL  UNDFL
F644: C9 8E               CMP  #$8E
F646: D0 F5               BNE  FIX1
F648: 24 F9               BIT  M1
F64A: 10 0A               BPL  FIXRTS
F64C: A5 FB               LDA  M1+2
F64E: F0 06               BEQ  FIXRTS
F650: E6 FA               INC  M1+1
F652: D0 02               BNE  FIXRTS
F654: E6 F9               INC  M1
F656: 60        FIXRTS    RTS
F657: A9 00     UNDFL     LDA  #$0
F659: 85 F9               STA  M1
F65B: 85 FA               STA  M1+1
F65D: 60                  RTS
