; =========================
; boot/boot.asm
; =========================
[org 0x7c00]
bits 16

start:
    ; 设置文本模式，清屏
    mov ax, 3
    int 0x10

    ; 初始化段寄存器
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    mov si, booting
    call print

    ; 读取 loader (从 LBA=2 开始)
    mov edi, 0x1000      ; 加载地址
    mov ecx, 1           ; 起始扇区
    mov bl, 4            ; 扇区数
    call read_disk

    ; 检查 loader 魔数
    cmp word [0x1000], 0x55aa
    jne error

    jmp 0:0x1000

hang:
    jmp hang

; =========================
; LBA28 读取
; =========================
read_disk:
    mov dx, 0x1f2
    mov al, bl
    out dx, al

    inc dx        ; 1f3
    mov al, cl
    out dx, al

    inc dx        ; 1f4
    shr ecx, 8
    mov al, cl
    out dx, al

    inc dx        ; 1f5
    shr ecx, 8
    mov al, cl
    out dx, al

    inc dx        ; 1f6
    shr ecx, 8
    and cl, 0x0f

    mov al, 0xe0
    or al, cl
    out dx, al

    inc dx        ; 1f7
    mov al, 0x20
    out dx, al

    mov cl, bl

.read:
    push cx
    call .wait
    call .read_sector
    pop cx
    loop .read
    ret

.wait:
    mov dx, 0x1f7
.check:
    in al, dx
    and al, 0x88
    cmp al, 0x08
    jne .check
    ret

.read_sector:
    mov dx, 0x1f0
    mov cx, 256

.next:
    in ax, dx
    mov [edi], ax
    add edi, 2
    loop .next
    ret

; -----------------------
; 打印函数
; -----------------------
print:
    mov ah, 0x0e
.next:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .next
.done:
    ret

booting db "Booting...", 0x0a, 0x0d, 0x00

error:
    mov si, err
    call print
    hlt
    jmp $

err db "Boot Error", 0x0a, 0x0d, 0x00

times 510-($-$$) db 0
dw 0xaa55
