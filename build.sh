
nasm -felf32 b.s -o b.o
i686-elf-ld -T l.ld b.o
