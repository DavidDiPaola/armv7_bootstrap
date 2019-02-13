/*
2018 David DiPaola
licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)
*/

/* code entry point */
ENTRY(_handler_reset)

/* memory regions (see QEMU:vexpress.c) */
MEMORY {
	MAP_IO_UART0   : ORIGIN = 0x1C090000, LENGTH = 0x00000400 /* PL011, 1KB */
	MAP_DRAM       : ORIGIN = 0x80000000, LENGTH = 0x80000000 /* 2GB */
}

/* ELF binary sections */
SECTIONS {
	/* NOTE `SUBALIGN` is used with the `gcc` flags `-ffunction-sections` and `-fdata-sections` to ensure each function and piece of data are properly aligned */

	/* IO: UART0 */
	SECTION_IO_UART0 : SUBALIGN(4) {
		*(.data)
		*(.bss)
	} >MAP_IO_UART0

	/* DRAM */
	.text : SUBALIGN(4) {
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

