global edgeSobel_asm

section .data

mascara_255_word: times 8 dw 255

section .text
;void edgeSobel_asm (unsigned char *src, unsigned char *dst, int cols, int filas,
;                    int src_row_size, int dst_row_size);
edgeSobel_asm:
  ;rdi=src, rsi=dst, edx=columnas, ecx= filas
  ;r8d=ancho de filas en bytes(src), r9d=ancho de filas en bytes(dst)
  push rbp         ;a
  mov rbp, rsp
  push rbx         ;d
  push r12         ;a
  push r13         ;d
  push r14         ;a
  push r15         ;d
  sub rsp, 8       ;a
  ;
  mov rbx, rdi;rbx=src
  mov r12, rsi;r12=dst
  mov r13d, edx;r13d=columnas
  mov r14d, ecx;r14d=filas
  ;
  sub ecx, 2;ecx=cant. de filas a procesar
    ;para comenzar a iterar necesito estar posicionado sobre
    ;la celda (x,y)=(1,1)
    ;posiciona src en (1,1)
  mov r8d, r8d;limpia la parte alta
  mov r15, rdi;r15=puntero para recorrer src
  add r15, r8 ;r15=(columna 0, fila 1)
  inc r15     ;r15=(columna 1, fila 1)
    ;posiciona dst en (1,1)
  mov r9d, r9d;limpia la parte alta
  add rsi, r9 ;rsi=(columna 0, fila 1)
  inc rsi     ;rsi=(columna 1, fila 1)

  movdqu xmm10, [mascara_255_word]
  ;en cada iteracion se van a procesar 4 pixels (por ahora)
  ;eax cuenta la cant. de pixels que faltan procesar (por cada fila)
  .ciclo:
    cmp ecx, 0
    je .fin_de_ciclo
    ;si no:procesar fila
    mov eax, r13d;eax=columnas
    sub eax, 2;descarto bordes

    ;//cuerpo del ciclo:*****
    .pintar:
    ;levantamos datos de src:
    ;se levantan datos en 9 registros para procesar en paralelo
    ;r10,r11 punteros auxilares
    mov r10, r15
    sub r10, r8;r10=fila anterior
    mov r11, r15
    add r11, r8;r11=fila siguiente

    ;|-1|0|1|
    ;|-2|0|2|
    ;|-1|0|1|
    ;OPERADOR X:**********
    ;NO usar PMOVSXBW !!!
    ;OBS:se usaba pmovsxbw, pero traia resultados no esperados
    ;se usa pmovzxbw que completa con 0's la parte alta de cada word
    pmovzxbw xmm1, [r10 - 1]
    pmovzxbw xmm2, [r10];(solo usado para Y)
    pmovzxbw xmm3, [r10 + 1]

    pmovzxbw xmm4, [r15 - 1]
    ;pmovsxbw xmm5, [r15]
    pmovzxbw xmm6, [r15 + 1]

    pmovzxbw xmm7, [r11 - 1]
    movdqu xmm12, xmm7;**(COPIA PARA USAR EN Y)
    pmovzxbw xmm8, [r11];(solo usado para Y)
    pmovzxbw xmm9, [r11 + 1]
      ;el word menos significativo guarda la info para procesar el primer pixel leido
      ;idem para el word "i"
    ;cuentas:
    movdqu xmm0, xmm1
    pxor xmm1, xmm1
    psubw xmm1, xmm0      ;x1=(-1)*src[i-1,j-1]
                          ;x2= 0*src[i-1,j]
                          ;x3=1*src[i-1,j+1]
    movdqu xmm0, xmm4
    pxor xmm4, xmm4
    psubw xmm4, xmm0
    psubw xmm4, xmm0      ;x4=(-2)*src[i,j-1]
                          ;x5= 0*src[i,j]
    paddw xmm6, xmm6      ;x6= 2*src[i,j+1]

    movdqu xmm0, xmm7
    pxor xmm7, xmm7
    psubw xmm7, xmm0      ;x7=(-1)*src[i+1,j-1]
                          ;x8= 0*src[i+1,j]
                          ;x9= 1*src[i+1,j+1]
                          ;SUMO
    movdqu xmm14, xmm9
    paddw xmm14, xmm7
    paddw xmm14, xmm6
    paddw xmm14, xmm4
    paddw xmm14, xmm3
    paddw xmm14, xmm1
      ;x14=|-|-|-|-|-|-|-|-|
      ;obs:en el word 0 se tiene OP_x del pixel 0, idem para word "i"
      ;tomo modulo y guardo en x14
    pabsw xmm14, xmm14     ;x14= abs(OP_x)

    ;|-1|-2|-1|
    ;|0|0|0|
    ;|1|2|1|
    ;OPERADOR Y:**********
                          ;x1=(-1)*src[i-1,j-1]
    movdqu xmm0, xmm2
    pxor xmm2, xmm2
    psubw xmm2, xmm0
    psubw xmm2, xmm0      ;x2=(-2)*src[i-1,j]

    movdqu xmm0, xmm3
    pxor xmm3, xmm3
    psubw xmm3, xmm0      ;x3=(-1)*src[i-1,j+1]
                          ;x4=0*src[i,j-1]
                          ;x5= 0*src[i,j]
                          ;x6= 0*src[i,j+1]
    movdqu xmm7, xmm12    ;x7=1*src[i+1,j-1]

    paddw xmm8, xmm8      ;x8= 2*src[i+1,j]
                          ;x9= 1*src[i+1,j+1]
                          ;SUMO
    movdqu xmm15, xmm9
    paddw xmm15, xmm8
    paddw xmm15, xmm7
    paddw xmm15, xmm3
    paddw xmm15, xmm2
    paddw xmm15, xmm1
      ;x15=|-|-|-|-|-|-|-|-|
      ;obs:en el word 0 se tiene OP_y del pixel 0, idem para word "i"
      ;tomo modulo y guardo en x15
    pabsw xmm15, xmm15     ;x15= abs(OP_y)

      ;sumo operadores x e y:
    ;paddw xmm15, xmm14 ;x15=abs(OP_x)+abs(OP_y)
    paddusw xmm15, xmm14 ;x15=abs(OP_x)+abs(OP_y) CON SATURACION SIN SIGNO

      ;FILTRO CASOS: tomando mínimo!!!
      ;de enteros sin signo
                          ;x10=|255| .. |255|255|
    pminuw xmm15, xmm10   ;tengo pixels procesados en word
                          ;EMPAQUETO a byte

    packuswb xmm15, xmm15;x15=| ... |b7|b6|b5|b4|b3|b2|b1|b0|
    ;guardo 8 bytes(pixels procesados)
    ;DOM 7/10:proceso de a 8 pixels
    movq rdx, xmm15;copia 8 pixels

    ;guardo en dst:
    mov [rsi], rdx;****

    ;//FIN del cuerpo del ciclo*****

    ;****controles de ciclo:

    ;//luego de guardar los 8 pixels en dst:
    sub eax, 8;****ya pinte 8 pixels
    cmp eax, 8;****
    jl .a_mano
    ;si no: hay al menos 8 pixels por procesar
    add r15, 8;avanzo punteros
    add rsi, 8
    jmp .pintar
    ;
    .a_mano:
    ;****DOMINGO:
    cmp eax, 0
    je .cambiar_fila      ;****no se cambiaron los punteros todavia!!
    ;si no: quedan 7, 6 , ... ó 1 pixels a procesar
      ;****operaciones para poder leer 4 pixels
      ;r10,r11 registros auxilares
    mov r10d, 8;constante 8
    sub r10d, eax;r10d=cuantos pixels faltan procesar (7,6,... ó 1)
    add r15, 8  ;src
    add rsi, 8  ;dst
    mov r11d, 8
    sub r11d, eax;r11d=cuanto retroceder para procesar 8 pixels
    mov r11d, r11d;limpio parte alta
                  ; actualizo (hacia atras)
    sub r15, r11;src
    sub rsi, r11;dst
    mov eax, 8 ;"restan procesar 8 pixels"
    jmp .pintar

    .cambiar_fila:
    dec ecx
    add r15, 10; 8 celdas pues ya se procesaron, +2 para cambiar de fila
    add rsi, 10
    jmp .ciclo

    ;//FIN DEL CICLO:
   .fin_de_ciclo:
    ;rbx=src
    ;r12=dst  
    ;r13d=columnas
    ;r14d=filas
      mov rsi, r12  ; rcx tengo el dst
      mov eax, eax
      mov edx, edx
      mov eax, r14d ; rax <- #filas src
      dec eax
      mul r9d       ; EDX:EAX 
      shl rdx, 32
      or rax, rdx ;
      add rax, rsi    ; puntero a ultima fila...

      mov ecx, r13d   ; en rcx tengo la cantidad de columnas.... 

    .ciclo_bordes:
       pxor xmm0, xmm0
       movdqu [rsi], xmm0
       movdqu [rax], xmm0
       sub ecx, 16
       add rsi, 16
       add rax, 16
       cmp ecx,0
       je .prepara_bordes
       cmp ecx, 16
       jl .manopla
       jmp .ciclo_bordes

    .manopla:
    mov r10, 16
    sub r10d, ecx ; lo que me falta PROCESAR a 16
    ;
    mov ecx, ecx
    add rsi, rcx 
    add rax, rcx 
    sub rsi, 16
    sub rax, 16
    pxor xmm0, xmm0
    movdqu [rsi], xmm0
    movdqu [rax], xmm0
    
    .prepara_bordes:
    mov rsi, r12    ;rsi=puntero a inicio de fila 
    mov rax, r12    ;r12=puntero a celda fin de fila
    mov r9d, r9d    ;ancho d fila en bytes (dst)
    mov r13d, r13d  ; limpio parte alta.
    dec r13
    add rax, r13    ;rax=puntero a celda fin de fila
    mov ecx, r14d   ;ecx=cant. filas
    xor dl, dl      ; seteo en 0
    .ciclo_laterales:
      cmp ecx, 0 
      je .fin
      mov byte [rsi], 0 
      mov byte [rax], 0
      dec ecx
      add rsi, r9 
      add rax, r9 
      jmp .ciclo_laterales
  .fin:
  add rsp, 8
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbx
  pop rbp
  ret

  ;parece que procesa 8 pixels en lugar de 4, en tal caso:
  ;incrementar los punteros con "+8", y en "controles de ciclo"
  ;usar 8 en lugar de 4 para las preguntas
