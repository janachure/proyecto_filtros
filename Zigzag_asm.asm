global Zigzag_asm
section .data
mask_5: times 4 dd 0.2 ; Corregir
mask_255: db 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255 ; Corregir
mask_blue: db 0, 255, 255, 255, 1, 255, 255, 255, 2, 255, 255, 255, 3, 255, 255, 255 ; Corregir
mask_green: db 255, 0, 255, 255, 255, 1, 255, 255, 255, 2, 255, 255, 255, 3, 255, 255 ; Corregir
mask_red: db 255,255, 0, 255, 255, 255, 1, 255, 255, 255, 2, 255, 255, 255, 3, 255 ; Corregir

mask_white: db 255,255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 ; Corregir


;Rdi    uint8_t *src,
;Rsi    uint8_t *dst,
;edx    int columnas,
;ecx    int filas,
;R8d    int src_row_size,
;R9d   int dst_row_size
section .text
Zigzag_asm:
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	sub rsp, 8
;Preparar ciclo:
	xor r14, r14
	xor r12, r12
	mov [rsp-24], rcx ; guardo en la pila la cantidad de filas en dst
	mov r13d, 0 ; r13d <- resto de fila actual
	add r13d, 2
; Ajusto los 2 de cada lado Filas
	sub ecx, 4
; Ajusto los 2 de cada lado Columnas
	sub edx, 4
	; add r14, 2
	mov [rsp-8], r8 ; guardo en la pila la cantidad de bytes de una fila en dst
	mov [rsp-16], rsi ; guardo en la pila el inicio de la matriz dst

	add rdi, r8
	add rdi, r8
	add rdi, 8

	add rsi, r9
	add rsi, r9
	add rsi, 8

	; mov r10, rdi
	; mov r11, rsi
	; xor r9, r9
	; mov r9d, edx

	; add rdi, r9 
	; add rdi, r9
	; add rdi, 8 ; Lo pongo en la columna 2
	; ; inc rdi 
	; ;Ajusto rsi a el subcuadrado...
	; mov r11, rsi
	; mov r9d, r9d
	; add rsi, r9 
	; add rsi, r9
	; add rsi, 8 ; Lo pongo en la columna 2

	; mov r8, r10

	; xor r9, r9
	; mov r9d, edx


.ciclo:
	cmp r13d, 0
	je .mod_2 ; si no es 0 mod 4
	cmp r13d, 2
	je .mod_2 ; si no es 2 mod 4
	cmp r13d, 1
	je .mod_1 ; si no es 1 mod 4
;entonces es 3 mod 4
.mod_3: ; Corregir
	movdqu xmm12, [mask_255]
	movdqu xmm1, [rdi+8]
	por xmm1, xmm12
	movdqu [rsi], xmm1
	add rdi, 16
	add rsi, 16
	add r14, 4
	jmp .cambio_de_fila
.mod_1: ; Corregir
	movdqu xmm12, [mask_255]
	movdqu xmm1, [rdi-8]
	por xmm1, xmm12
	movdqu [rsi], xmm1
	add rdi, 16
	add rsi, 16
	add r14, 4
	jmp .cambio_de_fila
.mod_2: 
	movdqu xmm1, [rdi-4] ; b0| . . . | b16
	movdqu xmm2, [rdi-8] ; b1| . . . | b17
	movdqu xmm3, [rdi] ; b2| . . . | b18
	movdqu xmm4, [rdi+4] ; b3| . . . | b19
	movdqu xmm5, [rdi+8] ; b4| . . . | b20

	movdqu xmm6, xmm1 ; [rdi-4] ; b0| . . . | b16
	movdqu xmm7, xmm2 ; [rdi-8] ; b1| . . . | b17
	movdqu xmm8, xmm3 ; [rdi] ; b2| . . . | b18
	movdqu xmm9, xmm4 ; [rdi+4] ; b3| . . . | b19
	movdqu xmm10, xmm5 ; [rdi+8] ; b4| . . . | b20

	movdqu xmm11, xmm1 ; [rdi-4] ; b0| . . . | b16
	movdqu xmm12, xmm2 ; [rdi-8] ; b1| . . . | b17
	movdqu xmm13, xmm3 ; [rdi] ; b2| . . . | b18
	movdqu xmm14, xmm4 ; [rdi+4] ; b3| . . . | b19
	movdqu xmm15, xmm5 ; [rdi+8] ; b4| . . . | b20
; Componentes Azul
	pslld xmm1, 24
	pslld xmm2, 24
	pslld xmm3, 24
	pslld xmm4, 24
	pslld xmm5, 24

	psrld xmm1, 24
	psrld xmm2, 24
	psrld xmm3, 24
	psrld xmm4, 24
	psrld xmm5, 24
;Componente Verde
	psrld xmm6, 8
	psrld xmm7, 8
	psrld xmm8, 8
	psrld xmm9, 8
	psrld xmm10, 8
; 
	pslld xmm6, 24
	pslld xmm7, 24
	pslld xmm8, 24
	pslld xmm9, 24
	pslld xmm10, 24
; 
	psrld xmm6, 24
	psrld xmm7, 24
	psrld xmm8, 24
	psrld xmm9, 24
	psrld xmm10, 24	
;Componente Rojo
	pslld xmm11, 8
	pslld xmm12, 8
	pslld xmm13, 8
	pslld xmm14, 8
	pslld xmm15, 8
; 
	psrld xmm11, 24
	psrld xmm12, 24
	psrld xmm13, 24
	psrld xmm14, 24
	psrld xmm15, 24

