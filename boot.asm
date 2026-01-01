; boot.asm —— Stage 1 Bootloader (512 bytes)
bits 16
org 0x7c00

start:
    ; 初始化段寄存器
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; 显示加载信息
    mov si, msg_loading
    call print_string

    ; 从软盘第 2 扇区（LBA=1）读取 1 个扇区到 0x8000
    mov ah, 0x02        ; BIOS 读磁盘功能
    mov al, 1           ; 读 1 个扇区
    mov ch, 0           ; 柱面 0
    mov cl, 2           ; 扇区 2（LBA=1）
    mov dh, 0           ; 磁头 0
    mov dl, 0           ; 驱动器 A:
    mov bx, 0x8000      ; ES:BX = 目标地址（0x0000:0x8000）
    int 0x13            ; 调用 BIOS 磁盘服务

    jc disk_error       ; 如果出错，跳转

    ; 跳转到内核入口（0x8000）
    jmp 0x0000:0x8000

disk_error:
    mov si, msg_error
    call print_string
    hlt
    jmp $

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp print_string
.done:
    ret

msg_loading db 'System loading...', 13, 10, 0
msg_error   db 'Disk error!', 0

; 填充 + 签名
times 510 - ($ - $$) db 0
dw 0xaa55