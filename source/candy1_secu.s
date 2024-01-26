@;=                                                               		=
@;=== candy1_secu.s: rutinas para detectar y elimnar secuencias 	  ===
@;=                                                             	  	=
@;=== Programador tarea 1C: eduard.vericat@estudiants.urv.cat				  ===
@;=== Programador tarea 1D: eduard.vericat@estudiants.urv.cat				  ===
@;=                                                           		   	=

.include "../include/candy1_incl.i"

@;-- .bss. variables (globales) no inicializadas ---
.bss
		.align 2
@; número de secuencia: se utiliza para generar números de secuencia únicos,
@;	(ver rutinas 'marcar_horizontales' y 'marcar_verticales') 
	num_sec:	.space 1


@;-- .text. código de las rutinas ---
.text	
		.align 2
		.arm

@;TAREA 1C;
@; hay_secuencia(*matriz): rutina para detectar si existe, por lo menos, una
@;	secuencia de tres elementos iguales consecutivos, en horizontal o en
@;	vertical, incluyendo elementos en gelatinas simples y dobles.
@;	Rest


@;		* para detectar secuencias se invocará la rutina 'cuenta_repeticiones'
@;			(ver fichero "candy1_move.s")
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;	Resultado:
@;		R0 = 1 si hay una secuencia, 0 en otro caso
	.global hay_secuencia
hay_secuencia:
		push {r1-r4,r6-r7,r10-r12, lr}
			@; R0 -> Direcció de la matriu
			@; R1 -> INDEX de les files
			@; R2 -> INDEX de les columnes
			@; R3 -> INDEX de la orientació
			@; R10 -> copia direccio de la matriu
			@; R11 -> numero de columnes
			
			mov r10, r0			@; Copiem la direccio de la matriu per tindrela guardada
			mov r1, #0			@; Assignem el valor incial a r1
			mov r11, #COLUMNS	@; Guardem el numero total de columnes
			
			@; Iniciem el bucle de les files
			bucle_files:
				cmp r2, #COLUMNS
				addeq r1, #1		@; Si hem recorregut totes les columnes incrementem les files	
				cmp r1, #ROWS	
				moveq r0, #0		@; S'asigna el valor a r0 si el valor de r1 es igual
				bge fi
				
				@; Iniciem el bucle de les columnes
				mov r2, #0
				bucle_columnes:
					cmp r2, #COLUMNS
					beq bucle_files
					
					mla r6, r1, r11, r2	@; (i*n_col) + j
					
					ldrb r7, [r10, r6]	@; guardem a r7 -> matriu[r6]
					
					and r7, #0x07	@; Si l'element actual es un 7 o un 15 no l'analitzem
					cmp r7, #0x07
					beq no_valid
					tst r7, #0x07	@; Si l'element actual es un 0 8 o 16 no l'analitzem
					beq no_valid
					
					cmp r1, #ROWS-2
					bge nomes_horitzontal
					cmp r2, #COLUMNS-2
					bge nomes_vertical
					
					@; Iniciem el bucle de la orientació que comprovara en horitzontal i vertical
					mov r3, #0
					bucle_orientacio:
						cmp r3, #2
						addge r2, #1	@; Si hem recorregut totes les orientacions incrementem r2 (columnes)
						beq bucle_columnes
						
						mov r0, r10		@; Copiem la direccio de la matriu a r0
						bl cuenta_repeticiones
						cmp r0, #3		@; Si el resultat de cuenta_repeticiones es 3 o major hi ha seqüencia 
						movge r0, #1	@; Nomes s'asignara el valor a r0 si es major o igual a 3
						bge fi
						
						add r3, #1
					b bucle_orientacio
					b no_valid
					
					nomes_horitzontal:
						cmp r2, #COLUMNS-2
						bge no_valid
						
						mov r3, #0		@; Orientacio nomes horitzontal
						mov r0, r10		@; Copiem la direccio de la matriu a r0
						
						bl cuenta_repeticiones
						cmp r0, #3		@; Si el resultat de cuenta_repeticiones es 3 o major hi ha seqüencia 
						movge r0, #1	@; Nomes s'asignara el valor a r0 si es major o igual a 3
						bge fi
					b no_valid		@; Passem a la seguent columna
					
					
					nomes_vertical:
						cmp r1, #ROWS-2
						bge no_valid
					
						mov r3, #1		@; Orientacio nomes vertical
						mov r0, r10		@; Copiem la direccio de la matriu a r0
						
						bl cuenta_repeticiones
						cmp r0, #3		@; Si el resultat de cuenta_repeticiones es 3 o major hi ha seqüencia 
						movge r0, #1	@; Nomes s'asignara el valor a r0 si es major o igual a 3
						bge fi
					
					no_valid:
					add r2, #1	
				b bucle_columnes
			fi:
		pop {r1-r4,r6-r7,r10-r12, pc}



