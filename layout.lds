/*
2018,2019 David DiPaola
licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)
*/

/* code entry point */
ENTRY(_handler_reset)

/* memory regions (see QEMU:vexpress.c) */
MEMORY {
	MAP_DRAM : ORIGIN = 0x80000000, LENGTH = 0x80000000 /* 2GB */
}

/* ELF binary sections */
SECTIONS {
	/* NOTE `SUBALIGN` is used with the `gcc` flags `-ffunction-sections` and `-fdata-sections` to ensure each function and piece of data are properly aligned */

	/* DRAM */
	.text : SUBALIGN(4) {
		layout_text_start = .;
		init.o(.text)
		init.o(.rodata)
		*(.text)
		*(.rodata)
	} >MAP_DRAM
	.data : SUBALIGN(4) {
		*(.data)
	} >MAP_DRAM
	.bss : SUBALIGN(4) {
		*(.bss)
	} >MAP_DRAM
}

