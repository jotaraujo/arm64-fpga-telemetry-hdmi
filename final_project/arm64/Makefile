CROSS ?= aarch64-linux-gnu
AS := $(CROSS)-as
LD := $(CROSS)-ld
QEMU ?= qemu-aarch64
.RECIPEPREFIX := >

BUILD := build
OBJS := $(BUILD)/main.o $(BUILD)/packet.o $(BUILD)/syscalls.o

.PHONY: all run hex check clean

all: $(BUILD)/packet_gen

$(BUILD):
>mkdir -p $(BUILD)

$(BUILD)/%.o: src/%.s | $(BUILD)
>$(AS) -g -o $@ $<

$(BUILD)/packet_gen: $(OBJS)
>$(LD) -static -e _start -o $@ $(OBJS)

run: $(BUILD)/packet_gen
>$(QEMU) $(BUILD)/packet_gen > $(BUILD)/commands.bin

hex: run
>python3 ../bridge/bin_to_hex.py $(BUILD)/commands.bin ../fpga/sim/commands.hex

check: hex
>python3 ../bridge/check_packets.py $(BUILD)/commands.bin

clean:
>rm -rf $(BUILD)