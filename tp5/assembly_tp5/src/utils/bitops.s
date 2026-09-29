.global extract_field
.global rotate_left
.text

extract_field:
    lsr     x0, x0, x1
    mov     x3, #1
    lsl     x3, x3, x2
    sub     x3, x3, #1
    and     x0, x0, x3
    ret

rotate_left:
    and     w1, w1, #31
    mov     w2, #32
    sub     w2, w2, w1
    ror     w0, w0, w2
    ret
