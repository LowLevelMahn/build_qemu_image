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
ldd-rewrite-script = sysdeps/unix/sysv/linux/mips/mips64/ldd-rewrite.sed

# System configuration.
config-machine = mips64
base-machine = mips
config-vendor = unknown
config-os = linux-gnu
config-sysdirs =  sysdeps/unix/sysv/linux/mips/mips64/n64 sysdeps/unix/sysv/linux/mips/mips64 sysdeps/unix/sysv/linux/mips sysdeps/mips/nptl sysdeps/unix/sysv/linux sysdeps/nptl sysdeps/pthread sysdeps/gnu sysdeps/unix/inet sysdeps/unix/sysv sysdeps/unix/mips/mips64/n64 sysdeps/unix/mips/mips64 sysdeps/unix/mips sysdeps/unix sysdeps/posix sysdeps/mips/mips64/n64/fpu sysdeps/mips/mips64/n64 sysdeps/mips/ieee754 sysdeps/ieee754/ldbl-128 sysdeps/mips/mips64 sysdeps/ieee754/flt-32 sysdeps/ieee754/dbl-64 sysdeps/mips sysdeps/wordsize-64 sysdeps/mips/fpu sysdeps/ieee754 sysdeps/generic
cflags-cpu = 
asflags-cpu = 

config-extra-cflags = 
config-extra-cppflags = 
config-cflags-nofma = -ffp-contract=off

defines = 
sysheaders = /tools/include
sysincludes = -nostdinc -isystem /home/dl/ramdisk/clfs_cross_tools/system/mips64-64/cross-tools/bin/../lib/gcc/mips64-unknown-linux-gnu/5.2.0/include -isystem /home/dl/ramdisk/clfs_cross_tools/system/mips64-64/cross-tools/bin/../lib/gcc/mips64-unknown-linux-gnu/5.2.0/include-fixed -isystem /tools/include
c++-sysincludes =  -isystem /usr/include/c++/4.9 -isystem /usr/include/x86_64-linux-gnu/c++/4.9 -isystem /usr/include/c++/4.9/backward
all-warnings = 
enable-werror = yes

have-z-combreloc = no
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
have-hash-style = no
use-default-link = no
output-format = elf64-tradbigmips

static-libgcc = -static-libgcc

exceptions = -fexceptions
multi-arch = no

mach-interface-list = 

sizeof-long-double = 16

nss-crypt = no

# Configuration options.
build-shared = yes
build-pic-default= yes
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
CC = mips64-unknown-linux-gnu-gcc -march=5kc -mtune=5kc -mabi=64 -B/cross-tools/bin/
CXX = g++
BUILD_CC = gcc
CFLAGS = -g -O2
CPPFLAGS-config = 
CPPUNDEFS = 
ASFLAGS-config = 
AR = /home/dl/ramdisk/clfs_cross_tools/system/mips64-64/cross-tools/bin/../lib/gcc/mips64-unknown-linux-gnu/5.2.0/../../../../mips64-unknown-linux-gnu/bin/ar
NM = mips64-unknown-linux-gnu-nm
MAKEINFO = :
AS = $(CC) -c
BISON = no
AUTOCONF = no
OBJDUMP = /home/dl/ramdisk/clfs_cross_tools/system/mips64-64/cross-tools/bin/../lib/gcc/mips64-unknown-linux-gnu/5.2.0/../../../../mips64-unknown-linux-gnu/bin/objdump
OBJCOPY = /home/dl/ramdisk/clfs_cross_tools/system/mips64-64/cross-tools/bin/../lib/gcc/mips64-unknown-linux-gnu/5.2.0/../../../../mips64-unknown-linux-gnu/bin/objcopy
READELF = mips64-unknown-linux-gnu-readelf

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
o32-fpabi = 
mips-mode-switch = yes
default-abi = n64_hard
build-mathvec = no
