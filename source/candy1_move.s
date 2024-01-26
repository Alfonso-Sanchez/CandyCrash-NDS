@;=                                                         	      	=
@;=== candy1_move: rutinas para contar repeticiones y bajar elementos ===
@;=                                                          			=
@;=== Programador tarea 1E: carlos.castanon@estudiants.urv.cat		  ===
@;=== Programador tarea 1F: carlos.castanon@estudiants.urv.cat		  ===
@;=                                                         	      	=

.include "../include/candy1_incl.i"



@;-- .text. código de las rutinas ---
.text	
		.align 2
		.arm



@;TAREA 1E;
@; cuenta_repeticiones(*matriz,f,c,ori): rutina para contar el número de
@;	repeticiones del elemento situado en la posición (f,c) de la matriz, 
@;	visitando las siguientes posiciones según indique el parámetro de
@;	orientación 'ori'.
@;	Restricciones:
@;		* sólo se tendrán en cuenta los 3 bits de menor peso de los códigos
@;			almacenados en las posiciones de la matriz, de modo que se ignorarán
@;			las marcas de gelatina (+8, +16)
@;		* la primera posición también se tiene en cuenta, de modo que el número
@;			mínimo de repeticiones será 1, es decir, el propio elemento de la
@;			posición inicial
@;	Parámetros:
@;		R0 = dirección base de la matriz
@;		R1 = fila 'f'
@;		R2 = columna 'c'
@;		R3 = orientación 'ori' (0 -> Este, 1 -> Sur, 2 -> Oeste, 3 -> Norte)
@;	Resultado:
@;		R0 = número de repeticiones detectadas (mínimo 1)
@;	Variables:
@;		R4 = dirección base de la matriz (copiada de R0)
@;		R5 = r1*COLUMNS+r2 (nota: el índice suma/resta la fila y columna directamente ya que no se pasan por parámetro)
@;		R6 = [r4, r5] (posición original) -> se usa para compararlo con r7
@;		R7 = [r4, r5] (posición que se actualiza dentro del bucle)
@;		R8 = repeticiones (este luego se moverá a r0)
@;		R9 = #COLUMNS (no me deja hacer mla r5, r1, #COLUMNS, r2, asi que no me queda otra que guardar #COLUMNS en un registro)
@;	Nota: 
@;		No se crea una variable 'indice' la cual se usa para guardar 
@;		algo tipo "r1 * r2 + desplazamiento", sirve mejor actualizar r1 y 
@;		r2 ya que de esta manera se puede comprobar si r1 o r2 se pasan del 
@;		límite de la fila o columna respectivamente, o si son menores de 0.
@;		Además de que la fila y la columna NO se pasan por parámetro asi que
@;		se pueden cambiar dentro de la función sin problema ninguno.
	.global cuenta_repeticiones
cuenta_repeticiones:
		push {R1-R9, lr}
		
		@;Antes de empezar el bucle siempre es necesario realizar esto
		mov r4, r0
		mov r9, #COLUMNS
		mla r5, r1, r9, r2
		ldrb r6, [r4, r5]
		and r6, #0x07					@;Se obtiene los bits 2-0
		mov r8, #1 						@;En vez de calcular la primera casilla se inicializa la repetición como 1 y ya, ya que la primera casilla siempre será 1 
		
	.LstartBucle:
		
		@; Se actualiza r2 (columnas) o r1 (filas) dependiendo de la orientación
		
		@;Este
		cmp r3, #0
		addeq r2, #1
		
		@;Sur
		cmp r3, #1
		addeq r1, #1
		
		@;Oeste
		cmp r3, #2
		subeq r2, #1
		
		@;Norte
		cmp r3, #3
		subeq r1, #1
		
		@;Si se llega al límite de la columna o fila o va (se pasa del límite o la posición es menor a 0), se acaba la rutina
		
		cmp r1, #ROWS-1
		bhi .LfinBucle
		
		cmp r1, #0
		blt .LfinBucle
		
		cmp r2, #COLUMNS-1
		bhi .LfinBucle
		
		cmp r2, #0
		blt .LfinBucle
		
		mla r5, r1, r9, r2 				@;Se mueve a la siguiente posición
		ldrb r7, [r4, r5]
		and r7, #0x07					@; Se obtienen los bits 2-0
		cmp r7, r6						@; Solo se comparan los bits 2-0 para ver si son del mismo tipo de gelatina
		bne .LfinBucle
		add r8, #1
		b .LstartBucle
		
	.LfinBucle:
		mov r0, r8
		pop {R1-R9, pc}



