.code 32

/* stack sizes (see: DDI0406C.D B1-2) */
.set _svcstack_size, 0x10000
.set _usrstack_size,   0x100
.set _abtstack_size,   0x100
.set _undstack_size,   0x100
.set _irqstack_size,   0x100
.set _fiqstack_size,   0x100

/* Program Status Register Control bits (see: DDI0406C.D B1.3.3, DDI0406C.D B1.3.1) */
.set _psr_c_mode_usr, (0b10000 << 0)
.set _psr_c_mode_fiq, (0b10001 << 0)
.set _psr_c_mode_irq, (0b10010 << 0)
.set _psr_c_mode_svc, (0b10011 << 0)
.set _psr_c_mode_abt, (0b10111 << 0)
.set _psr_c_mode_und, (0b11011 << 0)
.set _psr_c_fiqdis,   (      1 << 6)
.set _psr_c_irqdis,   (      1 << 7)

.align 4
.section .text.init
.globl init
init:
	/* abt stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	msr cpsr_c, (_psr_c_irqdis | _psr_c_fiqdis | _psr_c_mode_abt)
	ldr sp, =_abtstack+_abtstack_size

	/* und stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	msr cpsr_c, (_psr_c_irqdis | _psr_c_fiqdis | _psr_c_mode_und)
	ldr sp, =_undstack+_undstack_size

	/* irq stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	msr cpsr_c, (_psr_c_irqdis | _psr_c_fiqdis | _psr_c_mode_irq)
	ldr sp, =_irqstack+_irqstack_size

	/* fiq stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	msr cpsr_c, (_psr_c_irqdis | _psr_c_fiqdis | _psr_c_mode_fiq)
	ldr sp, =_fiqstack+_fiqstack_size

	/* svc stack pointer init (see: DDI0406C.D B1-2, 100748_0609_00_en 6.16) */
	msr cpsr_c, (_psr_c_irqdis | _psr_c_fiqdis | _psr_c_mode_svc)
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
.comm _svcstack, _svcstack_size
.align 4
.comm _usrstack, _usrstack_size
.align 4
.comm _abtstack, _abtstack_size
.align 4
.comm _undstack, _undstack_size
.align 4
.comm _irqstack, _irqstack_size
.align 4
.comm _fiqstack, _fiqstack_size

