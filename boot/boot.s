/*
The multiboot header requires a 'magic number', some flags, and a checksum
because of the multiboot standard. The bootloader will the first 8kb to see
if it can find the information.
*/
.section .multiboot
.align 4
	.long 0x1BADB002		 /* 'Magic number' */
	.long 0					 /* Flags - set to 0 because none set */
	.long -(0x1BADB002 + 0)  /* Standard checksum (magic + flags + checksum = 0) */ 
 
/*
This section creates our stack by allocating about 16kb of space in the bss section,
which generally holds statically allocated variables. The space will be reserved once
the bootloader loads our kernel. Note: Stack grows down so bottom comes first.
*/
.section .bss
.align 4
	stack_bottom:
	.skip 4096 * 4
	stack_top:

/*
The linker script specifies _start as the entry point to the kernel and the
bootloader will jump to this position once the kernel has been loaded.
*/
.section .text
.align 4
.global _start
_start:
	/*
	The esp register generally holds the top of the stack. We are setting that
	up here.
	*/
	mov $stack_top, %esp
 
	/*
	Finally call our kernel
	*/
	call kernel_main
	hlt
 