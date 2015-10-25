# config.make.  Generated from config.make.in by configure.
# Don't edit this file.  Put configuration parameters in configparms instead.

version = 2.22
release = stable

# Installation prefixes.
install_root = $(DESTDIR)
prefix = /tools
exec_prefix = ${prefix}
datadir = ${datarootdir}
libdir = ${exec_prefix}/lib
slibdir = 
rtlddir = 
localedir = 
sysconfdir = ${prefix}/etc
libexecdir = ${exec_prefix}/libexec
rootsbindir = 
infodir = ${datarootdir}/info
includedir = ${prefix}/include
datarootdir = ${prefix}/share
localstatedir = ${prefix}/var

# Should we use and build ldconfig?
use-ldconfig = yes

# Maybe the `ldd' script must be rewritten.
ldd-rewrite-script = no

# System configuration.
config-machine = alphaev67
base-machine = alpha
config-vendor = unknown
config-os = linux-gnu
config-sysdirs =  sysdeps/unix/sysv/linux/alpha/alphaev67/fpu sysdeps/alpha/alphaev67/fpu sysdeps/alpha/alphaev6/fpu sysdeps/unix/sysv/linux/alpha/alphaev67 sysdeps/unix/sysv/linux/alpha/fpu sysdeps/alpha/fpu sysdeps/unix/sysv/linux/alpha sysdeps/alpha/nptl sysdeps/unix/sysv/linux/wordsize-64 sysdeps/ieee754/ldbl-64-128 sysdeps/ieee754/ldbl-opt sysdeps/unix/sysv/linux sysdeps/nptl sysdeps/pthread sysdeps/gnu sysdeps/unix/inet sysdeps/unix/sysv sysdeps/unix/alpha sysdeps/unix sysdeps/posix sysdeps/alpha/alphaev67 sysdeps/alpha/alphaev6 sysdeps/alpha/alphaev5 sysdeps/alpha sysdeps/wordsize-64 sysdeps/ieee754/ldbl-128 sysdeps/ieee754/dbl-64/wordsize-64 sysdeps/ieee754/dbl-64 sysdeps/ieee754/flt-32 sysdeps/alpha/soft-fp sysdeps/ieee754 sysdeps/generic
cflags-cpu = 
asflags-cpu = 

config-extra-cflags = 
config-extra-cppflags = 
config-cflags-nofma = -ffp-contract=off

defines = 
sysheaders = /tools/include
sysincludes = -nostdinc -isystem /home/dl/ramdisk/clfs_cross_tools/system/alpha/cross-tools/bin/../lib/gcc/alphaev67-unknown-linux-gnu/5.2.0/include -isystem /home/dl/ramdisk/clfs_cross_tools/system/alpha/cross-tools/bin/../lib/gcc/alphaev67-unknown-linux-gnu/5.2.0/include-fixed -isystem /tools/include
c++-sysincludes =  -isystem /usr/include/c++/4.9 -isystem /usr/include/x86_64-linux-gnu/c++/4.9 -isystem /usr/include/c++/4.9/backward
all-warnings = 
enable-werror = yes

have-z-combreloc = yes
have-z-execstack = yes
have-Bgroup = yes
have-protected-data = yes
with-fp = yes
old-glibc-headers = no
unwind-find-fde = yes
have-forced-unwind = yes
have-fpie = yes
gnu89-inline-CFLAGS = -fgnu89-inline
have-ssp = no
have-selinux = no
have-libaudit = 
have-libcap = 
have-cc-with-libunwind = no
fno-unit-at-a-time = -fno-toplevel-reorder -fno-section-anchors
bind-now = no
have-hash-style = yes
use-default-link = no
output-format = elf64-alpha

static-libgcc = -static-libgcc

exceptions = -fexceptions
multi-arch = no

mach-interface-list = 

sizeof-long-double = 8

nss-crypt = no

# Configuration options.
build-shared = yes
build-pic-default= no
build-pie-default= no
build-profile = no
build-static-nss = no
add-ons = libidn
add-on-subdirs =  libidn
sysdeps-add-ons = 
cross-compiling = yes
force-install = yes
link-obsolete-rpc = yes
build-nscd = yes
use-nscd = yes
build-hardcoded-path-in-tests= no
build-pt-chown = no
enable-lock-elision = no

# Build tools.
CC = alphaev67-unknown-linux-gnu-gcc -mcpu=ev67 -mtune=ev67 -B/cross-tools/bin/
CXX = g++
BUILD_CC = gcc
CFLAGS = -g -O2
CPPFLAGS-config = 
CPPUNDEFS = 
ASFLAGS-config =  -Wa,--noexecstack
AR = /home/dl/ramdisk/clfs_cross_tools/system/alpha/cross-tools/bin/../lib/gcc/alphaev67-unknown-linux-gnu/5.2.0/../../../../alphaev67-unknown-linux-gnu/bin/ar
NM = alphaev67-unknown-linux-gnu-nm
MAKEINFO = :
AS = $(CC) -c
BISON = no
AUTOCONF = no
OBJDUMP = /home/dl/ramdisk/clfs_cross_tools/system/alpha/cross-tools/bin/../lib/gcc/alphaev67-unknown-linux-gnu/5.2.0/../../../../alphaev67-unknown-linux-gnu/bin/objdump
OBJCOPY = /home/dl/ramdisk/clfs_cross_tools/system/alpha/cross-tools/bin/../lib/gcc/alphaev67-unknown-linux-gnu/5.2.0/../../../../alphaev67-unknown-linux-gnu/bin/objcopy
READELF = alphaev67-unknown-linux-gnu-readelf

# Installation tools.
INSTALL = /usr/bin/install -c
INSTALL_PROGRAM = ${INSTALL}
INSTALL_SCRIPT = ${INSTALL}
INSTALL_DATA = ${INSTALL} -m 644
INSTALL_INFO = /usr/bin/install-info
LN_S = ln -s
MSGFMT = msgfmt

# Script execution tools.
BASH = /bin/bash
AWK = gawk
PERL = /usr/bin/perl

# Additional libraries.
LIBGD = no

# Package versions and bug reporting configuration.
PKGVERSION = (GNU libc) 
PKGVERSION_TEXI = (GNU libc) 
REPORT_BUGS_TO = <http://www.gnu.org/software/libc/bugs.html>
REPORT_BUGS_TEXI = @uref{http://www.gnu.org/software/libc/bugs.html}

# More variables may be inserted below by configure.

override stddef.h = # The installed <stddef.h> seems to be libc-friendly.
build-mathvec = no
