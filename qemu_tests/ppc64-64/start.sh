#!/bin/bash

qemu_dir=~/qemu

${qemu_dir}/ppc64-softmmu/qemu-system-ppc64 -m 1GB -kernel clfskernel-4.2.3 -initrd initrd.cpio -nographic -monitor telnet::4440,server,nowait -serial telnet::3000,server # -append 'console=ttyS0'
