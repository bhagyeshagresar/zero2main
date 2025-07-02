
# Zero2Main

A from-scratch walkthrough for understanding the embedded build process and how code reaches `main()` on a bare-metal ARM system.
This project was implemented for STM32F401RE MCU. Nothing in this project is particularly new. This was just a small learning project for me to
understand what happens when code excution gets to main(). Thanks Artful Bytes for helping me understand this process.

References : https://github.com/artfulbytes/how_a_microcontroller_starts_video
---

## ✅ Step 1: Install the GNU Arm Embedded Toolchain

Run:

```bash
sudo apt install gcc-arm-none-eabi
```

This package provides a cross-compiler toolchain for ARM targets. It includes:

- `arm-none-eabi-gcc`: The C compiler for ARM targets that don’t run an OS (bare metal)
- `arm-none-eabi-as`: The assembler
- `arm-none-eabi-ld`: The linker
- `arm-none-eabi-gdb`: Debugger (optional depending on version)
- **Newlib**: A small C standard library for embedded systems

Use this toolchain to compile your firmware for microcontrollers like STM32, nRF52, or LPC series.

---

## ✅ Step 2: Compile your source file

Run:

```bash
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -std=c11 -g -O0 -c myProgram.c -o myProgram.o
```

This compiles `myProgram.c` for a Cortex-M4 MCU and generates an object file `myProgram.o` (not yet executable or linkable).

### Explanation:

- `-mcpu=cortex-m4`: Target the Cortex-M4 core
- `-mthumb`: Use Thumb instruction set (smaller instructions)
- `-std=c11`: Use the C11 standard
- `-g`: Generate debug information
- `-O0`: No optimization (easier to debug)
- `-c`: Compile only (do not link)
- `-o`: Output object file

---

## ✅ Step 3: Disassemble the object file

Run:

```bash
arm-none-eabi-objdump -d myProgram.o
```

This disassembles the `.o` file to human-readable ARM assembly.

Sample output:

```
myProgram.o:     file format elf32-littlearm

Disassembly of section .text:

00000000 <main>:
   0:	b480      	push	{r7}
   2:	af00      	add	r7, sp, #0
   ...
```

---

## ✅ Step 4: View object size

Run:

```bash
arm-none-eabi-size myProgram.o
```

Sample output:

```
text	   data	    bss	    dec	    hex	filename
14	       0	       0	     14	       e	myProgram.o
```

---

## ✅ Step 5: Try linking (expect failure)

Run:

```bash
arm-none-eabi-gcc myProgram.o -o myProgram.elf
```

You’ll get linker errors because you're missing:

- A linker script
- Startup code
- System call stubs (`_sbrk`, `_write`, `_read`, etc.)

---

## ✅ Step 6: Try again with nosys

Run:

```bash
arm-none-eabi-gcc --specs=nosys.specs myProgram.o -o myProgram.elf
```

This avoids some linker errors by providing **dummy stubs** for system calls (they’ll compile but not work at runtime).

---

## ✅ Step 7: Size of `.elf` file

```bash
arm-none-eabi-size myProgram.elf
```

Sample output:

```
text	   data	    bss	    dec	    hex	filename
7860	   1364	    808	  10032	   2730	myProgram.elf
```

---

## ✅ Step 8: Disassemble `.elf` file

```bash
arm-none-eabi-objdump -d myProgram.elf
```

Output includes many runtime and library functions (e.g. `memset`, Newlib), and their addresses may not match the Flash range for STM32 (usually `0x08000000`). This is because the **default linker script is being used**.

---

## ✅ Step 9: Verbose linker output

```bash
arm-none-eabi-gcc myProgram.o -o myProgram.elf --specs=nosys.specs -Wl,--verbose
```

This shows the linker script and files used. It helps you debug memory layout issues.

---

## ✅ Step 10: Use full manual control

```bash
arm-none-eabi-gcc -nolibc -nostartfiles -Wl,--verbose myProgram.o -o myProgram.elf
```

- `-nolibc`: Don’t link the C standard library
- `-nostartfiles`: Don’t use startup files like `crt0.o`
- `-Wl,--verbose`: Pass `--verbose` to the linker

Expected warning:

```
ld: warning: cannot find entry symbol _start; defaulting to 00008000
```

This means the linker couldn't find an entry point and is guessing.

---

## ✅ Step 11: Use your own linker script

```bash
arm-none-eabi-gcc myProgram.o -o myProgram.elf -nolibc -nostartfiles -T stm32f401re.ld -Wl,--verbose
```

If `stm32f401re.ld` is empty, the linker falls back to defaults.

Once a proper script is provided, the `.text` section is placed at address `0x08000000` (matching STM32 Flash).

Disassembly confirms the address:

```
00000000 <main>:
   ...
```

Size:

```
text	   data	    bss	    dec	    hex	filename
14	       0	       0	     14	       e	myProgram.elf
```

---

## ✅ Step 12: Add a startup file

### 1. Compile the startup code:

```bash
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -std=c11 -g -O0 -c startup_stm32f401re.c -o startup_stm32f401re.o
```

### 2. Link everything:

```bash
arm-none-eabi-gcc -nolibc -nostartfiles -T stm32f401re.ld myProgram.o startup_stm32f401re.o -o myProgram.elf
```

This links your program with startup code and a custom linker script — you're now in control of everything before `main()`!

---

## ✅ Step 13: Debug with VS Code + Cortex-Debug

### 📦 Install:
- `Cortex-Debug` extension for Visual Studio Code

### 🔁 How it works:

```
VS Code ← Cortex-Debug → GDB ←→ OpenOCD / J-Link / pyOCD ←→ Microcontroller
```

It:
- Launches GDB (e.g., `gdb-multiarch`)
- Connects to debug server (OpenOCD, J-Link, etc.)
- Uses SWD/JTAG to control the MCU

### 🛠 Add a `.vscode/launch.json`

Example:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Cortex Debug",
      "type": "cortex-debug",
      "request": "launch",
      "executable": "${workspaceFolder}/myProgram.elf",
      "cwd": "${workspaceFolder}",
      "runToEntryPoint": "main",
      "device": "STM32F401RE",
      "servertype": "openocd",
      "gdbPath": "gdb-multiarch",
      "configFiles": [
        "interface/stlink.cfg",
        "target/stm32f4x.cfg"
      ],
      "preLaunchCommands": [
        "monitor reset halt",
        "load",
        "monitor reset init"
      ],
      "internalConsoleOptions": "openOnSessionStart"
    }
  ]
}
```

This lets you debug right from VS Code with breakpoints, watch variables, and step through your embedded code.

---