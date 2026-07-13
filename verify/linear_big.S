    PROCESSOR 16F17146
#include <xc.inc>

#define BIG_SIZE 200
    DLABS   1,0x20,BIG_SIZE,bigBuf

    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main

    PSECT code
main:
    movlw   low(bigBuf)
    movwf   FSR0L
    movlw   high(bigBuf)
    movwf   FSR0H
    clrw
    movwi   FSR0++
    goto    $

    END     resetVec
