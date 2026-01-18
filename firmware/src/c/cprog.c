#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

#include "uart.h"
#include "uart68681.h"
#include "asm/entry.h"
#include "asm/irq.h"

void* memset(void* s, int c, size_t n)
{
    unsigned char* p = s;

    for (size_t i = 0; i < n; i++)
    {
        p[i] = (unsigned char)c;
    }

    return s;
}

extern int printf_(const char* format, ...);

// Pass the sp value
extern void start_first_task(uint32_t sp);

typedef struct _p_ctx {
    uint32_t *sp;           // saved SP for this task
    uint32_t *stack_top;    // one-past-end
    bool runnable;
} p_ctx;

static p_ctx  processes[4];
static int    current_i;
static p_ctx* current;

#define PROCESS_STACK_SIZE 256

static uint32_t process1_stack[PROCESS_STACK_SIZE];
static uint32_t process2_stack[PROCESS_STACK_SIZE];
static uint32_t process3_stack[PROCESS_STACK_SIZE];
static uint32_t process4_stack[PROCESS_STACK_SIZE];

static p_ctx* pick_next()
{
    int max = (sizeof(processes) / sizeof(processes[0])) - 1;
    int candidate = current_i + 1;
    if (candidate > max)
        candidate = 0;
    
    current   = &processes[candidate];
    current_i = candidate;
    return current;
}

uint32_t* schedule_from_isr(isr_trapframe_t *tf)
{
    // 1. save current task SP
    current->sp = (uint32_t*)tf;

    // 2. pick next runnable task
    current = pick_next();

    // 3. return next stack SP
    return current->sp;
}

// Constructs exception stack frame
static void start_process(p_ctx* p, void (*start_addr)(void))
{
    isr_trapframe_t* tf = (isr_trapframe_t*)p->stack_top;
    tf--;
    
    memset(tf, 0, sizeof(*tf));

    tf->frame.sr     = 0x2000; /* S=1 IPL=000 */
    tf->frame.pc     = (unsigned long)start_addr;
    tf->frame.fmtvec = FMTVEC(0x0, 28*4);

    p->sp  = (uint32_t*)tf;
    return;
}

static void process1_func(void)
{
    while (1)
    {
        _putchar('.');

        for (int i = 0; i < 1000000; i++) {}
    }
}

static void process2_func(void)
{
    while (1)
    {
        _putchar('+');

        for (int i = 0; i < 2000000; i++) {}
    }
}

static void process3_func(void)
{
    while (1)
    {
        _putchar('O');

        for (int i = 0; i < 3000000; i++) {}
    }
}

extern void process4_func(void);

// Configures the programmable interrupt timer (DUART) for 100ms interrupts
static void setup_pic(void)
{
    uart->imr  = 0x00; // Reset interrupt sources
    uart->acr  = 0xF0; // I know it used to be 0x80, add TIMER_MODE: 6 | X1/16: 54
    
    // N = (period * (XTAL_FREQ/16)) / 2
    uint16_t n = 112;
    uart->ctur = (uint8_t)((n >> 8) & 0xFF);
    uart->ctlr = (uint8_t)(n & 0xFF);

    (void)uart->cnt_start;  // Start the counter by reading magic register
    uart->imr  = 0x08; // Enable timer interrupt
}

void handle_uart_int(void)
{
    (void)uart->cnt_stop; // Clear timer interrupt
    return;
}

/*---------------------------------------------------------------------------
 *  Entry
 *---------------------------------------------------------------------------*/

void c_prog_entry(void) {
    
    memset(&processes[0], 0, sizeof(p_ctx));
    memset(&processes[1], 0, sizeof(p_ctx));
    memset(&processes[2], 0, sizeof(p_ctx));
    memset(&processes[3], 0, sizeof(p_ctx));

    // Configure the processes
    processes[0].stack_top = process1_stack + PROCESS_STACK_SIZE;
    processes[1].stack_top = process2_stack + PROCESS_STACK_SIZE;
    processes[2].stack_top = process3_stack + PROCESS_STACK_SIZE;
    processes[3].stack_top = process4_stack + PROCESS_STACK_SIZE;

    start_process(&processes[0], process1_func);
    start_process(&processes[1], process2_func);
    start_process(&processes[2], process3_func);
    start_process(&processes[3], process4_func);

    current_i = 0;
    current = &processes[0];

    setup_pic();

    start_first_task((uint32_t)processes[current_i].sp);

    irq_enable();

    while (1) {
    }

    return;
}

