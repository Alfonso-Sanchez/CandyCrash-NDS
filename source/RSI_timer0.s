@;=                                                          	     	=
@;=== RSI_timer0.s: rutinas para mover los elementos (sprites)		  ===
@;=                                                           	    	=
@;=== Programador tarea 2E: alfonso.sanchez@estudiants.urv.cat				  ===
@;=== Programador tarea 2G: yyy.yyy@estudiants.urv.cat				  ===
@;=== Programador tarea 2H: zzz.zzz@estudiants.urv.cat				  ===
@;=                                                       	        	=

.include "../include/candy2_incl.i"


@;-- .data. variables (globales) inicializadas --- 
.data
		.align 2
		.global update_spr
	update_spr:	.hword	0			@;1 -> actualizar sprites
		.global timer0_on
	timer0_on:	.hword	0 			@;1 -> timer0 en marcha, 0 -> apagado
	divFreq0: .hword	-5754		@;divisor de frecuencia inicial para timer 0
	limitFreq0: .hword 0			@; limitador de la frequencia a la frequencia maxima permitida. Es decir la freq ira de -5754 a 0. Una vez sea 0 volvera a -5754.

@; Calculo del divFreq0:
@; T Max transicion: 0.35s/Max ii = 32 ---> 0.0109375s (0.35s = Maximo de tiempo i 32 = interrupciones)
@; Frequencia de salida es 1/0.0109375s = 91hz (f = 1/T)
@; Ahora podemos usar la frequencia de entrada base encontrada en el tema 4 pagina 34.
@; FRequencia F.Base(33513982/64) = 523.655,96875 Hz (si intentamos otras frequencias superiores, nos pasamos del valor 65536 que permite el registro de 16 bits del divFREQ)
@; DivFreq = -(523.655,96875 / 91) = -5.754,4612 (El divisorFREQ nunca puede superar los 65.536).

@;-- .bss. variables (globales) no inicializadas ---
.bss
		.align 2
	divF0: .space	2				@;divisor de frecuencia actual


@;-- .text. código de las rutinas ---
.text	
		.align 2
		.arm

@;TAREAS 2Ea,2Ga,2Ha;
@;rsi_vblank(void); Rutina de Servicio de Interrupciones del retrazado vertical;
@;Tareas 2E,2F: actualiza la posición y forma de todos los sprites
@;Tarea 2G: actualiza las metabaldosas de todas las gelatinas
@;Tarea 2H: actualiza el desplazamiento del fondo 3
	.global rsi_vblank
rsi_vblank:
		push {r0-r3, lr} @; Tamanio no definitivo. Solo basado en la tarea 2Ea 
		
@;Tareas 2Ea
		ldr r2, =update_spr				@; cargamos la direccion de memoria de update_spr(half word) cargamos la direccion de memoria de update_spr(hf)
		ldrh r3, [r2]					@; cogemos el valor de update_spr(hf)
		cmp r3, #0						@; Comparamos con el valor de update_spr con 0, si es igual indica que no se deben actualizar los sprites. 
		beq .Lfin_rsi_vblank_2Ea		    @; salta a la etiqueta de finalizacion de la tarea. 
		ldr r3, =n_sprites				@; cargamos la direccion de memoria de n_sprites. 
		ldr r1, [r3]					@; obtenemos el valor de n_sprites
		mov r0, #0x07000000				@; movemos el r0 al origen de la memoria del procesador grafico principal
		bl SPR_actualizarSprites		@; llamamos al metodo SPR_actualizarSprites() pasandole a r0 --> direccion de la memoria grafica principal i r1 --> limite de los sprites. 
		mov r0, #0						@; movemos a r0 el valor 0
		strh r0, [r2]					@; actualizamos el valor de update_spr a 0
		.Lfin_rsi_vblank_2Ea:			@; fin Tarea 2Ea f
@;Tarea 2Ga
	@; Falta hacer por parte del programador correspondiente. 

@;Tarea 2Ha
	@; Falta hacer por parte del programador correspondiente. 
		
		pop {r0-r3, pc} @; Se tiene que modificar a falta de los programadores de las 2 tareas pendientes.  

@;TAREA 2Eb;
@;activa_timer0(init); rutina para activar el timer 0, inicializando o no el
@;	divisor de frecuencia según el parámetro init.
@;	Parámetros:
@;		R0 = init; si 1, restablecer divisor de frecuencia original divFreq0
	.global activa_timer0
