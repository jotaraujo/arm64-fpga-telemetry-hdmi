.global int_to_float
.global float_to_int
.text

int_to_float:
    scvtf   s0, x0
    ret

float_to_int:
    fcvtzs  x0, s0
    ret
