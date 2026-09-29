AS      = aarch64-linux-gnu-as
LD      = aarch64-linux-gnu-ld
OBJDUMP = aarch64-linux-gnu-objdump
QEMU    = qemu-aarch64

SRC_DIR   = src
BUILD_DIR = build

SOURCES = $(SRC_DIR)/multiword.s $(SRC_DIR)/fpconv.s $(SRC_DIR)/lookup.s $(SRC_DIR)/bitops.s $(SRC_DIR)/neon_int.s $(SRC_DIR)/neon_float.s $(SRC_DIR)/link.s $(SRC_DIR)/main.s
OBJECTS = $(patsubst $(SRC_DIR)/%.s, $(BUILD_DIR)/%.o, $(SOURCES))
TARGET  = $(BUILD_DIR)/main

.PHONY: all clean run debug disasm

all: $(TARGET)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s | $(BUILD_DIR)
	$(AS) -g -o $@ $<

$(TARGET): $(OBJECTS)
	$(LD) -o $@ $^

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

run: all
	$(QEMU) $(TARGET)
	@echo "Exit code: $$?"

debug: all
	@echo "Rode em outro terminal: gdb-multiarch $(TARGET)  ->  target remote localhost:1234"
	$(QEMU) -g 1234 $(TARGET)

disasm: all
	$(OBJDUMP) -d $(TARGET) > $(BUILD_DIR)/main_disasm.txt
	@echo "Disassembly salvo em $(BUILD_DIR)/main_disasm.txt"
