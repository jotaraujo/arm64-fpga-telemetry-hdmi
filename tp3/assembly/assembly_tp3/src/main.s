.global _start
.data
msg_result: .ascii "Resultado: "
msg_result_len = . - msg_result
newline:    .ascii "\n"

test_vector: .word 10, 20, 30, 40, 50   // soma esperada = 150
test_cmd:    .asciz "STATUS"             // deve retornar indice 2

.bss
.align 3
out_buf:    .skip 16

.text
_start:
    // ---- Teste 1: sum_array ----
    adr     x0, test_vector
    mov     x1, #5
    bl      sum_array
    // x0 agora tem 150

    // ---- Teste 2: classify_value (usa o resultado do teste 1: 150 -> CRITICO=3) ----
    bl      classify_value
    // x0 agora tem 3 (categoria)

    // ---- Teste 3: jump_table_dispatch (dispara acao ERROR, indice 3) ----
    bl      jump_table_dispatch
    // x0 agora tem 103

    // ---- Teste 4: parse_command ----
    adr     x0, test_cmd
    bl      parse_command
    // x0 agora tem 2 (STATUS)

    // ---- Teste 5: GPIO simulado (via QEMU, sem hardware fisico) ----
    mov     x0, #4              // pino 4 (arbitrario, dentro da faixa 0-9)
    bl      gpio_set_output     // configura pino 4 como saida
    // x0 == 0 esperado (sucesso)

    mov     x0, #4
    bl      gpio_write_high     // simula GPSET no pino 4

    mov     x0, #4
    bl      gpio_write_low      // simula GPCLR no pino 4

    mov     x9, x0              // guarda resultado final para inspecao no GDB

    // ---- Saida: imprime resultado como caractere numerico (0-9) ----
    bl      print_result

    // ---- Encerra o programa (syscall exit) ----
    mov     x0, #0
    mov     x8, #93             // syscall exit
    svc     #0

// Converte x9 (0-9) para ASCII e imprime via write()
print_result:
    adr     x1, msg_result
    mov     x2, msg_result_len
    mov     x0, #1              // fd = stdout
    mov     x8, #64             // syscall write
    svc     #0

    add     w3, w9, #'0'
    strb    w3, [sp, #-16]!
    mov     x1, sp
    mov     x2, #1
    mov     x0, #1
    mov     x8, #64
    svc     #0
    add     sp, sp, #16

    adr     x1, newline
    mov     x2, #1
    mov     x0, #1
    mov     x8, #64
    svc     #0
    ret