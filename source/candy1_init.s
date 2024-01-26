@;=                                                          	     	=
@;=== candy1_init.s: rutinas para inicializar la matriz de juego	  ===
@;=                                                           	    	=
@;=== Programador tarea 1A: alfonso.sanchez@estudiants.urv.cat				  ===
@;=== Programador tarea 1B: alfonso.sanchez@estudiants.urv.cat				  ===
@;=                                                       	        	



.include "../include/candy1_incl.i"



@;-- .bss. variables (globales) no inicializadas ---
.bss
		.align 2
@; matrices de recombinaci�n: matrices de soporte para generar una nueva matriz
@;	de juego recombinando los elementos de la matriz original.
	mat_recomb1:	.space ROWS*COLUMNS
	mat_recomb2:	.space ROWS*COLUMNS



@;-- .text. c�digo de las rutinas ---
.text	
		.align 2
		.arm



@;TAREA 1A;
@; inicializa_matriz(*matriz, num_mapa): rutina para inicializar la matriz de
@;	juego, primero cargando el mapa de configuraci�n indicado por par�metro (a
@;	obtener de la variable global 'mapas'), y despu�s cargando las posiciones
@;	libres (valor 0) o las posiciones de gelatina (valores 8 o 16) con valores
@;	aleatorios entre 1 y 6 (+8 o +16, para gelatinas)
@;	Restricciones:
@;		* para obtener elementos de forma aleatoria se invocar� la rutina
@;			'mod_random'
@;		* para evitar generar secuencias se invocar� la rutina
@;			'cuenta_repeticiones' (ver fichero "candy1_move.s")
@;	Par�metros:
@;		R0 = direcci�n base de la matriz de juego
@;		R1 = n�mero de mapa de configuraci�n
	.global inicializa_matriz
inicializa_matriz:
		push {R0-R12, lr}		@;guardar registros utilizados
			
			@; === MATRIZ DE NIVEL A USAR ===
			@; Obtenemos el valor inicial de posicion de memoria donde empieza el mapa del
			@; nivel que queremos generar en la matriz.
			mov r2, #ROWS*COLUMNS
			mul r3, r1, r2 @; r3 = num_level * num_elem_matr
			
			
			ldr r12, =mapas @; r12 tiene la dir inicial de los esquemas de niveles.
			add r12, r3 @; Desplazamos la dir inicial tantas posiciones como nivel requerido.
			mov r2, r12 
			mov r3, #0 @; i = 0 - fila
			
			@; Informacion de entrada al bucle
			@; r0 = Dir matriz juego
			@; r2 = Dir matriz mapa/esquema
			@; r3 = i - fila
			
		@; === BUCLES DE GENERACION MATRIZ DE JUEGO ====
		.Lfori:
			mov r12, #COLUMNS @; R12 = COLUMNS
			mul r5, r3, r12 @; i * COLUMNS
			mov r4, #0 @; j = 0 - columna
		.Lforj:
			add r6, r5, r4 @; i*COLUMNS + j
				
			ldrb r7, [r2, r6] @; Obtener dato del mapa de nivel a generar.
 
			@; Verificamos los 3 bits de menor peso. Si es diferente de 000 [tipo a descartar] > (1-6, 7, 15)
			tst r7, #0x07 @; Hace un AND bit a bit, si el resultado es 000 activa la Zero Flag (0, 8, 16)
			beq .GenerarAleatorio @; Si se activa la Zero Flag significa que no es (1-6, 7, 15).
			
			@; === ZONA DE GUARDADO DIRECTO, SIN TRATAR EL VALOR OBTENIDO DEL MAPA NIVEL ==
			strb r7, [r0, r6] @; 
			@; Saltamos al final del bucle, para pasar al siguiente valor del mapa nivel.
			b .contBucleJ
			
			@; === SI ES UN ELEMENTO, GELATINA O GELATINA DOBLE PASA AQUI (0, 8, 16)====
			.GenerarAleatorio:
			mov r11, r0 @; r11 = dir matriz juego
			mov r0, #6 @; modrandom (0-5)
			bl mod_random
			@; Generamos un numero eleatorio entre 0-5 el cual se añadira al elemento/gelatina/gelatina d.
			@; Ya que el mapa nivel, solo tiene los elementos base.
			add r0, #1 @; num_aleat + 1 = (0-5 > 1-6)
			add r8, r7, r0 @; dato + numero_aleat
					
			strb r8, [r11, r6] @; Guardar dato en la matriz de juego.				
			
			@; === BLOQUE COMPRUEBA SECUENCIA EN LA MATRIZ DE JUEGO ====
			mov r0, r11 @; Le pasamos la matriz de juego a la funcion.
			mov r1, r3 @; Fila / en este caso ya no es necesario almacenar el nivel, el puntero de matriz mapa ya esta desplazado.
			mov r10, r2 @; Guardo matriz mapa
			mov r2, r4 @; Columna
					
			bl hay_secuencia_n_o @; Comprobamos si se ha generado una secuencia N y O con el nuevo dato en la matriz de juego.
			mov r9, r0
			mov r0, r11 @; Recupero matriz juego
			mov r2, r10 @; Recupero matriz mapa
			cmp r9, #0 @; Si devuelve 0 = false (No hay secuencia)
			bne .GenerarAleatorio
					
		.contBucleJ:
			add r4, #1 @; j++
			cmp r4, #COLUMNS
			blt .Lforj @; j < columnas
			
			add r3, #1 @; i++
			cmp r3, #ROWS @; 
			blt .Lfori @; i < filas > bucle_filas.
			
			@; Fin programa, no tenemos que devolver el r0 por que se ha pasado por referencia.
		
		pop {R0-R12, pc}			@;recuperar registros y volver



