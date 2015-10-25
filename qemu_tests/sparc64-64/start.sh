#!/bin/bash

qemu_dir=~/ramdisk/qemu

${qemu_dir}/sparc64-softmmu/qemu-system-sparc64 -m 1024 -nographic -monitor telnet::4440,server,nowait -serial telnet::3000,server -kernel clfskernel-4.2.3 -initrd initramfs.cpio

