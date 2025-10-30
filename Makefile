# Linux Driver Development SDK

# Load configuration modules
include config.mk
include arch.mk
include toolchain.mk

# Common build commands
KERNEL_MAKE := $(MAKE) -C $(KERNEL_DIR) ARCH=$(KERNEL_ARCH) CROSS_COMPILE=$(CROSS_COMPILE)
TOYBOX_MAKE := $(MAKE) -C $(TOYBOX_DIR) CROSS_COMPILE=$(CROSS_COMPILE) \
	CFLAGS="-I$(PWD)/$(SYSROOT)/include" LDFLAGS="--static -L$(PWD)/$(SYSROOT)/lib"

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

.PHONY: all kernel rootfs initrd qemu template clean help
.DEFAULT_GOAL := help

help:
	@echo "Linux Driver Development SDK (ARCH=$(ARCH))"
	@echo ""
	@echo "Targets:"
	@echo "  all              - Build and launch QEMU"
	@echo "  kernel           - Build Linux kernel"
	@echo "  rootfs           - Build toybox rootfs"
	@echo "  initrd           - Build initrd with drivers"
	@echo "  qemu             - Launch QEMU"
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

kernel: $(KERNEL_DIR)/.config
	@echo "Building kernel for $(ARCH)..."
	@$(KERNEL_MAKE) -j$(NPROC)

kernel-menuconfig: $(KERNEL_DIR)/.config
	@$(KERNEL_MAKE) menuconfig

# ===== Toybox =====
$(TOYBOX_DIR)/.git:
	@echo "Cloning toybox..."
	@git clone --depth=1 $(TOYBOX_REPO) $(TOYBOX_DIR)

$(TOYBOX_DIR)/.config: $(TOYBOX_DIR)/.git $(TOOLCHAIN_PATH)
	@echo "Generating toybox config..."
	@$(TOYBOX_MAKE) allyesconfig
	@sed -i 's/^CONFIG_STRACE=y/# CONFIG_STRACE is not set/; s/^CONFIG_SYSLOGD=y/# CONFIG_SYSLOGD is not set/' $@

rootfs: $(TOYBOX_DIR)/.config
	@echo "Building toybox for $(ARCH)..."
	@$(TOYBOX_MAKE) -j$(NPROC)
	@mkdir -p $(TOYBOX_DIR)/root
	@$(TOYBOX_MAKE) PREFIX=$(PWD)/$(TOYBOX_DIR)/root install

rootfs-menuconfig: $(TOYBOX_DIR)/.config
	@$(TOYBOX_MAKE) menuconfig

# ===== Initrd =====
initrd: kernel rootfs templates/init.sh
	@echo "Building initrd..."
	@rm -rf $(ROOTFS_DIR) && mkdir -p $(ROOTFS_DIR)
	@cp -a $(TOYBOX_DIR)/root/* $(ROOTFS_DIR)/
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
	@rm -rf $(TOYBOX_DIR)
	@rm -rf $(BUILD_DIR)

clean-all: clean toolchain-clean
	@echo "Cleaned everything"
