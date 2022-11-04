.MODEL SMALL

.DATA

.STACK

.CODE        
        START:
                ; set video mode:

                MOV     AH,     00h
                MOV     AL,     13h
                INT     10h

                ; set background colour:

                MOV     AH,     0Bh
                MOV     BH,     00h
                MOV     BL,     01h
                INT     10h

                MOV     AH,     4CH
                INT     10h
                RET

        END     START
