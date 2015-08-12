
nasm -felf32 boot.s -o boot.o
i686-elf-ld -T l.ld boot.o
