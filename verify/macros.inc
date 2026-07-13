CONFIG_OUTPUT MACRO port, bit, initial
    BANKSEL ANSEL&port
    bcf     BANKMASK(ANSEL&port), bit
    BANKSEL LAT&port
    IF initial
        bsf BANKMASK(LAT&port), bit
    ELSE
        bcf BANKMASK(LAT&port), bit
    ENDIF
    BANKSEL TRIS&port
    bcf     BANKMASK(TRIS&port), bit
    ENDM
