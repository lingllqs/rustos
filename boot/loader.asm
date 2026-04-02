[org 0x1000]

dw 0x55aa ; 用于判断是否读取错误

mov si, loading
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

loading:
	db "Loading RustOS...", 0x0a, 0x0d, 0x00

error:
	mov si, .msg
	call print
	hlt
	jmp $
	.msg db "Loading Error...", 0x0a, 0x0d, 0x00
