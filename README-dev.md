# MyOS 开发进度

>最后更新：2026-01-01

## 已完成

- [x] Boches 软盘启动配置 (使用 `floppy0: type=floppy`)
- [x] 引导程序修复*(`dl = 0x00`)
- [x] 本地Git初始化 + 首次提交

## 下一步

- [ ] 推送到Github

## 关键命令备忘

```bash
# 编译
nasm -f bin boot.asm -o boot.bin
copy /b boot.bin + kernel.bin os.img

# 运行
bochs -q -f bochsrc.txt

# Git 提交
git add .
git commit -m "update"
