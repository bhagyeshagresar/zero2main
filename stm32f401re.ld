MEMORY
{
    flash (rx)  : ORIGIN = 0x08000000, LENGTH = 512K
    ram   (rwx) : ORIGIN = 0x20000000, LENGTH = 96K
}


_eram = ORIGIN(ram) + LENGTH(ram);
_stack = _eram; /* stack starts at the end of RAM and grows downward */

SECTIONS
{
    .ivt 0x08000000 : ALIGN(4)
    {
        KEEP(*(.ivt))
    } > flash

    .text : ALIGN(4)
    {
        *(.text*)
        . = ALIGN(4);
        _etext = .;
    } > flash


     /* Initial (constant) values for data is placed in flash after the program code */
    _idata = LOADADDR(.data);

    .data : ALIGN(4)
    {
        _data = .;
        *(.data*)
        . = ALIGN(4);
        _edata = .;
    } > ram AT > flash

    .bss : ALIGN(4)
    {
        _bss = .;
        *(.bss*)
        . = ALIGN(4);
        _ebss = .;
        PROVIDE(_end = .);
    } > ram



}