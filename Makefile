#2018 David DiPaola
#licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)

KERNEL_SRC_S = init.S
KERNEL_SRC_C = main.c
KERNEL_OBJ = $(KERNEL_SRC_S:.S=.o) $(KERNEL_SRC_C:.c=.o)
KERNEL_ELF = boot.elf

BIOSSTUB_SRC = biosstub.S
BIOSSTUB_OBJ = $(BIOSSTUB_SRC:.S=.o)
BIOSSTUB_BIN = biosstub.bin

PREFIX ?= arm-none-eabi-
GCC ?= $(PREFIX)gcc
GCC_ASFLAGS = \
	-mcpu=cortex-a7 \
	-g \
	$(CPP_FLAGS_DEBUG)
GCC_CFLAGS = \
	-std=c99 \
	-mcpu=cortex-a7 \
	-ffreestanding -nostdinc \
	-ffunction-sections -fdata-sections \
	-g \
	$(CPP_FLAGS_DEBUG)
GLD ?= $(PREFIX)ld
GLD_FLAGS = \
	-static -nostdlib \
	-O1 --gc-sections --print-gc-sections
QEMU ?= qemu-system-arm
QEMU_FLAGS = \
	-gdb tcp::1234 \
	-nographic \
	-machine vexpress-a15 -cpu cortex-a7 \
	-m 32M
GDB ?= gdb-multiarch
GDB_FLAGS = \
	--command=gdbinit
OBJDUMP ?= $(PREFIX)objdump
OBJCOPY ?= $(PREFIX)objcopy

.PHONY: all
all: $(BIOSSTUB_BIN) $(KERNEL_ELF)

.PHONY: run
run: $(BIOSSTUB_BIN) $(KERNEL_ELF)
	@echo [QEMU] $<
	@$(QEMU) $(QEMU_FLAGS) -bios $(BIOSSTUB_BIN) -kernel $(KERNEL_ELF)

.PHONY: run-paused
run-paused: $(BIOSSTUB_BIN) $(KERNEL_ELF)
	@echo [QEMU] $^
	@$(QEMU) $(QEMU_FLAGS) -S -bios $(BIOSSTUB_BIN) -kernel $(KERNEL_ELF)

.PHONY: run-debugger
run-debugger: $(KERNEL_ELF)
	@echo [GDB] $<
	@$(GDB) $(GDB_FLAGS) $<

.PHONY: dump-elf
dump-elf: $(KERNEL_ELF)
	@echo [OBJDUMP] $<
	@$(OBJDUMP) --disassemble --source --line-numbers $<

.PHONY: dump-elf-syms
dump-elf-syms: $(KERNEL_ELF)
	@echo [OBJDUMP] $<
	@$(OBJDUMP) --syms $<

.PHONY: clean
clean:
	@echo [RM] $(BIOSSTUB_OBJ) $(BIOSSTUB_BIN)
	@rm -rf $(BIOSSTUB_OBJ) $(BIOSSTUB_BIN)
	@echo [RM] $(KERNEL_OBJ) $(KERNEL_ELF)
	@rm -rf $(KERNEL_OBJ) $(KERNEL_ELF)

.S.o:
	@echo [AS] $<
	@$(GCC) $(GCC_ASFLAGS) -o $@ -c $<

.c.o:
	@echo [CC] $<
	@$(GCC) $(GCC_CFLAGS) -o $@ -c $<

$(BIOSSTUB_BIN): $(BIOSSTUB_OBJ)
	@echo [OBJCOPY] $< $@
	@$(OBJCOPY) --set-start 0x00000000 --only-section .text --output-target binary $< $@

$(KERNEL_ELF): layout.lds $(KERNEL_OBJ)
	@echo [LD] -T layout.lds -o $@ $(KERNEL_OBJ)
	@$(GLD) $(GLD_FLAGS) -T layout.lds -o $@ $(KERNEL_OBJ)

