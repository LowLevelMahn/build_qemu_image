#!/bin/bash

qemu_dir=~/ramdisk/qemu

${qemu_dir}/mips64-softmmu/qemu-system-mips64 -M malta -m 1GB -nographic -monitor telnet::4440,server,nowait -serial telnet::3000,server -kernel clfskernel-4.2.3 -initrd initrd.cpio

# -append "console=tty0"
