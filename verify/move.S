    PROCESSOR 16F17146
#include <xc.inc>
    PSECT udata_shr
myByte:
    DS      1
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main
    PSECT code
main:
    clrf    myByte
    movlw   0x2A
    movwf   myByte
    movlw   0x00
    movf    myByte,w
    goto    $
    END     resetVec
