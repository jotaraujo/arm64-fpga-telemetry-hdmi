.global mac_sw_init
.global mac_sw_step
.global mac_sw_result

.bss
.align 3
mac_sw_acc: .quad 0

.text

mac_sw_init:
    adr     x0, mac_sw_acc
    str     xzr, [x0]
    ret

mac_sw_step:
    sxth    x0, w0
    sxth    x1, w1
    mul     x2, x0, x1
    adr     x3, mac_sw_acc
    ldr     x4, [x3]
    add     x4, x4, x2
    str     x4, [x3]
    ret

mac_sw_result:
    adr     x0, mac_sw_acc
    ldr     x0, [x0]
    ret
