#!/bin/bash

qemu_dir=~/build_qemu_image/qemu

${qemu_dir}/mips64-softmmu/qemu-system-mips64 -M malta -nographic -monitor telnet::4440,server,nowait -serial telnet::3000,server -kernel clfskernel-4.2.3 -initrd initramfs.cpio

# -append "console=tty0"
