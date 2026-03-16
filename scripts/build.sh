#!/bin/bash
set -e

mkdir -p build

echo "Building bootloader..."

# 编译 bootloader
nasm -f bin boot/boot.asm -o build/boot.bin
nasm -f bin boot/loader.asm -o build/loader.bin

echo "Building Rust kernel..."

cd kernel
cargo build
cd ..

echo "Converting kernel ELF to binary..."

objcopy -O binary kernel/target/x86_64-unknown-none/debug/kernel build/kernel.bin

echo "Creating disk image..."

dd if=/dev/zero of=build/os.img bs=512 count=2880

echo "Writing bootloader..."

dd if=build/boot.bin of=build/os.img conv=notrunc
dd if=build/loader.bin of=build/os.img bs=512 seek=1 conv=notrunc

echo "Writing kernel..."

dd if=build/kernel.bin of=build/os.img bs=512 seek=5 conv=notrunc

echo "Build complete!"
