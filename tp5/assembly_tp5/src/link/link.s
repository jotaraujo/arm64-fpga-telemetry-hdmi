.global send_packet
.global receive_and_validate
.global log_telemetry
.global compute_checksum
.global link_buffer

.bss
.align 3
link_buffer: .skip 8
log_buffer:  .skip 32
log_index:   .word 0

.text

compute_checksum:
    mov     w1, w0
    and     w2, w1, #0xFF
    lsr     w1, w1, #8
    and     w3, w1, #0xFF
    add     w2, w2, w3
    lsr     w1, w1, #8
    and     w3, w1, #0xFF
    add     w2, w2, w3
    lsr     w1, w1, #8
    and     w3, w1, #0xFF
    add     w2, w2, w3
    and     w0, w2, #0xFF
    ret

send_packet:
    stp     x19, x30, [sp, #-16]!
    mov     w19, w0
    adr     x1, link_buffer
    str     w19, [x1]

    mov     w0, w19
    bl      compute_checksum

    adr     x1, link_buffer
    strb    w0, [x1, #4]

    ldp     x19, x30, [sp], #16
    ret

receive_and_validate:
    stp     x30, xzr, [sp, #-16]!

    adr     x1, link_buffer
    ldr     w2, [x1]
    ldrb    w9, [x1, #4]

    mov     w0, w2
    bl      compute_checksum

    cmp     w0, w9
    b.eq    rav_ok
    mov     x0, #1
    ldp     x30, xzr, [sp], #16
    ret
rav_ok:
    mov     x0, #0
    ldp     x30, xzr, [sp], #16
    ret

log_telemetry:
    adr     x2, log_index
    ldr     w3, [x2]

    adr     x4, log_buffer
    mov     w5, #8
    mul     w6, w3, w5
    add     x4, x4, x6

    strb    w0, [x4]
    str     w1, [x4, #4]

    add     w3, w3, #1
    and     w3, w3, #3
    str     w3, [x2]
    ret
