
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

; "anonymous" functions
anon:
	; doPrintCall(void *o, char c)
	; wraps call to putcColor
	.doPrintCall:
		mov edx, 0x7
		jmp Display.putcColor

global _start
_start:
	; set stack to bootstrap stack
	mov esp, bsStackTop
	mov ebp, esp

	; clear screen
	mov edi, Display
	call Display.clear

	; write string to screen
	mov ecx, 10
.lp:
	push ecx
	mov edi, msg
	mov esi, anon.doPrintCall
	mov edx, Display ; saved edi
	call String.foreach
	pop ecx
	loop .lp

	pop ebp
	; turn off interrupts, hang
	mov edi, haltmsg
	call puts
	cli
.hang:
	hlt
	jmp .hang

puts:
	push ebp
	mov ebp, esp

	mov edx, Display
	mov esi, anon.doPrintCall
	call String.foreach

	pop ebp
	ret



; Display {
;     dword addr
;     dword h
;     dword w
;     dword off
; }
Display:
	dd 0xb8000
	dd 25
	dd 80
	dd 0

; clearDisplay(display *s);
; clear screen
Display.clear:
	; grab parameters from display
	mov ebx, edi
	mov edi, [ebx]
	mov ecx, [ebx + 0x4]
	mov eax, [ebx + 0x8]
	mul ecx
	mov ecx, eax
	mov eax, 0xf0 | ' '
	cld ; clear direction flag
	rep stosw

	mov eax, ebx ; return display
	ret

; printDisplay(display *s, char c, byte color);
; write to screen
Display.putcColor:
	; parameters
	mov eax, edi ; display
	mov ecx, edx ; color
	shl ecx, 8

	; calculate di
	mov edi, [eax] ; addr
	add edi, [eax + 0xc] ; + offset

	; or with color byte
	or esi, ecx
	mov [edi], si
	add dword [eax + 0xc], 2 ; increment offset
	ret

; String.foreach(char *s, func f(void *o, char c), void *o)
String.foreach:
	push ebp
	mov ebp, esp

; loop over characters
.lp:
	; get current char
	xor eax, eax
	mov al, [edi]
	inc edi
	; quit on null
	test al, al
	jz .break

	; save registers, return eip; jmp to func
	push edi
	push esi
	push edx
	push .r
	mov ebx, esi
	mov edi, edx
	mov esi, eax
	jmp ebx
.r:
	pop edx
	pop esi
	pop edi

	jmp .lp
.break:
	pop ebp
	ret

; greeting msg
msg db "Hello, World!", 0
haltmsg db "halting!", 0
