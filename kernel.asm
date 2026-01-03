; kernel.asm ------ 100%可靠版（时间日期完全正常）

bits 16
org 0x8000

start:
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7000
    
    call clear_screen
    mov si, banner
    call print_str
    
main_loop:
    mov si, prompt
    call print_str
    
    mov ah, 0x00
    int 0x16
    
    cmp al, 't'
    je cmd_time
    cmp al, 'd'
    je cmd_date
    cmp al, 's'
    je cmd_set_time
    cmp al, 'a'
    je cmd_set_date
    cmp al, 'c'
    je cmd_clear
    cmp al, 'i'
    je cmd_info
    cmp al, 'h'
    je cmd_help
    cmp al, 'r'
    je cmd_reboot
    cmp al, 'q'
    je cmd_reboot
    
    mov ah, 0x0e
    int 0x10
    mov al, '?'
    int 0x10
    call newline
    jmp main_loop

; ----------------------------------------------------
; 子程序：清屏
clear_screen:
    push ax
    push bx
    push cx
    mov ah, 0x06
    mov al, 0
    mov bh, 0x07
    mov cx, 0
    mov dh, 24
    mov dl, 79
    int 0x10
    pop cx
    pop bx
    pop ax
    ret

cmd_clear:
    call clear_screen
    jmp main_loop

; ----------------------------------------------------
; 子程序：显示系统信息
cmd_info:
    mov si, info_msg
    call print_str
    jmp main_loop

; ----------------------------------------------------
; 子程序：帮助
cmd_help:
    mov si, help_msg
    call print_str
    jmp main_loop

; ----------------------------------------------------
; 子程序：重启
cmd_reboot:
    mov si, reboot_msg
    call print_str
    mov ah, 0x00
    int 0x16
    int 0x19

; ----------------------------------------------------
; 子程序：打印字符串
print_str:
    push ax
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp .loop
.done:
    pop ax
    ret

; ----------------------------------------------------
; 子程序：换行
newline:
    push ax
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    pop ax
    ret

; ----------------------------------------------------
; BCD转ASCII
bcd_to_ascii:
    push bx
    mov bl, al
    shr al, 4
    add al, '0'
    mov ah, al
    mov al, bl
    and al, 0x0F
    add al, '0'
    pop bx
    ret

; ----------------------------------------------------
; 打印两位字符
print_two:
    push ax
    mov al, ah
    mov ah, 0x0e
    int 0x10
    pop ax
    mov ah, 0x0e
    int 0x10
    ret

; ----------------------------------------------------
; 获取实时时间
get_real_time:
    mov ah, 0x02
    int 0x1a
    jc .error
    mov [hour], ch
    mov [minute], cl
    mov [second], dh
.error:
    ret

; ----------------------------------------------------
; 获取实时日期
get_real_date:
    mov ah, 0x04
    int 0x1a
    jc .error
    mov [year], cx
    mov [month], dh
    mov [day], dl
.error:
    ret

; ----------------------------------------------------
; 显示时间
cmd_time:
    call get_real_time
    mov si, msg_time
    call print_str
    
    mov al, [hour]
    call bcd_to_ascii
    call print_two
    
    mov al, ':'
    int 0x10
    
    mov al, [minute]
    call bcd_to_ascii
    call print_two
    
    mov al, ':'
    int 0x10
    
    mov al, [second]
    call bcd_to_ascii
    call print_two
    
    call newline
    jmp main_loop

; ----------------------------------------------------
; 显示日期
; ----------------------------------------------------
; 显示日期
cmd_date:
    call get_real_date
    mov si, msg_date
    call print_str
    
    ; ========== 仅修改这6行：显示20开头的年份 ==========
    ; 显示世纪（20）
    mov al, [century]   ; 取世纪变量（0x20=20的BCD）
    call bcd_to_ascii
    call print_two
    ; 显示年份后两位
    mov al, [year]      ; 取年份变量（00-99的BCD）
    call bcd_to_ascii
    call print_two
    ; ========== 其余代码保持不变 ==========
    
    mov al, '-'
    int 0x10
    
    mov al, [month]
    call bcd_to_ascii
    call print_two
    
    mov al, '-'
    int 0x10
    
    mov al, [day]
    call bcd_to_ascii
    call print_two
    
    call newline
    jmp main_loop

; ----------------------------------------------------
; **终极修复：只操作BL，确保BH=0**
read_num:
    push ax
    push cx
    push dx
    
    xor bx, bx      ; BH=0, BL=0
    xor cx, cx
    xor dx, dx      ; DL=位数
    
.loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 13
    je .done
    
    cmp al, '0'
    jb .loop
    
    cmp al, '9'
    ja .loop
    
    cmp dl, 2
    je .loop
    
    ; 回显
    mov ah, 0x0e
    int 0x10
    
    ; **核心：只修改BL**
    sub al, '0'
    mov cl, al      ; CL = 新数字
    
    mov al, bl      ; AL = 当前BL
    mov ah, 0
    
    ; BL = BL*10 + CL
    ; BL*10 = (BL<<3) + (BL<<1)
    mov ch, bl      ; CH = 原值
    shl bl, 1       ; BL = 原值*2
    mov al, ch      ; AL = 原值
    mov ah, 0
    shl ax, 3       ; AX = 原值*8
    add bx, ax      ; BX = 原值*2 + 原值*8 = 原值*10
    add bl, cl      ; BL = 原值*10 + 新数字
    
    inc dl
    jmp .loop

.done:
    cmp dl, 0
    je .invalid
    clc
    jmp .exit

