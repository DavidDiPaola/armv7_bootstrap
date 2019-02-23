# 2018,2019 David DiPaola
# licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)

00_SRC_S = 00_helloworld/init.S
00_SRC_C = 00_helloworld/main.c
00_OBJ = $(00_SRC_S:.S=.o) $(00_SRC_C:.c=.o)
00_ELF = 00_helloworld/kernel.elf

01_SRC_S = 01_vectors/init.S
01_SRC_C = 01_vectors/main.c
01_OBJ = $(01_SRC_S:.S=.o) $(01_SRC_C:.c=.o)
01_ELF = 01_vectors/kernel.elf

include config_build.mk

PREFIX ?= arm-none-eabi-
GCC ?= $(PREFIX)gcc
GCC_ASFLAGS = \
	-mcpu=$(CONFIG_BUILD_KERNEL_CPU) \
	-g \
	$(CPP_FLAGS_DEBUG)
GCC_CFLAGS = \
	-std=c99 \
	-mcpu=$(CONFIG_BUILD_KERNEL_CPU) \
	-ffreestanding -nostdinc \
	-ffunction-sections -fdata-sections \
	-g \
	$(CPP_FLAGS_DEBUG)
GLD ?= $(PREFIX)ld
GLD_FLAGS = \
	-static -nostdlib \
	-O1 --gc-sections --print-gc-sections
CPP ?= $(PREFIX)cpp
CPP_FLAGS = -C -P



.PHONY: all
all: $(00_ELF) $(01_ELF)

.PHONY: clean
clean:
	@echo [RM] layout.lds
	@rm -f layout.lds
	@echo [RM] $(00_OBJ) $(00_ELF)
	@rm -rf $(00_OBJ) $(00_ELF)
	@echo [RM] $(01_OBJ) $(01_ELF)
	@rm -rf $(01_OBJ) $(01_ELF)

layout.lds: layout.lds.cpp
	@echo [CPP] $< -o $@
	@$(CPP) $(CPP_FLAGS) $< -o $@

$(00_ELF): layout.lds $(00_OBJ)
	@echo [LD] -T layout.lds -o $@ $(00_OBJ)
	@$(GLD) $(GLD_FLAGS) -T layout.lds -o $@ $(00_OBJ)

$(01_ELF): layout.lds $(01_OBJ)
	@echo [LD] -T layout.lds -o $@ $(01_OBJ)
	@$(GLD) $(GLD_FLAGS) -T layout.lds -o $@ $(01_OBJ)

.S.o:
	@echo [AS] $<
	@$(GCC) $(GCC_ASFLAGS) -o $@ -c $<

.c.o:
	@echo [CC] $<
	@$(GCC) $(GCC_CFLAGS) -o $@ -c $<

