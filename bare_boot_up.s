; 	David @InfinitelyManic
;	bare_boot_up.s ; minimum baremetal boot up ARMv7 code for Tiva C EK-TM4C1294XL Cortex-M4
;	Using Code Composer Studio with ARM Compiler
; 	Default Linker Command file for the Texas Instruments TM4C123GH6PM * This is derived from revision 15071 of the TivaWare Library.
;	Code derived from ARM Assembly Language, 2nd Edition, W. Hohl, C. Hinds
;	03/21/2016 - WORK IN PROGRESS
; 
; Define the stack
myStack: .usect ".stack", 0x400

; Interrupt vector table {abbr}
		.retain ".intvecs"		; this is for the linker
		.sect ".intvecs"
Vecs:
		.word myStack			; stack pointer
		.word _c_int00			; This is the Reset handler
		.word NmISR
		.word FaultISR
		.word 0
		
		.global myStack, Vecs, _c_int00, NmISR, FaultISR, myStart

	.sect ".myCode" 			; Enter your code below ****************************
myStart:
		


	b myStart
	; *******************************************************************************
		
; ************* interrupts **************		
	.text
_c_int00:						; This is the Reset handler
		b myStart
NmISR: 							; This is the dummy Fault handler
		b $
FaultISR:						; This is the dummy Fault Handler
		b $
.end
