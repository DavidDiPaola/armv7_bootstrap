/*
2018,2019 David DiPaola
licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)
*/

typedef unsigned int u32;

/* PL011 registers (see: DDI0183 3.2) */
struct uart_pl011 {
	volatile u32 dr;  /* 0x000 */
};
struct uart_pl011 * const uart0 = (void *)0x1C090000;  /* (see QEMU:vexpress.c) */

static void
print(const char * s) {
	char c;
	for (;;) {
		c = *s;
		if (c == '\0') break;
		uart0->dr = c;
		s++;
	}
}

void
main(void) {
	print("hello world!" "\r\n");
}

