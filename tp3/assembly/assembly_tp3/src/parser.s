.global parse_command
.data
str_led_on:  .asciz "LED_ON"
str_led_off: .asciz "LED_OFF"
str_status:  .asciz "STATUS"

.text

// Contrato: x0 = ponteiro para string de comando (terminada em \0)
// Retorno:  x0 = indice do comando (0=LED_OFF 1=LED_ON 2=STATUS), ou -1 se invalido
parse_command:
    stp     x19, x30, [sp, #-16]!
    mov     x19, x0             // preserva o ponteiro de entrada

    adr     x1, str_led_off
    bl      str_compare
    cbz     x0, pc_is_led_off   // x0==0 -> strings iguais

    mov     x0, x19
    adr     x1, str_led_on
    bl      str_compare
    cbz     x0, pc_is_led_on

    mov     x0, x19
    adr     x1, str_status
    bl      str_compare
    cbz     x0, pc_is_status

    mov     x0, #-1             // nenhum comando reconhecido
    b       pc_end

pc_is_led_off:
    mov     x0, #0
    b       pc_end
pc_is_led_on:
    mov     x0, #1
    b       pc_end
pc_is_status:
    mov     x0, #2

pc_end:
    ldp     x19, x30, [sp], #16
    ret

// ---- Sub-rotina auxiliar: compara duas strings ASCII ----
// Contrato: x0 = ptr string A, x1 = ptr string B
// Retorno:  x0 = 0 se iguais, != 0 se diferentes
str_compare:
    mov     x19, x0
    mov     x0, x19
    // usa x0/x1 diretamente, nao precisa preservar mais nada aqui

str_compare_loop:
    ldrb    w2, [x0], #1
    ldrb    w3, [x1], #1
    cmp     w2, w3
    b.ne    str_compare_diff

    cbz     w2, str_compare_equal   // chegou no \0 de ambas -> iguais
    b       str_compare_loop

str_compare_diff:
    mov     x0, #1
    ret

str_compare_equal:
    mov     x0, #0
    ret