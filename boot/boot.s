.intel_syntax noprefix

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
	page_table_4:
		.skip 4096
	page_table_3:
		.skip 4096
	page_table_2:
		.skip 4096
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
	mov stack_top, %esp

	# call check_multiboot
	call check_CPUID
	call check_long_mode

	/*
	Finally call our kernel
	*/
	call kernel_main
	hlt

/*
Check for multiboot support
*/
check_multiboot:
    cmp eax, 0x36d76289
    jne no_multiboot
    ret

/*
CPUID allows us to see the details of our processor, including support for long mode. Before we
can use that instruction, we need to confirm that processor allows using it. To do so, we check
our flags to see if ID bit (number 21) can be flipped. If it can, we have CPUID support.
*/
check_CPUID:
	pushfd        		# Saves the flags
	pop eax       		# Stores them onto the register
	mov ecx, eax  		# Store additional copy onto ecx register

	xor eax, 1 << 21    # Flip bit number 21 on eax - this is the ID bit

	push eax      		# Push eax back onto the stack
	popfd				# Now pop it but back into the flags register

	pushfd				# Save flag on stack again (this time with the modified bit)
	pop eax				# Store modified flag into the register again

	push ecx			# Push the correct flags back onto the stack (UN-modifed)
	popfd				# Store the correct flags back onto the flags register

	# Now compare the flags
	xor eax, ecx
	jz no_CPUID
	ret

/*
This checks for long mode by first checking for the processor's extended function support. If
it does find the support, it then checks bit 29 in the d register to see if there is long mode
support.
*/
check_long_mode:
	# Checks for extended functions
	mov eax, 0x80000000    # Set the A-register to 0x80000000
	cpuid                  # CPU identification will save maximum input value for CPUID info
	cmp eax, 0x80000001    # Check to see if it is greater than 0x80000000
	jb no_long_mode        # There is no long mode if it is less than 0x80000000

	# Checks for long mode
	mov eax, 0x80000001    # Set the A-register to 0x80000001.
	cpuid                  # CPU identification.
	test edx, 1 << 29      # Test if the LM-bit, which is bit 29, is set in the D-register.
	jz no_long_mode        # They aren't, there is no long mode.
	ret

/*
This subroutine sets the error number to 0 and then calls the print error routine.
An error of 2 means that we did not find multiboot support.
*/
no_multiboot:
	mov al, 0x30
	call print_error
	ret

/*
This subroutine sets the error number to 1 and then calls the print error routine.
An error of 1 means that we could not find CPUID support.
*/
no_CPUID:
	mov al, 0x31
	call print_error
	ret

/*
This subroutine sets the error number to 2 and then calls the print error routine.
An error of 2 means that we did not find long mode support.
*/
no_long_mode:
	mov al, 0x32
	call print_error
	ret

/*
This little subroutine will print out an error for us whenever there is an issue. For
reference, the terminal buffer begins at the address 0xB8000.
*/
print_error:
	mov byte ptr [0xB8000], 0x45 # E
	mov byte ptr [0xB8002], 0x72 # r
	mov byte ptr [0xB8004], 0x72 # r
	mov byte ptr [0xB8006], 0x6f # o
	mov byte ptr [0xB8008], 0x72 # r
	mov byte ptr [0xB800a], 0x3a # :
	mov byte ptr [0xB800c], al
	hlt



