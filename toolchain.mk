# Toolchain Management
# Provides musl-based cross-compilation toolchain with libraries

# Toolchain paths and configuration
TOOLCHAIN_PATH := $(PWD)/$(TOOLCHAIN_DIR)/$(TOOLCHAIN_TRIPLET)-cross
TOOLCHAIN_PREFIX := $(TOOLCHAIN_PATH)/bin/$(TOOLCHAIN_TRIPLET)-
TOOLCHAIN_URL := https://musl.cc/$(TOOLCHAIN_TRIPLET)-cross.tgz
CROSS_COMPILE := $(TOOLCHAIN_PREFIX)

# Download and extract helper
define download_extract
	@wget -q --show-progress -O $(2) $(1)
	@tar -xzf $(2) -C $(3)
	@rm -f $(2)
endef

# Build zlib
define build_zlib
	@echo "Building zlib..."
	$(call download_extract,$(ZLIB_URL),$(TOOLCHAIN_DIR)/zlib.tar.gz,$(TOOLCHAIN_DIR))
	@cd $(TOOLCHAIN_DIR)/zlib-$(ZLIB_VERSION) && \
		CC=$(TOOLCHAIN_PREFIX)gcc AR=$(TOOLCHAIN_PREFIX)ar RANLIB=$(TOOLCHAIN_PREFIX)ranlib \
		CFLAGS="-O2" ./configure --prefix=$(PWD)/$(SYSROOT) --static && \
		$(MAKE) -j$(NPROC) && $(MAKE) install
	@rm -rf $(TOOLCHAIN_DIR)/zlib-$(ZLIB_VERSION)
endef

# Build openssl
define build_openssl
	@echo "Building openssl..."
	$(call download_extract,$(OPENSSL_URL),$(TOOLCHAIN_DIR)/openssl.tar.gz,$(TOOLCHAIN_DIR))
	@cd $(TOOLCHAIN_DIR)/openssl-$(OPENSSL_VERSION) && \
		./Configure $(OPENSSL_TARGET) --prefix=$(PWD)/$(SYSROOT) --openssldir=$(PWD)/$(SYSROOT)/ssl \
		no-shared no-tests --cross-compile-prefix=$(TOOLCHAIN_PREFIX) && \
		$(MAKE) -j$(NPROC) && $(MAKE) install_sw
	@rm -rf $(TOOLCHAIN_DIR)/openssl-$(OPENSSL_VERSION)
endef

# Download and setup toolchain with libraries
$(TOOLCHAIN_PATH):
	@echo "Setting up $(ARCH) musl toolchain..."
	@mkdir -p $(TOOLCHAIN_DIR) $(SYSROOT)
	$(call download_extract,$(TOOLCHAIN_URL),$(TOOLCHAIN_DIR)/toolchain.tgz,$(TOOLCHAIN_DIR))
	@echo "Toolchain installed: $(TOOLCHAIN_PREFIX)"
	$(call build_zlib)
	$(call build_openssl)
	@echo "Libraries installed to: $(SYSROOT)"

# Clean toolchain
.PHONY: toolchain-clean
toolchain-clean:
	@rm -rf $(TOOLCHAIN_DIR)
