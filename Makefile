# Linux Driver Development SDK

# Load configuration modules
include config.mk
include arch.mk
include toolchain.mk

# Common build commands
KERNEL_MAKE := $(MAKE) -C $(KERNEL_DIR) ARCH=$(KERNEL_ARCH) CROSS_COMPILE=$(CROSS_COMPILE)
BUSYBOX_MAKE := $(MAKE) -C $(BUSYBOX_DIR) CROSS_COMPILE=$(CROSS_COMPILE)

# Build driver helper
define build_drivers
	@if [ -d "$(DRIVERS_DIR)" ]; then \
		for d in $(DRIVERS_DIR)/*; do \
			[ -f "$$d/Makefile" ] || continue; \
			echo "Building $$(basename $$d)..."; \
			$(KERNEL_MAKE) M=$(PWD)/$$d modules && \
			cp $$d/*.ko $(ROOTFS_DIR)/lib/modules/ 2>/dev/null || true; \
		done; \
	fi
endef

.PHONY: all kernel rootfs initrd qemu gdb template clean help
.DEFAULT_GOAL := help

help:
	@echo "Linux Driver Development SDK (ARCH=$(ARCH))"
	@echo ""
	@echo "Targets:"
	@echo "  all              - Build and launch QEMU"
	@echo "  kernel           - Build Linux kernel"
	@echo "  rootfs           - Build busybox rootfs"
	@echo "  initrd           - Build initrd with drivers"
	@echo "  qemu             - Launch QEMU"
	@echo "  gdb              - Launch QEMU with GDB server"
	@echo "  template         - Create driver template"
	@echo "  clean            - Clean build artifacts"

all: kernel initrd qemu

# ===== Kernel =====
$(KERNEL_DIR)/.git:
	@echo "Cloning Linux kernel..."
	@git clone --depth=1 $(KERNEL_REPO) $(KERNEL_DIR)

$(KERNEL_DIR)/.config: $(KERNEL_DIR)/.git $(TOOLCHAIN_PATH)
	@echo "Generating kernel config..."
	@$(KERNEL_MAKE) defconfig
	@kernel/scripts/config --file $(KERNEL_DIR)/.config -e DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT -e GDB_SCRIPTS
	@$(KERNEL_MAKE) olddefconfig

kernel: $(KERNEL_DIR)/.config
	@echo "Building kernel for $(ARCH)..."
	@$(KERNEL_MAKE) -j$(NPROC)

kernel-menuconfig: $(KERNEL_DIR)/.config
	@$(KERNEL_MAKE) menuconfig

# ===== BusyBox =====
$(BUSYBOX_DIR)/.git:
	@echo "Cloning busybox..."
	@git clone --depth=1 $(BUSYBOX_REPO) $(BUSYBOX_DIR)

$(BUSYBOX_DIR)/.config: $(BUSYBOX_DIR)/.git $(TOOLCHAIN_PATH)
	@echo "Generating busybox config..."
	@$(BUSYBOX_MAKE) defconfig
	@sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' $@
	@$(BUSYBOX_MAKE) oldconfig

rootfs: $(BUSYBOX_DIR)/.config
	@echo "Building busybox for $(ARCH)..."
	@$(BUSYBOX_MAKE) -j$(NPROC)
	@mkdir -p $(BUSYBOX_DIR)/_install
	@$(BUSYBOX_MAKE) CONFIG_PREFIX=$(PWD)/$(BUSYBOX_DIR)/_install install

rootfs-menuconfig: $(BUSYBOX_DIR)/.config
	@$(BUSYBOX_MAKE) menuconfig

# ===== Initrd =====
initrd: kernel rootfs templates/init.sh
	@echo "Building initrd..."
	@rm -rf $(ROOTFS_DIR) && mkdir -p $(ROOTFS_DIR)
	@cp -a $(BUSYBOX_DIR)/_install/* $(ROOTFS_DIR)/
	@mkdir -p $(ROOTFS_DIR)/{dev,proc,sys,lib/modules}
	$(call build_drivers)
	@cp templates/init.sh $(ROOTFS_DIR)/init && chmod +x $(ROOTFS_DIR)/init
	@cd $(ROOTFS_DIR) && find . | cpio -o -H newc | gzip > ../initrd.img
	@echo "Initrd created: $(INITRD)"

# ===== QEMU =====
qemu: $(KERNEL_DIR)/$(KERNEL_IMAGE_PATH) $(INITRD)
	@echo "Launching QEMU for $(ARCH)..."
	@$(QEMU) $(QEMU_OPTS) -m 1G \
		-kernel $(KERNEL_DIR)/$(KERNEL_IMAGE_PATH) \
		-initrd $(INITRD) \
		-append "console=ttyS0 nokaslr" \
		-nographic

gdb: $(KERNEL_DIR)/$(KERNEL_IMAGE_PATH) $(INITRD)
	@echo "Launching QEMU with GDB server for $(ARCH)..."
	@echo "Connect with: gdb $(KERNEL_DIR)/vmlinux -ex 'target remote :1234'"
	@$(QEMU) $(QEMU_OPTS) -m 1G \
		-kernel $(KERNEL_DIR)/$(KERNEL_IMAGE_PATH) \
		-initrd $(INITRD) \
		-append "console=ttyS0 nokaslr" \
		-nographic -s -S

# ===== Template =====
template:
	@read -p "Driver name: " name && \
	mkdir -p $(DRIVERS_DIR)/$$name && \
	sed "s/DRIVER_NAME/$$name/g" templates/driver.c > $(DRIVERS_DIR)/$$name/$$name.c && \
	echo "obj-m += $$name.o" > $(DRIVERS_DIR)/$$name/Makefile && \
	echo "Driver template created in $(DRIVERS_DIR)/$$name"

# ===== Clean =====
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(KERNEL_DIR)
	@rm -rf $(BUSYBOX_DIR)
	@rm -rf $(BUILD_DIR)

clean-all: clean toolchain-clean
	@echo "Cleaned everything"