@;TAREA 1B;
@; recombina_elementos(*matriz): rutina para generar una nueva matriz de juego
@;	mediante la reubicaci�n de los elementos de la matriz original, para crear
@;	nuevas jugadas.
@;	Inicialmente se copiar� la matriz original en 'mat_recomb1', para luego ir
@;	escogiendo elementos de forma aleatoria y colocandolos en 'mat_recomb2',
@;	conservando las marcas de gelatina.
@;	Restricciones:
@;		* para obtener elementos de forma aleatoria se invocar� la rutina
@;			'mod_random'
@;		* para evitar generar secuencias se invocar� la rutina
@;			'cuenta_repeticiones' (ver fichero "candy1_move.s")
@;		* para determinar si existen combinaciones en la nueva matriz, se
@;			invocar� la rutina 'hay_combinacion' (ver fichero "candy1_comb.s")
@;		* se supondr� que siempre existir� una recombinaci�n sin secuencias y
@;			con combinaciones
@;	Par�metros:
@;		R0 = direcci�n base de la matriz de juego
	.global recombina_elementos
recombina_elementos:
		push {R0-R12,lr}
		.empezar_de_nuevo:
			ldr r1, =mat_recomb1
			mov r2, r0 @; Guardamos la matriz de juego
			
			bl crear_matrecomb1
			
			mov r3, r0 @; recomb1
			mov r0, r2 @; r0 = mat_juego
			ldr r1, =mat_recomb2
			
			@; Tenemos en r0 mat_juego y r1 mat_recomb2
			
			bl crear_matrecomb2
			
			@;Guardamos ahora todos los datos en orden.
			mov r4, r0 @; recomb2
			mov r0, r2 @; r0 = matjuego
			mov r1, r3 @; r1 = matrecomb 1
			mov r2, r4 @; r2 = matrecomb 2
			
			@; Datos en este punto del programa.
			@; r0 = matjuego
			@; r1 = matrecomb1
			@; r2 = matrecomb2
			bl crear_matriz_recomb
			
			cmp r3, #0 @; La rutina, crear_matriz_recomb genera un bool que devuelve 1 (true) si todo OK | 0 si no OK
			beq .empezar_de_nuevo
			
			mov r1, r2 @; r1 = matrecomb2
			bl copiar_matriz_recomb_juego @; Simplemente esta rutina copia todo el contenido de matrecomb2 en la matriz de juego.
			
			
		pop {R0-R12,pc}

	@; ======= Rutinas recombina_elemetos =======
	
	@; 	crear_matrecomb1: rutina para cargar en matrecomb1 transformando los bloques solidso, huecos y gelatinas vacias en ceros.
	@;	Transforma las gelatinas simples y dobles a su codigo basico. 
	@;	Restricciones:
	@;		* Solo puede recibir por parametro la direccion de la matriz a trabajar.
	@;	Par�metros:
	@;		R0 = matriz de juego
	@;		R1 = matriz matrecomb1
	@;	Resultado:
	@;		R0 = matriz matrecomb1

	crear_matrecomb1:
		push {r1-r7, lr}
		
			mov r2, #0 @; i = 0
			
		.LforI:
			mov r7, #COLUMNS @; r12 = COLUMNS
			mul r4, r2, r7 @; i * COLUMNS

			mov r3, #0 @; j = 0

		.LforJ:
			add r5, r4, r3 @; i * COLUMNS + j
					
			ldrb r6, [r0, r5] @; Obtenemos el dato de la matriz de juego. 
					
			@; === BLOQUE DE COMPROBACION DEL DATO OBTENIDO EN LA MATRIZ DE JUEGO ====
			@; Si ( R6 == 7 || R6 == 15 || R6 == 8 || R6 == 16) >> R6 = 0 y guardar directamente en matrecomb1.
					
			tst r6, #0x07 @; Si el dato es 0, 8, 16 se pone a 0. Aun que en el caso del 0 es totalmente redundante... 
			beq .DatoIgualCero
					
			and r7, r6, #7 @; Veriicamos tambien que el dato 
			cmp r7, #7
			beq .DatoIgualCero
					
			@; Si (r6 < 9 && r6 >= 15) >> Pasamos a la comprobacion de las gemas dobles \\ si no >> Generamos el codigo simple de r6.
			cmp r6, #9
			blt .CompDob @; dato < 9 & dato >= 15 == Fuera del rango (comp doble)
			cmp r6, #15
			bge .CompDob
			b .GenerarCodSimp
					
			@; Si (r6 < 17 && r6 > 23) >> Guardamos el dato directamente \\ Si no >> Generamos el codigo doble de r6.
		.CompDob:
			cmp r6, #17
			blt .FueraRango @; dato < 17 & dato > 23 == Fuera del rango (Guardar dato)
			cmp r6, #23
			bhi .FueraRango
			b .GenerarCodDob
					
			@; ==== BLOQUE DE DIFERENTES TRATADOS DEL DATO, SEGUN LAS CONDICIONES ANTERIORES A ESTE BLOQUE =====
		.GenerarCodSimp:
			sub r6, #8
			b .GuardarDato
					
		.GenerarCodDob:
			sub r6, #16
			b .GuardarDato
					
		.FueraRango:
			b .GuardarDato
					
		.DatoIgualCero:
			mov r6, #0;

		.GuardarDato:
			strb r6, [r1, r5] @; Guardamos el dato dentro de la matriz recomb1
					
			@; j ++ & j < Columns
			add r3, #1
			cmp r3, #COLUMNS
			blt .LforJ
			@; FIN FOR J
				
			@; i++ & i < rows
			add r2, #1
			cmp r2, #ROWS
			blt .LforI
			@; FIN FOR I
				
			mov r0, r1 @; Copiamos matrecomb1 a r0 para devolver.
				
		pop {r1-r7, pc}
		
	@; 	crear_matrecomb2: rutina para cargar en matrecomb2 transformando los elementos basicos 1-6 en 0.
	@;	Transforma las gelatinas simples y dobles a su codigo basico.
	@;	Copia cualquier otro elemento directamente (bloque solido, huecos).
	@;	Restricciones:
	@;		* Solo puede recibir por parametro la direccion de la matriz a trabajar.
	@;	Par�metros:
	@;		R0 = matriz de juego
	@;		R1 = matriz matrecomb2
	@;	Resultado:
	@;		R0 = matriz matrecomb2
	
	crear_matrecomb2:	
		push {r1-r7, lr}
			mov r2, #0 @; i = 0
			
		.LforI2:
			mov r7, #COLUMNS @; r7 = COLUMNS
			mul r4, r2, r7 @; i * COLUMNS

			mov r3, #0 @; j = 0

		.LforJ2:
			add r5, r4, r3 @; i * COLUMNS + j
					
			ldrb r6, [r0, r5] @; Obtenemos el dato de la matriz de juego.
				
			@; === BLOQUE DE COMPROBACIONES Y FILTRADO DEL DATO DE LA MATRIZ DE JUEGO===	
				
			tst r6, #0x07 @; bits 2..0 (espacio vacio, gels vacia, geld vacia)
			beq .GuardarDato2 @; Si (r6 = 0 || r6 = 8 || r6 = 16) >> Se guarda directamente
					
			and r7, r6, #7
			cmp r7, #7 @; Si (r6 = 7 || r6 = 15) >> Se guarda directamente
			beq .GuardarDato2 @; Se guardan los huecos y los bloques solidos.
				
			@; AND R6 con (11000) = (0x18) = (24) >> Compruebo los 2 bits mas altos para detectar que tipo de elemento/gelatina estamos tratando.
			and r7, r6, #0x18
			cmp r7, #0 @; Es un elemento simple?
			beq .DatoIgualCero2
			cmp r7, #8 @; Es una gelatina simple?
			beq .GenerarCodSimp2
			cmp r7, #16 @; Es una gelatina doble?
			beq .GenerarCodDob2
				
			@; === BLOQUE DE TRATADO DE DATO, SEGUN LAS CONDICIONES ENCONTRADAS EN LAS COMPROBACIONES ===
				
		.GenerarCodSimp2:
			mov r6, #8
			b .GuardarDato2
					
		.GenerarCodDob2:
			mov r6, #16
			b .GuardarDato2
					
		.DatoIgualCero2:
			mov r6, #0;
					
		.GuardarDato2:
			strb r6, [r1, r5] @; Guardamos el dato dentro de la matriz recomb1
					
			@; j ++ & j < Columns
			add r3, #1
			cmp r3, #COLUMNS
			blt .LforJ2
			@; FIN FOR J
				
			@; i++ & i < rows
			add r2, #1
			cmp r2, #ROWS
			blt .LforI2
			@; FIN FOR I
				
			mov r0, r1 @; Copiamos matrecomb para devolver.
				
		pop {r1-r7, pc}
		
	
	@; Genera la matriz recombinada dentro de matrecomb2 siguiendo las siguientes instrucciones
	@; 1. Recorre la matriz de juego. (ok)
	@; 2. Ignora los espacios vacios, bloques solidos o hueco. (ok)
	@; 3. Selecciona una posicion aleatoria de matrecomb_1 con elemento distinto a 0. (ok)
	@; 4. Anade el codigo de elemento obtenido de mat_recomb1 a la posicion actual en mat_recomb2 sumando el codigo de gelatina aleatorio. (ok)
	@; 5. Comprobar que no genera ninguna secuencia horizontal ni vertical. (ok)
	@; 6. Si hay secuencia volver al valor anterior en matrecomb2 y volver paso 3. (ok)
	@; 7. Una vez completado se acaba el programa. (ok)
	@;	Restricciones:
	@;		* Solo puede recibir por parametro la direccion de la matriz a trabajar.
	@;	Par�metros:
	@;		R0 = matriz de juego
	@;		R1 = matriz matrecomb1
	@;		R2 = matriz matrecomb2
	@;	Devuelve:
	@;		R0 = matriz de juego
	@;		R1 = matriz matrecomb1
	@;		R2 = matriz matrecomb2
	@;		R3 = True/False (1) (0) 
	crear_matriz_recomb:
		push {r4-r12, lr}
				mov r3, #0 @; i = 0
			.Lfori4:
				mov r4, #0 @; j = 0 - columna
				mov r5, #COLUMNS @; R12 = ROWS
				mul r6, r3, r5 @; i * COLUMNS
			.Lforj4:
				add r7, r6, r4 @; i*COLUMNS + j 
				ldrb r8, [r0, r7] @; Obtener dato mapa
				
				tst r8, #0x07 @; Si el valor del dato del mapa (r8) es (0, 8, 16) nos lo saltamos.
				beq .contBucleJ4 @;
				and r9, r8, #7 @; Si el valor dentro del dato del mapa (r8) es (7 o 15) nos lo saltamos. 
				cmp r9, #7
				beq .contBucleJ4
				
				@; Hacemos una copia de los registros, ya que la funcion a llamar devuelve bastantes registros. 
				mov r8, r0 @; r8 = mat juego
				mov r9, r1 @; r9 = matrecomb1
				mov r10, r2 @; r10 = matrecomb2
				mov r11, r3 @; r11 = fila
				
				@; preparamos todo para llamar a la funcion
				mov r0, r9 @; r0 = matrecomb1 
				mov r1, r10 @; r1 = matrecomb2
				mov r2, r3 @; r2 = fila del bucle actual
				mov r3, r4 @; r3 = col del bucle actual
				bl recombinarPosicionActual
				mov r9, r0 @; r9 = new matrecomb1
				mov r10, r1 @; r10 = new matrecomb2
				mov r12, r2 @; boolean
				mov r0, r8 @; r0 = matjuego
				mov r1, r9 @; r1 = matrecomb1
				mov r2, r10 @; r2 = matrecomb2
				cmp r12, #0 @; No OK (0) = Reiniciar | Todo OK (1) = Pasar a la siguiente posicion 
				beq .reiniciar
				
				mov r3, r11 @; r3 = i
				
			.contBucleJ4:
				add r4, #1 @; j++
				cmp r4, #COLUMNS
				blt .Lforj4 @; j < columnas
			
				add r3, #1 @; i++
				cmp r3, #ROWS @; 
				blt .Lfori4 @; i < filas > bucle_filas.
			.reiniciar:
				mov r3, r12 @; Devolvemos el booleano de salida!
		pop {r4-r12, pc}
		
	
				
				
	@; 	recombinarMatriz: rutina para recombinar la matriz sin secuencias.
	@;	Parametros:
	@;		R0 = matriz matrecomb1
	@;		R1 = matriz matrecomb2 
	@;		R2 = fila actual
	@;		R3 = columna actual
	@;	Resultado:
	@;		R0 = matriz matrecomb1
	@;		R1 = matriz matrecomb2
	@;		R2 = True (Se ha hecho con exito) / False (ha dado un error)
	recombinarPosicionActual:
		push {r3-r12, lr}
				
				mov r12, #0 @; Contador de recombinacion
			.WhileSecuencia:
				@; === BLOQUE DE OBTENCION DE FILA Y COLUMNA ALEATORIA A MIRAR EN MATERCOMB1 ===
				mov r5, r0 @; r5 = matrecomb1 *
				mov r6, r1 @; r6 = matrecomb2 *
				mov r7, r2 @; r7 = fila actual *
				mov r8, r3 @; r8 = columna actual *
				
				@; Funcion extra de soporte que nos devuelve una fila y columna aleatoria.
				@; Comprueba ademas que la fila y columna aleatorias no den con una posicion en matrecomb1 donde el valor sea 0.
				@; Solo necesita r0 = matrecomb1
				bl pos_aleat_matrecomb1				
				mov r9, r0 @; r9 = fila aleat *
				mov r10, r1 @; r10 = col aleat *
				
				@; === BLOQUE DE OBTENCION DEL DATO EN MATERCOMB1 ===
				mov r0, r5 
				mov r3, #COLUMNS
				mla r4, r9, r3, r10 @; fila_aleat * COLUMNS + column_aleat
				ldrb r3, [r0, r4] @; Obtenemos el dato de matrecomb1 en la posicion aleatoria. 
				
				@; === BLOQUE DE AÑADIR EL DATO A MATRECOMB2 ===
				mov r0, r6 @; matrecomb 2
				mov r1, r7 @; fila actual
				mov r2, r8 @; columna actual
				
				mov r4, #COLUMNS @; Anadimos el codigo a matrecomb2
				mla r4, r1, r4, r2 @; fila_mat2 * COLUMNS + column_mat2
				ldrb r11, [r0, r4] @; Obtenemos el dato de matrecomb2 
				add r3, r3, r11 @; Dato final = datomatrecomb1 + datomatrecomb2
				strb r3, [r0, r4] @; Guardamos dato final en matrecomb2
				
				@; === BLOQUE DE VERIFICACION DE SECUENCIA EN MATRECOMB2 ==== 
				mov r0, r6 @; Comprobamos si hay secuencia.
				mov r1, r7
				mov r2, r8
				bl hay_secuencia_n_o
				cmp r0, #0
				beq .fin
				
				mov r0, #COLUMNS @; Si hay secuencia devolvemos el valor a matrecomb1
				mla r1, r7, r0, r8
				strb r11, [r6, r1]
				
				mov r0, r5 @; r0 = matrecomb1 *
				mov r1, r6 @; r1 = matrecomb2 *
				mov r2, r7 @; r2 = fila actual *
				mov r3, r8 @; r3 = columna actual *
				add r12, #1
				
				cmp r12, #10 @; Si se intenta 10 veces con distintos numeros y no se ha podido realizar, salte del bucle para que se reinicie todo de nuevo!.
				beq .error
				b .WhileSecuencia
				
			.fin:
				@; Cambiamos la posicion aleatoria de matrecomb1 a 0.
				mov r0, r5 @; matrecomb1
				mov r12, #COLUMNS
				mla r5, r9, r12, r10 @; i * COLUMNS + col ALEATS
				mov r3, #0
				strb r3, [r0, r5] @; pos matrecomb1 a 0
				
				mov r5, r0 @; Evitamos perder matrecomb 1  
				
				@; --------- ARREGLO DE FASE 2 ----------
				mov r0, r9
				mov r1, r10 @; Fila y columna origen (aleatoria de matrecomb1) que es de donde viene el elemento
				mov r2, r7
				mov r3, r8 @; Fila y columna destino (fija, del recorrido de matrecomb2 para ir generando los elementos).
				bl activa_elemento @; Devuelve el indice o ROWS*COLS pero para este caso, no lo necesitamos. 
				
				@; ------- FIN ARREGLO FASE 2 --------
				mov r0, r5 @; Devolvemos matrecomb 1
				
				mov r1, r6 @; Devolvemos matrecomb 2
				mov r2, #1 @; EXITO = TRUE
				b .salir
			.error:
				mov r2, #0 @; EXITO = FALSE
			.salir: @; r12 = 10 -> Exito (False) | Exito (True)
				
		pop {r3-r12, pc}
	
	
