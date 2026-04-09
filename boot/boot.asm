LF equ 0x0d
CR equ 0x0a
NUL equ 0x00

[org 0x7c00]

; 设置屏幕为文本模式
mov ax, 3
int 0x10

; 初始化段寄存器
mov ax, 0
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00

mov si, msg
call print

mov edi, 0x1000 ; 目标内存
mov ecx, 2      ; 起始扇区
mov bl, 4       ; 扇区数
call read_disk

cmp word [0x1000], 0x55aa
jnz error

jmp 0:0x1002

; 读取硬盘函数
read_disk:
	mov dx, 0x1f2 ; 设置读取扇区数
	mov al, bl
	out dx, al

	mov dx, 0x1f3 ; 起始扇区低8位
	mov al, cl    ; 起始扇区低8位
	out dx, al

	inc dx ; 0x1f4
	shr ecx, 8
	mov al, cl
	out dx, al

	inc dx ; 0x1f5
	shr ecx, 8
	mov al, cl
	out dx, al

	inc dx ; 0x1f6
	shr ecx, 8
	and cl, 0b1111

	mov al, 0b11100000
	or al, cl ; 固定1 LBA模式1 固定1 主盘0
	out dx, al

	mov dx, 0x1f7
	mov al, 0x20 ; 0x20: 读硬盘 | 0x30: 写硬盘
	out dx, al

	; 设置好参数后开始读取硬盘
	xor ecx, ecx
	mov cl, bl ; 读取扇区数

	.read:
		push cx
		call .waits
		call .read_sector
		pop cx
		loop .read
	ret
	
	; 等待硬盘准备就绪
	.waits:
		mov dx, 0x1f7
		.check:
			in al, dx
			jmp $+2
			jmp $+2
			jmp $+2
			and al, 0b10001000 ; 3bit: 数据准备完毕1 7bit: 硬盘繁忙1
			cmp al, 0b00001000 ; 判断是否准备就绪
			jnz .check
		ret
	
	; 读取扇区
	.read_sector:
		mov dx, 0x1f0
		mov cx, 256
		.read_word:
			in ax, dx
			jmp $+2
			jmp $+2
			jmp $+2
			mov [edi], ax
			add edi, 2
			loop .read_word
		ret

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

error:
	mov si, .msg
	call print
	hlt
	jmp $
	.msg db "Loading Loader Error...", LF, CR, NUL

msg db "Booting RustOS...", LF, CR, NUL

times 510 - ($-$$) db 0x00

db 0x55, 0xaa
