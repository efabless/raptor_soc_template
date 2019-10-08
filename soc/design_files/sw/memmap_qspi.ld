<%
let memSize = 8;
let memoryAddress = 0;
for (let addr in base_address) {
    if (base_address[addr].component === 'ahb2mem') {
        memoryAddress = addr;
        break;
    } 
}
if (base_address[memoryAddress]) {
	memSize = parseInt(base_address[memoryAddress].options.mem_size) || 8;
}
let memoryHexAddress = Number(memoryAddress << 4*4).toString(16);
let memoryHexSize = Number(memSize * 1024).toString(16);
%>
MEMORY
{
    rom(RX)   : ORIGIN = 0x00000000, LENGTH = 0x100000        /* ROM starts at 0 and has a length of 1MB */
    ram(WAIL) : ORIGIN = 0x<%=memoryHexAddress%>, LENGTH = 0x<%=memoryHexSize%>
}
ENTRY(Reset_Handler)
SECTIONS
{
    .text : {
        . = ORIGIN(rom);
        . = ALIGN(4);
        *(.isr_vector*)
        . = ALIGN(4);
        . = 0x100;
        *(.text*)
        *(.rodata*)
    } > rom
    .bss :
    {
        . = ALIGN(4);
        __bss_start__ = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end__ = .;
    } > ram
    .data : { *(.data*) } > ram
    .stack_dummy (COPY):
    {
        *(.stack*)
    } > ram
    __StackTop = ORIGIN(ram) + LENGTH(ram);
    __StackLimit = __StackTop - SIZEOF(.stack_dummy);
}