@;TAREA 1D;
@; elimina_secuencias(*matriz, *marcas): rutina para eliminar todas las
@;	secuencias de 3 o más elementos repetidos consecutivamente en horizontal,
@;	vertical o combinaciones, así como de reducir el nivel de gelatina en caso
@;	de que alguna casilla se encuentre en dicho modo; 
@;	además, la rutina marca todos los conjuntos de secuencias sobre una matriz
@;	de marcas que se pasa por referencia, utilizando un identificador único para
@;	cada conjunto de secuencias (el resto de las posiciones se inicializan a 0). 
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;		R1 = dirección de la matriz de marcas
	.global elimina_secuencias
elimina_secuencias:
		push {r6-r8, lr}
				
				mov r6, #0
				mov r8, #0				@;R8 es desplazamiento posiciones matriz
			.Lelisec_for0:
				strb r6, [r1, r8]		@;poner matriz de marcas a cero
				add r8, #1
				cmp r8, #ROWS*COLUMNS
			blo .Lelisec_for0
			
			bl marcar_horizontales
			bl marcar_verticales
			
			bl eliminar_gelatines
			
		pop {r6-r8, pc}


	
@;:::RUTINAS DE SOPORTE:::


@; marcar_horizontales(mat): rutina para marcar todas las secuencias de 3 o más
@;	elementos repetidos consecutivamente en horizontal, con un número identifi-
@;	cativo diferente para cada secuencia, que empezará siempre por 1 y se irá
@;	incrementando para cada nueva secuencia, y cuyo último valor se guardará en
@;	la variable global 'num_sec'; las marcas se guardarán en la matriz que se
@;	pasa por parámetro 'mat' (por referencia).
@;	Restricciones:
@;		* se supone que la matriz 'mat' está toda a ceros
@;		* para detectar secuencias se invocará la rutina 'cuenta_repeticiones'
@;			(ver fichero "candy1_move.s")
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;		R1 = dirección de la matriz de marcas
marcar_horizontales:
		push {r0-r12, lr}
		
			mov r6, #1	@; Identificador de les seqüencies
			mov r3, #0	@; Assignem la orientacio
			mov r10, r0			@; Copiem la direccio de la matriu per tindrela guardada
			mov r12, r1			@; Copiem la direccio de la matriu de marques
			mov r1, #0			@; Assignem el valor incial a r1
			mov r11, #COLUMNS	@; Guardem el numero total de columnes			
			mov r8, #0	@; Identificador que comença per 1 i s'anirà incrementant
			mov r2, #0
			@; Iniciem el bucle de les files
			bucle_files1:
				cmp r2, #COLUMNS-2
				addge r1, #1		@; Si hem recorregut totes les columnes incrementem les files	
				cmp r1, #ROWS	
				beq fi1
				@; Iniciem el bucle de les columnes
				mov r2, #0
				bucle_columnes1:
					cmp r2, #COLUMNS-2
					bge bucle_files1
					
					mla r6, r1, r11, r2	@; (i*n_col) + j
					
					ldrb r7, [r10, r6]	@; guardem a r7 -> matriu[r6]
					
					and r7, #0x07	@; Si l'element actual es un 7 o un 15 no l'analitzem
					cmp r7, #0x07
					beq no_valid1
					tst r7, #0x07	@; Si l'element actual es un 0 8 o 16 no l'analitzem
					beq no_valid1
				
					mov r4, #0	@; repeticions
					mov r0, r10		@; Copiem la direccio de la matriu a r0
					bl cuenta_repeticiones
						
					cmp r0, #3		@; Si el resultat de cuenta_repeticiones es 3 o major hi ha seqüencia
					addge r8, #1	@; Incrementem el numero de indentificador 
					blt no_valid1
					
					for1:
						cmp r4, r0
						addge r2, r4
						subge r2, #2
						bge no_valid1
						
						add r9, r2, r4	@; sumem les columnes actuals mes les seguents (j)
						mla r6, r1, r11, r9	@; (i*n_col) + j
						
						strb r8, [r12, r6]	@; introduim un 1 a cada lloc on estigui repetit
						add r4, #1	@; incrementem les repeticions
					b for1
					
					
					no_valid1:
					add r2, #1	
				b bucle_columnes1
			fi1:
			
			ldr r5, =num_sec
			strb r8, [r5]
			
			
		pop {r0-r12, pc}

