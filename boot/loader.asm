[org 0x1000]
[bits 16]

dw 0x55aa ; 用于判断是否读取错误(in boot.asm)

mov si, loading
call print

; 内存检测
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

	mov si, detecting_success
	call print

; 切换到保护模式前的准备
prepare_protect_mode:
	cli
	; 开启 A20
	in al, 0x92
	or al, 0x02
	out 0x92, al

	; 加载 gdt
	lgdt [gdt_ptr]

	; 启用保护模式
	mov eax, cr0
	or eax, 1
	mov cr0, eax

	; 跳转刷新缓存，真正启用保护模式
	jmp dword code_selector:protect_mode_entry

[bits 32]
protect_mode_entry:
	mov ax, data_selector ; 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov esp, 0x90000

	mov edi, 0x100000
	mov ecx, 20
	mov bl, 40
	call read_disk

	jmp $

	jmp 0x100000

code_selector equ (1 << 3) ; 代码段
data_selector equ (2 << 3) ; 数据段

memory_base equ 0
memory_limit equ ((1024 * 1024 * 1024 * 4) / (4 * 1024)) - 1

gdt_ptr:
	dw (gdt_end - gdt_base)
	dd gdt_base
gdt_base:
	dq 0
gdt_code:
	dw memory_limit & 0xffff
	dw memory_base & 0xffff
	db (memory_base >> 16) & 0xff
	db 0b10011010
	db 0b11110000 | (memory_limit >> 16) & 0xf
	db (memory_base >> 24) & 0xff
gdt_data:
	dw memory_limit & 0xffff
	dw memory_base & 0xffff
	db (memory_base >> 16) & 0xff
	db 0b10010010 ; P|PL|S|Type
	db 0b11110000 | (memory_limit >> 16) & 0xf
	db (memory_base >> 24) & 0xff
gdt_end:

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
[bits 16]
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
detecting_success: db "Detecting Memory Success...", 0x0a, 0x0d, 0x00

error:
	mov si, .msg
	call print
	hlt
	jmp $
	.msg db "Loading Error...", 0x0a, 0x0d, 0x00

ards_count:
	dw 0
ards_buffer:
