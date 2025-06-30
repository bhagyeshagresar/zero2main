
extern int main(void);

//Symbols defined by the linker script
extern unsigned int _stack;


//called immediately after reset
void isr_reset(void){
    main();

    while(1);
}

//If the CPU encounters a fault, it endup here
void isr_hardfault(void){
    
    while(1);


}


#define IVT_ARRAY_SIZE (48U)

// typedef return_type (*alias_name)(parameter_types);
//
typedef void (*isr_t)(void);
__attribute((used, section(".ivt"))) //we need to place this table at the start of flash memory in linker script. Set it to "used" to prevent the compiler from optimizing
static const isr_t ivt[IVT_ARRAY_SIZE]=
{
    (isr_t)&_stack,
    isr_reset,
    0, //isr_nmi
    isr_hardfault,
    //incomplete table, the rest of the ISRs defaults to value 0. Common practice other wise is to give these a default handler and attribute
    //to weak.


};

