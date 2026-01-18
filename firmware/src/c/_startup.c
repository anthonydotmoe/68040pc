#include <stdint.h>

#include "asm/irq.h"

/* Symbols from the linker script, all 32-bit aligned */

extern uint32_t __data_load[];  // src ROM address
extern uint32_t __data_start[]; // dst RAM address
extern uint32_t __data_end[];   // dst+len RAM address
extern uint32_t __bss_start[];  // dst RAM address
extern uint32_t __bss_end[];    // dst+len RAM address
extern uint32_t __stack_top;

/* Forward declarations ----------------------------------------------------- */

void _exc_ResetHandler(void) __attribute__((noreturn));
void __exc_DefaultExceptionHandler(void);

/* Exception handler prototypes */

void _exc_BusError(void);
void _exc_AddressError(void);
void _exc_IllegalInstruction(void);
void _exc_ZeroDivide(void);
void _exc_CHKInstruction(void);
void _exc_TRAPVInstruction(void);
void _exc_PrivilegeViolation(void);
void _exc_Trace(void);
void _exc_Line1010Emulator(void);
void _exc_Line1111Emulator(void);
void _exc_HardwareBreakpoint(void);
void _exc_CoprocessorProtocolViolation(void);
void _exc_FormatError(void);
void _exc_UninitializedInterrupt(void);
void _exc_SpuriousInterrupt(void);
void _exc_Autovector1(void);
void _exc_Autovector2(void);
void _exc_Autovector3(void);
void _exc_Autovector4(void);
void _exc_Autovector5(void);
void _exc_Autovector6(void);
void _exc_Autovector7(void);
void _exc_Trap0(void);
void _exc_Trap1(void);
void _exc_Trap2(void);
void _exc_Trap3(void);
void _exc_Trap4(void);
void _exc_Trap5(void);
void _exc_Trap6(void);
void _exc_Trap7(void);
void _exc_Trap8(void);
void _exc_Trap9(void);
void _exc_Trap10(void);
void _exc_Trap11(void);
void _exc_Trap12(void);
void _exc_Trap13(void);
void _exc_Trap14(void);
void _exc_Trap15(void);
void _exc_FPBranchOrSetUnorderedCondition(void);
void _exc_FPInexactResult(void);
void _exc_FPZeroDivide(void);
void _exc_FPUnderflow(void);
void _exc_FPOperandError(void);
void _exc_FPOverflow(void);
void _exc_FPSignalingNAN(void);
void _exc_FPUnimplementedDataType(void);
void _exc_MMUConfigurationError(void);
void _exc_MMUIllegalOperation(void);
void _exc_MMUAccessLevelViolation(void);

/* Weak aliases, undefined handlers defer to the default handler */

void __exc_DefaultExceptionHandler(void)        __attribute__((weak));
void _exc_BusError(void)                        __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_AddressError(void)                    __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_IllegalInstruction(void)              __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_ZeroDivide(void)                      __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_CHKInstruction(void)                  __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_TRAPVInstruction(void)                __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_PrivilegeViolation(void)              __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trace(void)                           __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Line1010Emulator(void)                __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Line1111Emulator(void)                __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_HardwareBreakpoint(void)              __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_CoprocessorProtocolViolation(void)    __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_FormatError(void)                     __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_UninitializedInterrupt(void)          __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_SpuriousInterrupt(void)               __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Autovector1(void)                     __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Autovector2(void)                     __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Autovector3(void)                     __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Autovector4(void)                     __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Autovector5(void)                     __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Autovector6(void)                     __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Autovector7(void)                     __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap0(void)                           __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap1(void)                           __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap2(void)                           __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap3(void)                           __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap4(void)                           __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap5(void)                           __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap6(void)                           __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap7(void)                           __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap8(void)                           __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap9(void)                           __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap10(void)                          __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap11(void)                          __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap12(void)                          __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap13(void)                          __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap14(void)                          __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_Trap15(void)                          __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_FPBranchOrSetUnorderedCondition(void) __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_FPInexactResult(void)                 __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_FPZeroDivide(void)                    __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_FPUnderflow(void)                     __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_FPOperandError(void)                  __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_FPOverflow(void)                      __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_FPSignalingNAN(void)                  __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_FPUnimplementedDataType(void)         __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_MMUConfigurationError(void)           __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_MMUIllegalOperation(void)             __attribute__((weak, alias("__exc_DefaultExceptionHandler")));
void _exc_MMUAccessLevelViolation(void)         __attribute__((weak, alias("__exc_DefaultExceptionHandler")));

/* Default handler just spins for now */
void __exc_DefaultExceptionHandler(void)
{
    for (;;) {
        /* hang */
    }
}

