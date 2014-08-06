

********************************
*
* MUSIC SUBROUTINE
*
* GARY J. SHANNON
*
********************************
       ORG   $D717
*
* ZERO PAGE WORK AREAS
* PARAMETER PASSING AREAS
*
DOWNTIME EQU   $0
UPTIME EQU   $1
LENGTH EQU   $2
VOICE  EQU   $2FD
LONG   EQU   $2FE
NOTE   EQU   $2FF
SPEAKER EQU   $C030
ENTRY  JMP LOOKUP

PLAY   LDY   UPTIME
       LDA   SPEAKER
PLAY2  INC   LENGTH
       BNE   PATH1
       INC   LENGTH+1
       BNE   PATH2
       RTS   
PATH1  NOP   
       JMP   PATH2
PATH2  DEY   
       BEQ   DOWN
       JMP   PATH3
PATH3  BNE   PLAY2
DOWN   LDY   DOWNTIME
       LDA   SPEAKER
PLAY3  INC   LENGTH
       BNE   PATH4
       INC   LENGTH+1
       BNE   PATH5
       RTS   
PATH4  NOP   
       JMP   PATH5
PATH5  DEY   
       BEQ   PLAY
       JMP   PATH6
PATH6  BNE   PLAY3
LOOKUP LDA   NOTE
       ASL   
       TAY   
       LDA   NOTES,Y
       STA   DOWNTIME
       LDA   VOICE
SHIFT  LSR   
       BEQ   DONE
       LSR   DOWNTIME
       BNE   SHIFT
DONE   LDA   NOTES,Y
       SEC   
       SBC   DOWNTIME
       STA   UPTIME
       INY   
       LDA   NOTES,Y
       ADC   DOWNTIME
       STA   DOWNTIME
       LDA   #$0
       SEC   
       SBC   LONG
       STA   LENGTH+1
       LDA   #$0
       STA   LENGTH
       LDA   UPTIME
       BNE   PLAY
REST   NOP   
       NOP   
       JMP   REST2
REST2  INC   LENGTH
       BNE   REST3
       INC   LENGTH+1
       BNE   REST4
       RTS   
REST3  NOP   
       JMP   REST4
REST4  BNE   REST
NOTES  HEX   00,00,F6,F6,E8,E8,DB,DB
       HEX   CF,CF,C3,C3,B8,B8,AE,AE
       HEX   A4,A4,9B,9B,92,92,8A,8A
       HEX   82,82,7B,7B,74,74,6D,6E
       HEX   67,68,61,62,5C,5C,57,57
       HEX   52,52,4D,4E,49,49,45,45
       HEX   41,41,3D,3E,3A,3A,36,37
       HEX   33,34,30,31,2E,2E,2B,2C
       HEX   29,29,26,27,24,25,22,23
       HEX   20,21,1E,1F,1D,1D,1B,1C
       HEX   1A,1A,18,19,17,17,15,16
       HEX   14,15,13,14,12,12,11,11
       HEX   10,10,0F,10,0E,0F
