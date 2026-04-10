LF equ 0x0a
CR equ 0x0d
NUL equ 0x00

[org 0x1000]
[bits 16]

dw 0x55aa               ; 魔数

; 加载内核（从LBA=20开始，读120个扇区 ≈ 60KB，足够简单内核）
mov edi, 0x100000
mov ecx, 20             ; 起始扇区
mov bl, 120
call read_disk_lba28

; 打印内核已加载
mov si, msg_kernel_loaded
call print
jmp $

; ==================== 切换到保护模式并进入64位长模式 ====================
cli
in al, 0x92
or al, 0x02
out 0x92, al            ; 开启A20

lgdt [gdt_ptr]
mov eax, cr0
or eax, 1
mov cr0, eax
jmp dword code_sel:protect_mode_entry

; ====================== 32位临时代码 ======================
[bits 32]
protect_mode_entry:
    mov ax, data_sel
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; 显示 'P' 表示进入32位保护模式
    mov byte [0xb8000], 'P'
    mov byte [0xb8001], 0x0c

    call enable_long_mode

    lgdt [gdt64_ptr]
    jmp code_sel64:long_mode_entry

; ====================== 启用64位长模式 ======================
enable_long_mode:
    ; PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; 设置分页表
    mov eax, pml4_table
    mov cr3, eax

    ; EFER.LME = 1
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; 启用分页 PG
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax
    ret

; ====================== 64位GDT ======================
gdt_ptr:
    dw gdt_end - gdt_base - 1
    dd gdt_base
gdt_base:
    dq 0
gdt_code: dw 0xffff, 0, 0, 0b10011010, 0b11001111, 0
gdt_data: dw 0xffff, 0, 0, 0b10010010, 0b11001111, 0
gdt_end:

code_sel equ gdt_code - gdt_base
data_sel equ gdt_data - gdt_base

gdt64_ptr:
    dw gdt64_end - gdt64_base - 1
    dd gdt64_base
gdt64_base:
    dq 0
gdt64_code: dw 0xffff, 0, 0, 0b10011010, 0b10101111, 0
gdt64_data: dw 0xffff, 0, 0, 0b10010010, 0b10101111, 0
gdt64_end:

code_sel64 equ gdt64_code - gdt64_base

; ====================== 分页表（映射前2MB） ======================
align 4096
pml4_table:
    dq pml3_table + 3
    times 511 dq 0

align 4096
pml3_table:
    dq pml2_table + 3
    times 511 dq 0

align 4096
pml2_table:
    mov ecx, 0
.loop:
    mov eax, ecx
    shl eax, 21             ; 2MB huge page
    or eax, 0x83            ; P + W + PS
    mov [pml2_table + ecx*8], eax
    inc ecx
    cmp ecx, 512
    jne .loop

; ====================== 64位入口 ======================
[bits 64]
long_mode_entry:
    mov ax, data_sel
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rsp, 0x90000

    ; 显示 'L' 表示成功进入64位长模式
    mov byte [0xb8000 + 4], 'L'
    mov byte [0xb8000 + 5], 0x0a

    ; 跳转到Rust内核
    jmp 0x100000

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

msg_kernel_loaded db "Kernel Loaded, Entering PM...", LF, CR, 0
