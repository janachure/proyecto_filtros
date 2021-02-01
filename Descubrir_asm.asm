global Descubrir_asm
section .rodata
ceroTres 			: times 4 db 0x03, 0x03, 0x03, 0xFF
ceroUno 			: times 4 db 0x01, 0x01, 0x01, 0xFF
soloB 				: times 4 db 0xFF, 0x00, 0x00, 0x00
soloG 				: times 4 db 0x00, 0xFF, 0x00, 0x00
soloR 				: times 4 db 0x00, 0x00, 0xFF, 0x00
transparencia 		: times 4 db 0x00, 0x00, 0x00, 0xFF
maskShuffle			: db 0x0C, 0x0C, 0x0C, 0xFF, 0x08, 0x08, 0x08, 0xFF, 0x04, 0x04, 0x04, 0xFF, 0x00, 0x00, 0x00, 0xFF
%define src 			rdi
%define dst 			rsi
%define width 			edx
%define height 			ecx
%define src_row_size 	r8d
%define src_row_size 	r9d
%define i				r10d
%define j				r11d
section .text
Descubrir_asm: ; void Descubrir_asm (uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size);
	push rbp
	mov rbp, rsp
	push r12

	pxor xmm8, xmm8						; sirve para desempaquetar y empaquetear
	movdqu xmm9, [transparencia]		; conservo la transparencia en OXFF ya que posiblemenete se vea modificada mas adelante
	movdqu xmm10, [ceroTres]			;  0x0 0x3 0x3 0x3 || 0x0 0x3 0x3 0x3 || 0x0 0x3 0x3 0x3 || 0x0 0x3 0x3 0x3
	movdqu xmm11, [ceroUno]				;  0x0 0x1 0x1 0x1 || 0x0 0x1 0x1 0x1 || 0x0 0x1 0x1 0x1 || 0x0 0x1 0x1 0x1
	movdqu xmm12, [soloB]
	movdqu xmm13, [soloG]
	movdqu xmm14, [soloR]				; cargo las máscaras en los registros para no perder performance cargando de todo el tiempo en pleno ciclo
	movdqu xmm15, [maskShuffle]			; mascara para hacer broadcast e invertir la posición de los píxeles
	mov r10d, edx
	mov eax, width
	mul height
	mov edx, r10d

	lea r12, [src + 4*rax - 16] 		;en r12 tengo el puntero estoy en la esquina inferior derecha del filtro
	xor i, i							;limpio r10d y r11d 	
	xor i, i							;limpio r10d y r11d para ciclar	
	xor j, j

	.recorro_por_columnas:
		cmp j, width
		je .siguiente_fila

		movdqu xmm0, [r12] 				; src[height - 1 - i][width - 1 -i]
		movdqu xmm1, xmm0

		punpcklbw xmm0, xmm8			; A1 0 R1 0 G1 0 B1 || A0 0 R0 0 G0 0 B0 
		punpckhbw xmm1, xmm8 			; A3 0 R3 0 G3 0 B3 || A2 0 R2 0 G2 0 B2 

		psrlw xmm0, 2					; A1 0 R1 0 G1 0 B1 || A0 0 R0 0 G0 0 B0  >> 2
		psrlw xmm1, 2					; A3 0 R3 0 G3 0 B3 || A2 0 R2 0 G2 0 B2  >> 2
		packuswb xmm0, xmm1				; reconstruido
		por xmm0, xmm9					; retorno la transparencia a la normalidad

		movdqu xmm3, [src]				; src[height - 1 - i][width - 1 -i] >> 2 ^ src[i][j]
										; xmm3 = PIX3 | PIX2 | PIX1 | PIX0
		pshufd xmm3, xmm3, 0x1B 		; xmm3 = PIX0 | PIX1 | PIX2 | PIX3

		pxor xmm0, xmm3					; src[height - 1 - i][width - 1 -i] >> 2 ^ src[i][j] 
		por xmm0, xmm9					; otra vez le doy la transparencia
		pand xmm0, xmm10				; xmm0 & 0x3

		movdqu xmm1, xmm0				; (src[height - 1 - i][width - 1 -i] >> 2 ^ src[i][j]) & 0x3
		movdqu xmm2, xmm0				; (src[height - 1 - i][width - 1 -i] >> 2 ^ src[i][j]) & 0x3

		pand xmm2, xmm11				; src[height - 1 - i][width - 1 -i] >> 2 ^ src[i][j] & 0x1; bits 7 6 5

		punpcklbw xmm0, xmm8			; parte baja 
		punpckhbw xmm1, xmm8			; parte alta

		psrlw xmm0, 1					; parte baja >> 1
		psrlw xmm1, 1

		packuswb xmm0, xmm1				; empaqueto de nuevo, xmm0 con xmm1
		por xmm0, xmm9					; le doy la transparencia otra vez
		pand xmm0, xmm11				; >> 1 & 0x1, bits 4 3 2

		;----------AZUL----------
		movdqu xmm4, xmm2				; bit 7
		pslld xmm4, 7					; bit 7 << 7
		pand xmm4, xmm12				; solo la componente azul

		movdqu xmm5, xmm0				; bit 4	
		pslld xmm5, 4					; bit 4 << 4
		pand xmm5, xmm12				; me quedo con la componente azul

		por xmm5, xmm4					; bit 7 << 7 | bit 4 << 4
		;----------VERDE----------
		movdqu xmm4, xmm2
		pand xmm4, xmm13				; verde
		psrld xmm4, 8			
		pslld xmm4, 6					; bit 6 << 6

		movdqu xmm6, xmm0
		pand xmm6, xmm13				; verde				
		psrld xmm6, 8					; bit 3 << 3
		pslld xmm6, 3

		por xmm6, xmm4 					; bit 6 << 6 | bit 3 << 3

		por xmm6, xmm5					; bit 7 << 7 | bit 4 << 4 | bit 6 << 6 | bit 3 << 3
		;----------ROJO----------		; todo ok hasta aca
		movdqu xmm4, xmm2
		pand xmm4, xmm14				; rojo
		psrld xmm4, 16					
		pslld xmm4,	5					; bit 5 << 5

		movdqu xmm5, xmm0
		pand xmm5, xmm14				; rojo
		psrld xmm5, 16
		pslld xmm5, 2					; bit 2 << 2

		por xmm5, xmm4 					; bit 5 << 5 | bit 2 << 2
		por xmm6, xmm5					; bit 7 << 7 | bit 4 << 4 | bit 6 << 6 | bit 3 << 3 | bit 5 << 5 | bit 2 << 2

		pshufb xmm6, xmm15				; ponemos los pixeles en el orden correcto para pegarlos en memoria

		por xmm6, xmm9					;le doy la transparencia

		movdqu [dst], xmm6
		add j, 4

		sub r12, 16
		add src, 16
		add dst, 16
	jmp .recorro_por_columnas
	.siguiente_fila:
	xor j, j
	inc i
	cmp i, height
	je .fin
	jmp .recorro_por_columnas

	.fin:
	pop r12
	pop rbp
ret