; 	David @InfinitelyManic
;	bare_boot_up.asm ;bare minimum boot up Assembly code for Tiva C EK-TM4C1294XL Cortex-M4
;	Using Code Composer Studio with ARM Compiler
; 	Default Linker Command file for the Texas Instruments TM4C123GH6PM * This is derived from revision 15071 of the TivaWare Library.
;	Code derived from ARM Assembly Language, 2nd Edition, W. Hohl, C. Hinds
;	11/04/2016 - WORK IN PROGRESS

	.global myStart, myStack, ResetISR, Vecs, _c_int00, _main
	
	; Interrupt vector table {abbr}
		.retain ".intvecs"	; this is for the linker
		.sect ".intvecs"
Vecs:
		.word myStack
		.word _c_int00
		.word NmISR
		.word FaultISR
		.word 0

	.sect ".myCode" ; Enter your code below 
myStart:
		


	b myStart
	
	
	.text
; ************* interrupts **************

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

.end
