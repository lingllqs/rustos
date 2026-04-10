LF equ 0x0a
CR equ 0x0d
NUL equ 0x00

[org 0x7c00]
[bits 16]

; 设置为文本模式
mov ax, 3
int 0x10

mov si, msg_booting
call print

; 初始化段寄存器
mov ax, 0
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00

mov si, msg_loading
call print

mov edi, 0x1000
mov ecx, 2
mov bl, 8
call read_disk_lba28

cmp word [0x1000], 0x55aa
jnz error

jmp 0:0x1002

; ---------------------- 读取硬盘 LBA28 -------------------------
read_disk_lba28:
	mov dx, 0x1f2
	mov al, bl			; bl - 读取的扇区数量
	out dx, al

	inc dx
	mov al, cl
	out dx, al

	inc dx
	mov al, ch
	out dx, al

	inc dx
	shr ecx, 16
	mov al, cl
	out dx, al

	inc dx
	and ch, 0x0f
	mov al, 0xe0		; 0b1110_0000 - 4bit: 主盘0,从盘1  6bit: LBA1,CHS0
	or al, ch
	out dx, al

	mov dx, 0x1f7
	mov al, 0x20		; 0x20: 读  0x30: 写
	out dx, al

	xor ecx, ecx
	mov cl, bl			; 循环次数
	.read_loop:
		push cx
		call wait_disk
		call read_sector
		pop cx
		loop .read_loop

	ret

wait_disk:
	mov dx, 0x1f7
	.check:
		in al, dx
		and al, 0x88
		cmp al, 0x08
		jnz .check
	ret

read_sector:
	mov dx, 0x1f0
	mov cx, 256
	.read_word:
		in ax, dx
		mov [edi], ax
		add edi, 2
		loop .read_word
	ret

; ---------------------- 打印函数 -------------------------
print:
	mov ah, 0x0e
.next:
	lodsb				; mov al, [ds:si] -> inc si
	cmp al, NUL
	jz .done
	int 0x10
	jmp .next
.done:
	ret

error:
	mov si, .msg
	call print
	.msg db "Loading Loader Error ...", LF, CR, NUL
	jmp $

msg_booting db "Booting RustOS ...", LF, CR, NUL
msg_loading db "Loading Loader ...", LF, CR, NUL


times 510 - ($ - $$) db 0x00
dw 0xaa55
