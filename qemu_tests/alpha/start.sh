#!/bin/bash

qemu_dir=~/build_qemu_image/qemu

# ${qemu_dir}/alpha-softmmu/qemu-system-alpha -m 1GB -monitor telnet::4440,server,nowait -kernel vmlinux.img-2.6.26-2-alpha-generic -initrd initrd.img-2.6.26-2-alpha-generic -net nic -net user -hda alpha.qcow2 -drive file=debian-5010-alpha-netinst.iso,if=ide,media=cdrom -append 'root=/dev/hda3'

# ${qemu_dir}/alpha-softmmu/qemu-system-alpha -m 1GB -nographic -monitor telnet::4440,server,nowait -serial telnet::3000,server -kernel clfskernel-4.2.3 -append 'console=ttyS0' -initrd initramfs.cpio
# ${qemu_dir}/alpha-softmmu/qemu-system-alpha -m 1GB -nographic -monitor telnet::4440,server,nowait -serial telnet::3000,server -kernel clfskernel-4.2.3 -append 'console=ttyS0' -initrd initramfs.cpio
${qemu_dir}/alpha-softmmu/qemu-system-alpha -m 1GB -nographic -monitor telnet::4440,server,nowait -serial telnet::3000,server -kernel clfskernel-4.2.3 -append 'console=ttyS0' -initrd initramfs.cpio