; Convierto a floats
	cvtdq2ps xmm1, xmm1
	cvtdq2ps xmm2, xmm2
	cvtdq2ps xmm3, xmm3
	cvtdq2ps xmm4, xmm4
	cvtdq2ps xmm5, xmm5

	cvtdq2ps xmm6, xmm6
	cvtdq2ps xmm7, xmm7
	cvtdq2ps xmm8, xmm8
	cvtdq2ps xmm9, xmm9
	cvtdq2ps xmm10, xmm10

	cvtdq2ps xmm11, xmm11
	cvtdq2ps xmm12, xmm12
	cvtdq2ps xmm13, xmm13
	cvtdq2ps xmm14, xmm14
	cvtdq2ps xmm15, xmm15

	addps xmm1, xmm2
	addps xmm1, xmm3
	addps xmm1, xmm4
	addps xmm1, xmm5

	addps xmm6, xmm7
	addps xmm6, xmm8
	addps xmm6, xmm9
	addps xmm6, xmm10

	addps xmm11, xmm12
	addps xmm11, xmm13
	addps xmm11, xmm14
	addps xmm11, xmm15	

; Divido x 5
	movdqu xmm14, [mask_5]
	mulps xmm1, xmm14 ; x1 <- x1 / 5
	mulps xmm6, xmm14 ; x6 <- x6 / 5
	mulps xmm11, xmm14 ; x11 <- x11 / 5	
; Convierto a dword
	cvtps2dq xmm1, xmm1 
	cvtps2dq xmm6, xmm6 
	cvtps2dq xmm11, xmm11 

	pxor xmm2, xmm2

	packusdw xmm1, xmm2
	packusdw xmm6, xmm2
	packusdw xmm11,xmm2

	packuswb xmm1, xmm2
	packuswb xmm6, xmm2
	packuswb xmm11, xmm2

	movdqu xmm2, [mask_blue]
	pshufb xmm1, xmm2
	movdqu xmm2, [mask_green]
	pshufb xmm6, xmm2
	movdqu xmm2, [mask_red]
	pshufb xmm11, xmm2

;Guardo
	movdqu xmm12, [mask_255]

	por xmm1, xmm6
	por xmm1, xmm11
	por xmm1, xmm12 ; mascara

	movdqu [rsi], xmm1
	; Corregir
	add rdi, 16
	add rsi, 16
	add r14, 4 ; Corregir
	jmp .cambio_de_fila

.cambio_de_fila:
	cmp edx, r14d
	je .termine_fila
	jmp .ciclo

.termine_fila:
	xor r14, r14
	; add r14, 2
	cmp r12d, ecx
	jg .termine
	add rdi, 8 ; Moverte 4 pixeles para que rdi este ReaDI 
	add rsi, 8 ; Moverte 4 pixeles para que rsi este listo 
	pxor xmm1, xmm1
	; pcmpeqb xmm1, xmm1
	; movq [rsi], xmm1
	add rdi, 8 ; Moverte 4 pixeles para que rdi este ReaDI 
	add rsi, 8 ; Moverte 4 pixeles para que rsi este listo 
	inc r12d
	cmp r13d, 3
	je .cero
	inc r13d
	jmp .ciclo
.cero:
	mov r13, 0
	jmp .ciclo

	

; Terminar
.termine:
	; mov [rsp-8], r9 ; guardo en la pila la cantidad de bytes de una fila en dst
	; mov [rsp-16], rsi ; guardo en la pila el inicio de la matriz dst
	; mov [rsp-24], rcx ; guardo en la pila la cantidad de filas en dst
	xor r12, r12
	mov r9d, r9d
	xor r10, r10
	mov r9,[rsp-8] ; r9d  =bytes de una fila 
	mov r10, r9 ; r10 bytes de una fila
	add r9, r9
	mov rsi, [rsp-16] ; ; guardo en la pila el inicio de la matriz dst
	mov r12, rsi
	mov r11, rsi
	add r11, r10
	sub r11, 8
	mov rcx, [rsp-24] ; ; guardo en la pila la cantidad de filas en dst
	mov rax, rcx
	xor r8, r8
	mul r10
	sub rax, r10 ; vuelvo todo para atras 1 fila
	sub rax, r10 ; vuelvo todo para atras 1 fila	
	add r12, rax	
	xor rax, rax
	; add r8, 2
	inc r8d
	inc r8d
	pcmpeqb xmm1, xmm1
	.ciclo_borde: 
		movdqu [rsi+rax], xmm1	 ; pinto 4 pixeles 
		movdqu [r12+rax], xmm1	 ; pinto 4 pixeles 
		add rax, 16
		cmp rax, r9
		je .salgo_doblefila
		jmp .ciclo_borde
	.salgo_doblefila:
		movdqu [r11], xmm1	 ; pinto 8 pixeles 
		add r11, r10 ; le sumo una fila de nuevo para ir a la de abajo
		inc r8d
		cmp r8d, ecx
		je .fin
		jmp .salgo_doblefila
	; add r9, 4
	; xor r8, r8
	; xor r12, r12 
	; ; tengo que hacer el calculo de una fila
	; mov r13, r9
	; shl r13, 2
	; movdqu [rsi], xmm1	
	; movq [r11+r13], xmm1	
	; add rsi, 16
	; ; add r13, r13
	; add r8, 16
	; sub r9, 2
	; cmp dword r9, 0
	; je .fin
	; jmp .ciclo_borde

.fin:
movdqu [rsi], xmm1	
add rsp, 8
pop r14
pop r13
pop r12
pop rbp	
ret
