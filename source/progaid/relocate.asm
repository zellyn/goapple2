****************************
*			   *
*     6502 RELOCATION	   *
*        SUBROUTINE	   *
*			   *
*   1. DEFINE BLOCKS	   *
*      *A4<A1.A2 ^Y	   *
*      (^Y IS CTRL-Y)	   *
*			   *
*   2. FIRST SEGMENT	   *
*      *A4<A1.A2 ^Y	   *
*         (IF CODE)	   *
*			   *
*      *A4<A1.A2M	   *
*         (IF MOVE)	   *
*			   *
*   3. SUBSEQUENT SEGMENTS *
*      *.A2 ^Y OR *.A2M	   *
*			   *
*     WOZ  11-10-77	   *
*   APPLE COMPUTER INC.	   *
*			   *
****************************

*
*    RELOCATION SUBROUTINE EQUATES
*
R1L    EQU   $02 SWEET 16 REG 1.
INST   EQU   $0B 3-BYTE INST FIELD.
LENGTH EQU   $2F LENGTH CODE
YSAV   EQU   $34 CMND BUF POINTER
A1L    EQU   $3C APPLE-II MON PARAM AREA.
A4L    EQU   $42 APPLE-II MON PARAM REG 4
IN     EQU   $0200
SW16   EQU   $F689 ;SWEET 16 ENTRY
INSDS2 EQU   $F88E ;DISASSEMBLER ENTRY
NXTA4  EQU   $FCB4 POINTER INCR SUBR
FRMBEG EQU   $01 SOURCE BLOCK BEGIN
FRMEND EQU   $02 SOURCE BLOCK END
TOBEG  EQU   $04 DEST BLOCK BEGIN
ADR    EQU   $06 ADR PART OF INST.

*
*   6502 RELOCATION SUBROUTINE
*
       ORG   $D4DC
       OBJ   $A4DC
RELOC  LDY   YSAV
       LDA   IN,Y
       CMP   #$AA
       BNE   RELOC2
       INC   YSAV
       LDX   #$07
INIT   LDA   A1L,X
       STA   R1L,X
       DEX 
       BPL   INIT
       RTS 
RELOC2 LDY   #$02
GETINS LDA   (A1L),Y
       STA   INST,Y
       DEY 
       BPL   GETINS
       JSR   INSDS2
       LDX   LENGTH
       DEX 
       BNE   XLATE
       LDA   INST
       AND   #$0D
       BEQ   STINST
       AND   #$08
       BNE   STINST
       STA   INST+2
XLATE  JSR   SW16
       LD    FRMEND
       CPR   ADR
       BNC   SW16RT
       LD    ADR
       SUB   FRMBEG
       BNC   SW16RT
       ADD   TOBEG
       ST    ADR
SW16RT RTN
STINST LDX   #$00
STINS2 LDA   INST,X
       STA   (A4L),Y
       INX 
       JSR   NXTA4
       DEC   LENGTH
       BPL   STINS2
       BCC   RELOC2
       RTS 
