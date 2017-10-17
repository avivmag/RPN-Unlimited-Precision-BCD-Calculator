all: calc

calc:	
	nasm -f elf calc.asm -o calc.o
	gcc -m32 -Wall -g calc.o -o calc.bin
