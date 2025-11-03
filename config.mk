# Project Configuration
# Centralized version numbers, URLs, and directory settings

# Source repositories
KERNEL_REPO := https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
BUSYBOX_REPO := https://git.busybox.net/busybox

# Library versions
ZLIB_VERSION := 1.3.1
OPENSSL_VERSION := 3.6.0

# Library URLs
ZLIB_URL := https://zlib.net/zlib-$(ZLIB_VERSION).tar.gz
OPENSSL_URL := https://www.openssl.org/source/openssl-$(OPENSSL_VERSION).tar.gz

# Directory structure
KERNEL_DIR := kernel
BUSYBOX_DIR := busybox
DRIVERS_DIR := drivers
BUILD_DIR := build
TOOLCHAIN_DIR := toolchain

# Derived directories
ROOTFS_DIR := $(BUILD_DIR)/rootfs
INITRD := $(BUILD_DIR)/initrd.img
SYSROOT := $(TOOLCHAIN_DIR)/sysroot

# Build configuration
NPROC := $(shell nproc)
