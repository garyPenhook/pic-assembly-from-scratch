    PROCESSOR 16F17146
#include <xc.inc>
    CONFIG "FEXTOSC = OFF"
    CONFIG "RSTOSC = HFINTOSC_1MHz"
    CONFIG "CLKOUTEN = OFF"
    CONFIG "CSWEN = ON"
    CONFIG "VDDAR = HI"
    CONFIG "FCMEN = ON"
    CONFIG "MCLRE = EXTMCLR"
    CONFIG "PWRTS = PWRT_64"
    CONFIG "LPBOREN = OFF"
    CONFIG "BOREN = NSLEEP"
    CONFIG "DACAUTOEN = OFF"
    CONFIG "BORV = LO"
    CONFIG "ZCD = OFF"
    CONFIG "PPS1WAY = ON"
    CONFIG "STVREN = ON"
    CONFIG "WDTCPS = WDTCPS_31"
    CONFIG "WDTE = OFF"
    CONFIG "WDTCWS = WDTCWS_7"
    CONFIG "WDTCCS = SC"
    CONFIG "BBSIZE = BB512"
    CONFIG "LVP = ON"
    CONFIG "BBEN = OFF"
    CONFIG "SAFEN = OFF"
    CONFIG "WRTAPP = OFF"
    CONFIG "WRTB = OFF"
    CONFIG "WRTC = OFF"
    CONFIG "WRTD = OFF"
    CONFIG "WRTSAF = OFF"
    CONFIG "CP = OFF"
    CONFIG "CPD = OFF"
    PSECT udata_shr
d1: DS  1
d2: DS  1
    PSECT resetVec,class=CODE,delta=2
resetVec:
    goto    main
    PSECT code
main:
    BANKSEL ANSELC
    bcf     BANKMASK(ANSELC),ANSELC_ANSC1_POSN
    BANKSEL LATC
    bsf     BANKMASK(LATC),LATC_LATC1_POSN
    BANKSEL TRISC
    bcf     BANKMASK(TRISC),TRISC_TRISC1_POSN
loop:
    bcf     BANKMASK(LATC),LATC_LATC1_POSN
    call    delay
    bsf     BANKMASK(LATC),LATC_LATC1_POSN
    call    delay
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
