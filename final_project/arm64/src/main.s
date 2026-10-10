.section .rodata
.align 3
command_table:
    // PING
    .byte 0x7F, 4
    .hword 0
    .word 0x44332211

    // SET_MODE
    .byte 0x01, 1
    .hword 0
    .word 0x00000001

    // SET_COLOR
    .byte 0x02, 3
    .hword 0
    .word 0x00E08020

    // SET_GAIN
    .byte 0x03, 2
    .hword 0
    .word 0x00000180

    // MAC_STEP
    .byte 0x04, 4
    .hword 0
    .word 0x00800100
    
    // MAC_STEP
    .byte 0x04, 4
    .hword 0
    .word 0x0040FF00
    
    // SET_MODE
    .byte 0x01, 1
    .hword 0
    .word 0x00000003

    // GET_STATUS
    .byte 0x06, 0
    .hword 0
    .word 0x00000000
command_table_end:

.section .bss
.align 4
packet_buffer:
    .skip 16 // Reserva 16 bytes na memória

.section .text
.global _start
.type _start, %function
_start:
    // Verifica onde começa e termina a tabela de comandos
    adrp x20, command_table
    add x20, x20, :lo12:command_table
    adrp x21, command_table_end
    add x21, x21, :lo12:command_table_end
    mov w19, wzr

.Lnext_command:
    // Verifica se há mais comandos na tabela
    cmp x20, x21
    b.hs .Lsuccess

    ldrb w2, [x20] // Busca informação da memória nesse ponteiro e coloca no registrador w2
    ldrb w3, [x20, #1] 
    ldr w4, [x20, #4]
    
    adrp x0, packet_buffer
    add x0, x0, :lo12:packet_buffer
    mov w1, w19
    bl build_packet

    adrp x0, packet_buffer


    add x0, x0, :lo12:packet_buffer
    mov x1, #10
    bl write_all
    cbnz w0, .Lwrite_error

    add x20, x20, #8
    add w19, w19, #1
    b .Lnext_command

.Lsuccess:
    mov x0, #0
    bl sys_exit

.Lwrite_error:
    mov x0, #1
    bl sys_exit

.size _start, .-_start