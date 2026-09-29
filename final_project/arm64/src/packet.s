.section .text
.global build_packet
.type build_packet, %function
// x0 = buffer, w1 = sequence, w2 = command, w3 = length, w4 = payload
build_packet:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]

    mov x19, x0
    mov w22, w4

    mov w5, #0xA5
    strb w5, [x19, #0]
    mov w5, #0x01
    strb w5, [x19, #1]
    strb w1, [x19, #2]
    strb w2, [x19, #3]
    strb w3, [x19, #4]
    str w22, [x19, #5]

    mov w20, wzr
    mov x21, #1

.Lcrc_loop:
    ldrb w1, [x19, x21]
    mov w0, w20
    bl crc8_update
    mov w20, w0
    add x21, x21, #1
    cmp x21, #9
    b.lo .Lcrc_loop

    strb w20, [x19, #9]
    mov x0, x19

    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret
.size build_packet, .-build_packet

.global crc8_update
.type crc8_update, %function
crc8_update:
    eor w0, w0, w1
    and w0, w0, #0xFF
    mov w2, #8

.Lcrc_bit:
    tst w0, #0x80
    lsl w0, w0, #1
    and w0, w0, #0xFF
    b.eq .Lcrc_no_xor
    eor w0, w0, #0x07

.Lcrc_no_xor:
    subs w2, w2, #1
    b.ne .Lcrc_bit
    ret
.size crc8_update, .-crc8_update
