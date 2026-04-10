BOOT_DIR  = boot
BUILD_DIR = build

BOOT_BIN   = $(BUILD_DIR)/boot.bin
LOADER_BIN = $(BUILD_DIR)/loader.bin
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
IMG        = $(BUILD_DIR)/os.img

all: qemu

$(IMG): $(BOOT_BIN) $(LOADER_BIN) $(KERNEL_BIN)
	dd if=/dev/zero of=$(IMG) bs=1M count=10
	dd if=$(BOOT_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
	dd if=$(LOADER_BIN) of=$(IMG) bs=512 count=8 seek=2 conv=notrunc
	dd if=$(KERNEL_BIN) of=$(IMG) bs=512 count=120 seek=20 conv=notrunc

$(BUILD_DIR)/%.bin: $(BOOT_DIR)/%.asm
	mkdir -p $(BUILD_DIR)
	nasm -f bin $< -o $@

$(KERNEL_BIN):
	cargo build
	objcopy -O binary ./target/x86_64-rustos/debug/kernel $@

.PHONY: qemu
qemu: $(IMG)
	qemu-system-x86_64 -drive file=$(IMG),format=raw

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
