    PROCESSOR 16F17146
#include <xc.inc>
    GLOBAL  delay
    PSECT   udata_shr
d1: DS  1
d2: DS  1
    PSECT   code,delta=2
delay:
    movlw   0xFF
    movwf   d1
douter:
    movlw   0xFF
    movwf   d2
dinner:
    decfsz  d2,f
    goto    dinner
    decfsz  d1,f
    goto    douter
    return
