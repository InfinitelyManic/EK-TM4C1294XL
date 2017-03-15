//      David @InfinitelyManic
//      uart_startup_gnu.s minimum baremetal bootup and uart init for ARMv7 code for Tiva C EK-TM4C1294XL Cortex-M4f

//      ARM Assembly Language Tools
//      Tiva™ TM4C1294NCPDT Microcontroller DATA SHEET
//      http://www.ti.com/lit/ds/symlink/tm4c1294ncpdt.pdf
//      assembly and link:
/*
        arm-none-eabi-as -g uart_startup_gnu.s -o uart_startup_gnu.o && arm-none-eabi-ld uart_startup_gnu.o -o uart_startup_gnu -T startup_gnu.ld                                            
*/
//  Last revision: 03/09/2017 @ 15:32 hours
.syntax unified
.thumb
.bss
.data
        M:      .word 4
        .equ Stack,                     0x200

        // the best thing to do it to include the header file from vendor
        .equ SCS_BASE,                  0x400FE000      // SYSTEM Control Base
        .equ RCGCUART,                  0x618           // UART Run Mode Clock Gating Ctrl
        .equ RCGCGPIO,                  0x608           // GPIO Run Mode Clock Gating Ctrl
        .equ ALTCLKCFG,                 0x138           // Alternate Clock Configuration
        .equ PRGPIO,                    0xA08           // GPIO Peripheral Ready
        .equ PRUART,                    0xA18           // UART Peripheral Ready

        // manual entry if we're not using header file
        .equ UARTn_BASE,                0x4000C000      // UART 0 Base
        .equ GPIO_PORTx_Base,           0x40058000      // Port x Base

        .equ GPIO_PORT_F_Base,          0x4005D000      // Port F Base
        .equ GPIO_PORT_N_Base,          0x40064000      // Port N Base

        .equ GPIO_PORTx_AHB_DIR_R,      0x400           // GPIO Direction
        .equ GPIO_PORTx_AHB_AFSEL_R,    0x420           // Alternate Func Select
        .equ GPIOPUR,                   0x510           // GPIO Pull Up
        .equ GPIO_PORTx_AHB_DEN_R,      0x51C           // Digital Enable
        .equ GPIOLOCK,                  0x520           // GPIO Lock  -
        .equ GPIOCR,                    0x524           // GPIO Commit
        .equ GPIO_PORTx_AHB_AMSEL_R,    0x528           // Analogue Mode Select
        .equ GPIO_PORTx_AHB_PCTL_R,     0x52C           // Port Ctrl

        .equ UARTn_DR_R,                0x000           // Data
        .equ UARTn_RSR_R,               0x004           // Receive Status/Error
        .equ UARTn_FR_R,                0x018           // Flag
        .equ UARTn_IBRD_R,              0x024           // Int Baud Rate Divr
        .equ UARTn_FBRD_R,              0x028           // Frac Baud Rate Divr
        .equ UARTn_LCRH_R,              0x02C           // Line Ctrl
        .equ UARTn_CTL_R,               0x030           // Ctrl
        .equ UARTn_CC_R,                0xFC8           // Clock Config
.align

.global myStack
myStack:
        .space Stack                    // allocate storage for stack STACK_SIZE
.align

// bare interrupt vector table for Cortex-M4
.sect ".isr_vector"
.global Vecs
Vecs:
        .word myStack + Stack           // Stop of stack
        .word _start                    // ResetISR
        .word NMI                       // Non-maskable interrupt
        .word FaultISR                  // Hard fault
        .word IntDefaultHandler         // mpu fault handler
        .word IntDefaultHandler         // bus fault handler
        .word IntDefaultHandler         // usage fault handler

// UART init for UART
.thumb_func
.global init_UART
init_UART:
        // config UART *********************************************************
        ldr r1,=SCS_BASE                // System Control Base
        ldr r2,=RCGCUART
        mov r12, #(1 << 0)              // Provide a clock re UART module n
        str r12,[r1, r2]

        //wait for clock to be ready
        ldr r2,=PRUART                  // UART Peripheral Ready
