@;=                                                               		=
@;=== candy1_combi.s: rutinas para detectar y sugerir combinaciones   ===
@;=                                                               		=
@;=== Programador tarea 1G: clara.puig@estudiants.urv.cat				  ===
@;=== Programador tarea 1H: clara.puig@estudiants.urv.cat				  ===
@;=                                                             	 	=



.include "../include/candy1_incl.i"



@;-- .text. c�digo de las rutinas ---
.text	
		.align 2
		.arm

@;.data
@;		vect_pos:	.space 6


@;TAREA 1G;
@; hay_combinacion(*matriz): rutina para detectar si existe, por lo menos, una
@;	combinaci�n entre dos elementos (diferentes) consecutivos que provoquen
@;	una secuencia v�lida, incluyendo elementos en gelatinas simples y dobles.
@;	Par�metros:
@;		R0 = direcci�n base de la matriz de juego
@;	Variables:
@;		R1 = fila
@;		R2 = columna
@; 		R3 = total de columnas
@;		R4 = total de filas
@; 		R5 = posici�n en la matriz
@;		R6 = valor que hay en la posici�n r5
@;		R7 = columnas-1
@;		R8 = filas-1
@;		R9 = posici�n derecha / valor de R10
@; 		R10 = posici�n abajo / valor de R9
@;	Resultado:
@;		R0 = 1 si hay una secuencia, 0 en otro caso

	.global hay_combinacion
	
hay_combinacion:
		push {R1-R12, lr}
		mov r1, #0
		mov r2, #0
		mov r3, #COLUMNS
		mov r4, #ROWS
		sub r7, r3, #1 
		sub r8, r4, #1
		
		.startBucle: 				@; El bucle termina cuando se encuentra una combinaci�n
		mla r5, r1, r3, r2			@; Posici�n cuando se recorre la matriz
		ldrb r6, [r0, r5]
		cmp r6, #7
		beq .incrementa_posicion
		cmp r6, #15
		beq .incrementa_posicion
		and r6, #0x07				@; M�scara para obtener los bits 2-0 de un n�mero
		cmp r6, #0					@; Se controla que la posici�n actual no sea un espacio vac�o, un bloque s�lido o un hueco
		beq .incrementa_posicion
		cmp r2, r7					@; Se comprueba si estamos en la ultima fila para evitar un intercambio de posiciones con el elemento de debajo
		beq .ultima_columna
		
		@; Se intercambian los n�meros de la posici�n r5 y la siguiente (r9)
		
		add r9, r5, #1			
		ldrb r10, [r0, r9]			@; Ahora r10 es el valor de la posici�n r9
		cmp r10, #7
		beq .intercambia_abajo
		cmp r10, #15
		beq .intercambia_abajo
		and r10, #0x07
		cmp r10, #0					@; Se comprueba que r10 no sea bloque s�lido, espacio vac�o o hueco
		beq .intercambia_abajo
		strb r10, [r0, r5]			@; Ahora en la posici�n r5 est� el valor de la posici�n r9
		strb r6, [r0, r9]			@; Ahora en la posici�n r9 est� el valor de la posici�n r5, copiado anteriormente en r6
		
		@; detectar_orientacion
		
		@;	Par�metros:
	@;		R1 = fila 'f'
	@;		R2 = columna 'c'
	@;		R4 = direcci�n base de la matriz
	@;	Resultado:
	@;		R0 = c�digo de orientaci�n;
	@;				inicio de secuencia: 0 -> Este, 1 -> Sur, 2 -> Oeste, 3 -> Norte
	@;				en medio de secuencia: 4 -> horizontal, 5 -> vertical
	@;				sin secuencia: 6 
	
	mov r11, r0
	mov r12, r5
	mov r4, r0
	bl detectar_orientacion
	
	mov r3, #COLUMNS
	mov r4, #ROWS
	mov r5, r12
	
		@; Se devuelven los n�meros a sus posiciones originales
		
		ldrb r6, [r11, r9]			@; En r6 se ha guardado el valor que hay ahora en la posici�n r9
		ldrb r10, [r11, r5]			@; En r10 se ha guardado el valor nuevo de la posici�n r5
		strb r6, [r11, r5]			@; En la posici�n r5 se ha guardado el valor que ten�a la posici�n r9, guardado anteriormente en el registro r6
		strb r10, [r11, r9]			@; En la posici�n r9 se ha guardado el valor que ten�a la posici�n r5, guardado anteriormente en el registro r10
		cmp r0, #6
		blo .secuenciaEncontrada	@; Se devuelve la direccion de la matriz
		mov r0, r11
		cmp r1, r8					@; Con las filas ocurre lo mismo que con las columnas, solo que se evita el intercambio con el elemento de la derecha
		beq .ultima_fila

		.intercambia_abajo:
		.ultima_columna:
		@; Se intercambian los n�meros de la posici�n r5 y la posici�n inferior (r10)
		
		add r1, #1
		mla r10, r1, r3, r2			@; r10 es la posici�n inferior a r5 *comprobar si esta es la posici�n inferior
		ldrb r9, [r0, r10]			@; Ahora r9 contiene el valor que hay en la posici�n r10
		cmp r9, #7
		beq .incrementa_posicion
		cmp r9, #15
		beq .incrementa_posicion
		and r9, #0x07		
		cmp r9, #0					@; Se comprueba que r9 no sea espacio vac�o, bloque s�lido o hueco
		beq .incrementa_posicion
		ldrb r6, [r0, r5]			@; r6 es el valor de la posici�n r5
		strb r9, [r0, r5]			@; Ahora en la posici�n r5 est� el valor de la posici�n r10
		strb r6, [r0, r10]			@; Ahora en la posici�n r10 est� el valor de la posici�n r5, copiado anteriormente en r6
		sub r1, #1
		
		@; detectar_orientacion
		
	@;	Par�metros:
	@;		R1 = fila 'f'
	@;		R2 = columna 'c'
	@;		R4 = direcci�n base de la matriz
	@;	Resultado:
	@;		R0 = c�digo de orientaci�n;
	@;				inicio de secuencia: 0 -> Este, 1 -> Sur, 2 -> Oeste, 3 -> Norte
	@;				en medio de secuencia: 4 -> horizontal, 5 -> vertical
	@;				sin secuencia: 6 
	
	mov r11, r0
	mov r4, r0
	bl detectar_orientacion
	@;cmp r0, #6
	@;blo .secuenciaEncontrada
	
	mov r3, #COLUMNS
	mov r4, #ROWS
	@;mov r0, r11
	mov r5, r12
	
		@; Se devuelven los n�meros a sus posiciones originales
	
		
		ldrb r6, [r11, r10]			@; En r6 se ha guardado el valor que hay ahora en la posici�n r10
		ldrb r9, [r11, r5]			@; En r9 se ha guardado el valor nuevo de la posici�n r5
		strb r6, [r11, r5]			@; En la posici�n r5 se ha guardado el valor que ten�a la posici�n r10, guardado anteriormente en r6
		strb r9, [r11, r10]			@; En la posici�n r10 se ha guardado el valor que ten�a la posici�n r5, guardado anteriormente en r9
		cmp r0, #6
		blo .secuenciaEncontrada
		mov r0, r11					@; Se devuelve la direcci�n de la matriz
		
		.ultima_fila:
		.incrementa_posicion:
		add r2, #1
		cmp r2, r3
		blo .startBucle
		add r1, #1
		mov r2, #0
		cmp r1, r4
		blo .startBucle
		.endBucle:
		
		mov r0, #0
		b .fin
		
		.secuenciaEncontrada:
		mov r0, #1
		
		.fin:
		
		pop {R1-R12, pc}



