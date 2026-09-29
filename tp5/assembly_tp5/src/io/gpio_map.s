.global gpio_set_output
.global gpio_write_high
.global gpio_write_low
.global gpio_read
.global gpio_buffer

// ===================================================================
// SIMULACAO DE MAPA GPIO — BCM2837/BCM2710A1 (Raspberry Pi Zero 2W)
// ATENCAO: os offsets abaixo sao os OFICIAIS do SoC (a confirmar
// contra a documentacao BCM2837-ARM-Peripherals.pdf antes do relatorio
// final). O endereco BASE real seria 0x3F200000, mas como nao ha
// hardware fisico disponivel, usamos "gpio_buffer" (regiao alocada em
// memoria de usuario) para simular o espaco de enderecos do periferico.
// Toda validacao aqui e' LOGICA/SIMULADA via QEMU, nunca fisica.
// ===================================================================

.equ OFF_GPFSEL0, 0x00   // Function Select 0 (pinos 0-9)
.equ OFF_GPSET0,  0x1C   // Pin Output Set 0 (pinos 0-31)
.equ OFF_GPCLR0,  0x28   // Pin Output Clear 0 (pinos 0-31)
.equ OFF_GPLEV0,  0x34   // Pin Level 0 (leitura, pinos 0-31)

.bss
.align 3
gpio_buffer: .skip 64     // buffer simulando o mapa de registradores GPIO

.text

// -------------------------------------------------------------------
// gpio_set_output: configura um pino como saida (FSEL = 001)
// Contrato: x0 = numero do pino (0-9, cabe em GPFSEL0 nesta simulacao)
// Retorno:  x0 = 0 (sucesso) ou -1 (pino fora da faixa suportada)
// -------------------------------------------------------------------
gpio_set_output:
    cmp     x0, #9
    b.hi    gso_error

    adr     x1, gpio_buffer
    ldr     w2, [x1, #OFF_GPFSEL0]  // le o registrador atual

    mov     x3, x0
    add     x3, x3, x3, lsl #1      // x3 = pino * 3 (cada pino usa 3 bits)

    mov     w4, #0b001              // codigo de "saida" no GPFSEL
    lsl     w4, w4, w3              // desloca para a posicao do pino

    mov     w5, #0b111
    lsl     w5, w5, w3              // mascara dos 3 bits do pino
    bic     w2, w2, w5              // limpa os 3 bits atuais
    orr     w2, w2, w4              // seta como saida

    str     w2, [x1, #OFF_GPFSEL0]
    mov     x0, #0
    ret

gso_error:
    mov     x0, #-1
    ret

// -------------------------------------------------------------------
// gpio_write_high: seta o pino em nivel alto (equivalente a GPSET)
// Contrato: x0 = numero do pino (0-31)
// Retorno:  nenhum (void)
// -------------------------------------------------------------------
gpio_write_high:
    adr     x1, gpio_buffer
    mov     w2, #1
    lsl     w2, w2, w0              // bit correspondente ao pino
    str     w2, [x1, #OFF_GPSET0]   // simula escrita write-to-set
    ret

// -------------------------------------------------------------------
// gpio_write_low: seta o pino em nivel baixo (equivalente a GPCLR)
// Contrato: x0 = numero do pino (0-31)
// Retorno:  nenhum (void)
// -------------------------------------------------------------------
gpio_write_low:
    adr     x1, gpio_buffer
    mov     w2, #1
    lsl     w2, w2, w0
    str     w2, [x1, #OFF_GPCLR0]   // simula escrita write-to-clear
    ret

// -------------------------------------------------------------------
// gpio_read: le o nivel atual de um pino (equivalente a GPLEV)
// Contrato: x0 = numero do pino (0-31)
// Retorno:  x0 = 0 ou 1 (nivel do pino simulado)
// -------------------------------------------------------------------
gpio_read:
    adr     x1, gpio_buffer
    ldr     w2, [x1, #OFF_GPLEV0]
    lsr     w2, w2, w0
    and     x0, x2, #1
    ret