@;TAREA 1F;
@; baja_elementos(*matriz): rutina para bajar elementos hacia las posiciones
@;	vacías, primero en vertical y después en sentido inclinado; cada llamada a
@;	la función sólo baja elementos una posición y devuelve cierto (1) si se ha
@;	realizado algún movimiento, o falso (0) si está todo quieto.
@;	Restricciones:
@;		* para las casillas vacías de la primera fila se generarán nuevos
@;			elementos, invocando la rutina 'mod_random' (ver fichero
@;			"candy1_init.s")
@;	Parámetros:
@;		R0 = dirección base de la matriz de juego
@;	Resultado:
@;		R0 = 1 indica se ha realizado algún movimiento, de modo que puede que
@;				queden movimientos pendientes. 
@;	Variables:
@;		R4 = copia de la dirección base de la matriz de juego, para que al llamar una función de bajar elementos se pase el registro correctamente
@;		además de que R0 se modifica con los returns de las otras funciones
	.global baja_elementos
baja_elementos:
		push {R4, lr}
		mov r4, r0
		bl baja_verticales
		cmp r0, #1
		blne baja_laterales
		pop {R4, pc}



@;:::RUTINAS DE SOPORTE:::



@; baja_verticales(mat): rutina para bajar elementos hacia las posiciones vacías
@;	en vertical; cada llamada a la función sólo baja elementos una posición y
@;	devuelve cierto (1) si se ha realizado algún movimiento.
@;	Nota: En la parte de bajar elementos, lo que hago es ir al elemento más alto que no sea un 0,8,16 o 7. Entonces obtengo los bits 2-0 y esos son los que
@;	restan/añaden a los valores de cada elemento (para así no quitarles la gelatina, o que puedan caer por los huecos fácilmente) - para hacer esto necesito
@;	primero obtener los bits 2-0 del -siguiente- elemento antes de hacer el bucle, por eso quizás se ve rara esa parte
@;	Parámetros:
@;		R4 = dirección base de la matriz de juego
@;	Resultado:
@;		R0 = 1 indica que se ha realizado algún movimiento. 
@;	Registros:
@;		R1 = Posición del array, se empieza desde la última posición -> También la posición de donde se encontró el 0,8,16
@;		R2 = Valor de la matriz en la posición r1 -> Valor del elemento en la posición r3 -> Valor del elemento en la posición de r6 (bits 2-0) -> r0 temporalmente
@;		R3 = Posición de la matriz en validarBucle -> Valor del elemento en la posición r7 (bits 2-0)
@;		R5 = Dictará si hay un elemento a mover en .buscarLimite, si no lo hay generamos un número aleatorio directamente donde tenemos el 0 (si no hay solidos arriba)
@;		R6 = Posición del elemento más alto
@;		R7 = Posición del elemento actual
@;		R8 = Posición del siguiente elemento
@;		R9 = Bits 2-0 de R2
@;		R10 = Bits 2-0 de R3

