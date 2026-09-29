.global lookup_square
.data
.align 3
square_table:
    .word 0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 144, 169, 196, 225

.text

lookup_square:
    cmp     x0, #15
    b.hi    ls_invalid

    adr     x1, square_table
    ldr     w0, [x1, x0, lsl #2]
    ret

ls_invalid:
    mov     x0, #-1
    ret