@;:::RUTINAS DE SOPORTE:::


@; mod_random(n): rutina para obtener un n�mero aleatorio entre 0 y n-1,
@;	utilizando la rutina 'random'
@;	Restricciones:
@;		* el par�metro 'n' tiene que ser un valor entre 2 y 255, de otro modo,
@;		  la rutina lo ajustar� autom�ticamente a estos valores m�nimo y m�ximo
@;	Par�metros:
@;		R0 = el rango del n�mero aleatorio (n)
@;	Resultado:
@;		R0 = el n�mero aleatorio dentro del rango especificado (0..n-1)
	.global mod_random
mod_random:
		push {r1-r4, lr}
		
		cmp r0, #2				@;compara el rango de entrada con el m�nimo
		bge .Lmodran_cont
		mov r0, #2				@;si menor, fija el rango m�nimo
	.Lmodran_cont:
		and r0, #0xff			@;filtra los 8 bits de menos peso
		sub r2, r0, #1			@;R2 = R0-1 (n�mero m�s alto permitido)
		mov r3, #1				@;R3 = m�scara de bits
	.Lmodran_forbits:
		cmp r3, r2				@;genera una m�scara superior al rango requerido
		bhs .Lmodran_loop
		mov r3, r3, lsl #1
		orr r3, #1				@;inyecta otro bit
		b .Lmodran_forbits
		
	.Lmodran_loop:
		bl random				@;R0 = n�mero aleatorio de 32 bits
		and r4, r0, r3			@;filtra los bits de menos peso seg�n m�scara
		cmp r4, r2				@;si resultado superior al permitido,
		bhi .Lmodran_loop		@; repite el proceso
		mov r0, r4			@; R0 devuelve n�mero aleatorio restringido a rango
		
		pop {r1-r4, pc}

