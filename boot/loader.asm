; =========================
; boot/loader.asm
; =========================
[org 0x1000]
bits 16

dw 0x55aa

start:
    mov si, msg
    call print

; 进入保护模式
	cli

	in al, 0x92
	or al, 2
	out 0x92, al

	lgdt [gdt_ptr]

	mov eax, cr0
	or eax, 1
	mov cr0, eax

	jmp 0x08:pmode

; =========================
; 16位函数
; =========================
print:
    mov ah, 0x0e
.next:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .next
.done:
    ret

msg db "Loading...",0

; -------------------
; GDT
; -------------------
gdt_start:
dq 0                  ; NULL
dq 0x00cf9a000000ffff ; code segment
dq 0x00cf92000000ffff ; data segment

gdt_end:

gdt_ptr:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; =========================
; 32位代码
; =========================
bits 32
pmode:

    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov esp, 0x90000

; -------------------------
; 读取 kernel ELF
; -------------------------
    mov edi, 0x100000
    mov ecx, 5
    mov bl, 200
    call read_disk

	; jmp 0x100000

; -------------------------
; ELF 解析
; -------------------------
    mov esi, 0x100000

    mov eax, [esi]
    cmp eax, 0x464c457f
    jne $

    mov ebx, [esi+28]
    add ebx, esi

    movzx ecx, word [esi+44]

ph_loop:
    test ecx, ecx
    jz done

    mov eax, [ebx+4]
    add eax, esi

    mov edi, [ebx+12]
    mov edx, [ebx+16]

    push ebx
    push ecx
    call memcpy
    pop ecx
    pop ebx

    add ebx, 32
    dec ecx
    jmp ph_loop

done:
    mov eax, [esi+24]
    jmp eax

; =========================
memcpy:
    push esi
    push edi
    push ecx

    mov esi, eax
    mov ecx, edx

.copy:
    test ecx, ecx
    jz .done
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    dec ecx
    jmp .copy

.done:
    pop ecx
    pop edi
    pop esi
    ret

; =========================
; 复用 boot 的 read_disk
; =========================
read_disk:
    mov dx, 0x1f2
    mov al, bl
    out dx, al

    inc dx
    mov al, cl
    out dx, al

    inc dx
    shr ecx, 8
    mov al, cl
    out dx, al

    inc dx
    shr ecx, 8
    mov al, cl
    out dx, al

    inc dx
    shr ecx, 8
    and cl, 0x0f

    mov al, 0xe0
    or al, cl
    out dx, al

    inc dx
    mov al, 0x20
    out dx, al

    mov cl, bl

.r:
    push cx
    call .wait
    call .read
    pop cx
    loop .r
    ret

.wait:
    mov dx, 0x1f7
.w:
    in al, dx
    and al, 0x88
    cmp al, 0x08
    jne .w
    ret

.read:
    mov dx, 0x1f0
    mov cx, 256
.l:
    in ax, dx
    mov [edi], ax
    add edi, 2
    loop .l
    ret