@; rutina que comprova si dins de la sequencia trobada hi ha alguna posicio on ja hi hagi 
@; un numero, cosa que voldra dir que s'ha trobat una interseccio.
@;	Parámetros:
@;		R0 = numero de repeticiones
@;		R1 = numero de filas
@;		R2 = numero de columnas
@;		R12 = dirección de la matriz de marcas
@;		
@;	Retorna:
@;		R7 = boolean de si hi ha interseccio	0-(no)	1-(si)
@;		R5 = numero que sha de posar a la interseccio
comprovar_interseccio:
		push {r0-r4, r6, r8-r11, lr}
			
			mov r4, #0
			mov r5, #0
			mov r7, #0
			
			for3:
				cmp r4, r0
				bge ficompr
				add r9, r1, r4	@; sumem les columnes actuals mes les seguents (j)
				mla r6, r9, r11, r2	@; (i*n_col) + j
						
				ldrb r5, [r12, r6]	@; agafem el numero que hi ha a la posicio de l'array
						
				cmp r5, #0
				movne r5, r5	@; movem l'identificador que hi ha a r5 cap a r10	
				bne interseccioTrobada
			
				add r4, #1	@; incrementem les repeticions
			b for3
			b ficompr
			
			interseccioTrobada:	@; s'ha trobat una interseccio
			mov r7, #1	@; activem el boolean
			
			ficompr:
		
		pop {r0-r4, r6, r8-r11, pc}

