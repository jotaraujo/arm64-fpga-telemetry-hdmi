.global str_len
.global mem_copy
.global mem_set

.text

str_len:
    mov     x1, x0
strlen_loop:
    ldrb    w2, [x1], #1
    cbnz    w2, strlen_loop
    sub     x0, x1, x0
    sub     x0, x0, #1
    ret

mem_copy:
    cbz     x2, memcopy_done
memcopy_loop:
    ldrb    w3, [x1], #1
    strb    w3, [x0], #1
    subs    x2, x2, #1
    b.ne    memcopy_loop
memcopy_done:
    ret

mem_set:
    cbz     x2, memset_done
memset_loop:
    strb    w1, [x0], #1
    subs    x2, x2, #1
    b.ne    memset_loop
memset_done:
    ret
