myos.bin : ./boot/boot.o ./kernel/kernel.o ./boot/linker.ld
	ld -T ./boot/linker.ld -m elf_i386 -o myos.bin ./kernel/kernel.o ./boot/boot.o

./kernel/kernel.o : ./kernel/kernel.c
	gcc -c ./kernel/kernel.c -o ./kernel/kernel.o -ffreestanding -nostdlib -m32

./boot/boot.o : ./boot/boot.s
	gcc -c ./boot/boot.s -o ./boot/boot.o -m32
