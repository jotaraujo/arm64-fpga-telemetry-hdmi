.global _start
.data
msg: .ascii "TP4 rotinas OK\n"
msg_len = . - msg
.text
_start:
    mov     x0, #-1
    mov     x1, #0
    mov     x2, #1
    mov     x3, #0
    bl      add128
    mov     x20, x0
    mov     x21, x1

    mov     x0, #42
    bl      int_to_float
    bl      float_to_int
    mov     x22, x0

    mov     x0, #7
    bl      lookup_square
    mov     x23, x0

    movz    x0, #0x1234
    movk    x0, #0xABCD, lsl #16
    mov     x1, #8
    mov     x2, #8
    bl      extract_field
    mov     x24, x0

    mov     x0, #0x00000001
    mov     x1, #4
    bl      rotate_left
    mov     x25, x0

    bl      vector_add_int

    bl      vector_mul_float

    mov     x0, #12345
    bl      send_packet
    bl      receive_and_validate
    mov     x26, x0
    mov     x0, x26
    mov     x1, #12345
    bl      log_telemetry

    adr     x1, link_buffer
    ldrb    w2, [x1, #4]
    eor     w2, w2, #0xFF
    strb    w2, [x1, #4]
    bl      receive_and_validate
    mov     x27, x0
    mov     x0, x27
    mov     x1, #12345
    bl      log_telemetry

    adr     x1, msg
    mov     x2, msg_len
    mov     x0, #1
    mov     x8, #64
    svc     #0

    mov     x0, #0
    mov     x8, #93
    svc     #0
