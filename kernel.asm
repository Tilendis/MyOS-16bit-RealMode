; kernel.asm —— Stage 2 Kernel (>512 bytes)
bits 16
org 0x8000

start:
    call clear_screen
    call show_copyright
    call main_loop

clear_screen:
    mov ax, 0x0600      ; 滚动全屏
    mov bh, 0x07        ; 白底黑字
    mov cx, 0           ; 左上角
    mov dx, 0x184f      ; 右下角 (25x80)
    int 0x10
    ret

show_copyright:
    mov si, banner
    call print_string
    ret

main_loop:
    mov si, prompt
    call print_string

    mov ah, 0x00
    int 0x16            ; 等待按键

    cmp al, 'd'
    je cmd_date
    cmp al, 't'
    je cmd_time
    cmp al, 'q'
    je exit_system
    ; 可扩展 set date/time...

    jmp main_loop

cmd_date:
    call get_date
    call print_date
    jmp main_loop

cmd_time:
    call get_time
    call print_time
    jmp main_loop

exit_system:
    mov si, bye_msg
    call print_string
    cli                 ; 禁用中断
    hlt                 ; 停止 CPU
    jmp $               ; 保险

; ===== 时间/日期获取与显示函数 =====
get_date:
    mov ah, 0x04
    int 0x1a            ; CX=year, DH=month, DL=day
    ret

get_time:
    mov ah, 0x02
    int 0x1a            ; CH=hour, CL=minute, DH=second
    ret

print_date:
    ; 打印 "YYYY-MM-DD"
    mov si, msg_date_stub
    call print_string
    ret

print_time:
    mov si, msg_time_stub
    call print_string
    ret

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp print_string
.done:
    ret



; 数据区
banner        db 'MyOS v1.0', 13, 10
              db 'Copyright (c) 2025 Azad, YZU University', 13, 10, 0
prompt        db '> ', 0
msg_date_stub db '[DATE: 2025-12-31]', 13, 10, 0
msg_time_stub db '[TIME: 12:34:56]', 13, 10, 0
bye_msg       db 'Bye!', 13, 10, 0

; 填充到 512 字节（确保占满一个扇区）
times 512 - ($ - $$) db 0