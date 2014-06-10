* MISCELLANEOUS ROUTINES AT $F699
* IN THE APPLE II INTEGER BASIC ROM
	ORG $F669
* ADDRESSES
ASAVE	EQU $56
XSAVE	EQU $57
YSAVE	EQU $58
PSAVE	EQU $59
STACK   EQU $100
*
SAVE    STY YSAVE
        STX XSAVE
        STA ASAVE
        PHP
        PLA
        STA PSAVE
        TSX
        INX
        INX
        LDA $0100,X
        ASL
        ASL
        ASL
        ASL
        RTS
RESTORE LDY YSAVE
        LDX XSAVE
        LDA PSAVE
        PHA
        LDA ASAVE
        PLP
        RTS