baja_verticales:
		push {R1-R10, lr}
		mov r0, #0					@; Inicializado a 0
		mov r1, #ROWS*COLUMNS		@; Nota: la última posición de un array bidimensional es (n*m-1), el -1 se hace en el bucle
		
		.LrecorrerJuego:
		mov r5, #0			@; Con cada iteración del bucle, hay que poner r5 a 0
		sub r1, #1
		cmp r1, #0
		blt .LendBucle		@; NECESARIO el 'lt', para comprobar r1 CON SIGNO
		ldrb r2, [r4, r1]
		tst r2, #0x07		@; Si es 0, 8 o 16 empezamos a mover elementos
		bne .LrecorrerJuego
		sub r3, r1, #COLUMNS
		mov r6, r1				@; Si nunca encontramos un elemento a bajar en el bucle, entonces la posición original (donde encontramos el 0,8,16) es donde se genera el aleatorio
								@; Por ende esta misma posición es también la 'más alta' (teniendo en cuenta que literalmente no hay otras posiciones válidas).
		cmp r1, #COLUMNS		@; Caso especial: si estamos en la 1ra fila de la matriz, directamente generamos el aleatorio
		blt .LgenerarAleatorio
		
		.LbuscarLimite:			@; Busca el elemento más alto de una fila, también cambia r5 a 1 si encuentra algún elemento a bajar
		cmp r3, #0
		addlt r3, #COLUMNS		@; Hay que volver a sumarle la columna si estamos a menos de 0
		blt .LbajarElementos		@; Si hemos llegado a la última fila (la posición de la matriz < número de columnas en una fila) entonces vamos al bucle
		ldrb r2, [r4, r3]
		cmp r2, #7				@; Si encontramos un sólido, paramos de buscar elementos
		beq .LbajarElementos
		tst r2, #0x07			@; Si encontramos otro 0,8,16, paramos de buscar elementos
		beq .LbajarElementos
		cmp r2, #15				@; Si hay un hueco entonces directamente seguimos buscando el siguiente elemento
		subeq r3, #COLUMNS
		beq .LbuscarLimite		
		mov r5, #1				@; Solamente confirmamos de que hay elementos a bajar si encontramos un valor diferente de 0, 7, 8, 15 y 16
		mov r6, r3				@; Si hemos llegado a este punto, tenemos el valor más alto actualmente
		sub r3, #COLUMNS		@; Aumentamos de fila
		b .LbuscarLimite
		
		.LbajarElementos:		@; En esta parte de aquí preparo los registros antes de empezar el bucle
		cmp r5, #0				@; Si no hay elementos a bajar, generamos un aleatorio (en la posición donde se encontró el 0,8,16)
		moveq r7, r1			@; Comprovar solidos mira los elementos al revés de bajarElementos, es decir empieza desde abajo y va hasta arriba
		beq .LcomprovarSolidos	@; PERO si hay un 7 (un bloque sólido) arriba del 0, entonces NO se genera un aleatorio - esta parte de la rutina comprueba de si hay un 7 o no
		mov r7, r6				@; Si no, entonces seguimos igual
		add r8, r7, #COLUMNS
		ldrb r2, [r4, r7]		@; Obtenemos el valor del elemento más arriba -> redundancia: esto se repite en el bucle, pero de esta manera el código está más organizado
		and r9, r2, #0x07		@; Nos quedamos con los bits 2-0 del primer elemento
		
		.LbajarElementosBucle:
		cmp r7, r1				@; Si hemos llegado a la última posición del bucle, osea donde habíamos encontrado el 0,8,16, comprobamos si hay un 0,8,16 o 7 arriba
		beq .LcomprovarSolidos
		ldrb r2, [r4, r7]
		ldrb r3, [r4, r8]
		cmp r3, #15				@; Actualizamos el flag de comparación para dentro de poco
		and r10, r3, #0x07
		sub r2, r9
		add r3, r9
		strb r2, [r4, r7]
		strb r3, [r4, r8]
		movne r9, r10			@; Si r3 = 15 (si el siguiente elemento es uno hueco), entonces el siguiente elemento no le cogemos los bits 2-0 - se mantienen igual
		add r7, #COLUMNS
		add r8, #COLUMNS
		mov r0, #1				@; Se ha hecho un movimiento
		b .LbajarElementosBucle
		
		.LcomprovarSolidos:
		sub r7, #COLUMNS
		ldrb r2, [r4, r7]
		cmp r2, #7
		beq .LrecorrerJuego		@; Si hay un 7 entonces **NO** genero un aleatorio
		tst r2, #0x07
		beq .LrecorrerJuego		@; Lo mismo si solamente hay un 0,8, o 16 arriba
		cmp r7, r3
		beq .LgenerarAleatorio	@; Si no se ha detectado ningún 0,8,7 o 16 y hemos recorrido toda la fila, podemos asumir de que no hay ningún bloque sólido o 0,8,16
		b .LcomprovarSolidos
		
		.LgenerarAleatorio:
		mov r0, #6				@; Luego le pondré 1 como result - por ahora lo preparo para mod_random
		bl mod_random			@; Genera un número del 0 al 5
		add r0, #1				@; Ahora es un número del 1 al 6 (un elemento)
		ldrb r3, [r4, r6]		@; Obtengo el valor de la posición más alta, donde voy a generar el aleatorio
		and r3, #0x18			@; Obtengo los bits 4-3, manteniendo si es gelatina, doble o simple
		add r3, r0				@; Añado el elemento aleatorio
		strb r3, [r4, r6]		@; Guardo el valor
		mov r0, #1				@; ASUMO de que generar un elemento aleatorio cuenta como movimiento.
		b .LrecorrerJuego		@; Se vuelve a recorrer el juego
		
		.LendBucle:
		
		pop {R1-R10, pc}



