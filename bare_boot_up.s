; 	David @InfinitelyManic
;	bare_boot_up.asm ;bare minimum boot up Assembly code for Tiva C EK-TM4C1294XL Cortex-M4
;	Using Code Composer Studio with ARM Compiler
; 	Default Linker Command file for the Texas Instruments TM4C123GH6PM * This is derived from revision 15071 of the TivaWare Library.
;	Code derived from ARM Assembly Language, 2nd Edition, W. Hohl, C. Hinds
;	03/21/2016 - WORK IN PROGRESS

	.global myStart, myStack, ResetISR, Vecs, _c_int00, _main

	.sect ".myCode" ; This can be whatever you want it to be...
myStart:
		


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
