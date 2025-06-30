# Zero2Main









start from scratch

step 1: Install the GNU Arm Embedded Toolchain by running : sudo apt install gcc-arm-none-eabi
This package provides a cross-compiler toolchain for ARM targets. It includes:

arm-none-eabi-gcc: The C compiler for ARM targets that don’t run an OS (bare metal).

arm-none-eabi-as: The assembler.

arm-none-eabi-ld: The linker.

arm-none-eabi-gdb: Debugger (optional depending on version).

Newlib: A small C standard library implementation for embedded systems.


If you're developing firmware for microcontrollers (like STM32, nRF52, or LPC boards), you use gcc-arm-none-eabi to compile your C or C++ code into machine code for the target MCU.


step 2: run : arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -std=c11 -g -O0 -c myProgram.c -o myProgram.o
This command is compiling a C source file (myProgram.c) for a Cortex-M4 microcontroller using the GNU Arm Embedded Toolchain, producing an object file (myProgram.o), which is a compiled binary not yet linked.

arm-none-eabi-gcc: 	The ARM GCC cross-compiler for bare-metal embedded development.
-mcpu=cortex-m4:	Target the Cortex-M4 core (important for instruction set and FPU settings).
-mthumb:    	Use Thumb instruction set, which is typical for Cortex-M MCUs (smaller, more efficient).
-std=c11:	Use the C11 standard for compiling the C code.
-g:	Generate debug information (for tools like GDB).
-O0:	Set optimization level to none (easier to debug, slower code).
-c:	Compile only, do not link. Produces .o (object) file.
myProgram.c:	Your input C source file.
-o myProgram.o: 	Output file name: compiled object file.

You cannot flash this file directly to a microcontroller — it must first be linked with startup code, a linker script, and possibly other .o files into a final ELF or binary image (e.g., .elf, .bin, or .hex).


step 3: running arm-none-eabi-objdump -d myProgram.o
This step disassembles the object file myProgram.o, converting the compiled machine code back into human-readable assembly instructions.

arm-none-eabi-objdump	Tool that displays information about binary files (object files, ELF files, etc.).
-d	Disassemble the machine code sections (like .text) into ARM/Thumb assembly.
myProgram.o	The object file to analyze (compiled with -c earlier).

Output: 
myProgram.o:     file format elf32-littlearm


Disassembly of section .text:

00000000 <main>:
   0:	b480      	push	{r7}
   2:	af00      	add	r7, sp, #0
   4:	2300      	movs	r3, #0
   6:	4618      	mov	r0, r3
   8:	46bd      	mov	sp, r7
   a:	bc80      	pop	{r7}
   c:	4770      	bx	lr



step 4: Look at the size of the object file by running : arm-none-eabi-size myProgram.o

Output:
text	   data	    bss	    dec	    hex	filename
  14	      0	      0	     14	      e	myProgram.o


step 5: If we run arm-none-eabi-gcc myProgram.o -o myProgram.elf
We get bunch of linker errors  because you're trying to compile and link a bare-metal embedded program using arm-none-eabi-gcc without providing essential components, like:

    A linker script

    Startup code

    Minimal system call stubs (_sbrk, _write, _read, etc.)

These missing pieces cause the linker to complain about undefined references to system-level functions that don't exist in bare-metal environments unless you implement or stub them.


step 6: Try running  arm-none-eabi-gcc --specs=nosys.specs myProgram.o -o myProgram.elf

--specs=nosys.specs tells the linker not to expect full system call support, and instead to use stub implementations that return failure codes (like -1). This avoids full linkage errors for functions like _write() — but still generates warnings, because those functions exist, but do nothing useful. So printf() and write() will compile but will not do anything useful.


step 7: Run arm-none-eabi-size myProgram.elf
Output;
text	   data	    bss	    dec	    hex	filename
7860	   1364	    808	  10032	   2730	myProgram.elf

.elf file - It is a final linked output which is produced by linking multiple .o files + linker script + libraries


step 8: Look at the disassembly with ObjDump: arm-none-eabi-objdump -d myProgram.elf

Output:

There are many functions other than the main function like from memset, runtime library code, newlib.

Addresses of the instructions for these functions are placed an order of maganitude away from the flash memory address of this microcontroller which starts at 0x8000000
and the reason for that is that without a specified linker script GCC uses a default one that isn't tailored for this micrcontroller


