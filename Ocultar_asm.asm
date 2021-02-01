section .data

mask_255: db 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255 
mask_1: db 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 
mask_2: db 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0 
mask_3: db 3, 0, 0, 0, 3, 0, 0, 0, 3, 0, 0, 0, 3, 0, 0, 0 


mask_div: times 4 dd 0.25

mask_invert: db 12,13,14,15,8,9,10,11,4,5,6,7,0,1,2,3

mask_FC: db 0xfc, 0, 0, 0, 0xfc, 0, 0, 0, 0xfc, 0, 0, 0, 0xfc, 0, 0, 0 ; Corregir


mask_blue: db 0, 255, 255, 255, 1, 255, 255, 255, 2, 255, 255, 255, 3, 255, 255, 255 ; Corregir
mask_green: db 255, 0, 255, 255, 255, 1, 255, 255, 255, 2, 255, 255, 255, 3, 255, 255 ; Corregir
mask_red: db 255,255, 0, 255, 255, 255, 1, 255, 255, 255, 2, 255, 255, 255, 3, 255 ; Corregir


section .text
global Ocultar_asm

;Rdi uint8_t *src,
;Rsi uint8_t *src2,
;rdx uint8_t *dst,
;ecx int width,
;R8d int height,
;R9d int src_row_size,
; int dst_row_size


Ocultar_asm:
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	
	; sub rsp, 8

	mov r12, rdi; src
	mov r13, rsi; src2
	mov r14, rdx; dst
	mov r15, rdi

	mov eax, ecx
	mul r8d ; eax = cantidad de pixeles totales
	mov rcx, rax ; rcx cantidad de pixeles a procesar 
	xor r9, r9
	xor rax, rax
	; Para ubicar espejo ... 
	mov r9, rcx ; r15 al final de la imagen 
	mov eax, 4
	mul r9d
	add r15, rax
	; r15 = donde empieza el espejo...
	xor r9, r9

	movdqu xmm12, [mask_2]
	movdqu xmm13, [mask_FC]
	movdqu xmm14, [mask_3]
	movdqu xmm15, [mask_1]
;;
;; ** Aca tengo que calcular la de src "espejo" 
;; ** usando r15 como 
;;
; Poner la imagen en Blanco y Negro
.ciclo:
;P1	
	sub r15, 16
	movdqu xmm1, [r13] ; b
	movdqu xmm2, xmm1 ; g 
	movdqu xmm3, xmm1 ; r
	;B
	pslld xmm1, 24
	psrld xmm1, 24
	;G
	psrld xmm2, 8
	pslld xmm2, 24
	psrld xmm2, 24
	;R
	pslld xmm3, 8
	psrld xmm3, 24

; Guardarlos.... en x8,x9,x10
	; movdqu xmm8, xmm1 ; B
	; movdqu xmm9, xmm2 ; G
	; movdqu xmm10, xmm3 ; R
; 

	paddd xmm2, xmm2 ; Gx2
	paddd xmm1, xmm2
	paddd xmm1, xmm3

	; cvtdq2ps xmm1, xmm1
	; movdqu xmm2, [mask_div]
	; mulps xmm1, xmm2
	; cvttps2dq xmm1,xmm1
	psrld xmm1, 2 ; Descarto los ultimos 2 bits 
; Mascara para 1's
	
	movdqu xmm2, xmm1 ; bitsB 
	movdqu xmm3, xmm1 ; bitsG
	movdqu xmm4, xmm1 ; bitsR

	movdqu xmm5, xmm1 ; bitsB Parte Or 
	movdqu xmm6, xmm1 ; bitsG Parte Or
	movdqu xmm7, xmm1 ; bitsR Parte Or

	psrld xmm2, 4
	psrld xmm3, 3
	psrld xmm4, 2

	psrld xmm5, 7
	psrld xmm6, 6
	psrld xmm7, 5

	pand xmm2, xmm15
	pand xmm3, xmm15
	pand xmm4, xmm15

	pand xmm5, xmm15
	pand xmm6, xmm15
	pand xmm7, xmm15

	pslld xmm2, 1
	pslld xmm3, 1
	pslld xmm4, 1

	por xmm2, xmm5 ; Aca es donde tengo que guardarlos ... 
	por xmm3, xmm6 ; Aca es donde tengo que guardarlos ... 
	por xmm4, xmm7 ; Aca es donde tengo que guardarlos ... 