@; marcar_verticales(mat): rutina para marcar todas las secuencias de 3 o más
@;	elementos repetidos consecutivamente en vertical, con un número identifi-
@;	cativo diferente para cada secuencia, que seguirá al último valor almacenado
@;	en la variable global 'num_sec'; las marcas se guardarán en la matriz que se
@;	pasa por parámetro 'mat' (por referencia);
@;	sin embargo, habrá que preservar los identificadores de las secuencias
@;	horizontales que intersecten con las secuencias verticales, que se habrán
@;	almacenado en en la matriz de referencia con la rutina anterior.
@;	Restricciones:
@;		* se supone que la matriz 'mat' está marcada con los identificadores
@;			de las secuencias horizontales
@;		* la variable 'num_sec' contendrá el siguiente indentificador (>=1)
@;		* para detectar secuencias se invocará la rutina 'cuenta_repeticiones'
@;			(ver fichero "candy1_move.s")
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;		R1 = dirección de la matriz de marcas
marcar_verticales:
		push {r0-r12, lr}
			
			mov r3, #1	@; Assignem la orientacio
			mov r10, r0			@; Copiem la direccio de la matriu per tindrela guardada
			mov r12, r1			@; Copiem la direccio de la matriu de marques
			mov r1, #0			@; Assignem el valor incial a r1
			mov r11, #COLUMNS	@; Guardem el numero total de columnes			
			mov r2, #0
			
			ldr r5, =num_sec
			ldrb r8, [r5]
			
			@; Iniciem el bucle de les files
			bucle_files2:
				cmp r2, #COLUMNS
				addge r1, #1		@; Si hem recorregut totes les columnes incrementem les files	
				cmp r1, #ROWS-2	
				bge fi2
				@; Iniciem el bucle de les columnes
				mov r2, #0
				bucle_columnes2:
					cmp r2, #COLUMNS
					bge bucle_files2
					
					mla r6, r1, r11, r2	@; (i*n_col) + j
					
					ldrb r7, [r10, r6]	@; guardem a r7 -> matriu[r6]
					
					and r7, #0x07	@; Si l'element actual es un 7 o un 15 no l'analitzem
					cmp r7, #0x07
					beq no_valid2
					tst r7, #0x07	@; Si l'element actual es un 0 8 o 16 no l'analitzem
					beq no_valid2
					
					@; Assignem la orientació
				
					mov r4, #0	@; repeticions
					mov r0, r10		@; Copiem la direccio de la matriu a r0
					
					bl cuenta_repeticiones
					cmp r0, #3		@; Si el resultat de cuenta_repeticiones es 3 o major hi ha seqüencia
					blt no_valid2
					
					bl comprovar_interseccio
					cmp r7, #0		@; comprovem si hi ha interseccio
					addeq r8, #1	@; Incrementem el numero de indentificador
					
						for2:
							cmp r4, r0
							@;addge r2, r4
							@;subge r2, #2
							bge no_valid2
							
							add r9, r1, r4	@; sumem les columnes actuals mes les seguents (j)
							mla r6, r9, r11, r2	@; (i*n_col) + j
							
							@;ldrb r5, [r12, r6]	@; agafem el numero que hi ha a la posicio de l'array
							
							
							cmp r7, #1
							beq interseccio
							
							strb r8, [r12, r6]	@; introduim un 1 a cada lloc on estigui repetit
							b fiinterseccio
							
							interseccio:
							strb r5, [r12, r6]	@; introduim un 1 a cada lloc on estigui repetit
							
							fiinterseccio:
							add r4, #1	@; incrementem les repeticions
						b for2
					no_valid2:
					add r2, #1	
				b bucle_columnes2
			fi2:
		pop {r0-r12, pc}
	
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;		R1 = dirección de la matriz de marcas
eliminar_gelatines:
	
	push {r3-r6, r11-r12, lr}
	 
			mov r12, #0	@; Identificador per les sequencies sense gelatina doble
			mov r11, #8	@; Identificador per les sequencies sense gelatina simple
			
			mov r4, #0				@; R4 es desplazamiento posiciones matriz
		.Lelisec_for1:
			ldrb r3, [r1, r4]		@; posar la matriu de gelatines a 0
			
			cmp r3, #0
			beq fi3
			ldrb r6, [r0, r4]
			and r5, r6, #0x018	@; per comprovar si es una gelatina simple o no
			cmp r5, #16
			beq gelatinadoble
			
				strb r12, [r0, r4]	@; guardar un 8 a la posicio on hi ha una gelatina doble
			
			b fi3
			
			gelatinadoble:
				strb r11, [r0, r4]	@; guardar un 8 a la posicio on hi ha una gelatina doble
			
			fi3:
			
			add r4, #1
			cmp r4, #ROWS*COLUMNS
		blo .Lelisec_for1
		

	pop {r3-r6, r11-r12, pc}
.end
