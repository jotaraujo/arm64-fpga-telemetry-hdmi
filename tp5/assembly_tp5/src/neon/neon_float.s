.global vector_mul_float
.data
.align 4
vec_a_float: .float 1.5, 2.5, 3.5, 4.5
vec_b_float: .float 2.0, 2.0, 2.0, 2.0
vec_result_float: .float 0.0, 0.0, 0.0, 0.0

.text

vector_mul_float:
    adr     x0, vec_a_float
    adr     x1, vec_b_float
    adr     x2, vec_result_float

    ld1     {v0.4s}, [x0]
    ld1     {v1.4s}, [x1]

    fmul    v2.4s, v0.4s, v1.4s

    st1     {v2.4s}, [x2]

    mov     x0, #0
    ret
