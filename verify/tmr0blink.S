    PROCESSOR 16F17146
#include <xc.inc>
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main
    PSECT intVec,class=CODE,delta=2
isr:
    BANKSEL PIR0
    bcf     BANKMASK(PIR0),5
    BANKSEL LATC
    movlw   0x02
    xorwf   LATC,f
    retfie
    PSECT code,delta=2
main:
    BANKSEL ANSELC
    bcf     BANKMASK(ANSELC),1
    BANKSEL LATC
    bsf     LATC,1
    BANKSEL TRISC
    bcf     TRISC,1
    BANKSEL T0CON1
    movlw   0x40
    movwf   BANKMASK(T0CON1)
    movlw   0x10
    movwf   BANKMASK(T0CON0)
    BANKSEL PIR0
    bcf     BANKMASK(PIR0),5
    BANKSEL PIE0
    bsf     BANKMASK(PIE0),5
    BANKSEL T0CON0
    movlw   0x90
    movwf   BANKMASK(T0CON0)
    bsf     INTCON,7
idle:
    goto    idle
    END     resetVec
