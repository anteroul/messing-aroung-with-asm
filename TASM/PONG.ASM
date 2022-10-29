STACK SEGMENT PARA 'STACK'
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
        PADDLE_LEFT_X   DW 0Ah
        PADDLE_LEFT_Y   DW 55h
        PADDLE_RIGHT_X  DW 130h
        PADDLE_RIGHT_Y  DW 55h
        P_ONE_SCORE     DB 0
        P_TWO_SCORE     DB 0
        PADDLE_W        DW 06h
        PADDLE_H        DW 25h
        MOVE_SPEED      DW 0Fh
DATA ENDS

CODE SEGMENT PARA 'CODE'

        MAIN PROC FAR
        ASSUME CS:CODE, DS:DATA, SS:STACK
        PUSH DS                                 ; push DS to stack
        SUB AX, AX                              ; clean AX register
        PUSH AX                                 ; push AX to stack
        MOV AX, DATA                            ; move DATA segment to AX register
        MOV DS, AX
        POP AX
        POP AX

                ; set video mode:
                MOV AH, 00h
                MOV AL, 13h
                INT 10h
                ; set background colour:
                MOV AH, 0Bh
                MOV BH, 00h
                MOV BL, 00h
                INT 10h

                ; draw paddles:
                MOV CX, PADDLE_LEFT_X
                MOV DX, PADDLE_LEFT_Y

                DRAW_P1:
                        MOV AH, 0Ch
                        MOV AL, 0Bh
                        MOV BH, 00h
                        INT 10h

                        INC CX
                        MOV AX, CX
                        SUB AX, PADDLE_LEFT_X
                        CMP AX, PADDLE_W
                        JNG DRAW_P1
                        MOV CX, PADDLE_LEFT_X
                        INC DX
                        MOV AX, DX
                        SUB AX, PADDLE_LEFT_Y
                        CMP AX, PADDLE_H
                        JNG DRAW_P1
                
                RET
        MAIN ENDP

CODE ENDS

END