step 9: arm-none-eabi-gcc myProgram.o -o myProgram.elf --specs=nosys.specs -Wl,--verbose
This tells GCC to linke the object file, output an elf file and use nosys.specs spec file to avoid full system dependencies and pass the verbose flag to the linker to see how exactly the linking process works.


step 10: arm-none-eabi-gcc -nolibc -nostartfiles -Wl, --verbose myProgram.o myProgram.elf
-nolibc	Don't link the standard C library (libc.a)
-nostartfiles	Don’t use the default startup files (like crt0.o, crtbegin.o) — you’re fully in control
-Wl,--verbose	Pass --verbose to the linker (ld) — show what it's doing (search paths, linker script, libraries, etc.)

output:
/usr/lib/gcc/arm-none-eabi/13.2.1/../../../arm-none-eabi/bin/ld: mode armelf
attempt to open myProgram.o succeeded
myProgram.o
attempt to open /usr/lib/gcc/arm-none-eabi/13.2.1/libgcc.so failed
attempt to open /usr/lib/gcc/arm-none-eabi/13.2.1/libgcc.a succeeded
/usr/lib/gcc/arm-none-eabi/13.2.1/libgcc.a
/usr/lib/gcc/arm-none-eabi/13.2.1/../../../arm-none-eabi/bin/ld: warning: cannot find entry symbol _start; defaulting to 00008000

We get the warning because we are still linking with the default linker script.
The linker (ld) is trying to find a symbol called _start, which is the default entry point for programs — the address where the program begins executing. Since it can't find _start, it defaults to address 0x00008000.


step 11: We will create a new linker script: arm-none-eabi-gcc myProgram.o -o myProgram.elf -nolibc -nostartfiles -T stm32f401re.ld -Wl,--verbose

Output: Empty linker script

GNU ld (2.42-1ubuntu1+23) 2.42
  Supported emulations:
   armelf
opened script file stm32f401re.ld
using external linker script:
==================================================

==================================================
/usr/lib/gcc/arm-none-eabi/13.2.1/../../../arm-none-eabi/bin/ld: mode armelf
attempt to open myProgram.o succeeded
myProgram.o
attempt to open /usr/lib/gcc/arm-none-eabi/13.2.1/libgcc.so failed
attempt to open /usr/lib/gcc/arm-none-eabi/13.2.1/libgcc.a succeeded
/usr/lib/gcc/arm-none-eabi/13.2.1/libgcc.a


after diassembling the object file and checking the size we can confirm that now we have a clean slate

myProgram.elf:     file format elf32-littlearm


Disassembly of section .text:

00000000 <main>:
   0:	b480      	push	{r7}
   2:	af00      	add	r7, sp, #0
   4:	2300      	movs	r3, #0
   6:	4618      	mov	r0, r3
   8:	46bd      	mov	sp, r7
   a:	bc80      	pop	{r7}
   c:	4770      	bx	lr

  text	   data	    bss	    dec	    hex	filename
    14	      0	      0	     14	      e	myProgram.elf  


step 12: Lets starting the first code the cpu will execute: the startup file.

Write the startup.c and the linker script as described in the Artful bytes video

1: arm-none-eabi-gcc -mcpu=cortex-m0 -mthumb -std=c11 -g -O0 -c startup_stm32f401re.c -o startup_stm32f401re.o
The above line compiles your startup code into an object file

2: arm-none-eabi-gcc -nolibc -nostartfiles -T stm32f401re.ld myProgram.o startup_stm32f401re.o -o myProgram.elf
The above line is linking together object files to produce a firmware image(myProgram.elf) for a bare-metal target


step 13: Install Cortex Debug Exension and create a launch.json file

Cortex Debug Extension:
VS Code ← Cortex-Debug → GDB ←→ Debug Server (OpenOCD, J-Link, etc.) ←→ MCU

    It launches gdb (e.g., gdb-multiarch)

    Connects to a debug server (e.g., OpenOCD)

    Controls your microcontroller through SWD or JTAG

A launch.json file in Visual Studio Code (VS Code) defines how a program is launched and debugged.
It tells VS Code what debugger to use, what binary to load, what hardware or environment to target, and how to run or attach to your program.


