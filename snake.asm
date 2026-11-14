.data
	# display 512x512 e celula 16x16, temos 32 x 32 = 1024 celulas.
	# 1024 celulas * 4 bytes = 4096 bytes
	display_buffer: .space 4096

	COR_FUNDO:      .word 0x00FFFFFF    # Branco
	COR_COBRA:      .word 0x004061fc    # Azul
	COR_COMIDA:     .word 0x004AB34B    # Verde
	
    # vetores para guardar as coordenadas X e Y de cada parte da cobra 
    cobra_x:        .space 4096
    cobra_y:        .space 4096

    tamanho:        .word 1             # Cobra comeca apenas com a cabeca
    dir_x:          .word 1             # Direcao inicial: 1 = direita, -1 = esquerda, 0 = parado
    dir_y:          .word 0             # Direcao inicial: 1 = baixo, -1 = cima, 0 = parado

.text
.globl main

main:
    jal limpar_tela

    # a cabeca na posicao inicial (0, 0)
    la $t0, cobra_x
    sw $zero, 0($t0)
    la $t0, cobra_y
    sw $zero, 0($t0)

    # desenha a cobra inicial
    li $a0, 0
    li $a1, 0
    lw $a2, COR_COBRA
    jal desenhar_celula

game_loop:
    # pausa o jogo por 0,5 segundos
    li $v0, 32
    li $a0, 500
    syscall

    jal ler_teclado             # verifica se alguma tecla WASD foi pressionada
    jal atualizar_cobra

    # verificacao das 4 bordas 
    la $t0, cobra_x
    lw $t1, 0($t0)
    bltz $t1, fim_jogo
    bge $t1, 32, fim_jogo

    la $t0, cobra_y
    lw $t1, 0($t0)
    bltz $t1, fim_jogo
    bge $t1, 32, fim_jogo

    j game_loop

fim_jogo:
    li $v0, 10
    syscall
 
ler_teclado:
    li $t0, 0xffff0000          # endereco de controle do teclado
    lw $t1, 0($t0)
    andi $t1, $t1, 1            # isola o bit 0 (1 = tecla disponivel, 0 = nenhuma tecla)
    beq $t1, $zero, fim_teclado

    li $t0, 0xffff0004          # endereco do caractere digitado 
    lw $t2, 0($t0)              # carrega o codigo ASCII da tecla

    lw $t3, tamanho             # carrega tamanho atual 
    lw $t4, dir_x
    lw $t5, dir_y

    # verifica tecla 'w' (119) ou 'W' (87) = Cima 
    beq $t2, 119, mover_cima
    beq $t2, 87, mover_cima

    # verifica tecla 's' (115) ou 'S' (83) = Baixo 
    beq $t2, 115, mover_baixo
    beq $t2, 83, mover_baixo

    # verifica tecla 'a' (97) ou 'A' (65) = Esquerda 
    beq $t2, 97, mover_esquerda
    beq $t2, 65, mover_esquerda

    # Verifica tecla 'd' (100) ou 'D' (68) = Direita 
    beq $t2, 100, mover_direita
    beq $t2, 68, mover_direita

    j fim_teclado

mover_cima:
    # se tamanho > 1 e ja esta indo para baixo, ignora comando
    ble $t3, 1, aplicar_cima
    beq $t5, 1, fim_teclado
aplicar_cima:
    sw $zero, dir_x
    li $t6, -1
    sw $t6, dir_y
    j fim_teclado

mover_baixo:
    # se tamanho > 1 e ja esta indo para cima, ignora comando
    ble $t3, 1, aplicar_baixo
    beq $t5, -1, fim_teclado
aplicar_baixo:
    sw $zero, dir_x
    li $t6, 1
    sw $t6, dir_y
    j fim_teclado

mover_esquerda:
    # se tamanho > 1 e ja esta indo para direita, ignora comando
    ble $t3, 1, aplicar_esquerda
    beq $t4, 1, fim_teclado
aplicar_esquerda:
    li $t6, -1
    sw $t6, dir_x
    sw $zero, dir_y
    j fim_teclado

mover_direita:
    # se tamanho > 1 e ja esta indo para esquerda, ignora comando
    ble $t3, 1, aplicar_direita
    beq $t4, -1, fim_teclado
aplicar_direita:
    li $t6, 1
    sw $t6, dir_x
    sw $zero, dir_y

fim_teclado:
    jr $ra

# atualiza o corpo da cobra, apaga a cauda antiga e desenha a nova cabeca
atualizar_cobra:
    addi $sp, $sp, -4
    sw $ra, 0($sp)              # salva endereco de retorno na pilha

    # apaga a ultima celula da cauda antes de mover
    lw $t0, tamanho
    addi $t0, $t0, -1
    sll $t1, $t0, 2

    la $t2, cobra_x
    add $t2, $t2, $t1
    lw $a0, 0($t2)

    la $t3, cobra_y
    add $t3, $t3, $t1
    lw $a1, 0($t3)

    lw $a2, COR_FUNDO
    jal desenhar_celula

    # desloca o corpo nos vetores de tras para frente 
    lw $t0, tamanho
    addi $t0, $t0, -1

loop_corpo:
    blez $t0, mover_cabeca

    sll $t1, $t0, 2
    addi $t2, $t1, -4

    la $t3, cobra_x
    add $t4, $t3, $t2
    lw $t5, 0($t4)
    add $t4, $t3, $t1
    sw $t5, 0($t4)

    la $t3, cobra_y
    add $t4, $t3, $t2
    lw $t5, 0($t4)
    add $t4, $t3, $t1
    sw $t5, 0($t4)

    addi $t0, $t0, -1
    j loop_corpo

mover_cabeca:
    # atualiza a posicao da cabeca somando a direcao atual
    la $t0, cobra_x
    lw $t1, 0($t0)
    lw $t2, dir_x
    add $t1, $t1, $t2
    sw $t1, 0($t0)

    la $t3, cobra_y
    lw $t4, 0($t3)
    lw $t5, dir_y
    add $t4, $t4, $t5
    sw $t4, 0($t3)

    # nao desenha se sair dos limites da grade (0 a 31)
    bltz $t1, fim_atualizar
    bge $t1, 32, fim_atualizar
    bltz $t4, fim_atualizar
    bge $t4, 32, fim_atualizar

    # desenha a nova posicao da cabeca
    move $a0, $t1
    move $a1, $t4
    lw $a2, COR_COBRA
    jal desenhar_celula

fim_atualizar:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# pinta todas as 1024 celulas com a cor de fundo
limpar_tela:
    li $t0, 0x10010000
    li $t1, 1024
    lw $t2, COR_FUNDO

loop_limpar:
    beq $t1, $zero, fim_limpar
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    j loop_limpar

fim_limpar:
    jr $ra

# pinta uma celula com a cor 
desenhar_celula:
    sll $t0, $a1, 5
    add $t0, $t0, $a0
    sll $t0, $t0, 2

    li $t1, 0x10010000
    add $t1, $t1, $t0
    sw $a2, 0($t1)
    jr $ra