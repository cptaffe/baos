
; boot assembly file

; multiboot header constants
mbh.magic: equ 0x1badb002
mbh.flags: equ (1 << 0) | (1 << 1)
mbh.checksum: equ -(mbh.flags + mbh.magic)

; multiboot header
section .multiboot
align 4
dd mbh.magic
dd mbh.flags
dd mbh.checksum

; boot strap stack
section .bsStack, nobits
align 4
bsStackBottom:
resb 0x4000
bsStackTop:

; startup code
section .text
global _start
_start:
	; set stack to bootstrap stack
	mov esp, bsStackTop
	mov ebp, esp

	; allocate screen
	sub esp, 0x10
	mov dword [esp + 0xc], vid.addr
	mov dword [esp + 0x8], vid.h
	mov dword [esp + 0x4], vid.w
	mov dword [esp], 0
	mov edi, esp

	; clear screen
	call clear

	; write string to screen
	mov edi, eax
	mov esi, msg
	mov edx, msg.len
	call write

	pop ebp
	; turn off interrupts, hang
	cli
.hang:
	hlt
	jmp .hang

; display {
;     u32 addr;
;     u32 h;
;     u32 w;
;     u32 off;
; }

; clear(display *s);
; clear screen
clear:
	; grab parameters from display
	mov ebx, edi
	mov edi, [ebx + 0xc]
	mov ecx, [ebx + 0x8]
	mov eax, [ebx + 0x4]
	mul ecx
	mov ecx, eax
	mov eax, 0xf0 | ' '
	cld ; clear direction flag
	rep stosw

	mov eax, ebx ; return display
	ret

; write(display *s, char *msg, size_t len);
; write to screen
write:
	; parameters
	mov eax, edi ; first param, display
	mov ecx, edx ; third param, len

	; TODO: outer loop for fitting
	; in height & width constraints

	; write string to screen
	mov edi, [eax + 0xc]
.lp:
	xor eax, eax
	mov al, [esi]
	lea esi, [esi + 1]
	or ax, vid.col << 8 ; or with color byte
	mov [edi], ax
	lea edi, [edi + 2]
	loop .lp
	ret

; greeting msg
msg db "Hello, World!"
msg.len equ $-msg

vid.addr equ 0xb8000
vid.col equ 0x0f
vid.w equ 80
vid.h equ 25
