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

__attribute__ ((interrupt ("SWI")))
void
_handler_svc(void) {
	print("(step 2 of 3) SVC exception occurred" "\r\n");
}

void
main(void) {
	print("hello world!" "\r\n");

	print("(step 1 of 3) going to trigger SVC exception..." "\r\n");
	__asm("svc 42");
	print("(step 3 of 3) returned from SVC exception" "\r\n");
}

