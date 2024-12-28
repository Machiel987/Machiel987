; Game of life per byte logic

;--------------------------------------------------------
; Interfacing
;--------------------------------------------------------
    EXTERN _popCount
    EXTERN _evolve_w
    EXTERN _evolve_h
    EXTERN _evolve_changeListIn
    EXTERN _evolve_changeListOut
    GLOBAL _runByte
    GLOBAL _evolveBoard

;--------------------------------------------------------
; code
;--------------------------------------------------------
    SECTION code_compiler

;--------------------------------------------------------
; Main functionality
;--------------------------------------------------------
; Input : HL points to byte to process
; Output:  L new byte

; Work  : IX points to byte to process
;         HL _popCount
;          B out
;          C circum
;          D = 0

MACRO HLpopcountA offsetA,bitsA
    LD A,(IX+offsetA)
    AND A,bitsA
    LD E,A
    LD HL,_popCount
    ADD HL,DE
ENDM

MACRO HLpopcountAB offsetA,bitsA,offsetB,bitsB
    LD A,(IX+offsetA)
    AND A,bitsA
    LD E,A
    LD A,(IX+offsetB)
    AND A,bitsB
    OR A,E
    LD E,A
    LD HL,_popCount
    ADD HL,DE
ENDM

MACRO GOLtest mybit,setlabel,nextlabel
;   if (((val & pxNumToChar0) && (circum == 2)) || (circum == 3))
    CP A,3
    JR Z,setlabel
    CP A,2
    JR NZ,nextlabel
    BIT mybit,(IX)
    JR Z,nextlabel
setlabel:
;       out |= pxNumToCharN;
    SET mybit,B
nextlabel:
ENDM

_runByte:
    PUSH IX
    PUSH HL
    POP IX
    EXX
;   unsigned char out = 0x20;
    LD B,0x20
    LD D,0

_start0:
;   circum =  popCount[(adr[-81] & 0b01000000) | (adr[-1] & 0b00001010)];
    HLpopcountAB -81,0b01000000,-1,0b00001010
    LD C,(HL)
;   circum += popCount[(adr[-80] & 0b01010000) | (adr[0] & 0b00001110)];
    HLpopcountAB -80,0b01010000,0,0b00001110
    LD A,(HL)
    ADD A,C
;   if (((val & pxNumToChar0) && (circum == 2)) || (circum == 3))
;       out |= pxNumToChar0;
    GOLtest 0,_set0,_next0


;   circum =  popCount[(adr[-80] & 0b01010000) | (adr[0] & 0b00001101)];
    HLpopcountAB -80,0b01010000,0,0b00001101
    LD C,(HL)

;   circum += popCount[(adr[-79] & 0b00010000) | (adr[1] & 0b00000101)];
    HLpopcountAB -79,0b00010000,1,0b00000101
    LD A,(HL)
    ADD A,C

;   if (((val & pxNumToChar1) && (circum == 2)) || (circum == 3))
;       out |= pxNumToChar1;
    GOLtest 1,_set1,_next1


;   circum =  popCount[adr[-1] & 0b01001010];
    HLpopcountA -1,0b01001010
    LD C,(HL)

;   circum += popCount[adr[0]  & 0b01011011];
    HLpopcountA 0,0b01011011
    LD A,(HL)
    ADD A,C

;   if (((val & pxNumToChar2) && (circum == 2)) || (circum == 3))
;       out |= pxNumToChar2;
    GOLtest 2,_set2,_next2


;   circum =  popCount[adr[0] & 0b01010111];
    HLpopcountA 0,0b01010111
    LD C,(HL)

;   circum += popCount[adr[1] & 0b00010101];
    HLpopcountA 1,0b00010101
    LD A,(HL)
    ADD A,C

;   if (((val & pxNumToChar3) && (circum == 2)) || (circum == 3))
;       out |= pxNumToChar3;
    GOLtest 3,_set3,_next3


;   circum =  popCount[(adr[-1] & 0b01001000) | (adr[79] & 0b00000010)];
    HLpopcountAB -1,0b01001000,79,0b00000010
    LD C,(HL)

;   circum += popCount[(adr[0]  & 0b01001100) | (adr[80] & 0b00000011)];
    HLpopcountAB 0,0b01001100,80,0b00000011
    LD A,(HL)
    ADD A,C

;   if (((val & pxNumToChar4) && (circum == 2)) || (circum == 3))
;       out |= pxNumToChar4;
    GOLtest 4,_set4,_next4


;   circum =  popCount[(adr[0] & 0b00011100) | (adr[80] & 0b00000011)];
    HLpopcountAB 0,0b00011100,80,0b00000011
    LD C,(HL)

;   circum += popCount[(adr[1] & 0b00010100) | (adr[81] & 0b00000001)];
    HLpopcountAB 1,0b00010100,81,0b00000001
    LD A,(HL)
    ADD A,C

;   if (((val & pxNumToChar5) && (circum == 2)) || (circum == 3))
;       out |= pxNumToChar5;
    GOLtest 6,_set6,_next6

;   return out;
    LD A,B
    EXX
    POP IX
    RET


_evolveBoard:
    PUSH IX

    LD IX,(_evolve_changeListIn)
    LD IY,(_evolve_changeListOut)

    LD A,(_evolve_h)
    LD B,A

    OuterLoop:
    PUSH BC
    LD A,(_evolve_w)
    LD B,A

    InnerLoop:
    LD A,(IX)
    OR A,A
    JR Z,Done

    ; Preserves BC,DE,HL,IX
    CALL _runByte

    LD (DE),A

    SUB A,(HL)
    JR Z,Done

    EXX
    PUSH IY
    POP HL

    LD B,0
    LD A,(_evolve_w)
    LD C,A
    INC C
    INC C

    LD (HL),1
    INC HL
    LD (HL),1
    XOR A       ; Clear carry
    SBC HL,BC
    LD (HL),1
    DEC HL
    LD (HL),1
    DEC HL
    LD (HL),1
    ADD HL,BC
    LD (HL),1
    ADD HL,BC
    LD (HL),1
    INC HL
    LD (HL),1
    INC HL
    LD (HL),1
    EXX

    Done:
    INC HL
    INC DE
    INC IX
    INC IY

    DJNZ InnerLoop

    INC IX
    INC IX
    INC IY
    INC IY

    LD A,(_evolve_w)
    LD B,A
    LD A,80
    SUB B
    LD B,0
    LD C,A
    ADD HL,BC

    POP BC
    DJNZ OuterLoop

    POP IX

    RET
