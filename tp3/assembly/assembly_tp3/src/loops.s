.global sum_array
.text

// Contrato: x0 = ptr do vetor (int32), x1 = quantidade de elementos
// Retorno:  x0 = soma (int64, evita overflow)
sum_array:
    // Prologo: salva registradores callee-saved que vamos usar
    stp     x19, x20, [sp, #-16]!

    mov     x19, x0          // x19 = ponteiro atual (preserva x0 original)
    mov     x20, xzr         // x20 = acumulador da soma
    mov     x2,  xzr         // x2  = contador i = 0

loop_for:
    cmp     x2, x1            // i < n ?
    b.ge    loop_for_end       // se i >= n, sai do loop

    ldr     w3, [x19, x2, lsl #2]   // w3 = vetor[i]  (offset = i*4)
    add     x20, x20, x3, sxtw     // soma com sign-extend

    add     x2, x2, #1         // i++
    b       loop_for

loop_for_end:
    mov     x0, x20            // retorna a soma

    ldp     x19, x20, [sp], #16   // epilogo: restaura registradores
    ret
// Teste
