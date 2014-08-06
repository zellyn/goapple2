*****************************
*			    *
*        TAPE VERIFY	    *
*			    *
*          JAN 78	    *
*          BY WOZ	    *
*			    *
*			    *
*****************************

*
*     TAPE VERIFY EQUATES
*
CHKSUM EQU   $2E
A1     EQU   $3C
HIMEM  EQU   $4C ;BASIC HIMEM POINTER
PP     EQU   $CA ;BASIC BEGIN OF PROGRAM
PRLEN  EQU   $CE ;BASIC PROGRAM LENGTH
XSAVE  EQU   $D8 ;PRESERVE X-REG FOR BASIC
HDRSET EQU   $F11E ;SETS TAPE POINTERS TO $CE.CF
PRGSET EQU   $F12C ;SETS TAPE POINTERS FOR PROGRAM
NXTA1  EQU   $FCBA ;INCREMENTS (A1) AND COMPARES TO (A2)
HEADR  EQU   $FCC9
RDBYTE EQU   $FCEC
RD2BIT EQU   $FCFA
RDBIT  EQU   $FCFD
PRA1   EQU   $FD92 ;PRINT (A1)-
PRBYTE EQU   $FDDA
COUT   EQU   $FDED
FINISH EQU   $FF26 ;CHECK CHECKSUM, RING BELL
PRERR  EQU   $FF2D

*
*       TAPE VERIFY ROUTINE
*
       ORG   $D535
       OBJ   $A535
VFYBSC STX   XSAVE
       SEC 
       LDX   #$FF
GETLEN LDA   HIMEM+1,X
       SBC   PP+1,X
       STA   PRLEN+1,X
       INX 
       BEQ   GETLEN
       JSR   HDRSET
       JSR   TAPEVFY
       LDX   #$01
       JSR   PRGSET
       JSR   TAPEVFY
       LDX   XSAVE
       RTS
*
* TAPE VERIFY RAM IMAGE (A1.A2)
*
TAPEVFY JSR   RD2BIT
       LDA   #$16
       JSR   HEADR
       STA   CHKSUM
       JSR   RD2BIT
VRFY2  LDY   #$24
       JSR   RDBIT
       BCS   VRFY2
       JSR   RDBIT
       LDY   #$3B
VRFY3  JSR   RDBYTE
       BEQ   EXTDEL
VFYLOOP EOR   CHKSUM
       STA   CHKSUM
       JSR   NXTA1
       LDY   #$34
       BCC   VRFY3
       JMP   FINISH
EXTDEL NOP 
       NOP 
       NOP 
       CMP   (A1,X)
       BEQ   VFYLOOP
       PHA 
       JSR   PRERR
       JSR   PRA1
       LDA   (A1),Y
       JSR   PRBYTE
       LDA   #$A0
       JSR   COUT
       LDA   #$A8
       JSR   COUT
       PLA 
       JSR   PRBYTE
       LDA   #$A9
       JSR   COUT
       LDA   #$8D
       JMP   COUT
