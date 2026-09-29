.PHONY: all arm64 sim clean
.RECIPEPREFIX := >

all: arm64 sim

arm64:
>$(MAKE) -C arm64 check

sim: arm64
>$(MAKE) -C fpga/sim all

clean:
>$(MAKE) -C arm64 clean
>$(MAKE) -C fpga/sim clean
>rm -f fpga/sim/commands.hex