; 	David @InfinitelyManic
;	bare_boot_up.asm ;bare minimum boot up Assembly code for Tiva C EK-TM4C1294XL Cortex-M4
;	Using Code Composer Studio with ARM Compiler
; 	Default Linker Command file for the Texas Instruments TM4C123GH6PM * This is derived from revision 15071 of the TivaWare Library.
;	Code derived from ARM Assembly Language, 2nd Edition, W. Hohl, C. Hinds
;	03/21/2016

	.global myStart, myStack, ResetISR, Vecs, _c_int00, _main

	.sect ".myCode" ; This can be whatever you want it to be...
myStart:
		; Setup sysclock {DIV/4, PLL, XTAL_16MHz, OSC_Main}
		; system control base is 0x400fe000 == SYSCTL_SYSCTL_DID0 Device ID 0
		movw	r0, #0xe000
		movt	r0, #0x400f			; SYSCTL_SYSCTL_DID0 = base  = 0x400fe000
		mov	r2, #0x60			; offset 0x60 = SYSCTL_SYSCTL_RCC= Run-Mode Clock Config
		movw	r1, #0x0540
		movt	r1, #0x01c0			; 0x01c00540  = 0001 1100 0000 0000 0101 0100 0000
		str	r1, [r0,r2]			; write the register's contents

		; enable SYSCTL_RCGGPIO_R5 clock = GPIO Run-Mode Clock Gating Control for register five (5)
		movw	r2, #0x608			; offset for SYSCTL_SYSCTL_RCGCGPIO
		ldr	r1, [r0,r2]
		orr	r1, r1, #0x20			; 0b10,0000 = GPIO Reg 4 - Port F
		str	r1, [r0,r2]			; SYSCTL_RCGCGPIO = 0x20

		; set direction (input | output) using GPIODIR
		; Address for LED on APB GPIO Port F is 0x40025000
		movw	r0, #0x5000
		movt	r0, #0x4002			;
		movw	r2, #0x400			; offset for GPIO_PORTF_GPIO_DIR
		mov	r1, #0xe			; 0b1110; must be set for output
		str	r1, [r0,r2]			; 0x40025400 = 0b1110 = 0xe

		; enable pin by setting the GPIO_PORTF_GPIO_DEN
		movw 	r2, #0x51c			; offset for Digital ENable reg
		str 	r1, [r0,r2]			; 0x4002551c = 0b1110 = 0xe
		sub 	r7, r7, r7			; zero out
		mov 	r6, #2				; 0b10

mainloop:
		; turn on LED
		str r6, [r0,#0x38]
		movt	r7, #0xf4
spin:
		subs	r7, r7, #1
		bne 	spin
		; change colors
		cmp		r6, #8
		ite		lt
		lsllt	r6, r6, #1
		movge	r6, #2
		b mainloop

	b myStart
	.text

	; This is the Reset Handler
_c_int00:
		b myStart

	; This is the dummy Fauly handler
NmISR:
		b $

	; This is the dummy Fault Handler
FaultISR:
		b $

	; Define the stack
myStack: .usect ".stack", 0x400

	; Interrupt vector table {abbr}
		.retain ".intvecs"	; this is for the linker
		.sect ".intvecs"
Vecs:
		.word myStack
		.word _c_int00
		.word NmISR
		.word FaultISR
		.word 0