1:
        ldrh r12, [r1,r2]               // get state - 16 bits
        and r12, r12, #(1 << 0)         // mask GPIO ready bit for UART n
        cmp r12, #0
        beq 1b                          // loop until ready bit is set
        // config UARTn
        ldr r1,=UARTn_BASE              // UARTn Base

        ldr r2,=UARTn_CTL_R
        ldr r12, [r1,r2]
        and r12, #0
        str r12, [r1,r2]                // disable UART by clearing UARTEN bit

        ldr r2,=UARTn_CC_R
        mov r12, #0x0                   // is not 0 then us clock
        str r12, [r1, r2]               // config clock source - default is 00

        ldr r2,=UARTn_IBRD_R
        movw r12, #8                    // IBRD=int(16MHz/(16*115,200))=int()=8
        str r12, [r1, r2]

        ldr r2,=UARTn_FBRD_R
        movw r12, #44                   // FBRD=round(.68056*64+0.5)=44
        str r12, [r1, r2]

        ldr r2,=UARTn_LCRH_R
        movw r12, #0x0060               // serial para [8-N-1, FIFO] 0110|000
        str r12, [r1, r2]

        ldr r2,=UARTn_CTL_R
        movw r12, #0x0301               // enable RXE, TXE & UARTEN = 0000|0011|0000|0001
        str r12, [r1, r2]
        bx lr
        // config UART done *********************************************************
.align


// GPIO init for UART
.thumb_func
.global init_GPIO_4_UART
init_GPIO_4_UART:
        // config GPIO **************************************************
        ldr r1,=SCS_BASE                // System Control Base
        ldr r2,=RCGCGPIO
        mov r12, #(1 << 0)              // Enable clock re GPIO Port x
        str r12,[r1, r2]

        //wait for clock to be ready
        ldr r2,=PRGPIO                  // GPIO Peripheral Ready
1:
        ldrh r12, [r1,r2]               // get state - 16 bits
        and r12, r12, #(1 << 0)         // mask GPIO ready bit for Port x
        cmp r12, #0
        beq 1b                          // loop until ready bit is set

        // config GPIO Port x
        ldr r1,=0x40058000

        ldr r2,=GPIO_PORTx_AHB_DEN_R
        ldr r12, [r1,r2]
        orr r12, r3, #(0b11 << 0)       // 0b0000|0000
        str r12, [r1,r2]                // set pins to enable digital function

        ldr r2,=GPIO_PORTx_AHB_AMSEL_R
        ldr r12, [r1,r2]
        bic r12, #(0b11 << 0)           // 0b0000}0000
        str r12, [r1,r2]                // disable analogue function = 0000|0000

        ldr r2,=GPIO_PORTx_AHB_AFSEL_R
        ldr r12, [r1,r2]
        orr r12, r12, #(0b11 << 0)      // 0b0000|0000
        str r12, [r1,r2]                        // set pins controlled by alt func

        ldr r2,=GPIO_PORTx_AHB_PCTL_R
        ldr r12, [r1,r2]
        orr r12, r12, #(0x11 << 0)      // 0x0000|0000
        str r12, [r1,r2]                        // set pins to digital function
        bx lr
        // config GPIO_4_UART ************** done *******************************
.align
.thumb_func
.global init_GPIO_4_LED_F
init_GPIO_4_LED_F:
        // GPIO init for LED Port F
        ldr r1,=SCS_BASE                // System Control Base

        ldr r2,=RCGCGPIO
        ldr r12, [r1,r2]
        orr r12, r12, #(1 << 5)         // Enable clock re GPIO Port x
        str r12,[r1, r2]
        //wait for clock to be ready
        ldr r2,=PRGPIO                  // GPIO Peripheral Ready
1:
        ldrh r12, [r1,r2]               // get state - 16 bits
        and r12, r12, #(1 << 5)         // get GPIO ready bit for Port x
        cmp r12, #0
        beq 1b                          // loop until ready bit is set
        // config GPIO Port F
        ldr r1,=GPIO_PORT_F_Base        // GPIO Port F AHB:w

        ldr r2,=GPIO_PORTx_AHB_DIR_R    // ********
        ldr r12, [r1,r2]
        orr r12, r12, #0x11             // 0001|00001 PF4, PF0
        str r12, [r1,r2]                // set pins to output

        ldr r2,=GPIO_PORTx_AHB_DEN_R
        ldr r12, [r1,r2]
        orr r12, r12, #0x11             // enable all .... PF4, PF0
        str r12, [r1,r2]                // set pins to enable digital function
        bx lr
.align
.thumb_func
.global init_GPIO_4_LED_N
init_GPIO_4_LED_N:
        // GPIO init for LED Port N
        ldr r1,=SCS_BASE                // System Control Base

        ldr r2,=RCGCGPIO
        ldr r12, [r1, r2]
        orr r12, r12, #(1 << 12)        // Enable clock re GPIO Port x
        str r12,[r1, r2]
        //wait for clock to be ready
        ldr r2,=PRGPIO                  // GPIO Peripheral Ready
