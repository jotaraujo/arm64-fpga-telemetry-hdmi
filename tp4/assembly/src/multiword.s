.global add128
.text

add128:
    adds    x0, x0, x2
    adc     x1, x1, x3
    ret
