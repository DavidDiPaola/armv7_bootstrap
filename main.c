/*
2018 David DiPaola
licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)
*/

#define pragma_section(name) __attribute__((section(name)))

typedef unsigned int u32;

/* PL011 registers (see DDI0183:3.2) */
struct uart_pl011 {
	volatile u32 dr;  /* 0x000 */
};

pragma_section("SECTION_IO_UART0") struct uart_pl011 uart0;

static void
print(const char * s) {
	char c;
	for (;;) {
		c = *s;
		if (c == '\0') break;
		uart0.dr = c;
		s++;
	}
}

static void
println(const char * s) {
	print(s);
	print("\r\n");
}

void
main(void) {
	for (;;) {
		println("hi");
	}
}

