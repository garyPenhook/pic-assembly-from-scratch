    PROCESSOR 16F17146
#include <xc.inc>
    PSECT myVars,class=BANK0,space=1
counter:
    DS      1
scratch:
    DS      1
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main
    PSECT myCode,class=CODE,delta=2
main:
    BANKSEL counter
    clrf    BANKMASK(counter)
    incf    BANKMASK(counter),f
    goto    $
    END     resetVec
