    PROCESSOR 16F17146
#include <xc.inc>
    PSECT udata_shr
counter:
    DS      2
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main
    PSECT code
main:
    clrf    counter
    clrf    counter+1
loop:
    incfsz  counter,f
    goto    loop
    incf    counter+1,f
    goto    loop
    END     resetVec
