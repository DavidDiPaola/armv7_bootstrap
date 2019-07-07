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

02_SRC_S = 02_timer/init.S
02_SRC_C = 02_timer/main.c
02_OBJ = $(02_SRC_S:.S=.o) $(02_SRC_C:.c=.o)
02_ELF = 02_timer/kernel.elf

03_SRC_S = 03_interrupts/init.S
03_SRC_C = 03_interrupts/main.c
03_OBJ = $(03_SRC_S:.S=.o) $(03_SRC_C:.c=.o)
03_ELF = 03_interrupts/kernel.elf

04_SRC_S = 04_mmu/init.S
04_SRC_C = 04_mmu/main.c
04_OBJ = $(04_SRC_S:.S=.o) $(04_SRC_C:.c=.o)
04_ELF = 04_mmu/kernel.elf

05_SRC_S = 05_sound/init.S
05_SRC_C = 05_sound/main.c
05_OBJ = $(05_SRC_S:.S=.o) $(05_SRC_C:.c=.o)
05_ELF = 05_sound/kernel.elf

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
all: $(00_ELF) $(01_ELF) $(02_ELF) $(03_ELF) $(04_ELF) $(05_ELF)

.PHONY: clean
clean:
	@echo [RM] layout.lds
	@rm -f layout.lds
	@echo [RM] $(00_OBJ) $(00_ELF)
	@rm -rf $(00_OBJ) $(00_ELF)
	@echo [RM] $(01_OBJ) $(01_ELF)
	@rm -rf $(01_OBJ) $(01_ELF)
	@echo [RM] $(02_OBJ) $(02_ELF)
	@rm -rf $(02_OBJ) $(02_ELF)
	@echo [RM] $(03_OBJ) $(03_ELF)
	@rm -rf $(03_OBJ) $(03_ELF)
	@echo [RM] $(04_OBJ) $(04_ELF)
	@rm -rf $(04_OBJ) $(04_ELF)
	@echo [RM] $(05_OBJ) $(05_ELF) 05_sound/sample.wav.h
	@rm -rf $(05_OBJ) $(05_ELF) 05_sound/sample.wav.h

layout.lds: layout.lds.cpp
	@echo [CPP] $< -o $@
	@$(CPP) $(CPP_FLAGS) $< -o $@

05_sound/sample.wav.h: 05_sound/sample.wav
	@echo [WAV2H] $< $@
	@./05_sound/wav2h.sh $< $@

05_sound/main.c: 05_sound/sample.wav.h

$(00_ELF): layout.lds $(00_OBJ)
	@echo [LD] -T layout.lds -o $@ $(00_OBJ)
	@$(GLD) $(GLD_FLAGS) -T layout.lds -o $@ $(00_OBJ)

$(01_ELF): layout.lds $(01_OBJ)
	@echo [LD] -T layout.lds -o $@ $(01_OBJ)
	@$(GLD) $(GLD_FLAGS) -T layout.lds -o $@ $(01_OBJ)

$(02_ELF): layout.lds $(02_OBJ)
	@echo [LD] -T layout.lds -o $@ $(02_OBJ)
	@$(GLD) $(GLD_FLAGS) -T layout.lds -o $@ $(02_OBJ)

$(03_ELF): layout.lds $(03_OBJ)
	@echo [LD] -T layout.lds -o $@ $(03_OBJ)
	@$(GLD) $(GLD_FLAGS) -T layout.lds -o $@ $(03_OBJ)

$(04_ELF): layout.lds $(04_OBJ)
	@echo [LD] -T layout.lds -o $@ $(04_OBJ)
	@$(GLD) $(GLD_FLAGS) -T layout.lds -o $@ $(04_OBJ)

$(05_ELF): layout.lds $(05_OBJ)
	@echo [LD] -T layout.lds -o $@ $(05_OBJ)
	@$(GLD) $(GLD_FLAGS) -T layout.lds -o $@ $(05_OBJ)

.S.o:
	@echo [AS] $<
	@$(GCC) $(GCC_ASFLAGS) -o $@ -c $<

.c.o:
	@echo [CC] $<
	@$(GCC) $(GCC_CFLAGS) -o $@ -c $<

