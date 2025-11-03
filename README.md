# Linux Driver Development SDK

A minimal SDK for Linux kernel driver development beginners.

## Quick Start

```bash
make all      # Build kernel, initrd, and launch QEMU
```

## Usage

### Build Targets

```bash
make kernel   # Build Linux kernel
make rootfs   # Build toybox-based root filesystem
make initrd   # Build initrd with your drivers
make qemu     # Launch QEMU virtual machine
make gdb      # Launch QEMU with GDB server for debugging
make template # Create a new driver template
make clean    # Clean build artifacts
```

### Create a Driver

```bash
make template
# Enter driver name when prompted
```

This creates a minimal driver in `drivers/<name>/` with:
- `<name>.c` - Driver source code
- `Makefile` - Build configuration

### Build and Test

```bash
make initrd   # Rebuild initrd with your driver
make qemu     # Boot and test
```

Inside QEMU:
```bash
insmod /lib/modules/<name>.ko   # Load driver
rmmod <name>                     # Unload driver
dmesg                            # View kernel logs
```

### Debug with GDB

Terminal 1:
```bash
make gdb
```

Terminal 2:
```bash
gdb kernel/vmlinux -ex 'target remote :1234'
```

## Architecture Support

Configure target architecture in `arch.mk`:
- x86_64
- arm64
- riscv64 (default)

## Directory Structure

```
.
├── drivers/        # Your driver modules
├── kernel/         # Linux kernel source (auto-cloned)
├── toybox/         # Toybox userspace (auto-cloned)
├── build/          # Build output
└── templates/      # Driver templates
```

## Requirements

- GCC toolchain
- QEMU
- Git
- Make