/* Reset handler: initialize C runtime, then call main ---------------------- */

extern int main(void);

void _exc_ResetHandler(void)
{
    irq_disable();

    /* Copy .data from ROM to RAM */
    uint32_t *src = __data_load;
    uint32_t *dst = __data_start;
    while (dst < __data_end) {
        *dst++ = *src++;
    }

    /* Clear .bss section */
    for (dst = __bss_start; dst < __bss_end; ++dst) {
        *dst = 0;
    }
    
    /* Call main */
    (void)main();

    /* Should never get here */
    for (;;) {}
}

/* 68040 exception vector table --------------------------------------------- */

#define VEC(x) ((uint32_t)(uintptr_t)(x))

__attribute__((section(".vectors")))
const uint32_t _exception_vectors[] = {
    /*  0 */ VEC(&__stack_top),
    /*  1 */ VEC(&_exc_ResetHandler),
    /*  2 */ VEC(&_exc_BusError),
    /*  3 */ VEC(&_exc_AddressError),
    /*  4 */ VEC(&_exc_IllegalInstruction),
    /*  5 */ VEC(&_exc_ZeroDivide),
    /*  6 */ VEC(&_exc_CHKInstruction),
    /*  7 */ VEC(&_exc_TRAPVInstruction),
    /*  8 */ VEC(&_exc_PrivilegeViolation),
    /*  9 */ VEC(&_exc_Trace),
    /* 10 */ VEC(&_exc_Line1010Emulator),
    /* 11 */ VEC(&_exc_Line1111Emulator),
    /* 12 */ VEC(&_exc_HardwareBreakpoint),
    /* 13 */ VEC(&_exc_CoprocessorProtocolViolation),
    /* 14 */ VEC(&_exc_FormatError),
    /* 15 */ VEC(&_exc_UninitializedInterrupt),
    
    /* Unassigned, Reserved */

    /* 16 */ VEC(0),
    /* 17 */ VEC(0),
    /* 18 */ VEC(0),
    /* 19 */ VEC(0),
    /* 20 */ VEC(0),
    /* 21 */ VEC(0),
    /* 22 */ VEC(0),
    /* 23 */ VEC(0),

    /* 24 */ VEC(&_exc_SpuriousInterrupt),
    /* 25 */ VEC(&_exc_Autovector1),
    /* 26 */ VEC(&_exc_Autovector2),
    /* 27 */ VEC(&_exc_Autovector3),
    /* 28 */ VEC(&_exc_Autovector4),
    /* 29 */ VEC(&_exc_Autovector5),
    /* 30 */ VEC(&_exc_Autovector6),
    /* 31 */ VEC(&_exc_Autovector7),
    /* 32 */ VEC(&_exc_Trap0),
    /* 33 */ VEC(&_exc_Trap1),
    /* 34 */ VEC(&_exc_Trap2),
    /* 35 */ VEC(&_exc_Trap3),
    /* 36 */ VEC(&_exc_Trap4),
    /* 37 */ VEC(&_exc_Trap5),
    /* 38 */ VEC(&_exc_Trap6),
    /* 39 */ VEC(&_exc_Trap7),
    /* 40 */ VEC(&_exc_Trap8),
    /* 41 */ VEC(&_exc_Trap9),
    /* 42 */ VEC(&_exc_Trap10),
    /* 43 */ VEC(&_exc_Trap11),
    /* 44 */ VEC(&_exc_Trap12),
    /* 45 */ VEC(&_exc_Trap13),
    /* 46 */ VEC(&_exc_Trap14),
    /* 47 */ VEC(&_exc_Trap15),
    /* 48 */ VEC(&_exc_FPBranchOrSetUnorderedCondition),
    /* 49 */ VEC(&_exc_FPInexactResult),
    /* 50 */ VEC(&_exc_FPZeroDivide),
    /* 51 */ VEC(&_exc_FPUnderflow),
    /* 52 */ VEC(&_exc_FPOperandError),
    /* 53 */ VEC(&_exc_FPOverflow),
    /* 54 */ VEC(&_exc_FPSignalingNAN),
    /* 55 */ VEC(&_exc_FPUnimplementedDataType),
    /* 56 */ VEC(&_exc_MMUConfigurationError),
    /* 57 */ VEC(&_exc_MMUIllegalOperation),
    /* 58 */ VEC(&_exc_MMUAccessLevelViolation),

    /* Unassigned, Reserved */

    /* 59 */ VEC(0),
    /* 60 */ VEC(0),
    /* 61 */ VEC(0),
    /* 62 */ VEC(0),
    /* 63 */ VEC(0),

    /* User defined vectors (192) */
    /* Not in the initial ROM vector table */
};
