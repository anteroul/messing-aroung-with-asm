STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
        WINDOW_WIDTH                    DW 140h
        WINDOW_HEIGHT                   DW 0C8h
        WINDOW_BOUNDS                   DW 6
	
        TIME_AUX                        DB 0
        GAME_ACTIVE                     DB 1
        EXITING_GAME                    DB 0
        WINNER_INDEX                    DB 0
        CURRENT_SCENE                   DB 0
	
        TEXT_PLAYER_ONE_POINTS          DB '0','$'
        TEXT_PLAYER_TWO_POINTS          DB '0','$'
        TEXT_GAME_OVER_TITLE            DB 'GAME OVER','$'
        TEXT_GAME_OVER_WINNER           DB 'Player 0 won','$'
        TEXT_GAME_OVER_PLAY_AGAIN       DB 'Press R to play again','$'
        TEXT_GAME_OVER_MAIN_MENU        DB 'Press E to exit to main menu','$'
        TEXT_MAIN_MENU_TITLE            DB 'MAIN MENU','$'
        TEXT_MAIN_MENU_SINGLEPLAYER     DB 'SINGLEPLAYER - S KEY','$'
        TEXT_MAIN_MENU_MULTIPLAYER      DB 'MULTIPLAYER - M KEY','$'
        TEXT_MAIN_MENU_EXIT             DB 'EXIT GAME - E KEY','$'
	
        BALL_ORIGINAL_X                 DW 0A0h              ;X position of the ball on the beginning of a game
        BALL_ORIGINAL_Y                 DW 64h               ;Y position of the ball on the beginning of a game
        BALL_X                          DW 0Ah               ;current X position (column) of the ball
        BALL_Y                          DW 64h               ;current Y position (line) of the ball
        BALL_SIZE                       DW 06h               ;size of the ball (how many pixels does the ball have in width and height)
        BALL_VELOCITY_X                 DW 05h               ;X (horizontal) velocity of the ball
        BALL_VELOCITY_Y                 DW 02h               ;Y (vertical) velocity of the ball
	
        PADDLE_LEFT_X                   DW 0Ah               ;current X position of the left paddle
        PADDLE_LEFT_Y                   DW 55h               ;current Y position of the left paddle
        PLAYER_ONE_POINTS               DB 0                 ;current points of the left player (player one)
	
        PADDLE_RIGHT_X                  DW 130h              ;current X position of the right paddle
        PADDLE_RIGHT_Y                  DW 55h               ;current Y position of the right paddle
        PLAYER_TWO_POINTS               DB 0                 ;current points of the right player (player two)
	
        PADDLE_WIDTH                    DW 06h               ;default paddle width
        PADDLE_HEIGHT                   DW 25h               ;default paddle height
        PADDLE_VELOCITY                 DW 0Fh               ;default paddle velocity

DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK      ;assume as code,data and stack segments the respective registers
	PUSH DS                              ;push to the stack the DS segment
        SUB AX, AX                           ;clean the AX register
	PUSH AX                              ;push AX to the stack
        MOV AX, DATA                         ;save on the AX register the contents of the DATA segment
        MOV DS, AX                           ;save on the DS segment the contents of AX
	POP AX                               ;release the top item from the stack to the AX register
	POP AX                               ;release the top item from the stack to the AX register
		
                CALL CLEAR_SCREEN                       ;set initial video mode configurations
		
                CHECK_TIME:                             ;time checking loop
			
                        CMP EXITING_GAME, 01h
			JE START_EXIT_PROCESS
			
                        CMP CURRENT_SCENE, 00h
			JE SHOW_MAIN_MENU
			
                        CMP GAME_ACTIVE, 00h
			JE SHOW_GAME_OVER
			
                        MOV AH, 2Ch                             ;get the system time
                        INT 21h                                 ;CH = hour CL = minute DH = second DL = 1/100 seconds
			
                        CMP DL, TIME_AUX                        ;is the current time equal to the previous one(TIME_AUX)?
                        JE CHECK_TIME                           ;if it is the same, check again
			
                ;If it reaches this point, it's because the time has passed


                        MOV TIME_AUX, DL                ;update time
			
                        CALL CLEAR_SCREEN               ;clear the screen by restarting the video mode
			
                        CALL MOVE_BALL                  ;move the ball
                        CALL DRAW_BALL                  ;draw the ball
			
                        CALL MOVE_PADDLES               ;move the two paddles (check for pressing of keys)
                        CALL DRAW_PADDLES               ;draw the two paddles with the updated positions
			
                        CALL DRAW_UI                    ;draw the game User Interface
			
                        JMP CHECK_TIME                  ;after everything checks time again
			
			SHOW_GAME_OVER:
				CALL DRAW_GAME_OVER_MENU
				JMP CHECK_TIME
				
			SHOW_MAIN_MENU:
				CALL DRAW_MAIN_MENU
				JMP CHECK_TIME
				
			START_EXIT_PROCESS:
				CALL CONCLUDE_EXIT_GAME
				
		RET		
	MAIN ENDP
	
        MOVE_BALL PROC NEAR


                ;Move the ball horizontally:

                MOV AX, BALL_VELOCITY_X    
                ADD BALL_X, AX                   


                ;Check if the ball has passed the left boundary (BALL_X < 0 + WINDOW_BOUNDS)


                ;If is colliding, reset its position:

                MOV AX, WINDOW_BOUNDS
                CMP BALL_X, AX                          ;BALL_X is compared with the left boundary of the screen (0 + WINDOW_BOUNDS)          
                JL GIVE_POINT_TO_PLAYER_TWO             ;if it is less, give one point to the player two and reset ball position


                ;Check if the ball has passed the right boundarie (BALL_X > WINDOW_WIDTH - BALL_SIZE  - WINDOW_BOUNDS)


                ;If is colliding, reset its position:

                MOV AX, WINDOW_WIDTH
                SUB AX, BALL_SIZE
                SUB AX, WINDOW_BOUNDS
                CMP BALL_X, AX                          ;BALL_X is compared with the right boundarie of the screen (BALL_X > WINDOW_WIDTH - BALL_SIZE  - WINDOW_BOUNDS)  
                JG GIVE_POINT_TO_PLAYER_ONE             ;if is greater, give one point to the player one and reset ball position
		JMP MOVE_BALL_VERTICALLY
		
                GIVE_POINT_TO_PLAYER_ONE:                       ;give one point to the player one and reset ball position
                        INC PLAYER_ONE_POINTS                   ;increment player one points
                        CALL RESET_BALL_POSITION                ;reset ball position to the center of the screen
			
                        CALL UPDATE_TEXT_PLAYER_ONE_POINTS      ;update the text of the player one points
			
                        CMP PLAYER_ONE_POINTS, 05h              ;check if this player has reached 5 points
                        JGE GAME_OVER                           ;if this player points is 5 or more, the game is over
			RET
		
                GIVE_POINT_TO_PLAYER_TWO:               ;give one point to the player two and reset ball position
                        INC PLAYER_TWO_POINTS           ;increment player two points
                        CALL RESET_BALL_POSITION        ;reset ball position to the center of the screen
			
                        CALL UPDATE_TEXT_PLAYER_TWO_POINTS      ;update the text of the player two points
			
                        CMP PLAYER_TWO_POINTS, 05h      ;check if this player has reached 5 points
                        JGE GAME_OVER                   ;if this player points is 5 or more, the game is over
			RET
			
                GAME_OVER:
                        CMP PLAYER_ONE_POINTS, 05h      ;check which player has 5 or more points
                        JNL WINNER_IS_PLAYER_ONE
                        JMP WINNER_IS_PLAYER_TWO
			
			WINNER_IS_PLAYER_ONE:
                                MOV WINNER_INDEX, 01h
				JMP CONTINUE_GAME_OVER
			WINNER_IS_PLAYER_TWO:
                                MOV WINNER_INDEX, 02h
				JMP CONTINUE_GAME_OVER
				
			CONTINUE_GAME_OVER:
                                MOV PLAYER_ONE_POINTS, 00h
                                MOV PLAYER_TWO_POINTS, 00h
				CALL UPDATE_TEXT_PLAYER_ONE_POINTS
				CALL UPDATE_TEXT_PLAYER_TWO_POINTS
                                MOV GAME_ACTIVE, 00h
				RET	


        ;Move the ball vertically:

		MOVE_BALL_VERTICALLY:		
                        MOV AX, BALL_VELOCITY_Y
                        ADD BALL_Y, AX             
		
        ;Check if the ball has passed the top boundary (BALL_Y < 0 + WINDOW_BOUNDS)
        ;If is colliding, reverse the velocity in Y:

		MOV AX,WINDOW_BOUNDS
		CMP BALL_Y,AX                    ;BALL_Y is compared with the top boundarie of the screen (0 + WINDOW_BOUNDS)
		JL NEG_VELOCITY_Y                ;if is less reverve the velocity in Y

        ;Check if the ball has passed the bottom boundary (BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)
        ;If is colliding, reverse the velocity in Y:

                MOV AX, WINDOW_HEIGHT 
                SUB AX, BALL_SIZE
                SUB AX, WINDOW_BOUNDS
                CMP BALL_Y, AX                    ;BALL_Y is compared with the bottom boundarie of the screen (BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)
                JG NEG_VELOCITY_Y                 ;if is greater reverve the velocity in Y


                ;Check if the ball is colliding with the right paddle:

		; maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
		; BALL_X + BALL_SIZE > PADDLE_RIGHT_X && BALL_X < PADDLE_RIGHT_X + PADDLE_WIDTH 
		; && BALL_Y + BALL_SIZE > PADDLE_RIGHT_Y && BALL_Y < PADDLE_RIGHT_Y + PADDLE_HEIGHT
		
                MOV AX, BALL_X
                ADD AX, BALL_SIZE
                CMP AX, PADDLE_RIGHT_X
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE
		
                MOV AX, PADDLE_RIGHT_X
                ADD AX, PADDLE_WIDTH
                CMP BALL_X, AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE
		
                MOV AX, BALL_Y
                ADD AX, BALL_SIZE
                CMP AX, PADDLE_RIGHT_Y
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE
		
		MOV AX,PADDLE_RIGHT_Y
		ADD AX,PADDLE_HEIGHT
		CMP BALL_Y,AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE
		
		JMP NEG_VELOCITY_X

		CHECK_COLLISION_WITH_LEFT_PADDLE:
		; maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
		; BALL_X + BALL_SIZE > PADDLE_LEFT_X && BALL_X < PADDLE_LEFT_X + PADDLE_WIDTH 
		; && BALL_Y + BALL_SIZE > PADDLE_LEFT_Y && BALL_Y < PADDLE_LEFT_Y + PADDLE_HEIGHT
		
                MOV AX, BALL_X
                ADD AX, BALL_SIZE
                CMP AX, PADDLE_LEFT_X
		JNG EXIT_COLLISION_CHECK  ;if there's no collision exit procedure
		
                MOV AX, PADDLE_LEFT_X
                ADD AX, PADDLE_WIDTH
                CMP BALL_X, AX
		JNL EXIT_COLLISION_CHECK  ;if there's no collision exit procedure
		
                MOV AX, BALL_Y
                ADD AX, BALL_SIZE
                CMP AX, PADDLE_LEFT_Y
		JNG EXIT_COLLISION_CHECK  ;if there's no collision exit procedure
		
                MOV AX, PADDLE_LEFT_Y
                ADD AX, PADDLE_HEIGHT
                CMP BALL_Y, AX
		JNL EXIT_COLLISION_CHECK  ;if there's no collision exit procedure
		

		JMP NEG_VELOCITY_X
		
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y
			RET
		NEG_VELOCITY_X:
			NEG BALL_VELOCITY_X
			RET                              
			
		EXIT_COLLISION_CHECK:
			RET
	MOVE_BALL ENDP
	
	MOVE_PADDLES PROC NEAR

		;check if any key is being pressed (if not check the other paddle)

                MOV AH, 01h
		INT 16h
                JZ CHECK_RIGHT_PADDLE_MOVEMENT  ;ZF = 1, JZ -> Jump If Zero
		
                MOV AH, 00h
		INT 16h
		
		;if it is 'w' or 'W' move up
                CMP AL, 77h                     ;77 = w
		JE MOVE_LEFT_PADDLE_UP
                CMP AL, 57h                     ;57 = W
		JE MOVE_LEFT_PADDLE_UP
		
		;if it is 's' or 'S' move down
                CMP AL, 73h
		JE MOVE_LEFT_PADDLE_DOWN
                CMP AL, 53h
		JE MOVE_LEFT_PADDLE_DOWN
		JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		MOVE_LEFT_PADDLE_UP:
			MOV AX,PADDLE_VELOCITY
                        SUB PADDLE_LEFT_Y, AX
			
			MOV AX,WINDOW_BOUNDS
                        CMP PADDLE_LEFT_Y, AX
			JL FIX_PADDLE_LEFT_TOP_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_TOP_POSITION:
                                MOV PADDLE_LEFT_Y, AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
		MOVE_LEFT_PADDLE_DOWN:
                        MOV AX, PADDLE_VELOCITY
                        ADD PADDLE_LEFT_Y, AX
                        MOV AX, WINDOW_HEIGHT
                        SUB AX, WINDOW_BOUNDS
                        SUB AX, PADDLE_HEIGHT
                        CMP PADDLE_LEFT_Y, AX
			JG FIX_PADDLE_LEFT_BOTTOM_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_BOTTOM_POSITION:
                                MOV PADDLE_LEFT_Y, AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		
                ;Right paddle movement:

		CHECK_RIGHT_PADDLE_MOVEMENT:
		
			;if it is 'o' or 'O' move up
                        CMP AL, 6Fh                     ;6F = o
			JE MOVE_RIGHT_PADDLE_UP
                        CMP AL, 4Fh                     ;4F = O
			JE MOVE_RIGHT_PADDLE_UP
			
			;if it is 'l' or 'L' move down
                        CMP AL, 6Ch
			JE MOVE_RIGHT_PADDLE_DOWN
                        CMP AL, 4Ch
			JE MOVE_RIGHT_PADDLE_DOWN
			JMP EXIT_PADDLE_MOVEMENT
			

			MOVE_RIGHT_PADDLE_UP:
                                MOV AX, PADDLE_VELOCITY
                                SUB PADDLE_RIGHT_Y, AX
				
                                MOV AX, WINDOW_BOUNDS
                                CMP PADDLE_RIGHT_Y, AX
				JL FIX_PADDLE_RIGHT_TOP_POSITION
				JMP EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_TOP_POSITION:
                                        MOV PADDLE_RIGHT_Y, AX
					JMP EXIT_PADDLE_MOVEMENT
			
			MOVE_RIGHT_PADDLE_DOWN:
                                MOV AX, PADDLE_VELOCITY
                                ADD PADDLE_RIGHT_Y, AX
                                MOV AX, WINDOW_HEIGHT
                                SUB AX, WINDOW_BOUNDS
                                SUB AX, PADDLE_HEIGHT
                                CMP PADDLE_RIGHT_Y, AX
				JG FIX_PADDLE_RIGHT_BOTTOM_POSITION
				JMP EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_BOTTOM_POSITION:
                                        MOV PADDLE_RIGHT_Y, AX
					JMP EXIT_PADDLE_MOVEMENT
		
		EXIT_PADDLE_MOVEMENT:
		
			RET
		
	MOVE_PADDLES ENDP
	
	RESET_BALL_POSITION PROC NEAR
		
                MOV AX, BALL_ORIGINAL_X
                MOV BALL_X, AX
		
                MOV AX, BALL_ORIGINAL_Y
                MOV BALL_Y, AX
		
		NEG BALL_VELOCITY_X
		NEG BALL_VELOCITY_Y
		
		RET
	RESET_BALL_POSITION ENDP
	
	DRAW_BALL PROC NEAR                  
		
                MOV CX, BALL_X
                MOV DX, BALL_Y
		
		DRAW_BALL_HORIZONTAL:
                        MOV AH, 0Ch
                        MOV AL, 0Fh
                        MOV BH, 00h
			INT 10h
			
			INC CX
                        MOV AX, CX
                        SUB AX, BALL_X
                        CMP AX, BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
			
                        MOV CX, BALL_X
			INC DX
			
                        MOV AX, DX
                        SUB AX, BALL_Y
                        CMP AX, BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
		
		RET
	DRAW_BALL ENDP
	
	DRAW_PADDLES PROC NEAR
		
                MOV CX, PADDLE_LEFT_X
                MOV DX, PADDLE_LEFT_Y
		
		DRAW_PADDLE_LEFT_HORIZONTAL:
                        MOV AH, 0Ch
                        MOV AL, 0Bh
                        MOV BH, 00h
			INT 10h
			
			INC CX
                        MOV AX, CX
                        SUB AX, PADDLE_LEFT_X
                        CMP AX, PADDLE_WIDTH
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
                        MOV CX, PADDLE_LEFT_X
			INC DX
			
                        MOV AX, DX
                        SUB AX, PADDLE_LEFT_Y
                        CMP AX, PADDLE_HEIGHT
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
			
                MOV CX, PADDLE_RIGHT_X
                MOV DX, PADDLE_RIGHT_Y
		
		DRAW_PADDLE_RIGHT_HORIZONTAL:
                        MOV AH, 0Ch
                        MOV AL, 04h
                        MOV BH, 00h
			INT 10h
			
			INC CX
                        MOV AX, CX
                        SUB AX, PADDLE_RIGHT_X
                        CMP AX, PADDLE_WIDTH
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
			
                        MOV CX, PADDLE_RIGHT_X
			INC DX
			
                        MOV AX, DX
                        SUB AX, PADDLE_RIGHT_Y
                        CMP AX, PADDLE_HEIGHT
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
			
		RET
	DRAW_PADDLES ENDP
	
	DRAW_UI PROC NEAR
				
                MOV AH, 02h
                MOV BH, 00h
                MOV DH, 04h
                MOV DL, 06h
		INT 10h							 
		
                MOV AH, 09h
                LEA DX, TEXT_PLAYER_ONE_POINTS
		INT 21h
				
                MOV AH, 02h
                MOV BH, 00h
                MOV DH, 04h
                MOV DL, 1Fh
		INT 10h							 
		
                MOV AH, 09h
                LEA DX, TEXT_PLAYER_TWO_POINTS
		INT 21h
		
		RET
	DRAW_UI ENDP
	
	UPDATE_TEXT_PLAYER_ONE_POINTS PROC NEAR
		
                XOR AX, AX
                MOV AL, PLAYER_ONE_POINTS
		
                ADD AL, 30h
                MOV [TEXT_PLAYER_ONE_POINTS], AL
		
		RET
	UPDATE_TEXT_PLAYER_ONE_POINTS ENDP
	
	UPDATE_TEXT_PLAYER_TWO_POINTS PROC NEAR
		
                XOR AX, AX
                MOV AL, PLAYER_TWO_POINTS

                ADD AL, 30h
                MOV [TEXT_PLAYER_TWO_POINTS], AL
		
		RET
	UPDATE_TEXT_PLAYER_TWO_POINTS ENDP
	
	DRAW_GAME_OVER_MENU PROC NEAR
		
		CALL CLEAR_SCREEN

                MOV AH, 02h
                MOV BH, 00h
                MOV DH, 04h
                MOV DL, 04h
		INT 10h							 
		
                MOV AH, 09h
                LEA DX, TEXT_GAME_OVER_TITLE
		INT 21h

                MOV AH, 02h
                MOV BH, 00h
                MOV DH, 06h
                MOV DL, 04h
		INT 10h

		CALL UPDATE_WINNER_TEXT
		
                MOV AH, 09h
                LEA DX, TEXT_GAME_OVER_WINNER
		INT 21h
		
                MOV AH, 02h
                MOV BH, 00h
                MOV DH, 08h
                MOV DL, 04h
		INT 10h							 

                MOV AH, 09h
                LEA DX, TEXT_GAME_OVER_PLAY_AGAIN
		INT 21h
		
                MOV AH, 02h
                MOV BH, 00h
                MOV DH, 0Ah
                MOV DL, 04h
		INT 10h							 

                MOV AH, 09h
                LEA DX, TEXT_GAME_OVER_MAIN_MENU
		INT 21h
		
                MOV AH, 00h
		INT 16h

                CMP AL, 'R'
		JE RESTART_GAME
                CMP AL, 'r'
		JE RESTART_GAME

                CMP AL, 'E'
		JE EXIT_TO_MAIN_MENU
                CMP AL, 'e'
		JE EXIT_TO_MAIN_MENU
		RET
		
		RESTART_GAME:
                        MOV GAME_ACTIVE, 01h
			RET
		
		EXIT_TO_MAIN_MENU:
                        MOV GAME_ACTIVE, 00h
                        MOV CURRENT_SCENE, 00h
			RET
			
	DRAW_GAME_OVER_MENU ENDP
	
	DRAW_MAIN_MENU PROC NEAR
		
		CALL CLEAR_SCREEN
		
                MOV AH, 02h
                MOV BH, 00h
                MOV DH, 04h
                MOV DL, 04h
		INT 10h							 
		
                MOV AH, 09h
                LEA DX, TEXT_MAIN_MENU_TITLE
		INT 21h
		
                MOV AH, 02h
                MOV BH, 00h
                MOV DH, 06h
                MOV DL, 04h
		INT 10h							 
		
                MOV AH, 09h
                LEA DX, TEXT_MAIN_MENU_SINGLEPLAYER
		INT 21h
		
                MOV AH, 02h
                MOV BH, 00h
                MOV DH, 08h
                MOV DL, 04h
		INT 10h							 
		
                MOV AH, 09h
                LEA DX, TEXT_MAIN_MENU_MULTIPLAYER
		INT 21h
		
                MOV AH, 02h
                MOV BH, 00h
                MOV DH, 0Ah
                MOV DL, 04h
		INT 10h							 
		
                MOV AH, 09h
                LEA DX, TEXT_MAIN_MENU_EXIT
		INT 21h
		
		MAIN_MENU_WAIT_FOR_KEY:
                        MOV AH, 00h
			INT 16h
		
                        CMP AL, 'S'
			JE START_SINGLEPLAYER
                        CMP AL, 's'
			JE START_SINGLEPLAYER
                        CMP AL, 'M'
			JE START_MULTIPLAYER
                        CMP AL, 'm'
			JE START_MULTIPLAYER
                        CMP AL, 'E'
			JE EXIT_GAME
                        CMP AL, 'e'
			JE EXIT_GAME
			JMP MAIN_MENU_WAIT_FOR_KEY
			
		START_SINGLEPLAYER:
                        MOV CURRENT_SCENE, 01h
                        MOV GAME_ACTIVE, 01h
			RET
		
		START_MULTIPLAYER:
			JMP MAIN_MENU_WAIT_FOR_KEY

		EXIT_GAME:
                        MOV EXITING_GAME, 01h
			RET

	DRAW_MAIN_MENU ENDP
	
	UPDATE_WINNER_TEXT PROC NEAR
		
                MOV AL, WINNER_INDEX
                ADD AL, 30h
                MOV [TEXT_GAME_OVER_WINNER+7], AL
		
		RET
	UPDATE_WINNER_TEXT ENDP
	
	CLEAR_SCREEN PROC NEAR
	
                        MOV AH, 00h
                        MOV AL, 13h
			INT 10h 
		
                        MOV AH, 0Bh
                        MOV BH, 00h
                        MOV BL, 00h
			INT 10h
			
			RET
			
	CLEAR_SCREEN ENDP
	
	CONCLUDE_EXIT_GAME PROC NEAR
		
                MOV AH, 00h
                MOV AL, 02h
		INT 10h
		
                MOV AH, 4Ch
		INT 21h

	CONCLUDE_EXIT_GAME ENDP

CODE ENDS
END
