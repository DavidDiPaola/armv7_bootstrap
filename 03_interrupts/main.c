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
struct uart_pl011 * const uart0 = (void *)0x1C090000;  /* (see QEMU:vexpress.c, DUI0834D table 8-4) */

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
struct sp804 * const timer01 = (void *)0x1C110000;  /* (see QEMU:vexpress.c, DUI0834D table 8-4) */

/* GIC-400 registers (see: DDI0471A table 3-1, DDI0471A table 3-2) */
struct __attribute__ ((packed)) gic400 {
	u8 _pad0[(0x0FFF-0x0000)+1];                    /* 0x0000-0x0FFF, reserved */
	struct __attribute__ ((packed)) gic400_dist {   /* 0x1000-0x1FFF, distributor registers */
		volatile u32 ctlr;           /* 0x000       read,write */
		volatile u32 typer;          /* 0x004       read       */
		volatile u32 iidr;           /* 0x008       read       */
		u8 _pad0[(0x07F-0x00C)+1];   /* 0x00C-0x07C            */
		volatile u32 igroupr[16];    /* 0x080-0x0BC read,write */
		u8 _pad1[(0x0FF-0x0C0)+1];   /* 0x0C0-0x0FF            */
		volatile u32 isenabler[16];  /* 0x100-0x13C read,write */
		u8 _pad2[(0x17F-0x140)+1];   /* 0x140-0x17F            */
		volatile u32 icenabler[16];  /* 0x180-0x1BC read,write */
		u8 _pad3[(0xFFF-0x1C0)+1];   /* 0x1C0-0xFFF            */ /* NOTE this is incomplete. there are actually registers here */
	} dist;
	struct __attribute__ ((packed)) gic400_cpuif {  /* 0x2000-0x3FFF, CPU interface registers */
		volatile u32 ctlr;  /* 0x0000 read,write */
		volatile u32 pmr;   /* 0x0004 read,write */
		volatile u32 bpr;   /* 0x0008 read,write */
		volatile u32 iar;   /* 0x000C read       */
		volatile u32 eoir;  /* 0x0010      write */
		/* NOTE not all registers are implemented here */
	} cpuif;
	/* NOTE not all registers are implemented here */
};
struct gic400 * const gic = (void *)0x2C000000;  /* (see: DDI0503H table 3-2) */
enum interrupt {
	interrupt_none    = 0x3FF,  /* (see: DDI0471A table 3-6) */
	interrupt_timer01 =    34,  /* (see: DDI0503H 2.8.2) */
};

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
print_hex8(u32 value) {
	for (int i=7; i>=0; i--) {
		u8 hex = ((value >> (i*4)) & 0xF);
		uart0->dr = hex + ((hex < 0xA) ? '0' : ('A' - 0xA));
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

static void
gic_init(void) {
	gic->cpuif.ctlr =    1;
	gic->cpuif.pmr  = 0xFF;

	gic->dist.ctlr = 1;
}

void
gic_interrupt_enable(enum interrupt intr) {
	if (intr == interrupt_none) return;

	gic->dist.isenabler[intr / 32] |= 1 << (intr % 32);
}

__attribute__ ((interrupt ("IRQ")))
void
_handler_irq(void) {
	/* (see: DDI0471A B.1) */

	for (;;) {
		enum interrupt intr = gic->cpuif.iar;
		if (intr == interrupt_none) break;

		print("IRQ exception occurred: ");
		if (intr == interrupt_timer01) {
			print("timer01");

			timer01->timer0.clear = 0;
		}
		else {
			print("UNKNOWN (");
			print_hex8(intr);
			print(")");
		}
		print("\r\n");

		gic->cpuif.eoir = intr;
	}
}

void
main(void) {
	print("hello world!" "\r\n");

	gic_init();
	gic_interrupt_enable(interrupt_timer01);
	__asm("cpsie i");

	timer_init(&(timer01->timer0), 0x80000);

	for (;;) { __asm("wfi"); }
}

