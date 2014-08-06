***************************
*			  *
*       RAMTEST:	  *
*			  *
*        BY WOZ		  *
*         6/77		  *
*			  *
*   COPYRIGHT 1987 BY:	  *
*   APPLE COMPUTER INC    *
*			  *
***************************

*
*      EQUATES
*
DATA   EQU   $0 TEST DATA $00 OR $FF
NDATA  EQU   $1 INVERSE TEST DATA.
TESTD  EQU   $2 GALLOP DATA.
R3L    EQU   $6 AUX ADR POINTER.
R3H    EQU   $7
R4L    EQU   $8 AUX ADR POINTER.
R4H    EQU   $9
R5L    EQU   $A AUX ADR POINTER.
R5H    EQU   $B
R6L    EQU   $C GALLOP BIT MASK.
R6H    EQU   $D ($0001 TO 2^N)
YSAV   EQU   $34 MONITOR SCAN INDEX.
A1H    EQU   $3D BEGIN TEST BLOCK ADR.
A2L    EQU   $3E LEN (PAGES) FROM MON.
SETCTLY EQU   $D5B0 ;SET UP CNTRL-Y LOCATION
PRBYTE EQU   $FDDA BYTE PRINT SUBR.
COUT   EQU   $FDED CHAR OUT SUBR.
PRERR  EQU   $FF2D PRINTS 'ERR-BELL'
BELL   EQU   $FF3A

*
*     RAMTEST:
*
       ORG   $D5BC
       OBJ   $A5BC
SETUP  LDA   #$C3
       LDY   #$D5
       JMP   SETCTLY
RAMTST LDA   #$0
       JSR   TEST
       LDA   #$FF
       JSR   TEST
       JMP   BELL
TEST   STA   DATA
       EOR   #$FF
       STA   NDATA
       LDA   A1H
       STA   R3H
       STA   R4H
       STA   R5H
       LDY   #$0
       STY   R3L
       STY   R4L
       STY   R5L
       LDX   A2L
       LDA   DATA
TEST01 STA   (R4L),Y
       INY   
       BNE   TEST01
       INC   R4H
       DEX   
       BNE   TEST01
       LDX   A2L
TEST02 LDA   (R3L),Y
       CMP   DATA
       BEQ   TEST03
       PHA   
       LDA   R3H
       JSR   PRBYTE
       TYA   
       JSR   PRBYSP
       LDA   DATA
       JSR   PRBYSP
       PLA   
       JSR   $D692    !!! Diverges - PRBYCR in listing. d692 is right after listing
TEST03 INY   
       BNE   TEST02
       INC   R3H
       DEX   
       BNE   TEST02
       LDX   A2L
TEST04 LDA   NDATA
       STA   (R5L),Y
       STY   R6H
       STY   R6L
       INC   R6L
TEST05 LDA   NDATA
       JSR   TEST6
       LDA   DATA
       JSR   TEST6
       ASL   R6L
       ROL   R6H
       LDA   R6H
       CMP   A2L
       BCC   TEST05
       LDA   DATA
       STA   (R5L),Y
       INC   R5L
       BNE   TEST04
       INC   R5H
       DEX   
       BNE   TEST04
RTS1   RTS   
TEST6  STA   TESTD
       LDA   R5L
       EOR   R6L
       STA   R4L
       LDA   R5H
       EOR   R6H
       STA   R4H
       LDA   TESTD
       STA   (R4L),Y
       LDA   (R5L),Y
       CMP   NDATA
       BEQ   RTS1
       PHA   
       LDA   R5H
       JSR   PRBYTE
       LDA   R5L
       JSR   PRBYSP
       LDA   NDATA
       STA   (R5L),Y
       JSR   PRBYSP
       PLA   
       JMP   $02CB    --- diverges. JSR PRBYSP in listing
       LDA   R4H
       JSR   PRBYTE
       LDA   R4L
       JSR   PRBYSP
       LDA   TESTD
PRBYCR JSR   PRBYSP
       JSR   PRERR
       LDA   #$8D
       JMP   COUT
PRBYSP JSR   PRBYTE
       LDA   #$A0
       JMP   COUT
