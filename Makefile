#2018 David DiPaola
#licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)

SRC = main.c
BIN_ELF = boot.elf
BIN_BIN = $(BIN_ELF:.elf=.bin)

OBJ = $(SRC:.c=.o)

PREFIX ?= arm-none-eabi-
GCC ?= $(PREFIX)gcc
GCC_FLAGS = \
	-std=c99 \
	-mcpu=cortex-a7 \
	-ffreestanding -nostdinc \
	-ffunction-sections -fdata-sections \
	-O2 \
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

.PHONY: all
all: $(BIN_ELF)

.PHONY: run
run: $(BIN_ELF)
	@echo [QEMU] $<
	@$(QEMU) $(QEMU_FLAGS) -kernel $<

.PHONY: run-paused
run-paused: $(BIN_ELF)
	@echo [QEMU] $<
	@$(QEMU) $(QEMU_FLAGS) -S -kernel $<

.PHONY: run-debugger
run-debugger: $(BIN_ELF)
	@echo [GDB] $<
	@$(GDB) $(GDB_FLAGS) $<

.PHONY: dump-elf
dump-elf: $(BIN_ELF)
	@echo [OBJDUMP] $<
	@$(OBJDUMP) --disassemble --source --line-numbers $<

.PHONY: dump-elf-syms
dump-elf-syms: $(BIN_ELF)
	@echo [OBJDUMP] $<
	@$(OBJDUMP) --syms $<

.PHONY: clean
clean:
	@echo [RM] $(OBJ) $(BIN_ELF) $(BIN_BIN)
	@rm -rf $(OBJ) $(BIN_ELF) $(BIN_BIN)

.c.o:
	@echo [GCC] $<
	@$(GCC) $(GCC_FLAGS) -o $@ -c $<

$(BIN_ELF): layout.lds $(OBJ)
	@echo [GLD] -T layout.lds -o $@ $(OBJ)
	@$(GLD) $(GLD_FLAGS) -T layout.lds -o $@ $(OBJ)

