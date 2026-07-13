    PROCESSOR 16F17146
#include <xc.inc>
#include "macros.inc"
    EXTRN   delay
    PSECT   resetVec,class=CODE,delta=2
resetVec:
    goto    main
    PSECT   code,delta=2
main:
    CONFIG_OUTPUT C, 1, 1
    BANKSEL LATC
loop:
    bcf     LATC,1
    fcall   delay
    bsf     LATC,1
    fcall   delay
    goto    loop
    END     resetVec
