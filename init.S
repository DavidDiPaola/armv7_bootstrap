.code 32

/* stack sizes (see: DDI0406C.D B1-2) */
.set _usrsysstack_size,   0x100
.set _fiqstack_size,      0x100
.set _irqstack_size,      0x100
.set _svcstack_size,    0x10000
.set _abtstack_size,      0x100
.set _undstack_size,      0x100

/* Program Status Register Control bits (see: DDI0406C.D B1.3.3, DDI0406C.D B1.3.1) */
.set _psr_c_mode_usr, ((0x10 | 0x0) << 0) 
.set _psr_c_mode_fiq, ((0x10 | 0x1) << 0) 
.set _psr_c_mode_irq, ((0x10 | 0x2) << 0) 
.set _psr_c_mode_svc, ((0x10 | 0x3) << 0)
.set _psr_c_mode_abt, ((0x10 | 0x7) << 0)
.set _psr_c_mode_und, ((0x10 | 0xB) << 0)
.set _psr_c_mode_sys, ((0x10 | 0xF) << 0)
.set _psr_c_fiqdis,   (           1 << 6)
.set _psr_c_irqdis,   (           1 << 7)

/* Change Processor State bits (see: QRC0001 Processor Modes) */
.set _cps_mode_usr, 16
.set _cps_mode_fiq, 17
.set _cps_mode_irq, 18
.set _cps_mode_svc, 19
.set _cps_mode_abt, 23
.set _cps_mode_und, 27
.set _cps_mode_sys, 31

.align 4
.section .text.init
.globl init
init:
	/* usr/sys stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	cpsid if, _cps_mode_sys
	ldr sp, =_usrsysstack+_usrsysstack_size

	/* abt stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	cpsid if, _cps_mode_abt
	ldr sp, =_abtstack+_abtstack_size

	/* und stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	cpsid if, _cps_mode_und
	ldr sp, =_undstack+_undstack_size

	/* irq stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	cpsid if, _cps_mode_irq
	ldr sp, =_irqstack+_irqstack_size

	/* fiq stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	cpsid if, _cps_mode_fiq
	ldr sp, =_fiqstack+_fiqstack_size

	/* svc stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	cpsid if, _cps_mode_svc
	ldr sp, =_svcstack+_svcstack_size

	/* TODO? handle sys mode */

	/* TODO create 'usr handler' to jump back into svc mode */
	/* TODO set usr sp */

	bl main
1:	wfi      /* sleep CPU forever */
	b 1b
/* end section */

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

