myos.bin : boot.o kernel.o linker.ld
	ld -T linker.ld -m elf_i386 -o myos.bin kernel.o boot.o

kernel.o : kernel.c
	gcc -c kernel.c -o kernel.o -ffreestanding -nostdlib -m32

boot.o : boot.s
	gcc -c boot.s boot.o -m32
