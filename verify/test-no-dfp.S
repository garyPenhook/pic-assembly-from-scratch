    PROCESSOR 16F17146
#include <xc.inc>

    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main

    PSECT code
main:
    goto    $

    END     resetVec
