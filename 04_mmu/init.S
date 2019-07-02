/*
2019 David DiPaola
licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)
*/

.code 32

/* stack sizes (see: DDI0406C.D B1-2) */
.set _usrsysstack_size, 65536
.set _fiqstack_size,      256
.set _irqstack_size,      256
.set _svcstack_size,      256
.set _abtstack_size,      256
.set _undstack_size,      256

/* Change Processor State bits (see: QRC0001 Processor Modes) */
.set _cps_mode_usr, 16
.set _cps_mode_fiq, 17
.set _cps_mode_irq, 18
.set _cps_mode_svc, 19
.set _cps_mode_abt, 23
.set _cps_mode_und, 27
.set _cps_mode_sys, 31

/* move VBAR to register (see: DDI0406C.D B4.1.156) */
.macro _mrc_VBAR reg
	mrc p15, 0, \reg, c12, c0, 0
.endm
/* move register to VBAR (see: DDI0406C.D B4.1.156) */
.macro _mcr_VBAR reg
	mcr p15, 0, \reg, c12, c0, 0
.endm

/* move SCTLR to register (see: DDI0406C.D B4.1.130) */
.macro _mrc_SCTLR reg
	mrc p15, 0, \reg, c1, c0, 0
.endm

/* move register to SCTLR (see: DDI0406C.D B4.1.130) */
.macro _mcr_SCTLR reg
	mcr p15, 0, \reg, c1, c0, 0
.endm



/* vector table (see: DDI0406C.D B1-3) */
.align 4
	b _handler_reset      /* reset vector */
	b _handler_undefined  /* undefined vector */
	b _handler_svc        /* SVC vector */
	b _handler_prefetch   /* prefetch vector */
	b _handler_abort      /* abort vector */
	b _handler_reset      /* reserved vector */
	b _handler_irq        /* IRQ vector */
	b _handler_fiq        /* FIQ vector */



.globl _handler_reset
_handler_reset:
	/* set VBAR to the start of this executable (see: DDI0464F 4.2.13) */
	_mrc_VBAR r0
	ldr r1, =0b11111
	and r0, r0, r1
	ldr r2, =layout_text_start  /* layout_text_start is from layout.lds */
	bic r2, r2, r0
	orr r0, r0, r2
	_mcr_VBAR r0

	/* use VBAR for vector base address */
	_mrc_SCTLR r0
	ldr r1, =(1 << 13)
	bic r0, r0, r1
	_mcr_SCTLR r0

	/* Abort mode stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	cpsid if, _cps_mode_abt
	ldr sp, =_abtstack+_abtstack_size

	/* Undefinied mode stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	cpsid if, _cps_mode_und
	ldr sp, =_undstack+_undstack_size

	/* IRQ mode stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	cpsid if, _cps_mode_irq
	ldr sp, =_irqstack+_irqstack_size

	/* FIQ mode stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	cpsid if, _cps_mode_fiq
	ldr sp, =_fiqstack+_fiqstack_size

	/* Supervisor mode stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	cpsid if, _cps_mode_svc
	ldr sp, =_svcstack+_svcstack_size

	/* User/System mode stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	cpsid if, _cps_mode_sys
	ldr sp, =_usrsysstack+_usrsysstack_size

	/* TODO create 'usr handler' to jump back into sys mode */

	bl main
1:	wfi      /* sleep CPU forever */
	b 1b



.weak _handler_undefined
_handler_undefined:
	b .



.weak _handler_svc
_handler_svc:
	b .



.weak _handler_prefetch
_handler_prefetch:
	b .



.weak _handler_abort
_handler_abort:
1:	wfi  /* sleep CPU forever */
	b 1b



.weak _handler_irq
_handler_irq:
	b .



.weak _handler_fiq
_handler_fiq:
	b .



/* stacks (see: DDI0406C.D B1-2) */
.align 4
.comm _usrsysstack, _usrsysstack_size
.align 4
.comm _fiqstack, _fiqstack_size
.align 4
.comm _irqstack, _irqstack_size
.align 4
.comm _svcstack, _svcstack_size
.align 4
.comm _abtstack, _abtstack_size
.align 4
.comm _undstack, _undstack_size

