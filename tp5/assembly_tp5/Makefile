AS      = aarch64-linux-gnu-as
AR      = aarch64-linux-gnu-ar
LD      = aarch64-linux-gnu-ld
OBJDUMP = aarch64-linux-gnu-objdump
QEMU    = qemu-aarch64

BUILD   = build
LIB_OUT = $(BUILD)/libtp5.a

LIB_SRCS = \
    src/arith/multiword.s \
    src/arith/fpconv.s    \
    src/arith/mac_sw.s    \
    src/io/syscalls.s     \
    src/io/gpio_map.s     \
    src/parsing/parser.s  \
    src/parsing/numconv.s \
    src/utils/bitops.s    \
    src/utils/lookup.s    \
    src/utils/buffers.s   \
    src/utils/macros.s    \
    src/link/link.s       \
    src/link/link_v2.s    \
    src/neon/neon_int.s   \
    src/neon/neon_float.s

LIB_OBJS = $(patsubst src/%.s, $(BUILD)/%.o, $(LIB_SRCS))
MAIN_OBJ = $(BUILD)/main.o
TARGET   = $(BUILD)/main

.PHONY: all clean run debug disasm lib

all: $(TARGET)

$(BUILD)/%.o: src/%.s
	@mkdir -p $(dir $@)
	$(AS) -g -o $@ $<

lib: $(LIB_OBJS)
	$(AR) rcs $(LIB_OUT) $(LIB_OBJS)
	@echo "Biblioteca estatica criada: $(LIB_OUT)"

$(TARGET): lib $(MAIN_OBJ)
	$(LD) -o $@ $(MAIN_OBJ) $(LIB_OUT)

$(BUILD)/main.o: src/main.s
	@mkdir -p $(BUILD)
	$(AS) -g -o $@ $<

clean:
	rm -rf $(BUILD)

run: all
	$(QEMU) $(TARGET)
	@echo "Exit code: $$?"

debug: all
	@echo "Rode em outro terminal: gdb-multiarch $(TARGET) -> target remote localhost:1234"
	$(QEMU) -g 1234 $(TARGET)

disasm: all
	$(OBJDUMP) -d $(TARGET) > $(BUILD)/main_disasm.txt
	@echo "Disassembly salvo em $(BUILD)/main_disasm.txt"

lib_info: lib
	$(OBJDUMP) -t $(LIB_OUT)
	@echo "Simbolos exportados pela biblioteca"
