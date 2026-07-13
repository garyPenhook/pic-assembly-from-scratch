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
    CONFIG "MVECEN = OFF"
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

FNCONF udata_acs,?au_,?pa_

PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto       main

PSECT code
FNSIZE add,0,4
GLOBAL ?pa_add
add:
    movf       BANKMASK(?pa_add+2),w,c
    addwf      BANKMASK(?pa_add+0),f,c
    movf       BANKMASK(?pa_add+3),w,c
    addwfc     BANKMASK(?pa_add+1),f,c
    return

FNSIZE incr,0,2
GLOBAL ?pa_incr
incr:
    addwf      BANKMASK(?pa_incr+0),f,c
    movlw      0
    addwfc     BANKMASK(?pa_incr+1),f,c
    return

GLOBAL ?au_main
GLOBAL result
result EQU     ?au_main+0
GLOBAL incval
incval EQU     ?au_main+2

FNROOT main
FNSIZE main,4,0
FNCALL main,add
FNCALL main,incr

PSECT code
main:
    clrf       BANKMASK(result+0),c
    clrf       BANKMASK(result+1),c
    movlw      2
    movwf      BANKMASK(incval+0),c
    clrf       BANKMASK(incval+1),c
loop:
    ; MOVFF encodes full data-memory addresses; do not BANKMASK its operands.
    movff      result+0,?pa_add+0
    movff      result+1,?pa_add+1
    movff      incval+0,?pa_add+2
    movff      incval+1,?pa_add+3
    call       add
    movff      ?pa_add+0,result+0
    movff      ?pa_add+1,result+1
    movff      incval+0,?pa_incr+0
    movff      incval+1,?pa_incr+1
    movlw      2
    call       incr
    movff      ?pa_incr+0,incval+0
    movff      ?pa_incr+1,incval+1
    goto       loop

    END        resetVec
