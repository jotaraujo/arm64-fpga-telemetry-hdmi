.global itoa
.global atoi_fn

.bss
.align 3
itoa_buf: .skip 24

.text

itoa:
    stp     x19, x30, [sp, #-32]!
    stp     x20, x21, [sp, #16]

    mov     x19, x0
    mov     x20, x1
    mov     x21, #0

    cmp     x19, #0
    b.ge    itoa_pos
    mov     w2, #'-'
    strb    w2, [x20], #1
    add     x21, x21, #1
    neg     x19, x19

itoa_pos:
    adr     x2, itoa_buf
    mov     x3, x2
    mov     x4, #0

itoa_loop:
    mov     x5, #10
    udiv    x6, x19, x5
    msub    x7, x6, x5, x19
    add     w7, w7, #'0'
    strb    w7, [x3], #1
    add     x4, x4, #1
    mov     x19, x6
    cbnz    x19, itoa_loop

    sub     x3, x3, #1
itoa_rev:
    ldrb    w5, [x2]
    ldrb    w6, [x3]
    strb    w6, [x2], #1
    strb    w5, [x3], #-1
    cmp     x2, x3
    b.lt    itoa_rev

    adr     x2, itoa_buf
itoa_copy:
    ldrb    w5, [x2], #1
    strb    w5, [x20], #1
    add     x21, x21, #1
    subs    x4, x4, #1
    b.ne    itoa_copy

    mov     w5, #0
    strb    w5, [x20]

    mov     x0, x21
    ldp     x20, x21, [sp, #16]
    ldp     x19, x30, [sp], #32
    ret

atoi_fn:
    mov     x1, #1
    mov     x2, #0

    ldrb    w3, [x0]
    cmp     w3, #'-'
    b.ne    atoi_loop
    mov     x1, #-1
    add     x0, x0, #1

atoi_loop:
    ldrb    w3, [x0], #1
    cbz     w3, atoi_done
    sub     w3, w3, #'0'
    cmp     w3, #9
    b.hi    atoi_done
    mov     x4, #10
    mul     x2, x2, x4
    add     x2, x2, x3
    b       atoi_loop

atoi_done:
    mul     x0, x2, x1
    ret