@; random(): rutina para obtener un n�mero aleatorio de 32 bits, a partir de
@;	otro valor aleatorio almacenado en la variable global 'seed32' (declarada
@;	externamente)
@;	Restricciones:
@;		* el valor anterior de 'seed32' no puede ser 0
@;	Resultado:
@;		R0 = el nuevo valor aleatorio (tambi�n se almacena en 'seed32')
random:
	push {r1-r5, lr}
		
	ldr r0, =seed32				@;R0 = direcci�n de la variable 'seed32'
	ldr r1, [r0]				@;R1 = valor actual de 'seed32'
	ldr r2, =0x0019660D
	ldr r3, =0x3C6EF35F
	umull r4, r5, r1, r2
	add r4, r3					@;R5:R4 = nuevo valor aleatorio (64 bits)
	str r4, [r0]				@;guarda los 32 bits bajos en 'seed32'
	mov r0, r5					@;devuelve los 32 bits altos como resultado
		
	pop {r1-r5, pc}	


@; 	hay_secuencia: rutina para comprobar si hay secuencia tanto al N de la posicion actual como al O.
@;	Parametros:
@;		R0 = matriz
@;		R1 = fila
@;		R2 = col
@; Return: True (1) / False (0)
	hay_secuencia_n_o:
		push {r1-r7, lr}
		
					mov r4, r0 
					mov r5, r1
					mov r6, r2
					mov r3, #2
					mov r7, #0 @; boolean
					
					bl cuenta_repeticiones
					
					cmp r0, #3
					bhs .HayRepeticion
					
					mov r0, r4
					mov r1, r5
					mov r2, r6
					mov r3, #3
					
					bl cuenta_repeticiones
					
					cmp r0, #3
					bhs .HayRepeticion
					
					b .fin2
					.HayRepeticion:
					mov r7, #1
					
					.fin2:
					
					mov r0, r7
		pop {r1-r7, pc}
	
	
