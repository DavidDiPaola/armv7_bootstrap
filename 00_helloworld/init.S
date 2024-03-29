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


.globl _handler_reset
_handler_reset:
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

