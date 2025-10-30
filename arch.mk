# Architecture Configuration
# Unified architecture-specific settings using define blocks

# Default architecture
ARCH ?= riscv64

# x86_64 architecture
define ARCH_x86_64
KERNEL_ARCH := x86_64
KERNEL_IMAGE_PATH := arch/x86/boot/bzImage
QEMU := qemu-system-x86_64
QEMU_OPTS := -machine pc -cpu host -enable-kvm
TOOLCHAIN_TRIPLET := x86_64-linux-musl
OPENSSL_TARGET := linux-x86_64
endef

# aarch64 architecture
define ARCH_aarch64
KERNEL_ARCH := arm64
KERNEL_IMAGE_PATH := arch/arm64/boot/Image
QEMU := qemu-system-aarch64
QEMU_OPTS := -machine virt -cpu cortex-a57
TOOLCHAIN_TRIPLET := aarch64-linux-musl
OPENSSL_TARGET := linux-aarch64
endef

# riscv64 architecture
define ARCH_riscv64
KERNEL_ARCH := riscv
KERNEL_IMAGE_PATH := arch/riscv/boot/Image
QEMU := qemu-system-riscv64
QEMU_OPTS := -machine virt -cpu rv64
TOOLCHAIN_TRIPLET := riscv64-linux-musl
OPENSSL_TARGET := linux64-riscv64
endef

# Apply architecture configuration
$(eval $(ARCH_$(ARCH)))