1:
        ldrh r12, [r1,r2]               // get state - 16 bits
        and r12, r12, #(1 << 12)        // get GPIO ready bit for Port x
        cmp r12, #0
        beq 1b                          // loop until ready bit is set
        // config GPIO Port N
        ldr r1,=GPIO_PORT_N_Base        // GPIO Port N AHB

        ldr r2,=GPIO_PORTx_AHB_DIR_R    //
        ldr r12, [r1,r2]
        orr r12, r12, #0x03             // 0000|0011 PN1, PN0
        str r12, [r1,r2]                // set pins to output

        ldr r2,=GPIO_PORTx_AHB_DEN_R
        ldr r12, [r1,r2]
        orr r12, r12, #0x03             // PN1, PN0
        str r12, [r1,r2]                // set pins to enable digital function
        bx lr
.align
.thumb_func
.global PortF
PortF:
        ldr r1,=GPIO_PORT_F_Base                // GPIO Port F AHB
        add r1, r1, #0x0044                     // bit-specific addressing
        and r0, r0, #0b00010001
        str r0, [r1]
        bx lr
.align

.thumb_func
.global PortN
PortN:
        ldr r1,=GPIO_PORT_N_Base                // GPIO Port N AHB
        add r1, r1, #0x000c                     // bit-specific addressing
        and r0, r0 ,#0b00000011
        str r0, [r1]
        bx lr
.align


.thumb_func
_delay:
        movw r12, #0xffff
        movt r12, #0x7
1:
        nop
        subs r12, r12, #1
        bpl 1b
        bx lr
.align
.thumb_func
uart_receive:
        ldr r1,=UARTn_BASE              // UARTn Base
        ldr r2,=UARTn_DR_R              // UART Data
        ldr r3,=UARTn_FR_R              // UART Flag
.wait0:
        ldrb r12, [r1,r3]               // get flags
        and r12, r12, #0x00000010       // isolate bit 4 RXFE
        cmp r12, #0x10                  // RXFE
        beq .wait0                      //
        ldrb r0, [r1,r2]
        and r0, r0, #0xff               // clearing
        bx lr
.align


.thumb_func
uart_transmit:
        ldr r1,=UARTn_BASE              // UARTn Base
        ldr r2,=UARTn_DR_R              // UART Data
        ldr r3,=UARTn_FR_R              // UART Flag
.wait1:
        ldrb r12, [r1,r3]               // get flags
        and r12, r12, #0x00000020
        cmp r12, #0x20                  // check for TXFF
        beq .wait1                      //
        strb r0, [r1,r2]                // transmit data
        bx lr
.align
// ******************************************************************
.thumb_func
.global Start
Start:
        bl init_UART                    // init GPIO
        bl init_GPIO_4_UART             // init GPIO for UART
        bl init_GPIO_4_LED_F            // init GPIO for LED F
        bl init_GPIO_4_LED_N            // init GPIO for LED N
.stop0:
        nop
        // Linear congruential generator s/u
        ldr r12,=M
        mov r0, #2                      // init seed
        str r0, [r12]                   // M=1
.loop:
        bl _random

        rbit r0, r0                     // makes the output appear more random
        and r0, r0, #0xff               // mask
        cmp r0, #0x21                   // min ASCII value
        blt .skip
        cmp r0, #0x7e                   // max ASCII value
        bgt .skip

        bl uart_transmit                // print to UART

        // blink leds
        mov r12, r0                     // save copy of r0
//      and r0, r0, #0b00000011         // get first two bits 00xx
        bl PortN                        // toggle PN0 & PN1
        mov r0, r12                     // get copy of r0
//      and r0, r0, #0b00001100         // get bits 2 & 3
        bl PortF                        // toggle PF0 & PF4

        bl _delay                       // keeps the load average when viewing output
.skip:
        b .loop
_random:                        //Linear congruential generator
        ldr r12,=M
        ldr r0,[r12]
        ldr r1,=1664525
        mul r0, r0, r1
        ldr r1,=1013904223
        add r0, r0, r1
        str r0,[r12]
        bx lr
.align

.text
// ************ NVIC interrupts **************
.global _start
.thumb_func
_start:                                 // this is ResetHandler
        b Start                 //
.align

.global NMI
.thumb_func
NMI:                                    // Non-maskable interrupt
        b .
.align

.global FaultISR
.thumb_func
FaultISR:                               // Hard fault
        b .
.align

.global IntDefaultHandler
.thumb_func
IntDefaultHandler:                      // IntDefault handler
        b .
.align

.end
