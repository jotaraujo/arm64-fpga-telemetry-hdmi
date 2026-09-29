.global _start
.data
msg_ok:   .ascii "TP5 Assembly OK\n"
msg_ok_len = . - msg_ok

num_buf:  .skip 32

.bss
.align 3
read_buf: .skip 64

.text
_start:
    mov     x0, #42
    adr     x1, num_buf
    bl      itoa
    mov     x19, x0

    adr     x0, num_buf
    bl      atoi_fn
    mov     x20, x0


    adr     x0, msg_ok
    bl      str_len
    mov     x21, x0

    adr     x0, read_buf
    mov     x1, #0xAB
    mov     x2, #8
    bl      mem_set

    bl      mac_sw_init
    mov     x0, #10
    mov     x1, #20
    bl      mac_sw_step
    mov     x0, #30
    mov     x1, #40
    bl      mac_sw_step
    bl      mac_sw_result
    mov     x22, x0

    bl      vector_add_int
    bl      vector_mul_float

    movz    x0, #0x869F
    movk    x0, #0x1, lsl #16
    bl      send_packet
    bl      receive_and_validate
    mov     x23, x0

    mov     x0, #1
    movz    x1, #0xFEF
    movk    x1, #0x1, lsl #16
    bl      link_send_v2
    bl      link_receive_v2
    mov     x24, x0

    mov     x0, #1000
    bl      link_benchmark
    mov     x25, x0
    mov     x26, x1

    mov     x0, #1
    adr     x1, msg_ok
    mov     x2, #12
    bl      sys_write

    mov     x0, #0
    bl      sys_exit
