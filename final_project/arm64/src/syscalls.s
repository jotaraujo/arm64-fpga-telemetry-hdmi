.section .text
.global write_all
.type write_all, %function
// x0 = endereco, x1 = quantidade. Retorna w0 = 0 em sucesso, 1 em erro.
write_all:
    mov x3, x0
    mov x4, x1
.Lwrite_loop:
    cbz x4, .Lwrite_ok
    mov x0, #1
    mov x1, x3
    mov x2, x4
    mov x8, #64
    svc #0
    cmp x0, #0
    b.le .Lwrite_fail
    add x3, x3, x0
    sub x4, x4, x0
    b .Lwrite_loop
.Lwrite_ok:
    mov w0, wzr
    ret
.Lwrite_fail:
    mov w0, #1
    ret
.size write_all, .-write_all

.global sys_exit
.type sys_exit, %function
sys_exit:
    mov x8, #93
    svc #0
    b .
.size sys_exit, .-sys_exit