@;TAREA 1H;
@; sugiere_combinacion(*matriz, *sug): rutina para detectar una combinaci�n
@;	entre dos elementos (diferentes) consecutivos que provoquen una secuencia
@;	v�lida, incluyendo elementos en gelatinas simples y dobles, y devolver
@;	las coordenadas de las tres posiciones de la combinaci�n (por referencia).
@;	Restricciones:
@;		* se supone que existe por lo menos una combinaci�n en la matriz
@;			 (se debe verificar antes con la rutina 'hay_combinacion')
@;		* la combinaci�n sugerida tiene que ser escogida aleatoriamente de
@;			 entre todas las posibles, es decir, no tiene que ser siempre
@;			 la primera empezando por el principio de la matriz (o por el final)
@;		* para obtener posiciones aleatorias, se invocar� la rutina 'mod_random'
@;			 (ver fichero "candy1_init.s")
@;	Par�metros:
@;		R0 = direcci�n base de la matriz de juego
@;		R1 = direcci�n del vector de posiciones (char *), donde la rutina
@;				guardar� las coordenadas (x1,y1,x2,y2,x3,y3), consecutivamente.
@; Variables:
@; 		R2 = columna
@;		R3 = fila
@;		R4 = total filas
@;		R5 = total columnas
@;		R6 = posici�n cuando se recorre la matriz
@;		R7 = valor que hay en la posici�n r6
@; 		R8 = total de filas - 1
@; 		R9 = total de columnas -1
@; 		R10 = posici�n derecha / valor posici�n R10
@;		R11 = posici�n de abajo / valor posici�n R9

	.global sugiere_combinacion
	
