/*
2019 David DiPaola
licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)
*/

#include "../config_code.h"

typedef unsigned char  u8;
typedef unsigned int  u32;

/* PL011 registers (see: DDI0183 3.2) */
struct uart_pl011 {
	volatile u32 dr;  /* 0x000 */
};
struct uart_pl011 * const uart0 = (void *)0x1C090000;  /* (see QEMU:vexpress.c, DUI0834D table 8-4) */

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

/* ensures that changes made to CP15 are visible to the rest of the system (see: DDI0406C.D B3.15.5) */
#define arm_cp15_sync __asm("isb")

/* put CPU to sleep until an interrupt occurs */
#define arm_sleep __asm("wfi")

/* SCTLR (System Control Register) definitions (see: DDI0406C.D B4.1.130) */
#define __asm_mrc_SCTLR(var) __asm("mrc p15, 0, %[__reg], c1, c0, 0" : [__reg] "=r" (var))
#define __asm_mcr_SCTLR(var) __asm("mcr p15, 0, %[__reg], c1, c0, 0" : : [__reg] "r" (var))

/* TTBCR (Translation Table Base Control Register) definitions (see: DDI0406C.D B4.1.153) */
#define __asm_mrc_TTBCR(var) __asm("mrc p15, 0, %[__reg], c2, c0, 2" : [__reg] "=r" (var))
#define __asm_mcr_TTBCR(var) __asm("mcr p15, 0, %[__reg], c2, c0, 2" : : [__reg] "r" (var))

/* TTBR0 (Translation Table Base Register 0) 32-bit definitions (see: DDI0406C.D B4.1.154) */
#define __asm_mrc_TTBR0(var) __asm("mrc p15, 0, %[__reg], c2, c0, 0" : [__reg] "=r" (var))
#define __asm_mcr_TTBR0(var) __asm("mcr p15, 0, %[__reg], c2, c0, 0" : : [__reg] "r" (var))

/* DACR (Domain Access Control Register) definitions (see: DDI0406C.D B4.1.43) */
#define __asm_mrc_DACR(var) __asm("mrc p15, 0, %[__reg], c3, c0, 0" : [__reg] "=r" (var))
#define __asm_mcr_DACR(var) __asm("mcr p15, 0, %[__reg], c3, c0, 0" : : [__reg] "r" (var))

/* bit fields:
	ns (not secure):
	ng (not global):
	s (shareable):
	tex ():
	ap (access permissions):
		value    PL1 access    unprivileged access
		0b011    read,write    read,write
		(see DDI0406C.D table B3-8)
	domain ():
	xn (execute never): 0=can execute, 1=execution causes permission fault (see DDI0406C.D B3.7.2)
	c ():
	b ():
	pxn (privelaged execute never): 0=PL1 can execute, 1=execution causes permission fault (see DDI0406C.D B3.7.2)
*/

/* translation table level 1 entry macros (see: DDI0406C.D figure B3-4) */
#define _tt_l1_INVALID ((u32)( 0b00 ))
#define _tt_l1_PAGETABLE(address, domain, sbz, ns, pxn) ((u32)( \
	((address) & 0xFFFFFC00) | \
	(((domain)  &      0xF) <<  5) | \
	(((sbz)     &        1) <<  4) | \
	(((ns)      &        1) <<  3) | \
	(((pxn)     &        1) <<  2) | \
	(0b10                   <<  0)   \
))
#define _tt_l1_SECTION(address, ns, ng, s, tex, ap, domain, xn, c, b, pxn) ((u32)( \
	((address) & 0xFFF00000)    | \
	(((ns)      &     1) << 19) | \
	(((ng)      &     1) << 17) | \
	(((s)       &     1) << 16) | \
	((((ap)>>2) &     1) << 15) | \
	(((tex)     &   0x7) << 12) | \
	(((ap)      &   0x3) << 10) | \
	(((domain)  &   0xF) <<  5) | \
	(((xn)      &     1) <<  4) | \
	(((c)       &     1) <<  3) | \
	(((b)       &     1) <<  2) | \
	(1                   <<  1) | \
	(((pxn)     &     1) <<  0)   \
))

/* translation table level 2 entry macros (see: DDI0406C.D figure B3-5) */
#define _tt_l2_entry_INVALID ((u32)( 0b00 ))
#define _tt_l2_entry_PAGE_4K(address, ng, s, ap, tex, c, b, xn) ((u32)( \
	(((address)   & 0xFFFFF) << 12) | \
	(((ng)        &       1) << 11) | \
	(((s)         &       1) << 10) | \
	((((ap) >> 2) &       1) <<  9) | \
	(((tex)       &     0x7) <<  6) | \
	(((ap)        &     0x3) <<  4) | \
	(((c)         &       1) <<  3) | \
	(((b)         &       1) <<  2) | \
	(1                       <<  1) | \
	(((xn)        &       1) <<  0)   \
))