; Libres: 1,5,6,7, 8, 9 , 10

	; Ubicar el espejo
	; mov r8, r15
	; sub r8, 4 ; R15 cantidad de pixeles que ya procese.... 

	movdqu xmm1, [r15] ; Espejo B

	;Aca los tengo que dar vuelta ... uso xmm5 
	movdqu xmm5,[mask_invert] 
	pshufb xmm1, xmm5
	pxor xmm5, xmm5 ; Limpio 
	movdqu xmm5, xmm1 ; Espejo G
	movdqu xmm6, xmm1 ; Espejo R
; Espejo Separar componentes
	;B
	pslld xmm1, 24
	psrld xmm1, 24
	;G
	psrld xmm5, 8
	pslld xmm5, 24
	psrld xmm5, 24
	;R
	pslld xmm6, 8
	psrld xmm6, 24
;**************************************
; Divido por 4
	psrld xmm1, 2 ;
	psrld xmm5, 2 ; 
	psrld xmm6, 2 ; 
;**************************************
	pand xmm1, xmm14 ;x1 =  ... ^ espejo and 3 (B)
	pand xmm5, xmm14 ;x5 = ... ^ espejo and 3 (G)
	pand xmm6, xmm14 ;x6 = ... ^ espejo and 3 (R)


	pand xmm2, xmm14 ;x1 = (bitsB & 0x3)
	pand xmm3, xmm14 ;x5 = (bitsG & 0x3)
	pand xmm4, xmm14 ;x6 = (bitsR & 0x3)

	pxor xmm1, xmm2 ; ((bitsB & 0x3) XOR ((src[(height-1)-i][(width-1)-j].b >> 2) & 0x3))
	pxor xmm5, xmm3 ; ((bitsG & 0x3) XOR ((src[(height-1)-i][(width-1)-j].g >> 2) & 0x3))
	pxor xmm6, xmm4 ; ((bitsR & 0x3) XOR ((src[(height-1)-i][(width-1)-j].r >> 2) & 0x3))
; Libres xmm2,3,4

	movdqu xmm2, [r12]
	movdqu xmm3, xmm2
	movdqu xmm4, xmm2
; bits B = xmm2
; bits G = xmm3
; bits R = xmm4
; Espejo Separar componentes
	;B
	pslld xmm2, 24
	psrld xmm2, 24
	;G
	psrld xmm3, 8
	pslld xmm3, 24
	psrld xmm3, 24
	;R
	pslld xmm4, 8
	psrld xmm4, 24

	pand xmm2, xmm13 ; src[i][j].b & 0xFC
	pand xmm3, xmm13 ; src[i][j].g & 0xFC
	pand xmm4, xmm13 ; src[i][j].r & 0xFC

	por xmm2, xmm1 ; (src[i][j].b & 0xFC) + ((bitsB & 0x3) ^ ((src[(height-1)-i][(width-1)-j].b >> 2) & 0x3)) ; puede ser la inst paddd
	por xmm3, xmm5 ; (src[i][j].g & 0xFC) + ((bitsB & 0x3) ^ ((src[(height-1)-i][(width-1)-j].g >> 2) & 0x3)) ; puede ser la inst paddd
	por xmm4, xmm6 ; (src[i][j].r & 0xFC) + ((bitsB & 0x3) ^ ((src[(height-1)-i][(width-1)-j].r >> 2) & 0x3)) ; puede ser la inst paddd
; Aca puede ser que tenga que 
	pxor xmm5, xmm5 
	
	packusdw xmm2, xmm5
	packusdw xmm3, xmm5
	packusdw xmm4, xmm5


	packuswb xmm2,xmm5
	packuswb xmm3,xmm5
	packuswb xmm4,xmm5

	movdqu xmm5, [mask_blue]
	pshufb xmm2, xmm5
	movdqu xmm5, [mask_green]
	pshufb xmm3, xmm5
	movdqu xmm5, [mask_red]
	pshufb xmm4, xmm5

	; pslldq xmm3, 1
	; pslldq xmm4, 2

; junto todo en 1 pixel  
	movdqu xmm1, [mask_255]
	por xmm2, xmm3  
	por xmm2, xmm4  
	por xmm2, xmm1
	movdqu [r14], xmm2
	add r14, 16 ; pasar a los siguientes 4 pixeles  
	add r12, 16 ; pasar a los siguientes 4 pixeles
	add r13, 16 ; pasar a los siguientes 4 pixeles

; Falta una comparacion de ciclo
	sub rcx, 4 ; cantidad de pixeles que procese
	cmp rcx, 0
	je .termine
	jmp .ciclo
	


.termine:
; add rsp, 8
pop r15
pop r14
pop r13
pop r12
pop rbp
ret
