#!/bin/bash

rm qemu -rf
git clone git://git.qemu-project.org/qemu.git
cd qemu
./configure --target-list=sparc64-softmmu,alpha-softmmu,mips64-softmmu
make -j5
# make install # not needed for doing local tests