@; baja_laterales(mat): rutina para bajar elementos hacia las posiciones vacías
@;	en diagonal; cada llamada a la función sólo baja elementos una posición y
@;	devuelve cierto (1) si se ha realizado algún movimiento.
@;	Parámetros:
@;		R4 = dirección base de la matriz de juego
@;	Resultado:
@;		R0 = 1 indica que se ha realizado algún movimiento.
@;	Registros:
@;		R1 = Posición de la matriz, por ende posición de donde se ha encontrado la casilla vacia
@;		R2 = Índice de columna
@;		R3 = Valor del elemento en una posición
@;		R5 = 0 si no hay elementos a bajar, 1 si se puede por la derecha, 2 si se puede por la izquierda y 3 si se puede por ambos (y entonces se decide aleatoriamente)
@;		R6 = Posición del elemento en la fila superior
@;		R7 = Temporalmente R0 -> valor del elemento en r1
@;	Nota:
@;		Para diferenciar entre baja_laterales y baja_verticales, los nombres de las etiquetas de los saltos locales acaban con L (de 'laterales')
baja_laterales:
		push {R1-R7, lr}
		mov r0, #0				@; Inicializado
		mov r2, #COLUMNS
		mov r3, #ROWS
		mul r1, r2, r3
		
		.LrecorrerJuegoL:
		sub r1, #1				@; Las posiciones se recorren de 1 en 1, los índices de columna y fila en R2 y R3 respectivamente es para otra parte del código
		cmp r1, #COLUMNS
		blt .LendBucleL			@; NO hace falta recorer la primera fila de la matriz
		sub r2, #1
		cmp r2, #0				@; Comprovamos si nos hemos pasado a un número negativo, por ende que nos hemos pasado de las columnas
		movlt r2, #COLUMNS		@; Volvemos a pasar r2 al número pero columnas pero...
		sublt r2, #1			@; ...Hay que restar 1 al número de columnas, si tenemos 9 columnas en una fila las posiciones disponibles van del 0 al 8
		ldrb r3, [r4, r1]
		tst r3, #0x07
		bne .LrecorrerJuegoL	@; Si no encontramos un 0,8,16 entonces seguimos buscando
		
		mov r5, #0
		
		@; Comprobamos el lado derecho
		add r2, #1
		cmp r2, #COLUMNS		@; if (posicion_columna = #COLUMNS-1) = if (posicion_columna+1 = #COLUMNS)
		sub r2, #1
		beq .LcomprobarIzquierdaL	@; Si estamos en el extremo derecho del mapa, no hace falta comprobar nada
		mov r6, r1
		sub r6, #COLUMNS
		add r6, #1				@; Desplazamiento a la derecha
		ldrb r3, [r4, r6]
		and r3, #0x07
		cmp r3, #7
		beq .LcomprobarIzquierdaL
		cmp r3, #0
		beq .LcomprobarIzquierdaL
		add r5, #1				@; Se confirma que podemos movernos por la derecha
		
		.LcomprobarIzquierdaL:
		cmp r2, #0
		beq .LdecidirDireccionL
		mov r6, r1
		sub r6, #COLUMNS
		sub r6, #1				@; Desplazamiento a la izquierda
		ldrb r3, [r4, r6]
		and r3, #0x07
		cmp r3, #7
		beq .LdecidirDireccionL
		cmp r3, #0
		beq .LdecidirDireccionL
		add r5, #2				@; Se confirma que podemos movernos por la izquierda
		
		.LdecidirDireccionL:
		cmp r5, #0
		beq .LrecorrerJuegoL
		cmp r5, #1
		beq .LbajarDerechaL
		cmp r5, #2
		beq .LbajarIzquierdaL
		mov r5, #1				@; En el caso de que ambas direcciones sean posibles, se escoge una aleatoriamente
		mov r7, r0				
		mov r0, #1				@; Quiero generar un aleatorio del 0 al 1
		bl mod_random
		add r5, r0				@; R5 = 1 (1+0) o 2 (1+1) -> derecha o izquierda
		mov r0, r7				@; Recuperamos R0
		b .LdecidirDireccionL
		
		.LbajarDerechaL:
		mov r6, r1
		sub r6, #COLUMNS
		add r6, #1				@; Desplazamiento a la derecha
		ldrb r3, [r4, r6]
		and r7, r3, #0x07			@; Obtenemos bits 2-0
		ldrb r5, [r4, r1]		@; Re-uso R5 ya que no lo necesito más
		add r5, r7				@; Añado el elemento bajado a la posición donde cae
		sub r3, r7				@; Quito el elemento manteniendo el tipo de gelatino
		strb r5, [r4, r1]
		strb r3, [r4, r6]
		mov r0, #1	
		b .LrecorrerJuegoL
		
		.LbajarIzquierdaL:
		mov r6, r1
		sub r6, #COLUMNS
		sub r6, #1				@; Desplazamiento a la izquierda
		ldrb r3, [r4, r6]
		and r7, r3, #0x07			@; Obtenemos bits 2-0
		ldrb r5, [r4, r1]		@; Re-uso R5 ya que no lo necesito más
		add r5, r7				@; Añado el elemento bajado a la posición donde cae
		sub r3, r7				@; Quito el elemento manteniendo el tipo de gelatino
		strb r5, [r4, r1]
		strb r3, [r4, r6]
		mov r0, #1				@; Movimiento!
		b .LrecorrerJuegoL
		
		
		
		
		.LendBucleL:
		
		pop {R1-R7, pc}

.end