sugiere_combinacion:
		push {r2-r12, lr} 

		pop {r2-r12, pc}






@;:::RUTINAS DE SOPORTE:::







@; detectar_orientacion(f,c,mat): devuelve el c�digo de la primera orientaci�n
@;	en la que detecta una secuencia de 3 o m�s repeticiones del elemento de la
@;	matriz situado en la posici�n (f,c).
@;	Restricciones:
@;		* para proporcionar aleatoriedad a la detecci�n de orientaciones en las
@;			que se detectan secuencias, se invocar� la rutina 'mod_random'
@;			(ver fichero "candy1_init.s")
@;		* para detectar secuencias se invocar� la rutina 'cuenta_repeticiones'
@;			(ver fichero "candy1_move.s")
@;		* s�lo se tendr�n en cuenta los 3 bits de menor peso de los c�digos
@;			almacenados en las posiciones de la matriz, de modo que se ignorar�n
@;			las marcas de gelatina (+8, +16)
@;	Par�metros:
@;		R1 = fila 'f'
@;		R2 = columna 'c'
@;		R4 = direcci�n base de la matriz
@;	Resultado:
@;		R0 = c�digo de orientaci�n;
@;				inicio de secuencia: 0 -> Este, 1 -> Sur, 2 -> Oeste, 3 -> Norte
@;				en medio de secuencia: 4 -> horizontal, 5 -> vertical
@;				sin secuencia: 6 
detectar_orientacion:
		push {r3,r5,lr}
		
		mov r5, #0				@;R5 = �ndice bucle de orientaciones
		mov r0, #4
		bl mod_random
		mov r3, r0				@;R3 = orientaci�n aleatoria (0..3)
	.Ldetori_for:
		mov r0, r4
		bl cuenta_repeticiones
		cmp r0, #1
		beq .Ldetori_cont		@;no hay inicio de secuencia
		cmp r0, #3
		bhs .Ldetori_fin		@;hay inicio de secuencia
		add r3, #2
		and r3, #3				@;R3 = salta dos orientaciones (m�dulo 4)
		mov r0, r4
		bl cuenta_repeticiones
		add r3, #2
		and r3, #3				@;restituye orientaci�n (m�dulo 4)
		cmp r0, #1
		beq .Ldetori_cont		@;no hay continuaci�n de secuencia
		tst r3, #1
		bne .Ldetori_vert
		mov r3, #4				@;detecci�n secuencia horizontal
		b .Ldetori_fin
	.Ldetori_vert:
		mov r3, #5				@;detecci�n secuencia vertical
		b .Ldetori_fin
	.Ldetori_cont:
		add r3, #1
		and r3, #3				@;R3 = siguiente orientaci�n (m�dulo 4)
		add r5, #1
		cmp r5, #4
		blo .Ldetori_for		@;repetir 4 veces
		
		mov r3, #6				@;marca de no encontrada
		
	.Ldetori_fin:
		mov r0, r3				@;devuelve orientaci�n o marca de no encontrada
		
		pop {r3,r5,pc}


@; generar_posiciones(vect_pos,f,c,ori,cpi): genera las posiciones de sugerencia
@;	de combinaci�n, a partir de la posici�n inicial (f,c), el c�digo de
@;	orientaci�n 'ori' y el c�digo de posici�n inicial 'cpi', dejando las
@;	coordenadas en el vector 'vect_pos'.
@;	Restricciones:
@;		* se supone que la posici�n y orientaci�n pasadas por par�metro se
@;			corresponden con una disposici�n de posiciones dentro de los l�mites
@;			de la matriz de juego
@;	Par�metros:
@;		R0 = direcci�n del vector de posiciones 'vect_pos'
@;		R1 = fila inicial 'f'
@;		R2 = columna inicial 'c'
@;		R3 = c�digo de orientaci�n;
@;				inicio de secuencia: 0 -> Este, 1 -> Sur, 2 -> Oeste, 3 -> Norte
@;				en medio de secuencia: 4 -> horizontal, 5 -> vertical
@;		R4 = c�digo de posici�n inicial:
@;				0 -> izquierda, 1 -> derecha, 2 -> arriba, 3 -> abajo
@;	Resultado:
@;		vector de posiciones (x1,y1,x2,y2,x3,y3), devuelto por referencia

generar_posiciones:
		push {R5-R12, lr}
			
		pop {R5-R12, pc}

.end