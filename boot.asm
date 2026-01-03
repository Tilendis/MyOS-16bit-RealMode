; boot.asm ------ 增强版引导加载程序（加载8个扇区）

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
    
    ; 从软盘加载内核（LBA=1开始，加载8个扇区到0x8000）
    ; 可加载最多8*512=4KB内核
    mov ah, 0x02    ; BIOS读磁盘功能
    mov al, 8       ; 读8个扇区（增大内核空间）
    mov ch, 0       ; 柱面0
    mov cl, 2       ; 扇区2（LBA=1）
    mov dh, 0       ; 磁头0
    mov dl, 0       ; 驱动器A:
    mov bx, 0x8000  ; ES:BX = 目标地址
    int 0x13        ; 调用BIOS磁盘服务
    
    jc disk_error   ; 出错跳转
    
    ; 跳转到内核入口
    jmp 0x0000:0x8000

disk_error:
    mov si, msg_error
    call print_string
    mov ah, 0x00
    int 0x16        ; 等待按键
    mov ax, 0x0000
    int 0x19        ; 重启

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp print_string
.done:
    ret

msg_loading db 'MyOS Boot Loader v1.0 - Loading kernel...', 13, 10, 0
msg_error db 'Disk Error! Press any key to reboot...', 0

; 填充 + 签名
times 510 - ($ - $$) db 0
dw 0xaa55