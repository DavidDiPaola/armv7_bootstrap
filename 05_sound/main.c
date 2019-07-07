/*
2018,2019 David DiPaola
licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)
*/

typedef unsigned char   u8;
typedef unsigned short u16;
typedef unsigned int   u32;

/* PL011 registers (see: DDI0183 3.2) */
struct uart_pl011 {
	volatile u32 dr;  /* 0x000 */
};
struct uart_pl011 * const uart0 = (void *)0x1C090000;  /* (see: QEMU:vexpress.c) */

/* PL041 registers (see: DDI0173.B table 3-1) */
struct sound_pl041_fifo {
	volatile u32 rxcr;  /* 0x00 */
	volatile u32 txcr;  /* 0x04 */
	volatile u32 sr;    /* 0x08 */
	volatile u32 isr;   /* 0x0C */
	volatile u32 ie;    /* 0x10 */
};
struct sound_pl041 {
	struct sound_pl041_fifo fifo1;  /* 0x00 */
	u8 _pad0[0x54-(0x00+sizeof(struct sound_pl041_fifo))];  /* not implementing FIFOs 2 through 4 because QEMU doesn't emulate them (see: QEMU:hw/audio/pl041.c) */
	volatile u32 sl1tx;             /* 0x54 */
	u8 _pad1[0x5C-(0x54+sizeof(u32))];
	volatile u32 sl2tx;             /* 0x5C */
	u8 _pad2[0x78-(0x5C+sizeof(u32))];
	volatile u32 maincr;            /* 0x78 */
	volatile u32 reset;             /* 0x7C */
	u8 _pad3[0x90-(0x7C+sizeof(u32))];
	volatile u32 dr1;               /* 0x90 */
};
struct sound_pl041 * const sound = (void *)0x1C040000;  /* (see: QEMU:vexpress.c) */

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
sound_codec_write(u8 address, u16 data) {
	sound->sl2tx = data;     /* command data slot (see: AN115.B 3.4) */
	sound->sl1tx = address;  /* command address slot (see: AN115.B 3.4) */
}

void
sound_init(void) {
	/* (see: AN115B 3.1) */
	/* reset the codec (LM4549) */
	sound->reset |= (1<<0);
	sound->reset &= ~(1<<0);
	/* enable audio playback (see: DDI0173.B table 3-4) */
	sound->fifo1.txcr =
		(   1 << 16) |  /* FIFO enabled */
		(   0 << 15) |  /* compact mode disabled */
		(0b00 << 13) |  /* bit depth: 16bit */
		(   1 <<  3) |  /* this FIFO stores slot 3 data (see: AN115.B 3.3) */
		(   1 <<  0)    /* transmit enabled */
	;
	/* enable config of codec and use of audio system (see: DDI0173.B table 3-18) */
	sound->maincr =
		(0 << 9) |  /* DMA disabled */
		(1 << 6) |  /* slot 2 transmit enabled (see: AN115.B 3.4) */
		(1 << 4) |  /* slot 1 transmit enabled (see: AN115.B 3.4) */
		(0 << 2) |  /* low power mode disabled */
		(0 << 1) |  /* loopbackmode disabled */
		(1 << 0)    /* AACI interface enable */
	;
	/* configure codec (LM4549) */
	sound_codec_write(0x02, (0<<15)|(0b11111<<8)|(0b11111<<0));  /* master volume: unmute, left max, right max (see: AN115.B table 3-1) */
	sound_codec_write(0x18, (0<<15)|(0b11111<<8)|(0b11111<<0));  /* PCM out volume: unmute, left max, right max (see: AN115.B table 3-1) */
}

void
sound_play(u16 * data, u32 data_size) {
	/* (see: AN115B 3.1) */
	u32 data_length = data_size / sizeof(*data);
	for (u32 i=0; i<data_length; i++) {
		while ( sound->fifo1.sr & (1<<5) ) {}  /* wait while transmit FIFO is full (see: DDI0173.B table 3-5) */
		sound->dr1 = data[i];
	}
}

#include "sample.wav.h"

void
main(void) {
	print("hello world!" "\r\n");

	print("sound init..." "\r\n");
	sound_init();

	print("sound playback... ");
	sound_play((u16 *)sample, sizeof(sample));
	print("done!" "\r\n");
}

