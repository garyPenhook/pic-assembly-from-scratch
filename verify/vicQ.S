    PROCESSOR 18F57Q43
#include <xc.inc>

    CONFIG "FEXTOSC = OFF"
    CONFIG "RSTOSC = HFINTOSC_1MHZ"
    CONFIG "CLKOUTEN = OFF"
    CONFIG "PR1WAY = ON"
    CONFIG "CSWEN = ON"
    CONFIG "FCMEN = ON"
    CONFIG "MCLRE = EXTMCLR"
    CONFIG "PWRTS = PWRT_OFF"
    CONFIG "MVECEN = ON"
    CONFIG "IVT1WAY = ON"
    CONFIG "LPBOREN = OFF"
    CONFIG "BOREN = SBORDIS"
    CONFIG "BORV = VBOR_2P45"
    CONFIG "ZCD = OFF"
    CONFIG "PPS1WAY = ON"
    CONFIG "STVREN = ON"
    CONFIG "LVP = ON"
    CONFIG "XINST = OFF"
    CONFIG "WDTCPS = WDTCPS_31"
    CONFIG "WDTE = OFF"
    CONFIG "WDTCWS = WDTCWS_7"
    CONFIG "WDTCCS = SC"
    CONFIG "BBSIZE = BBSIZE_512"
    CONFIG "BBEN = OFF"
    CONFIG "SAFEN = OFF"
    CONFIG "DEBUG = OFF"
    CONFIG "WRTB = OFF"
    CONFIG "WRTC = OFF"
    CONFIG "WRTD = OFF"
    CONFIG "WRTSAF = OFF"
    CONFIG "WRTAPP = OFF"
    CONFIG "CP = OFF"

    GLOBAL __Livt

PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto    start

; TMR0 is interrupt vector number 31 on PIC18F57Q43.
PSECT ivt,class=CODE,reloc=2,ovrld
ivtbase:
    ORG     31*2
    DW      tmr0Isr shr 2

PSECT textISR,class=CODE,reloc=4
tmr0Isr:
    bcf     BANKMASK(PIR3),PIR3_TMR0IF_POSN,c
    movlw   1
    xorwf   BANKMASK(LATA),f,c
    retfie  f

PSECT code
start:
    ; IVT registers are in bank 4, not the Q43 Access Bank.
    bcf     BANKMASK(INTCON0),INTCON0_GIE_POSN,c
    BANKSEL IVTLOCK
    movlw   0x55
    movwf   BANKMASK(IVTLOCK),b
    movlw   0xAA
    movwf   BANKMASK(IVTLOCK),b
    bcf     BANKMASK(IVTLOCK),IVTLOCK_IVTLOCKED_POSN,b

    movlw   low highword __Livt
    movwf   BANKMASK(IVTBASEU),b
    movlw   high __Livt
    movwf   BANKMASK(IVTBASEH),b
    movlw   low __Livt
    movwf   BANKMASK(IVTBASEL),b

    movlw   0x55
    movwf   BANKMASK(IVTLOCK),b
    movlw   0xAA
    movwf   BANKMASK(IVTLOCK),b
    bsf     BANKMASK(IVTLOCK),IVTLOCK_IVTLOCKED_POSN,b

    ; RA0 is a digital output.
    BANKSEL ANSELA
    clrf    BANKMASK(ANSELA),b
    clrf    BANKMASK(LATA),c
    clrf    BANKMASK(TRISA),c

    ; TMR0: 16-bit, Fosc/4, high-priority interrupt.
    BANKSEL T0CON0
    clrf    BANKMASK(T0CON0),b
    bsf     BANKMASK(T0CON0),T0CON0_MD16_POSN,b
    movlw   0x40
    movwf   BANKMASK(T0CON1),b
    bsf     BANKMASK(IPR3),IPR3_TMR0IP_POSN,b
    bcf     BANKMASK(PIR3),PIR3_TMR0IF_POSN,c
    bsf     BANKMASK(PIE3),PIE3_TMR0IE_POSN,c
    bsf     BANKMASK(T0CON0),T0CON0_EN_POSN,b
    bsf     BANKMASK(INTCON0),INTCON0_IPEN_POSN,c
    bsf     BANKMASK(INTCON0),INTCON0_GIEH_POSN,c
idle:
    goto    idle

    END     resetVec
