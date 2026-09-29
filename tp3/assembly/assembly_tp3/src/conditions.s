.global classify_value
.text

// Contrato: x0 = valor lido (int32, em x0 como 64-bit)
// Retorno:  x0 = categoria: 0=BAIXO(<10) 1=NORMAL(10-49) 2=ALTO(50-89) 3=CRITICO(>=90)
classify_value:
    cmp     x0, #10
    b.lt    cat_baixo

    cmp     x0, #50
    b.lt    cat_normal

    cmp     x0, #90
    b.lt    cat_alto

    // else (>= 90)
    mov     x0, #3
    ret

cat_baixo:
    mov     x0, #0
    ret

cat_normal:
    mov     x0, #1
    ret

cat_alto:
    mov     x0, #2
    ret