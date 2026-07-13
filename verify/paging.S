    PROCESSOR 16F17146
#include <xc.inc>
    PSECT udata_shr
flag: DS  1
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main
    PSECT code,delta=2
main:
    fcall   farRoutine
    PAGESEL farRoutine
    call    PAGEMASK(farRoutine)
    PAGESEL $
    goto    $
    PSECT farCode,class=CODE,delta=2
farRoutine:
    BANKSEL flag
    bsf     flag,0
    return
    END     resetVec