#define _tt_l1_type u32
#define _tt_l1_size (16384)
#define _tt_l1_length (_tt_l1_size / sizeof(_tt_l1_type))
static _tt_l1_type __attribute__((aligned(_tt_l1_size))) _tt_l1[_tt_l1_length];

static void
mmu_tt_l1_clear(void) {
	for (u32 i=0; i<_tt_l1_length; i++) {
		_tt_l1[i] = _tt_l1_INVALID;
	}
}

static u32
mmu_tt_l1_mapsection(u32 physaddr, u32 virtaddr) {
	/* TODO add args to set mapping flags */
	virtaddr &= 0xFFF00000;
	u32 entry = _tt_l1_SECTION(
		/*address*/ physaddr,
		/*ns*/ 0,  /* use the secure state's address map */
		/*ng*/ 0,  /* global */
		/*s*/ 1,  /* ignored because this mapping is strongly-ordered */
		/*tex*/ 0b000,  /* strongly-ordered & shareable (see: DDI0406C.D table B3-10) */
		/*ap*/ 0b011,  /* read & write access (see: DDI0406C.D table B3-8) */
		/*domain*/ 0b0000,  /* which DACR bits to check */
		/*xn*/ 0,  /* execution allowed */
		/*c*/ 0,  /* strongly-ordered & shareable (see: DDI0406C.D table B3-10) */
		/*b*/ 0,  /* strongly-ordered & shareable (see: DDI0406C.D table B3-10) */
		/*pxn*/ 0  /* privelaged execution allowed */
	);
	u32 index = (virtaddr >> 20) & 0xFFF;
	_tt_l1[index] = entry;

	return virtaddr;
}

static void
mmu_init(void) {
	u32 sctlr;

	#ifdef DEBUG
	print("translation table level 1 address (tt l1): 0x");
	print_hex8((u32)_tt_l1);
	print("\r\n");
	#endif

	/* disable MMU */
	__asm_mrc_SCTLR(sctlr);
	sctlr &= ~(1 << 0);
	__asm_mcr_SCTLR(sctlr);

	/* disable EAE/LPAE (use short descriptor mode), set TTBR0's table size to 16KB (also disables TTBR1) (see: DDI0406C.D figure B3-6) */
	u32 ttbcr;
	__asm_mrc_TTBCR(ttbcr);
	ttbcr &= ~((1<<31) | 0b111);
	ttbcr |=   (0<<31  | 0b000);
	__asm_mcr_TTBCR(ttbcr);
	
	/* set TTBR0's table's address */
	u32 ttbr0;
	__asm_mrc_TTBR0(ttbr0);
	ttbr0 &= ~(0xFFFFC000);
	ttbr0 |=  (((u32)_tt_l1) & 0xFFFFC000);
	__asm_mcr_TTBR0(ttbr0);

	/* set all MMU domains as "client" (translation table permission bits are checked) (see DDI0406C.D B3.12.3) */
	u32 dacr = 0b01010101010101010101010101010101;
	__asm_mcr_DACR(dacr);

	arm_cp15_sync;

	/* clear level 1 translation table */
	mmu_tt_l1_clear();

	/* create section entry for kernel */
	mmu_tt_l1_mapsection(CONFIG_CODE_KERNEL_STARTADDR, CONFIG_CODE_KERNEL_STARTADDR);

	/* create section entry for IO devices */
	u32 iobase = ((u32)uart0) & 0xFFF00000;
	mmu_tt_l1_mapsection(iobase, iobase);

	#ifdef DEBUG
	print("enabling MMU..." "\r\n");
	#endif

	/* enable MMU */
	__asm_mrc_SCTLR(sctlr);
	sctlr |= (1 << 0);
	__asm_mcr_SCTLR(sctlr);

	arm_cp15_sync;

	#ifdef DEBUG
	print("... still running!" "\r\n");
	#endif
}

__attribute__ ((interrupt ("ABORT")))
void
_handler_abort(void) {
	print("abort exception occurred!" "\r\n");
	for (;;) { arm_sleep; }
}

static void
mmu_map() {
	/* see: DDI0406C.D figure B3-3 */
	/* see: DDI0406C.D figure B3.5.1 */
	/* see: DDI0406C.D figure B3-7 */
	/* see: DDI0406C.D figure B3-11 */

}

void
main(void) {
	print("hello world!" "\r\n");

	mmu_init();

	print("trying to write to un-mapped memory..." "\r\n");
	(*((u32 *)0xF00FF00F)) = 1;

	print("done" "\r\n");
	for (;;) { arm_sleep; }
}

