    PROCESSOR 16F17146
#include <xc.inc>
INDEX     EQU  3
    PSECT udata_shr
result: DS  1
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main
    PSECT code,delta=2
main:
    movlw   low(squares)
    movwf   FSR0L
    movlw   high(squares) | 0x80
    movwf   FSR0H
    moviw   INDEX[FSR0]
    movwf   result
    goto    $
    PSECT data
squares:
    DB  0, 1, 4, 9, 16, 25, 36, 49
    END     resetVec