activa_timer0:
		push {r0-r2, lr}
			cmp r0, #0							@; Comparamos el valor de init con 0
			beq .Lfin_activar_timer0				@; Si no es 0 no se modificara el divF0 ni el registro de datos del timer 0.
												@; == SI ES 0 ===
			ldr r1, =divFreq0					@; cargamos la direccion de memoria de divFreq0 (half word)
			ldsh r2, [r1]						@; obtenemos el valor de divFreq0 con la instruccion de ldsh que nos permite obtener el valor con signo almacenado en la direccion de memoria del paso anterior. 
			ldr r1, =divF0						@; Cargamos la direccion de memoria de divF0 
			strh r2, [r1]						@; Guardamos el valor de divFreq0 a divF0
			ldr r1, =0x04000100					@; Cargamos la direccion de memoria del divisor de frequencia del timer 0 (TIMER_DATA)
			strh r2, [r1]						@; Guardamos el valor de divFreq0 a TIMER0_DATA
			
			.Lfin_activar_timer0:
			ldr r1, =timer0_on					@; Cargamos la direccion de memoria del timer0_on (half word)
			mov r2, #1							@; Guardamos el valor 1 en el registro r2
			strh r2, [r1]						@; Actualizamos el timer0_on con el valor guardado en r2 guardando el valor dentro de timer0_on
			ldr r1, =0x04000102					@; Cargamos la direccion de memoria del registro de control del timer0 (TIMER0_cr)
			mov r2, #0xC1						@; Movemos a 32 el valor para activar el timer 0
												@; 11000001
												@; BITS:
												@; 7: Timer encendido
												@; 6: Interrupciones activadas
												@; 1-0:F/64 | F= 523.655,96875 Hz
			strh r2, [r1]						@; activamos el timer con el valor de r2
		pop {r0-r2, pc}


@;TAREA 2Ec;
@;desactiva_timer0(); rutina para desactivar el timer 0.
	.global desactiva_timer0
