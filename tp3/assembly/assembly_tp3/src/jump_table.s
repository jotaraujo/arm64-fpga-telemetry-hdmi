.global jump_table_dispatch
.text

// Contrato: x0 = indice (0..3). Fora da faixa -> retorna -1 em x0.
// Retorno:  x0 = codigo de execucao da rotina chamada
jump_table_dispatch:
    stp     x29, x30, [sp, #-16]!   // salva LR (vamos chamar sub-rotinas)
    mov     x29, sp

    cmp     x0, #3
    b.hi    jt_invalid              // indice > 3 (unsigned) -> invalido

    adr     x1, jump_table          // x1 = endereco base da tabela
    ldr     x2, [x1, x0, lsl #3]    // x2 = tabela[indice] (cada entrada = 8 bytes)
    br      x2                     // salta para a rotina (nao retorna aqui)

jt_invalid:
    mov     x0, #-1
    ldp     x29, x30, [sp], #16
    ret

// ---- Tabela de enderecos (uma entrada de 64 bits por comando) ----
.align 3
jump_table:
    .dword  action_led_off
    .dword  action_led_on
    .dword  action_status
    .dword  action_error

action_led_off:
    mov     x0, #100
    b       jt_return

action_led_on:
    mov     x0, #101
    b       jt_return

action_status:
    mov     x0, #102
    b       jt_return

action_error:
    mov     x0, #103
    b       jt_return

jt_return:
    ldp     x29, x30, [sp], #16
    ret