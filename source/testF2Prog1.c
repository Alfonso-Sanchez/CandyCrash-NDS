/*------------------------------------------------------------------------------
	Programa de testing para las tareas init_grafA() [genera_sprites, 2Aa, 
	de Computadores: candy-crash para NDS.
	(2º curso de Grado de Ingeniería Informática - ETSE - URV)
	
	Analista-programador: santiago.romani@urv.cat
	Programador 1: alfonso.sanchez@estudiants.urv.cat
	------------------------------------------------------------------------------*/
#include <nds.h>
#include <stdio.h>
#include <time.h>
#include <stdbool.h>
#include <candy2_incl.h>


/* variables globales */
char matrix[ROWS][COLUMNS];		// matriz global de juego
int seed32;						// semilla de números aleatorios
int level = 0;					// nivel del juego (nivel inicial = 0)
int points;						// contador global de puntos
int movements;					// número de movimientos restantes
int gelees;						// número de gelatinas restantes
bool salir;



/* actualizar_contadores(code): actualiza los contadores que se indican con el
	parámetro 'code', que es una combinación binaria de booleanos, con el
	siguiente significado para cada bit:
		bit 0:	nivel
		bit 1:	puntos
		bit 2:	movimientos
		bit 3:	gelatinas  */
void actualizar_contadores(int code)
{
	if (code & 1) printf("\x1b[38m\x1b[1;8H %d", level);
	if (code & 2) printf("\x1b[39m\x1b[2;8H %d  ", points);
	if (code & 4) printf("\x1b[38m\x1b[1;28H %d ", movements);
	if (code & 8) printf("\x1b[37m\x1b[2;28H %d ", gelees);
}

void inicializa_interrupciones()
{
	irqSet(IRQ_VBLANK, rsi_vblank);
	TIMER0_CR = 0x00;  		// inicialmente los timers no generan interrupciones
	irqSet(IRQ_TIMER0, rsi_timer0);		// cargar direcciones de las RSI
	irqEnable(IRQ_TIMER0);				// habilitar la IRQ correspondiente
}



/* ------------------------------------------------------------------- 	*/
/* candy1_main.c : funcion principal main para el testeo de las tareas para la fase 2 prog1*/
/* ------------------------------------------------------------------- 	*/
int main(void)
{
	seed32 = time(NULL);		// fijar semilla de números aleatorios
	consoleDemoInit();			// inicialización de pantalla de texto
	inicializa_interrupciones();
	init_grafA();
	printf("candyNDS (FASE 1 - 2)\n");
	printf("\x1b[38m\x1b[1;0H  nivel:");
	actualizar_contadores(1);
	inicializa_matriz(matrix, level);
	genera_sprites(matrix); // Solo se generan la primera vez, luego no es necesario salvo que se cambie de nivel.
	escribe_matriz(matrix);


	do							// bucle principal de pruebas
	{
		salir = false;
		printf("\x1b[39m\x1b[3;1H A > Sig. Nivel");
		printf("\x1b[39m\x1b[4;1H B > Recomb");
		retardo(2);
		do
		{	swiWaitForVBlank();
			scanKeys();					// esperar pulsación tecla 'A' o 'B'
		} while (!(keysHeld() & (KEY_A | KEY_B)));
		printf("\x1b[3;8H              ");
		
		if (keysHeld() & KEY_A)			// si pulsa 'A',
		{								// pasa a siguiente nivel
			level = (level + 1) % MAXLEVEL;
			actualizar_contadores(1);
			inicializa_matriz(matrix, level); 
			genera_sprites(matrix); // Como es un nuevo nivel, generamos los sprites correspondientes.
			escribe_matriz(matrix); // Lo mismo con la matriz numerica

		}
		if (keysHeld() & KEY_B) // si pulsa 'B' // Recombina elementos y lo muestra en pantalla
		{		
			printf("\x1b[39m\x1b[3;1H                                      ");
			printf("\x1b[39m\x1b[3;1H B > Recomb");
			printf("\x1b[39m\x1b[4;1H A > Salir ");
			do {
				recombina_elementos(matrix);
				activa_timer0(1);		// activar timer de movimientos
				while (timer0_on) swiWaitForVBlank();	// espera final
				escribe_matriz(matrix);
				do
				{	
					swiWaitForVBlank();
					scanKeys();					// esperar pulsación tecla 'B' o 'A'
				} while (!(keysHeld() & (KEY_A | KEY_B)));
				if (keysHeld() & KEY_A) {
					salir = true;
				}
			} while (!salir);
		}
	} while (1);
	return(0);
}
