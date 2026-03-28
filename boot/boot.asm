[org 0x7c00]

mov ax, 3
int 0x10

mov ax, 0
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00

mov si, msg
call print

jmp $

print:
	mov ah, 0x0e
.next:
	mov al, [si]
	cmp al, 0x00
	jz .done
	int 0x10
	inc si
	jmp .next
.done:
	ret

msg db "Booting RustOS...", 0x0a, 0x0d, 0x00

times 510 - ($-$$) db 0

db 0x55, 0xaa
