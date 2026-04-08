[org 0x1000]

dw 0x55aa ; 用于判断是否读取错误

mov si, loading
call print

detect_memory:
	xor ebx, ebx

	mov ax, 0
	mov es, ax
	mov edi, ards_buffer

	mov edx, 0x534d4150

.next:
	mov eax, 0xe820 ; 功能号
	mov ecx, 24     ; 描述内存的结构体大小
	int 0x15        ; 中断号

	jc error   ; CF 标志为1，表示出错
	add di, cx ; 指向下一个内存结构

	inc word [ards_count]

	cmp ebx, 0 ; ebx 为0表示结束
	jnz .next

	mov si, detecting
	call print


; 打印函数
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

loading: db "Loading RustOS...", 0x0a, 0x0d, 0x00
detecting: db "Detecting Memory...", 0x0a, 0x0d, 0x00

error:
	mov si, .msg
	call print
	hlt
	jmp $
	.msg db "Loading Error...", 0x0a, 0x0d, 0x00

ards_count:
	dw 0
ards_buffer:

