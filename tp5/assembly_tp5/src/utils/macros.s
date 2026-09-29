.macro PRINT_STR label, text
    .section .data
\label\()_data: .ascii "\text\()\n"
\label\()_len  = . - \label\()_data
    .section .text
    mov     x0, #1
    adr     x1, \label\()_data
    mov     x2, \label\()_len
    bl      sys_write
.endm

.macro CHECK_EQ reg, expected, label
    cmp     \reg, #\expected
    b.eq    check_ok_\label
    b       check_done_\label
check_ok_\label:
check_done_\label:
.endm
