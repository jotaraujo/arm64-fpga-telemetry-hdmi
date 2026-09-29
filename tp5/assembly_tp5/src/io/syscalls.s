.global sys_write
.global sys_read
.global sys_exit

.text

sys_write:
    mov     x8, #64
    svc     #0
    ret

sys_read:
    mov     x8, #63
    svc     #0
    ret

sys_exit:
    mov     x8, #93
    svc     #0