.invalid:
    mov si, msg_invalid
    call print_str
    xor bx, bx
    stc

.exit:
    pop dx
    pop cx
    pop ax
    ret

; ----------------------------------------------------
; 设置时间（修复：DL=0）
cmd_set_time:
    mov si, msg_set_hour
    call print_str
    call read_num
    jc .retry
    cmp bx, 23
    ja .invalid_range
    
    mov ax, bx
    mov cl, 10
    div cl
    mov cl, 4
    shl al, cl
    or al, ah
    mov [hour], al
    
    mov si, msg_set_min
    call print_str
    call read_num
    jc .retry
    cmp bx, 59
    ja .invalid_range
    
    mov ax, bx
    mov cl, 10
    div cl
    mov cl, 4
    shl al, cl
    or al, ah
    mov [minute], al
    
    mov si, msg_set_sec
    call print_str
    call read_num
    jc .retry
    cmp bx, 59
    ja .invalid_range
    
    mov ax, bx
    mov cl, 10
    div cl
    mov cl, 4
    shl al, cl
    or al, ah
    mov [second], al
    
    ; **关键修复：DL必须清零**
    mov ah, 0x03
    mov ch, [hour]
    mov cl, [minute]
    mov dh, [second]
    xor dl, dl      ; **DL=0（某些BIOS要求）**
    int 0x1a
    
    mov si, msg_ok
    call print_str
    jmp main_loop

.retry:
    mov si, msg_invalid
    call print_str
    jmp cmd_set_time

.invalid_range:
    mov si, msg_range_err
    call print_str
    jmp cmd_set_time

; ----------------------------------------------------
; 设置日期（修复：DL保留，世纪分离存储）
cmd_set_date:
    mov si, msg_set_year
    call print_str
    call read_num
    jc .retry
    cmp bx, 99
    ja .invalid_range
    
    mov ax, bx
    mov cl, 10
    div cl
    mov cl, 4
    shl al, cl
    or al, ah
    mov [year], al      ; **只存年份BCD**
    
    mov si, msg_set_month
    call print_str
    call read_num
    jc .retry
    cmp bx, 12
    ja .invalid_range
    
    mov ax, bx
    mov cl, 10
    div cl
    mov cl, 4
    shl al, cl
    or al, ah
    mov [month], al
    
    mov si, msg_set_day
    call print_str
    call read_num
    jc .retry
    cmp bx, 31
    ja .invalid_range
    
    mov ax, bx
    mov cl, 10
    div cl
    mov cl, 4
    shl al, cl
    or al, ah
    mov [day], al
    
    ; **关键修复：正确组合CX，DL保持0**
    mov ah, 0x05
    mov ch, [century]   ; CH = 0x20（世纪）
    mov cl, [year]      ; CL = 年份BCD
    mov dh, [month]     ; DH = 月份
    mov dl, [day]       ; DL = 日期
    int 0x1a
    
    mov si, msg_ok
    call print_str
    jmp main_loop

.retry:
    mov si, msg_invalid
    call print_str
    jmp cmd_set_date

.invalid_range:
    mov si, msg_range_err
    call print_str
    jmp cmd_set_date

; ----------------------------------------------------
; 数据段（增加century变量）
hour    db 0
minute  db 0
second  db 0
year    db 0          ; **改为db，只存年份**
month   db 0
day     db 0
century db 0x20       ; **新增：世纪BCD（默认为20）**

banner      db 13, 10, '========================================', 13, 10
            db '  MyOS - Minimal Operating System', 13, 10
            db '  Version 4.0', 13, 10
            db '  Developer: 13', 13, 10
            db '  University: YZU', 13, 10
            db '========================================', 13, 10, 10
            db ' Commands: t=time, d=date, s=set time', 13, 10
            db '           a=set date, c=clear, i=info', 13, 10
            db '           h=help, r/q=reboot', 13, 10, 10, 0

prompt      db 'MyOS> ', 0
msg_time    db 'Current Time: ', 0
msg_date    db 'Current Date: ', 0

help_msg    db 13, 10, '--- Help Information ---', 13, 10
            db 't - Display current time', 13, 10
            db 'd - Display current date', 13, 10
            db 's - Set system time', 13, 10
            db 'a - Set system date', 13, 10
            db 'c - Clear screen', 13, 10
            db 'i - Display system info', 13, 10
            db 'h - Show this help', 13, 10
            db 'r/q - Reboot system', 13, 10, 10, 0

info_msg    db 13, 10, '--- System Information ---', 13, 10
            db 'OS: MyOS v4.0', 13, 10
            db 'Mode: Real Mode (16-bit)', 13, 10
            db 'Memory: Kernel at 0x8000, Stack at 0x7000', 13, 10
            db 'Platform: x86 PC with BIOS', 13, 10, 10, 0

reboot_msg  db 13, 10, 'System will reboot. Press any key...', 0

msg_set_hour db 13, 10, 'Enter hour (0-23): ', 0
msg_set_min  db 'Enter minute (0-59): ', 0
msg_set_sec  db 'Enter second (0-59): ', 0

msg_set_year db 13, 10, 'Enter year (0-99, e.g., 24): ', 0
msg_set_month db 'Enter month (1-12): ', 0
msg_set_day  db 'Enter day (1-31): ', 0

msg_invalid  db 13, 10, 'Invalid input! Please retry.', 13, 10, 0
msg_range_err db 13, 10, 'Out of range! Please retry.', 13, 10, 0
msg_ok       db 13, 10, 'Set successfully!', 13, 10, 0

; 填充到4KB（8个扇区）
times 4096 - ($ - $$) db 0