/*
2018,2019 David DiPaola
licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)
*/

#include "config_code.h"

/* code entry point */
ENTRY(_handler_reset)

MEMORY {
	MEMORY_KERNEL : ORIGIN = CONFIG_CODE_KERNEL_STARTADDR , LENGTH = 8M
}

/* ELF binary sections */
SECTIONS {
	/* NOTE `SUBALIGN` is used with the `gcc` flags `-ffunction-sections` and `-fdata-sections` to ensure each function and piece of data are properly aligned */

	.text : SUBALIGN(4) {
		layout_text_start = .;
		*/init.o(.text)
		*/init.o(.rodata)
		*(.text)
		*(.rodata)
	} >MEMORY_KERNEL
	.data : SUBALIGN(4) {
		*(.data)
	} >MEMORY_KERNEL
	.bss : SUBALIGN(4) {
		*(.bss)
	} >MEMORY_KERNEL
}

