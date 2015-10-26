#!/bin/bash

qemu_dir=~/ramdisk/qemu

${qemu_dir}/alpha-softmmu/qemu-system-alpha -m 1GB -nographic -monitor telnet::4440,server,nowait -serial telnet::3000,server -kernel clfskernel-4.2.3 -append 'console=ttyS0' -initrd initrd.cpio