@; 	pos_aleat_matrecomb1: rutina para obtener una posicion aleatoria de matrecomb1 distinta de 0.
@;	Restricciones:
@;		* Solo puede recibir por parametro la direccion de la matriz a trabajar.
@;	Parametros:
@;		R0 = matriz matrecomb1
@;	Resultado:
@;		R0 = fila
@;		R1 = columna
	pos_aleat_matrecomb1:
		push {r2-r7, lr}
		
		.DatoIgualCero3:
		mov r7, r0 @; R12 tiene la direccion de matrecomb1
		mov r0, #ROWS
		bl mod_random
		mov r1, r0 
		mov r0, #COLUMNS
		bl mod_random 
		mov r2, r0 
		
		mov r0, r7 
		
		@; Tenemos ahora lo siguiente.
		@; R0 = matriz matrecomb1
		@; R1 = fila random
		@; R2 = columna random
		mov r3, #COLUMNS @; R3 = COLUMNS
		mul r4, r1, r3 @; i * COLUMNS
		add r5, r4, r2 @; i*COLUMNS + j
		ldrb r6, [r0, r5] @; Cargamos el dato aleatorio de matrecomb1
		
		cmp r6, #0 
		beq .DatoIgualCero3
		
		mov r0, r1
		mov r1, r2
		
		pop {r2-r7, pc}
	
@; 	:copiar_matriz_recomb_juego rutina para copiar una matriz a otra de misma dimension
@;	Restricciones:
@;		* Solo puede recibir por parametro direcciones de matrices de mismo FxC
@;	Par�metros:
@;		R0 = matriz de juego
@;		R1 = matriz matrecomb2
	copiar_matriz_recomb_juego:
		push {r0-r7, lr}
		
			mov r2, #0 @; i = 0
			.Lfori5:
			mov r3, #0 @; j = 0 - columna
			mov r4, #COLUMNS @; R12 = COLUMNS
			mul r5, r2, r4 @; i * COLUMNS
			.Lforj5:
				add r6, r5, r3 @; i*COLUMNS + j 
				ldrb r7, [r1, r6] @; Obtener dato maprecomb2
				strb r7, [r0, r6] @; Guardar dato en matriz juego
				
				add r3, #1 @; j++
				cmp r3, #COLUMNS
				blt .Lforj5 @; j < columnas
			
			add r2, #1 @; i++
			cmp r2, #ROWS @; 
			blt .Lfori5 @; i < filas > bucle_filas.
			
		pop {r0-r7, pc}
		
		
.end
