    PROCESSOR 16F570
#include <xc.inc>

    CONFIG "FOSC = EXTRC_CLKOUT"
    CONFIG "WDTE = OFF"
    CONFIG "CP = OFF"
    CONFIG "IOSCFS = 8MHz"
    CONFIG "CPSW = OFF"
    CONFIG "BOREN = OFF"
    CONFIG "DRTEN = OFF"

    PSECT udata_shr
counter: DS 1
loc:     DS 1

    ; Physical Reset fetch is 0x7FF (factory OSCCAL). It rolls over here.
    PSECT userEntry,class=CODE,delta=2
userEntry:
    ljmp    main

    PSECT code
main:
    movlw   0
    tris    PORTA
    clrf    counter
    movf    counter,w
loop:
    fcall   increment
    movwf   PORTA
    goto    loop

    PSECT entryCode,class=ENTRY,delta=2
increment:
    movwf   loc
    incf    loc,w
    return

    END     userEntry
