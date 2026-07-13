    PROCESSOR 16F17146
#include <xc.inc>
    PSECT udata
blinks: DS  1
    PSECT udata_shr
d1: DS  1
d2: DS  1
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main
    PSECT code
main:
    BANKSEL blinks
    clrf    BANKMASK(blinks)
    BANKSEL ANSELC
    bcf     BANKMASK(ANSELC),1
    BANKSEL TRISC
    bcf     TRISC,1
    BANKSEL LATC
    bsf     LATC,1
loop:
    bcf     LATC,1
    call    delay
    bsf     LATC,1
    call    delay
    BANKSEL blinks
    incf    BANKMASK(blinks),f
    BANKSEL LATC
    goto    loop
delay:
    movlw   0xFF
    movwf   d1
d_outer:
    movlw   0xFF
    movwf   d2
d_inner:
    decfsz  d2,f
    goto    d_inner
    decfsz  d1,f
    goto    d_outer
    return
    END     resetVec
