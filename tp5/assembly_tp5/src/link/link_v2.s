.global link_send_v2
.global link_receive_v2
.global link_benchmark
.global pkt_buffer

.bss
.align 3
pkt_buffer:  .skip 12
seq_counter: .hword 0

.text

chk_bytes:
    mov     w0, #0
chk_loop:
    cbz     x2, chk_done
    ldrb    w3, [x1], #1
    add     w0, w0, w3
    sub     x2, x2, #1
    b       chk_loop
chk_done:
    and     w0, w0, #0xFF
    ret

link_send_v2:
    stp     x19, x30, [sp, #-16]!
    mov     w19, w1

    adr     x2, seq_counter
    ldrh    w3, [x2]
    adr     x4, pkt_buffer
    strh    w3, [x4]
    add     w3, w3, #1
    strh    w3, [x2]

    strh    w0, [x4, #2]
    str     w19, [x4, #4]

    mov     x1, x4
    mov     x2, #8
    bl      chk_bytes
    strb    w0, [x4, #8]

    ldp     x19, x30, [sp], #16
    ret

link_receive_v2:
    stp     x19, x30, [sp, #-16]!

    adr     x1, pkt_buffer
    ldrb    w19, [x1, #8]

    mov     x2, #8
    bl      chk_bytes
    cmp     w0, w19
    b.ne    lrv2_chk_err

    mov     x0, #0
    ldp     x19, x30, [sp], #16
    ret

lrv2_chk_err:
    mov     x0, #1
    ldp     x19, x30, [sp], #16
    ret

link_benchmark:
    stp     x19, x20, [sp, #-32]!
    stp     x21, x30, [sp, #16]

    mov     x19, x0
    mov     x20, #0
    mov     x21, #0

bench_loop:
    cbz     x19, bench_done
    sub     x19, x19, #1

    mov     x0, #1
    mov     x1, #12345
    bl      link_send_v2

    bl      link_receive_v2
    cbnz    x0, bench_fail
    add     x20, x20, #1
    b       bench_next
bench_fail:
    add     x21, x21, #1
bench_next:
    b       bench_loop

bench_done:
    mov     x0, x20
    mov     x1, x21
    ldp     x21, x30, [sp, #16]
    ldp     x19, x20, [sp], #32
    ret
