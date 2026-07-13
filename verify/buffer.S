    PROCESSOR 16F17146
#include <xc.inc>
    PSECT udata
buf:    DS  8
    PSECT udata_shr
count:  DS  1
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main
    PSECT code
main:
    movlw   low(buf)
    movwf   FSR0L
    movlw   high(buf)
    movwf   FSR0H
    movlw   8
    movwf   count
    clrw
fill:
    movwi   FSR0++
    addlw   1
    decfsz  count,f
    goto    fill
    goto    $
    END     resetVec
