/*
2019 David DiPaola
licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)
*/

typedef unsigned char  u8;
typedef unsigned int  u32;

/* PL011 registers (see: DDI0183 3.2) */
struct uart_pl011 {
	volatile u32 dr;  /* 0x000 */
};
struct uart_pl011 * const uart0 = (void *)0x1C090000;  /* (see QEMU:vexpress.c) */

/* SP804 registers (see: DDI0271.D 3.1) */
struct __attribute__ ((packed)) sp804_unit {
	volatile u32 load;     /* 0x00 read,write */
	volatile u32 value;    /* 0x04 read       */
	volatile u32 control;  /* 0x08 read,write */
	volatile u32 clear;    /* 0x0C      write */
	volatile u32 ris;      /* 0x10 read       */
	volatile u32 mis;      /* 0x14 read       */
	volatile u32 bgload;   /* 0x18 read,write */
};
static const int sp804_control_enable           =    1 << 7;
static const int sp804_control_mode_mask        =    1 << 6;
static const int sp804_control_mode_freerun     =    0 << 6;
static const int sp804_control_mode_periodic    =    1 << 6;
static const int sp804_control_intenable        =    1 << 5;
static const int sp804_control_presc_mask       = 0b11 << 2;
static const int sp804_control_presc_div1       = 0b00 << 2;
static const int sp804_control_presc_div4       = 0b01 << 2;
static const int sp804_control_presc_div8       = 0b10 << 2;
static const int sp804_control_size_mask        =    1 << 1;
static const int sp804_control_size_16bit       =    0 << 1;
static const int sp804_control_size_32bit       =    1 << 1;
static const int sp804_control_overflow_mask    =    1 << 0;
static const int sp804_control_overflow_wrap    =    0 << 0;
static const int sp804_control_overflow_oneshot =    1 << 0;
struct __attribute__ ((packed)) sp804 {
	struct sp804_unit timer0;   /* 0x000-0x01B */
	u8 _pad0[(0x01F-0x01C)+1];  /* 0x01C-0x01F */
	struct sp804_unit timer1;   /* 0x020-0x03B */
	u8 _pad1[(0xFFF-0x03C)+1];  /* 0x03C-0xFFF */
};
struct sp804 * const timer01 = (void *)0x1C110000;  /* (see QEMU:vexpress.c) */

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

static void
timer_init(struct sp804_unit * timer, u32 value) {
	/* see: DDI0271.D 3.2.3 */

	timer->control &= ~sp804_control_enable;

	timer->load = value;

	u32 control = timer->control;
	timer->control =
		((control & sp804_control_mode_mask) | sp804_control_mode_periodic) |
		sp804_control_intenable |
		((control & sp804_control_presc_mask) | sp804_control_presc_div1) |
		((control & sp804_control_size_mask) | sp804_control_size_32bit) |
		((control & sp804_control_overflow_mask) | sp804_control_overflow_wrap)
	;

	timer->control |= sp804_control_enable;
}

void
main(void) {
	print("hello world!" "\r\n");

	timer_init(&(timer01->timer0), 0x80000);
	
	for (;;) {
		while (timer01->timer0.ris == 0) {}
		print("timer went off!" "\r\n");

		timer01->timer0.clear = 0;
	}
}

