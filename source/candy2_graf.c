/*------------------------------------------------------------------------------

	$ candy2_graf.c $

	Funciones de inicializaci�n de gr�ficos (ver 'candy2_main.c')

	Analista-programador: santiago.romani@urv.cat
	Programador tarea 2A: alfonso.sanchez@estudiants.urv.cat
	Programador tarea 2B: yyy.yyy@estudiants.urv.cat
	Programador tarea 2C: zzz.zzz@estudiants.urv.cat
	Programador tarea 2D: uuu.uuu@estudiants.urv.cat

------------------------------------------------------------------------------*/
#include <nds.h>
#include <candy2_incl.h>
#include <Graphics_data.h>
#include <Sprites_sopo.h>


/* variables globales */
int n_sprites = 0;					// n�mero total de sprites creados
elemento vect_elem[ROWS*COLUMNS];	// vector de elementos
gelatina mat_gel[ROWS][COLUMNS];	// matriz de gelatinas



// TAREA 2Ab
/* genera_sprites(): inicializar los sprites con prioridad 1, creando la
	estructura de datos y las entradas OAM de los sprites correspondiente a la
	representaci�n de los elementos de las casillas de la matriz que se pasa
	por par�metro (independientemente de los c�digos de gelatinas).*/
void genera_sprites(char mat[][COLUMNS])
{
	int cont_sprites = 0;
	SPR_ocultarSprites(128);																// Ocultamos todos los sprites que hay en la matriz de elementos. 	
	SPR_actualizarSprites(OAM, 128);														// Actualizamos los sprites para que queden ocultos. (soluciona el pixel rosa del primer sprite). 
	
	for(int i = 0; i < ROWS*COLUMNS; i++){
		vect_elem[i].ii = -1;															//Desactivamos todos los elementos del vector con -1.
	}																						//(ii=numero de interrupciones pendientes)
	n_sprites = 0; // Como vamos a contear de nuevo los sprites, lo ponemos a 0.
	for(int i = 0; i < ROWS; i++){
		for(int j = 0; j < COLUMNS; j++){				
			crea_elemento((mat[i][j] & 0x07), i, j);										//Recorremos la matriz de juego para ir generando todos los sprites. 	
			cont_sprites++;																	//Por cada elemento recorrido aumentamos el contador de sprites. 
		}
	}
	n_sprites = cont_sprites; 
	SPR_actualizarSprites(OAM, n_sprites);													// Actualizamos los sprites indicando el numero de sprites contados y el OAM (direccion de memoria con informacio esencial de los sprites). 
}

// TAREA 2Bb
/* genera_mapa2(*mat): generar un mapa de baldosas como un tablero ajedrezado
	de meta-baldosas de 32x32 p�xeles (4x4 baldosas), en las posiciones de la
	matriz donde haya que visualizar elementos con o sin gelatina, bloques
	s�lidos o espacios vac�os sin elementos, excluyendo s�lo los huecos.*/
void genera_mapa2(char mat[][COLUMNS])
{


}



// TAREA 2Cb
/* genera_mapa1(*mat): generar un mapa de baldosas correspondiente a la
	representaci�n de las casillas de la matriz que se pasa por par�metro,
	utilizando meta-baldosas de 32x32 p�xeles (4x4 baldosas), visualizando
	las gelatinas simples y dobles y los bloques s�lidos con las meta-baldosas
	correspondientes, (para las gelatinas, basta con utilizar la primera
	meta-baldosa de la animaci�n); adem�s, hay que inicializar la matriz de
	control de la animaci�n de las gelatinas mat_gel[][COLUMNS]. */
void genera_mapa1(char mat[][COLUMNS])
{


}



// TAREA 2Db
/* ajusta_imagen3(int ibg): rotar 90 grados a la derecha la imagen del fondo
	cuyo identificador se pasa por par�metro (fondo 3 de procesador principal)
	y desplazarla para que se visualice en vertical a partir del primer p�xel
	de la pantalla. */
void ajusta_imagen3(int ibg)
{


}




// TAREAS 2Aa,2Ba,2Ca,2Da
/* init_grafA(): inicializaciones generales del procesador gr�fico principal,
				reserva de bancos de memoria y carga de informaci�n gr�fica,
				generando el fondo 3 y fijando la transparencia entre fondos.*/
void init_grafA()
{
	//int bg1A, bg2A, bg3A;

	videoSetMode(MODE_3_2D | DISPLAY_SPR_1D_LAYOUT | DISPLAY_SPR_ACTIVE);
	
// Tarea 2Aa:
	// reservar banco F para sprites, a partir de 0x06400000
	vramSetBankF(VRAM_F_MAIN_SPRITE_0x06400000);
// Tareas 2Ba y 2Ca:
	// reservar banco E para fondos 1 y 2, a partir de 0x06000000
// Tarea 2Da:
	// reservar bancos A y B para fondo 3, a partir de 0x06020000
	



// Tarea 2Aa:
	// cargar las baldosas de la variable SpritesTiles[] a partir de la
	// direcci�n virtual de memoria gr�fica para sprites, y cargar los colores
	// de paleta asociados contenidos en  la variable SpritesPal[]
	dmaCopy(SpritesTiles, SPRITE_GFX, sizeof(SpritesTiles));				//Copiamos los datos de los sprites a la memoria principal
	dmaCopy(SpritesPal, SPRITE_PALETTE, sizeof(SpritesPal));				//Copiamos los colores de la palate a la memoria principa

// Tarea 2Ba:
	// inicializar el fondo 2 con prioridad 2



// Tarea 2Ca:
	//inicializar el fondo 1 con prioridad 0



// Tareas 2Ba y 2Ca:
	// descomprimir (y cargar) las baldosas de la variable BaldosasTiles[] a
	// partir de la direcci�n de memoria correspondiente a los gr�ficos de
	// las baldosas para los fondos 1 y 2, cargar los colores de paleta
	// correspondientes contenidos en la variable BaldosasPal[]


	
// Tarea 2Da:
	// inicializar el fondo 3 con prioridad 3


	// descomprimir (y cargar) la imagen de la variable FondoBitmap[] a partir
	// de la direcci�n virtual de v�deo correspondiente al banco de v�deoRAM A



	// fijar display A en pantalla inferior (t�ctil)
	lcdMainOnBottom();

	/* transparencia fondos:
		//	bit 1 = 1 		-> 	BG1 1st target pixel
		//	bit 2 = 1 		-> 	BG2 1st target pixel
		//	bits 7..6 = 01	->	Alpha Blending
		//	bit 11 = 1		->	BG3 2nd target pixel
		//	bit 12 = 1		->	OBJ 2nd target pixel
	*/
	*((u16 *) 0x04000050) = 0x1846;	// 0001100001000110
	/* factor de "blending" (mezcla):
		//	bits  4..0 = 01001	-> EVA coefficient (1st target)
		//	bits 12..8 = 00111	-> EVB coefficient (2nd target)
	*/
	*((u16 *) 0x04000052) = 0x0709;
}

