/*
2018 David DiPaola
licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)
*/

#define pragma_section(name) __attribute__((section(name)))

typedef unsigned char   u8;
typedef unsigned short u16;
typedef unsigned int   u32;

const void * NULL = 0;

/* PL011 registers (see DDI0183:3.2) */
struct uart_pl011 {
	volatile u32 dr;  /* 0x000 */
};

pragma_section("SECTION_IO_UART0") struct uart_pl011 uart0;

static void
print_char(char value) {
	uart0.dr = value;
}

static void
print(const char * s) {
	char c;
	for (;;) {
		c = *s;
		if (c == '\0') break;
		print_char(c);
		s++;
	}
}

static void
println(const char * s) {
	if (s != NULL) {
		print(s);
	}
	print("\r\n");
}

static void
print_hex4(u8 value) {
	value &= 0b1111;
	if (value < 0xA) {
		print_char('0' + (value - 0x0));
	}
	else {
		print_char('A' + (value - 0xA));
	}
}

static void
print_hex32(u32 value) {
	print_hex4(value >> 28);
	print_hex4(value >> 24);
	print_hex4(value >> 20);
	print_hex4(value >> 16);
	print_hex4(value >> 12);
	print_hex4(value >>  8);
	print_hex4(value >>  4);
	print_hex4(value >>  0);
}

static void
print_mem(u32 addr, u32 length) {
	u32 * mem = 0;
	for (u32 i=0; i<length; i++) {
		if ((i % 8) == 0) {
			print_hex32(i);
		}

		print("  ");
		print_hex32(mem[addr+i]);

		if ((i % 8) == 7) {
			println(NULL);
		}
	}
	println(NULL);
}

void
main(void) {
	println(NULL); println("booted");

	print_mem(0x1C090000, 400);
}

