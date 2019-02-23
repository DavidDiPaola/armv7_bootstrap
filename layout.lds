/*
2018,2019 David DiPaola
licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)
*/

/* code entry point */
ENTRY(_handler_reset)

/* ELF binary sections */
SECTIONS {
	/* NOTE `SUBALIGN` is used with the `gcc` flags `-ffunction-sections` and `-fdata-sections` to ensure each function and piece of data are properly aligned */

	.text : SUBALIGN(4) {
		layout_text_start = .;
		*/init.o(.text)
		*/init.o(.rodata)
		*(.text)
		*(.rodata)
	}
	.data : SUBALIGN(4) {
		*(.data)
	}
	.bss : SUBALIGN(4) {
		*(.bss)
	}
}

