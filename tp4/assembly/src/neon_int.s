.global vector_add_int
.data
.align 4
vec_a_int: .word 10, 20, 30, 40
vec_b_int: .word 1, 2, 3, 4
vec_result_int: .word 0, 0, 0, 0

.text

vector_add_int:
    adr     x0, vec_a_int
    adr     x1, vec_b_int
    adr     x2, vec_result_int

    ld1     {v0.4s}, [x0]
    ld1     {v1.4s}, [x1]

    add     v2.4s, v0.4s, v1.4s

    st1     {v2.4s}, [x2]

    mov     x0, #0
    ret
