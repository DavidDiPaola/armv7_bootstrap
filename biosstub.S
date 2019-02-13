/* reset vector */
.org 0x00000000
	ldr pc, =0x80000000  /* jump to kernel reset vector */
/* undefined vector */
.org 0x00000004
	ldr pc, =0x80000004  /* jump to kernel undefined vector */
/* SVC vector */
.org 0x00000008
	ldr pc, =0x80000008  /* jump to kernel SVC vector */
/* prefetch vector */
.org 0x0000000C
	ldr pc, =0x8000000C  /* jump to kernel prefetch vector */
/* abort vector */
.org 0x00000010
	ldr pc, =0x80000010  /* jump to kernel abort vector */
/* reserved vector */
.org 0x00000014
	nop
/* IRQ vector */
.org 0x00000018
	ldr pc, =0x80000018  /* jump to kernel IRQ vector */
/* FIQ vector */
.org 0x0000001C
	ldr pc, =0x8000001C  /* jump to kernel FIQ vector */