desactiva_timer0:
		push {r0-r2, lr}
			ldr r0, =0x04000102				@; Cargamos la direccion de memoria del registro de control del timer 0 (TIMER0_CR) 		
			mov r2, #0						@; Ponemos cargamos en el registro r2 el valor 0 
			strh r2, [r0]					@; Desactivamos el timer con el valor de r2
											@; 11000001 => 0000000
											@; BITS:
											@; 7: Timer apagado
											@; 6: Interrupciones apagadas
											@; 1-0:F/64 | F= 523.655,96875 Hz ==> F/1 (com esta desactivat no pasa res, quan s'active el volvem a posar a F/64 per al valor correcte).
			ldr r1, =timer0_on				@; Cargamos la direccion de memoria de timer0_on (half word)
			strh r2, [r1]					@; Actualizamos el valor de timer0_on
		pop {r0-r2, pc}



@;TAREA 2Ed;
@;rsi_timer0(); rutina de Servicio de Interrupciones del timer 0: recorre todas
@;	las posiciones del vector vect_elem y, en el caso que el código de
@;	activación (ii) sea mayor o igual a 0, decrementa dicho código y actualiza
@;	la posición del elemento (px, py) de acuerdo con su velocidad (vx,vy),
@;	además de mover el sprite correspondiente a las nuevas coordenadas.
@;	Si no se ha movido ningún elemento, se desactivará el timer 0. En caso
@;	contrario, el valor del divisor de frecuencia se reducirá para simular
@;  el efecto de aceleración (con un límite).
	.global rsi_timer0
rsi_timer0:
		push {r0-r12,lr}
			ldr r12, =vect_elem			 @; r12: Direccion del vector de elementos. 
			mov r1, #ROWS
			mov r2, #COLUMNS
			mul r11, r1, r2				 @; r11: Tamano del vector de elementos. 
			mov r10, #0 				 @; r10: Contador de iteraciones del bucle. 
			mov r9, r10 				 @; r9: Contador de iteraciones en la matriz con posicion de memoria. 
			mov r7, #0   				 @; r7: Contador para desactivar la RISI en caso de que no se mueva ningun elemento. 		
		.Linifor:
			cmp r10, r11				 @; Comparamos el numero de iteraciones con el tamano del vector de elementos. 
			bhs .Lfinbucle
			ldsh r3,[r12, r9]			 @; r3: Numero de interrupciones pendientes 
			cmp r3, #0					 @; Comprobamos si quedan interrupciones pendientes. 
			ble .Lfinfor
			mov r7, #1   				 @; Si movemos un elemento, indicamos a r7 (Desactiva la rsi) 1 para decir que ya no es necesario desactivarlo
			
			@;--------------ii---------------- acciones con las interrupciones
			sub r3, r3, #1				 @; Decrementamos ii = 'num_interrupciones'
			strh r3, [r12, r9]	         @; Guardamos el numero de interrupciones pendientes. 
			
			@;--------------PX=PX+VX--------------
			mov r8, r9					 @; Copiamos la posicion de memoria de r9 para actualizar PX segun VX
			add r9, #ELE_PX				 @; Anadimos r9 a #ELE_PX (que son las constantes que tenemos en el candy2_incl.i) [ Esto esta hecho para acceder al struct de forma mas eficiente ]
			add r8, #ELE_VX				 @; Anadimos r8 a #ELE_VX        ""

			ldrh r3, [r12, r9]			 @; Cargamos la posicion de ELE_PX a partir del vector de elementos. 
			ldrh r4, [r12, r8]			 @; "" para ELE_VX
			add r3, r4 					 @; Sumamos a la posicion X del elemento la velocidad del elemento. r3 = ELE_PX + ELE_VX
			strh r3, [r12, r9]			 @; Actualizamos la posicion del elemento. 
			mov r1, r3					 @; Guaramos la posicion en el registro R1 para su posterior uso en SPR_moverSprite()
			sub r9, #ELE_PX				 @; Dejamos las posiciones R9 y R8 como estaban a la entrada de este subbloque de la RSI [ PX=PX+VX ]
			sub r8, #ELE_VX
			
			@;--------------PY=PY+VY--------------
			add r9, #ELE_PY				 @; Anadimos r9 a #ELE_PY (que son las constantes que tenemos en el candy2_incl.i) [ Esto esta hecho para acceder al struct de forma mas eficiente ]
			add r8, #ELE_VY				 @; Anadimos r8 a #ELE_VY        "" 
			ldsh r3, [r12, r9]			 @; Cargamos la posicion de #ELE_PY
			ldrh r4, [r12, r8]			 @; Cargamos la posicion de #ELE_VY
			add r3, r4 					 @; Sumamos la posicion Y del elemento la velocidad del elemento. r3 = ELE_PY + ELE_VY
			strh r3, [r12, r9]			 @; Actualizamos la posicion del elemento con la calculada en la instruccion anterior. 
			mov r2, r3 					 @; Guardamos el resultado de la operacion en el registro 2 para su posteriuor uso en SPR_moverSprite()
			sub r9, #ELE_PY				 @; Dejamos las posiciones R9 y R8 como estaban a la entrada de este subbloque de la RSI [ PY = PY + VY ] 
			sub r8, #ELE_VY
			
			@;--------------SPR_moverSprite()-------------- Ver rutina en Sprites_sopo.s
			mov r0, r10  				 @; Movemos el indice de iteraciones del bucle a r0 para la rutina SPR_moverSprite()
			bl SPR_moverSprite			 @; Ejecutamos la rutina SPR_moverSprite.
			ldr r3,=update_spr  		 @; Cargamos en r3 la variable update_spr
			mov r4, #1  				 @;  
			strh r4, [r3]				 @; Y cambiamos la varaible update_spr a 1.
			
			@;--------------Reducir frecuencia timer--------------
			
			ldr r0, =divF0               @; Cargamos el divisor de frequencia actual. 
			ldsh r1, [r0]				 @; Guardamos en r1 el contenido de la variable divF0.
			ldr r2, =divFreq0			 @; Cargamos en r2 el divisor de frequencia calculado anteriormente. 
			ldsh r2, [r2]				 @; Guardamos en r2 el contenido de la frequencia calculada. 
			ldr r3, =limitFreq0			 @; Cargamos en r3 el limite de la frequencia del timer0
			ldsh r3, [r3]				 @; Guardamos en r3 valor limite de la frequencia del timer0 
			cmp r3, r1					 @; limitFreq0 > divF0, ok
			bge .LnoRestablecerFreq		 @; 
			mov r1, r2					 @; limitFreq0 < divF0, no ok, restablecemos el divisor de frequencia. 
		.LnoRestablecerFreq:
										 @; El valor 82, es por que queremos reducir el timer pero no llegar o acercarnos a 0, ya que en valores cercanos a este, la aceleracion es muy rapida. Y queremos que sea una animacion de 0.35s
			add r1, r1, #82		 	 	 @; Disminuimos el divisor del timer divF0. [OJO como el timer va de negativo a cercano a 0, el sumar 82 es disminuiur el divisor].
			strh r1, [r0]   			 @; Cargamos el nuevo valor del divF0
			
			ldr r5, =0x04000100 		 @; Direccion del TIMER0_DAT
			strh r1, [r5]  			 	 @; Actualizamos con el divF0 el data del timer0.

		.Lfinfor:
			add r10, #1					 @; Aumentamos el contador. 
			mov r8, #ELE_TAM             @; r8 = ELE_TAM
			mul r9, r10, r8              @; Guardamos en r9 la multiplicacion del contador por el tamano del vector. 
			b .Linifor
			
		.Lfinbucle:
			cmp r7, #0   				 @; Si no se ha movido ningun elemento, se desactivara el timer0.
			bne .LfinRSI
			bl desactiva_timer0
		.LfinRSI:
		pop {r0-r12,pc}

.end
