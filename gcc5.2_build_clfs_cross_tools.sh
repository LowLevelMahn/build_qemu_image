#!/bin/bash

function die {
  echo "!!!ERROR!!! STEP=${STEP_STR} sub-step=$1"
  exit $1
}

# die on laste error != 0
function die_on_error {
  if [ $? != 0 ]; then
    die $1 
  fi
}

function die_on_any_error {
  last_pipe_status=("${PIPESTATUS[@]}") # do not forget ()
  last_error=$?

  # echo "last_pipe_status: ${last_pipe_status[*]} "
  # echo "last_error: ${last_error} "
  # echo "last_pipe_status size: ${#last_pipe_status[@]}"

  for IX in ${!last_pipe_status[*]}
  do
    STATUS=${last_pipe_status[$IX]}
    # echo "last_pipe_status[$IX]: $STATUS"
    if [ "$STATUS" != "0" ]; then
      # echo ${last_pipe_status[*]}
      die $1 
    fi 
  done
}

# file not found die
function die_on_missing_file {
  if [ ! -f "$2" ]; then
    die $1
  fi
}

# directory not found die
function die_on_missing_directory {
  if [ ! -d "$2" ]; then
    die $1
  fi
}

function die_on_empty_var {
  if [ -z "$2" ]; then
    die $1
  fi
}


# based on freshly installed vmware player debian 8.1/ubuntu 15.04 amd64 (64bit user-space)
# ------------------
# needed packages for cross build
# ------------------
# apt-get install ncurses-dev sudo tree g++ git bison gawk
# ------------------
#
# (should) build qemu linux images for:
#   qemu-alpha default: cpu: Alpha, cpu model: EV67, system type: Tsunami, system variation: Clipper
#   qemu-sparc64 default: cpu: TI UltraSparc IIi (Sabre), fpu: UltraSparc IIi integrated FPU, pmu: ultra12, type: sun4u, cpucaps: flush,stbar,swap,muldiv,v9,mul32,div32,v8plus,vis
#   qemu-mips64 default: system type: MIPS Malta, cpu model: MIPS 20kc V10.0 FPU V0.0

# =============================================================
# possible targets
readonly TARGET_SYSTEM_ALPHA=alpha
readonly TARGET_SYSTEM_SPARC64_64=sparc64-64
readonly TARGET_SYSTEM_MIPS64_64=mips64-64
readonly TARGET_SYSTEM_PPC64_64=ppc64-64
readonly TARGET_SYSTEM_S390X_64=s390x-64
# =============================================================

# =============================================================
# choose target to build !!!
# =============================================================

TARGET_SYSTEM=$1
# TARGET_SYSTEM=${TARGET_SYSTEM_SPARC64_64}

BEGIN_STEP=$2
END_STEP=$3

# BEGIN_STEP=0
# END_STEP=20

# =============================================================
# set configuration for target
# =============================================================
CLFS_HOST=$(echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/')
die_on_any_error 100

PARALLEL_MAKE_JOBS=5 # the old (cores + 1)

GLIBC_STEP_16_FLAGS="libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes libc_cv_gnu89_inline=yes libc_cv_ssp=no"

case ${TARGET_SYSTEM} in
  ${TARGET_SYSTEM_ALPHA})
    CLFS_TARGET="alphaev67-unknown-linux-gnu"
    LINUX_ARCH=alpha
    GCC_BUILD_FLAGS=""
    GLIBC_STEP_16_FLAGS="${GLIBC_STEP_16_FLAGS} libc_cv_alpha_tls=yes"
    GCCTARGET="-mcpu=ev67 -mtune=ev67"
    BUILD64="${GCCTARGET}"
    LINUX_CONFIG=defconfig
    TARGET_BUILD=
    PREPARED_LINUX_CONFIG=linux-config-4.2.3-alpha
  ;;
  ${TARGET_SYSTEM_SPARC64_64})
    CLFS_TARGET="sparc64-unknown-linux-gnu"
    LINUX_ARCH=sparc64
    GCC_BUILD_FLAGS=""
    GLIBC_STEP_16_FLAGS="${GLIBC_STEP_16_FLAGS} libc_cv_sparc64_tls=yes"
    GCCTARGET="-mcpu=ultrasparc -mtune=ultrasparc"
    BUILD64="${GCCTARGET} -m64"
    LINUX_CONFIG=defconfig    
    TARGET_BUILD="-m64"    
    PREPARED_LINUX_CONFIG=linux-config-4.2.3-sparc64-64
  ;;
  ${TARGET_SYSTEM_MIPS64_64})
    CLFS_TARGET="mips64-unknown-linux-gnu" # big endian
    # CLFS_TARGET="mips64el-unknown-linux-gnu" # little endian
    LINUX_ARCH=mips
    GCC_BUILD_FLAGS="--with-abi=64"
    GLIBC_STEP_16_FLAGS="${GLIBC_STEP_16_FLAGS} libc_cv_mips_tls=yes"
    GCCTARGET="-march=5kc -mtune=5kc" # or 20kc
    BUILD64="${GCCTARGET} -mabi=64"
    LINUX_CONFIG=malta_defconfig
    TARGET_BUILD="-mabi=64"   
    PREPARED_LINUX_CONFIG=linux-config-4.2.3-mips64-64
  ;;
  ${TARGET_SYSTEM_PPC64_64})
    CLFS_TARGET="powerpc64-unknown-linux-gnu"
    LINUX_ARCH=powerpc
    GCC_BUILD_FLAGS=""
    GLIBC_STEP_16_FLAGS="${GLIBC_STEP_16_FLAGS}"
    GCCTARGET=""
    BUILD64="${GCCTARGET} -m64"
    LINUX_CONFIG=defconfig    
    TARGET_BUILD="-m64"    
    PREPARED_LINUX_CONFIG=linux-config-4.2.3-ppc64-64
  ;;  
  ${TARGET_SYSTEM_S390X_64})
    CLFS_TARGET="s390x-unknown-linux-gnu"
    LINUX_ARCH=s390
    GCC_BUILD_FLAGS=""
    GLIBC_STEP_16_FLAGS="${GLIBC_STEP_16_FLAGS}"
    GCCTARGET=""
    BUILD64="${GCCTARGET} -m64"
    LINUX_CONFIG=defconfig    
    TARGET_BUILD="-m64"    
    PREPARED_LINUX_CONFIG=
  ;;    
  *)
    echo "unknown target-system: arg1"
    exit 1
  ;;
esac

# =============================================================
# configure pathes
# =============================================================
SCRIPT_PATH=$(dirname $(readlink -f $0))
BUILD_ROOT=${SCRIPT_PATH}/clfs_cross_tools
FILES=${BUILD_ROOT}/files
CLFS=${BUILD_ROOT}/system/${TARGET_SYSTEM}
CLFS_LOG="${CLFS}/build_log"
CLFS_SOURCES=${CLFS}/sources
CLFS_TOOLS=${CLFS}/tools
CLFS_CROSS_TOOLS=${CLFS}/cross-tools
BUILD_CONFIG_LOG=${CLFS_LOG}/build.config
TOOLS=/tools
CROSS_TOOLS=/cross-tools

# =============================================================
# log script configuration
# =============================================================
set +h
PATH=/cross-tools/bin:$PATH
LC_ALL=POSIX
unset CFLAGS CXXFLAGS
export PATH LC_ALL

# extract package from files directory into build-source and change into the extracted directory
function prepare_source_package {
  PACKAGE=$1
  echo "PACKAGE: ${PACKAGE}"

  PACKAGE_FILE=$(find ${FILES} -name "${PACKAGE}")
  die_on_any_error 0
  die_on_missing_file 1 "${PACKAGE_FILE}"
  echo "PACKAGE_FILE: ${PACKAGE_FILE}"

  PACKAGE_DIR="$(tar tpf ${PACKAGE_FILE} | head -1 | sed -e 's/\/.*//')"
  die_on_any_error 2
  echo "PACKAGE_DIR: ${PACKAGE_DIR}"
  rm -rf ${PACKAGE_DIR}
  die_on_any_error 3
  die_on_empty_var 4 "${PACKAGE_DIR}"

  tar -xpf ${PACKAGE_FILE} -C ${CLFS_SOURCES}
  die_on_any_error 5
  
  PACKAGE_SOURCE=${CLFS_SOURCES}/${PACKAGE_DIR}
  cd ${PACKAGE_SOURCE}
  die_on_any_error 6

  STEP_PACKAGE_NAME="step_${STEP_STR}_${PACKAGE_DIR}"
  echo "STEP_PACKAGE_NAME: ${STEP_PACKAGE_NAME}"

  STEP_LOG_DIR="${CLFS_LOG}/${STEP_PACKAGE_NAME}"
  echo "STEP_LOG_DIR: ${STEP_LOG_DIR}"

  mkdir -vp ${STEP_LOG_DIR}
  die_on_any_error 7
}

# deletes current build-source package
function remove_source_package {
  die_on_missing_directory 0 "${PACKAGE_SOURCE}"
  rm -rf ${PACKAGE_SOURCE}
  die_on_any_error 1
  unset PACKAGE
  unset PACKAGE_FILE
  unset PACKAGE_DIR
  unset PACKAGE_SOURCE
}

if [ -d "${CLFS_TOOLS}" ]; then
(sudo ln -svf ${CLFS_TOOLS} /)
fi

if [ -d "${CLFS_CROSS_TOOLS}" ]; then
(sudo ln -svf ${CLFS_CROSS_TOOLS} /)
fi

# =============================================================
# build steps
# =============================================================
for STEP in `seq $BEGIN_STEP $END_STEP`;
do

STEP_STR=`printf %02d ${STEP}`

if [ "$STEP" -ge "18" ]
then
# http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/temp-system/variables.html

# export is needed for sub-processes - export does not pollute the parent-process
export CC="${CLFS_TARGET}-gcc ${BUILD64}"
export CXX="${CLFS_TARGET}-g++ ${BUILD64}"
export AR="${CLFS_TARGET}-ar"
export AS="${CLFS_TARGET}-as"
export RANLIB="${CLFS_TARGET}-ranlib"
export LD="${CLFS_TARGET}-ld"
export STRIP="${CLFS_TARGET}-strip"

echo "CC: ${CC}"
echo "CXX: ${CXX}"
echo "AR: ${AR}"
echo "AS: ${AS}"
echo "RANLIB: ${RANLIB}"
echo "LD: ${LD}"
echo "STRIP: ${STRIP}"
fi

  case ${STEP} in
    0)
# -------------------------------------------
# download files
# -------------------------------------------

# http://www.bastoul.net/cloog/pages/download/cloog-0.18.2.tar.gz not needed for gcc 5.2
# http://ftp.gnu.org/gnu/m4/m4-latest.tar.gz
# http://isl.gforge.inria.fr/isl-0.15.tar.xz - does not work with gcc 5.2 release - only gcc 5.2.x develop git

FILE_URLS=(
"http://ftp.clfs.org/pub/clfs/conglomeration/file/file-5.25.tar.gz"
"https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.2.3.tar.xz"
"http://ftp.gnu.org/gnu/m4/m4-1.4.17.tar.xz"
"http://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz"
"http://sourceforge.net/projects/pkgconfiglite/files/0.28-1/pkg-config-lite-0.28-1.tar.gz"
"http://ftp.gnu.org/gnu/gmp/gmp-6.0.0a.tar.xz"
"http://www.mpfr.org/mpfr-current/mpfr-3.1.3.tar.xz"
"ftp://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz"
"http://isl.gforge.inria.fr/isl-0.14.tar.bz2"
"http://ftp.gnu.org/gnu/binutils/binutils-2.25.1.tar.bz2"
"ftp://gcc.gnu.org/pub/gcc/releases/gcc-5.2.0/gcc-5.2.0.tar.bz2"
"http://ftp.gnu.org/gnu/glibc/glibc-2.22.tar.xz"
"http://ftp.gnu.org/gnu/bash/bash-4.4-beta.tar.gz"
"http://ftp.gnu.org/gnu/coreutils/coreutils-8.24.tar.xz"
"https://www.kernel.org/pub/linux/utils/util-linux/v2.27/util-linux-2.27.tar.xz"
)

for IX in ${!FILE_URLS[*]}
do
  FILE_URL=${FILE_URLS[$IX]}
  wget -N ${FILE_URL} -P ${FILES}/
  die_on_any_error ${IX}
done
#--------------------------------------------
    ;;
    1)
# -------------------------------------------
# create base directories
# -------------------------------------------
mkdir -pv ${BUILD_ROOT}
die_on_any_error 0
mkdir -pv ${FILES}
die_on_any_error 1
mkdir -pv ${CLFS}
die_on_any_error 2
mkdir -pv ${CLFS_LOG}
die_on_any_error 3

cat > ${BUILD_CONFIG_LOG} << EOF
# pathes
SCRIPT_PATH=${SCRIPT_PATH}
BUILD_ROOT=${BUILD_ROOT}
FILES=${FILES}
CLFS=${CLFS}
CLFS_SOURCES=${CLFS_SOURCES}
CLFS_TOOLS=${CLFS_TOOLS}
CLFS_CROSS_TOOLS=${CLFS_CROSS_TOOLS}
PATH=${PATH}
LC_ALL=${LC_ALL}
CFLAGS=${CFLAGS}
CXXFLAGS=${CXXFLAGS}
# target
TARGET_SYSTEM=${TARGET_SYSTEM}
CLFS_TARGET=${CLFS_TARGET}
LINUX_ARCH=${LINUX_ARCH}
BUILD64=${BUILD64}
GCCTARGET=${GCCTARGET}
EOF
# -------------------------------------------
    ;;
    2)
# -------------------------------------------
# 3.1. Introduction -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/materials/introduction.html
# -------------------------------------------
rm -vfr ${CLFS_SOURCES}
mkdir -v ${CLFS_SOURCES}
die_on_any_error 0
chmod -v a+wt ${CLFS_SOURCES}
die_on_any_error 1
# -------------------------------------------
    ;;
    3)
# -------------------------------------------
# 4.2. Creating the ${CLFS}/tools Directory -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/final-preps/creatingtoolsdir.html
# 4.3. Creating the ${CLFS}/cross-tools Directory -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/final-preps/creatingcrossdir.html
# -------------------------------------------
install -dv ${CLFS_TOOLS}
die_on_any_error 0
(sudo ln -svf ${CLFS_TOOLS} /)
die_on_any_error 1

install -dv ${CLFS_CROSS_TOOLS}
die_on_any_error 2
(sudo ln -svf ${CLFS_CROSS_TOOLS} /)
die_on_any_error 3
# -------------------------------------------
    ;;
    4)
# -------------------------------------------
# 5.2. File-5.19 -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/file.html
# -------------------------------------------
prepare_source_package file-5.25.tar.gz

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 0
mkdir -vp ${BUILD_DIR}
die_on_any_error 1

cd ${BUILD_DIR}
die_on_any_error 2

../${PACKAGE_DIR}/configure --prefix=/cross-tools --disable-static 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 3

cp -r ${BUILD_DIR} ${STEP_LOG_DIR}
die_on_any_error 4

make -j"${PARALLEL_MAKE_JOBS}" 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 5

make -j"${PARALLEL_MAKE_JOBS}" install 2>&1 | tee "${STEP_LOG_DIR}/make_install.out"
die_on_any_error 6

rm -rf ${BUILD_DIR}
die_on_any_error 7
 
remove_source_package
# -------------------------------------------
    ;;
    5)
# -------------------------------------------
# 5.3. Linux-3.14.21 Headers -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/linux-headers.html
# -------------------------------------------
prepare_source_package linux-4.2.3.tar.xz

# xzcat "${FILES}/patch-3.14.21.xz" | patch -Np1 -i -
# die_on_any_error 0

make mrproper 2>&1 | tee "${STEP_LOG_DIR}/make_mrproper.out"
die_on_any_error 1

make ARCH=${LINUX_ARCH} headers_check 2>&1 | tee "${STEP_LOG_DIR}/make_headers_check.out"
die_on_any_error 2

make ARCH=${LINUX_ARCH} INSTALL_HDR_PATH=/tools headers_install 2>&1 | tee "${STEP_LOG_DIR}/make_headers_install.out"
die_on_any_error 3

remove_source_package
# -------------------------------------------
    ;;
    6)
# -------------------------------------------
# 5.4. M4-1.4.17 -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/m4.html
# -------------------------------------------
prepare_source_package m4-1.4.17.tar.xz

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 0
mkdir -vp ${BUILD_DIR}
die_on_any_error 1

cd ${BUILD_DIR}
die_on_any_error 2

../${PACKAGE_DIR}/configure --prefix=/cross-tools --disable-static 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 3

cp -r ${BUILD_DIR} ${STEP_LOG_DIR}
die_on_any_error 4

make -j"${PARALLEL_MAKE_JOBS}" 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 5

make -j"${PARALLEL_MAKE_JOBS}" install 2>&1 | tee "${STEP_LOG_DIR}/make_install.out"
die_on_any_error 6

rm -rf ${BUILD_DIR}
die_on_any_error 7
 
remove_source_package
# -------------------------------------------
    ;;
    7)
# -------------------------------------------
# 5.5. Ncurses-5.9 -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/ncurses.html
# -------------------------------------------
prepare_source_package ncurses-6.0.tar.gz

# patch -Np1 -i "${FILES}/ncurses-5.9-bash_fix-1.patch"
# die_on_any_error 3

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 0
mkdir -vp ${BUILD_DIR}
die_on_any_error 1

cd ${BUILD_DIR}
die_on_any_error 2

../${PACKAGE_DIR}/configure --prefix=/cross-tools --without-debug --without-shared 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 4

cp -r ${BUILD_DIR} ${STEP_LOG_DIR}
die_on_any_error 5

make -j"${PARALLEL_MAKE_JOBS}" -C include 2>&1 | tee "${STEP_LOG_DIR}/make_c_include.out"
die_on_any_error 6

make -j"${PARALLEL_MAKE_JOBS}" -C progs tic 2>&1 | tee "${STEP_LOG_DIR}/make_c_progs_tic.out"
die_on_any_error 7

install -v -m755 progs/tic /cross-tools/bin
die_on_any_error 8

rm -rf ${BUILD_DIR}
die_on_any_error 9
 
remove_source_package
# -------------------------------------------
    ;;
    8)
# -------------------------------------------
# 5.6. Pkg-config-lite-0.28-1 -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/pkg-config-lite.html
# -------------------------------------------
prepare_source_package pkg-config-lite-0.28-1.tar.gz

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 0
mkdir -vp ${BUILD_DIR}
die_on_any_error 1

cd ${BUILD_DIR}
die_on_any_error 2

../${PACKAGE_DIR}/configure --prefix=/cross-tools --host=${CLFS_TARGET} --with-pc-path=/tools/lib/pkgconfig:/tools/share/pkgconfig 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 3

cp -r ${BUILD_DIR} ${STEP_LOG_DIR}
die_on_any_error 4

make -j"${PARALLEL_MAKE_JOBS}" 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 5

make -j"${PARALLEL_MAKE_JOBS}" install 2>&1 | tee "${STEP_LOG_DIR}/make_install.out"
die_on_any_error 6

rm -rf ${BUILD_DIR}
die_on_any_error 7
 
remove_source_package
# -------------------------------------------
    ;;
    9)
# -------------------------------------------
# 5.7. GMP-6.0.0 -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/gmp.html
# -------------------------------------------
prepare_source_package gmp-6.0.0a.tar.xz

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 0
mkdir -vp ${BUILD_DIR}
die_on_any_error 1

cd ${BUILD_DIR}
die_on_any_error 2

../${PACKAGE_DIR}/configure --prefix=/cross-tools --enable-cxx ABI=64 --disable-static 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 3

cp -r ${BUILD_DIR} ${STEP_LOG_DIR}
die_on_any_error 4

make -j"${PARALLEL_MAKE_JOBS}" 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 5

make -j"${PARALLEL_MAKE_JOBS}" install 2>&1 | tee "${STEP_LOG_DIR}/make_install.out"
die_on_any_error 6

rm -rf ${BUILD_DIR}
die_on_any_error 7
 
remove_source_package
# -------------------------------------------
    ;;
    10)
# -------------------------------------------
# 5.8. MPFR-3.1.2 -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/mpfr.html
# -------------------------------------------
prepare_source_package mpfr-3.1.3.tar.xz

# patch -Np1 -i "${FILES}/mpfr-3.1.2-fixes-4.patch"
# die_on_any_error 0

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 1
mkdir -vp ${BUILD_DIR}
die_on_any_error 2

cd ${BUILD_DIR}
die_on_any_error 3

LDFLAGS="-Wl,-rpath,/cross-tools/lib" ../${PACKAGE_DIR}/configure --prefix=/cross-tools --disable-static --with-gmp=/cross-tools 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 4

cp -r ${BUILD_DIR} ${STEP_LOG_DIR}
die_on_any_error 5

make -j"${PARALLEL_MAKE_JOBS}" 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 6

make -j"${PARALLEL_MAKE_JOBS}" install 2>&1 | tee "${STEP_LOG_DIR}/make_install.out"
die_on_any_error 7

rm -rf ${BUILD_DIR}
die_on_any_error 8
 
remove_source_package
# -------------------------------------------
    ;;
    11)
# -------------------------------------------
# 5.9. MPC-1.0.2 -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/mpc.html
# -------------------------------------------
prepare_source_package mpc-1.0.3.tar.gz

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 0
mkdir -vp ${BUILD_DIR}
die_on_any_error 1

cd ${BUILD_DIR}
die_on_any_error 2

LDFLAGS="-Wl,-rpath,/cross-tools/lib" ../${PACKAGE_DIR}/configure --prefix=/cross-tools --disable-static --with-gmp=/cross-tools --with-mpfr=/cross-tools 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 3

cp -r ${BUILD_DIR} ${STEP_LOG_DIR}
die_on_any_error 4

make -j"${PARALLEL_MAKE_JOBS}" 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 5

make -j"${PARALLEL_MAKE_JOBS}" install 2>&1 | tee "${STEP_LOG_DIR}/make_install.out"
die_on_any_error 6

rm -rf ${BUILD_DIR}
die_on_any_error 7
 
remove_source_package
# -------------------------------------------
    ;;
    12)
# -------------------------------------------
# 5.10. ISL-0.12.2 -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/isl.html
# -------------------------------------------
prepare_source_package isl-0.14.tar.bz2

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 0
mkdir -vp ${BUILD_DIR}
die_on_any_error 1

cd ${BUILD_DIR}
die_on_any_error 2

LDFLAGS="-Wl,-rpath,/cross-tools/lib" ../${PACKAGE_DIR}/configure --prefix=/cross-tools --disable-static --with-gmp-prefix=/cross-tools 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 3

cp -r ${BUILD_DIR} ${STEP_LOG_DIR}
die_on_any_error 4

make -j"${PARALLEL_MAKE_JOBS}" 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 5

make -j"${PARALLEL_MAKE_JOBS}" install 2>&1 | tee "${STEP_LOG_DIR}/make_install.out"
die_on_any_error 6

rm -rf ${BUILD_DIR}
die_on_any_error 7
 
remove_source_package
# -------------------------------------------
    ;;
    13)
# -------------------------------------------
# 5.11. CLooG-0.18.2 -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/cloog.html
# -------------------------------------------
# not needed for gcc 5.2
# -------------------------------------------
    ;;
    14)
# -------------------------------------------
# 5.12. Cross Binutils-2.24 -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/binutils.html
# -------------------------------------------
prepare_source_package binutils-2.25.1.tar.bz2

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 0
mkdir -vp ${BUILD_DIR}
die_on_any_error 1

cd ${BUILD_DIR}
die_on_any_error 2

AR=ar AS=as ../${PACKAGE_DIR}/configure \
--prefix=/cross-tools --host=${CLFS_HOST} --target=${CLFS_TARGET} \
--with-sysroot=${CLFS} --with-lib-path=/tools/lib --disable-nls \
--disable-static --enable-64-bit-bfd --disable-multilib --disable-werror 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 3

cp -r ${BUILD_DIR} ${STEP_LOG_DIR}
die_on_any_error 4

make -j"${PARALLEL_MAKE_JOBS}" 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 5

make -j"${PARALLEL_MAKE_JOBS}" install 2>&1 | tee "${STEP_LOG_DIR}/make_install.out"
die_on_any_error 6

"${CLFS_CROSS_TOOLS}/bin/${CLFS_TARGET}-ld" --verbose | grep SEARCH_DIR | tr -s ' ;' \\012 > "${STEP_LOG_DIR}/ld_SEARCHDIR.out"
die_on_any_error 7

rm -rf ${BUILD_DIR}
die_on_any_error 8
 
remove_source_package
# -------------------------------------------
    ;;
    15)
# -------------------------------------------
# 5.13. Cross GCC-4.8.3 - Static -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/gcc-static.html
# -------------------------------------------
prepare_source_package gcc-5.2.0.tar.bz2

patch -Np1 -i "${FILES}/gcc-5.20-gcc.c-STANDARD_STARTFILE_PREFIX.patch"
die_on_any_error 0

# read -p "Press [Enter] key..."

touch /tools/include/limits.h
die_on_any_error 4

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 5
mkdir -vp ${BUILD_DIR}
die_on_any_error 6

cd ${BUILD_DIR}
die_on_any_error 7

AR=ar LDFLAGS="-Wl,-rpath,/cross-tools/lib" \
../${PACKAGE_DIR}/configure --prefix=/cross-tools \
--build=${CLFS_HOST} --host=${CLFS_HOST} --target=${CLFS_TARGET} \
--with-sysroot=${CLFS} --with-local-prefix=/tools \
--with-native-system-header-dir=/tools/include --disable-nls \
--disable-shared --with-mpfr=/cross-tools --with-gmp=/cross-tools \
--with-isl=/cross-tools --with-mpc=/cross-tools \
--without-headers --with-newlib --disable-decimal-float --disable-libgomp \
--disable-libmudflap --disable-libssp --disable-libatomic --disable-libitm \
--disable-libsanitizer --disable-libquadmath --disable-threads \
--disable-multilib --disable-target-zlib --with-system-zlib "${GCC_BUILD_FLAGS}" \
--enable-languages=c --enable-checking=release 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 8

cp -r ${BUILD_DIR} ${STEP_LOG_DIR}
die_on_any_error 9

make -j"${PARALLEL_MAKE_JOBS}" all-gcc all-target-libgcc 2>&1 | tee "${STEP_LOG_DIR}/make_all_gcc_all_target_libgcc.out"
die_on_any_error 10

make -j"${PARALLEL_MAKE_JOBS}" install-gcc install-target-libgcc 2>&1 | tee "${STEP_LOG_DIR}/make_install_gcc_install_libgcc.out"
die_on_any_error 11

"${CLFS_CROSS_TOOLS}/bin/${CLFS_TARGET}-gcc" -print-search-dirs | sed '/^lib/b 1;d;:1;s,/[^/.][^/]*/\.\./,/,;t 1;s,:[^=]*=,:;,;s,;,;  ,g' | tr \; \\012 > "${STEP_LOG_DIR}/gcc_search_dirs.out"
die_on_any_error 12

cat "${STEP_LOG_DIR}/gcc_search_dirs.out" | sed -e $'s/:/\\\n/g' | sed 's/\/'"$TARGET_SYSTEM"'\//\/'{TARGET_SYSTEM}'\//g' | sed 's/'"$CLFS_TARGET"'/'{CLFS_TARGET}'/g'  > "${STEP_LOG_DIR}/gcc_search_dirs.diffable.out"

rm -rf ${BUILD_DIR}
die_on_any_error 13
 
remove_source_package
# -------------------------------------------
    ;;
    16)
# -------------------------------------------
# 5.14. Glibc-2.19 -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/glibc.html
# -------------------------------------------
prepare_source_package glibc-2.22.tar.xz

cp -v timezone/Makefile{,.orig}
die_on_any_error 0

sed 's/\\$$(pwd)/`pwd`/' timezone/Makefile.orig > timezone/Makefile
die_on_any_error 1

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 2
mkdir -vp ${BUILD_DIR}
die_on_any_error 3

cd ${BUILD_DIR}
die_on_any_error 4

echo ${GLIBC_STEP_16_FLAGS} > "config.cache"
die_on_any_error 5

BUILD_CC="gcc" CC="${CLFS_TARGET}-gcc ${BUILD64}" \
AR="${CLFS_TARGET}-ar" RANLIB="${CLFS_TARGET}-ranlib" \
../${PACKAGE_DIR}/configure --prefix=/tools \
--host=${CLFS_TARGET} --build=${CLFS_HOST} \
--disable-profile --enable-kernel=4.2.3 \
--with-binutils=/cross-tools/bin --with-headers=/tools/include \
--enable-obsolete-rpc  --cache-file=config.cache 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 6

cp -r ${BUILD_DIR} ${STEP_LOG_DIR}
die_on_any_error 7

make -j"${PARALLEL_MAKE_JOBS}" 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 8

make -j"${PARALLEL_MAKE_JOBS}" install 2>&1 | tee "${STEP_LOG_DIR}/make_install.out"
die_on_any_error 9

find "${CLFS}/tools/lib" -name "crt*.o" > "${STEP_LOG_DIR}/crt-path.out"

rm -rf ${BUILD_DIR}
die_on_any_error 10
 
remove_source_package
# -------------------------------------------
    ;;
    17)
# -------------------------------------------
# 5.15. Cross GCC-4.8.3 - Final -> http://www.clfs.org/view/CLFS-3.0.0-SYSTEMD/sparc64-64/cross-tools/gcc-final.html
# -------------------------------------------
prepare_source_package gcc-5.2.0.tar.bz2

patch -Np1 -i "${FILES}/gcc-5.20-gcc.c-STANDARD_STARTFILE_PREFIX.patch"
die_on_any_error 0

touch /tools/include/limits.h
die_on_any_error 4

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 5
mkdir -vp ${BUILD_DIR}
die_on_any_error 6

cd ${BUILD_DIR}
die_on_any_error 7

# added: --disable-libsanitizer (compile problems with sparc?)
# removed: --disable-static

# read again: http://www.linuxfromscratch.org/lfs/view/7.8/chapter05/gcc-pass2.html

AR=ar LDFLAGS="-Wl,-rpath,/cross-tools/lib" \
../${PACKAGE_DIR}/configure --prefix=/cross-tools \
--build=${CLFS_HOST} --target=${CLFS_TARGET} --host=${CLFS_HOST} \
--with-sysroot=${CLFS} --with-local-prefix=/tools \
--with-native-system-header-dir=/tools/include --disable-nls \
--enable-languages=c,c++ \
--enable-__cxa_atexit --enable-threads=posix \
--disable-multilib --with-mpc=/cross-tools --with-mpfr=/cross-tools \
--with-gmp=/cross-tools \
--with-isl=/cross-tools --with-system-zlib --enable-checking=release "${GCC_BUILD_FLAGS}" \
--disable-libsanitizer \
--enable-libstdcxx-time 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 8

cp -r ${BUILD_DIR} ${STEP_LOG_DIR}
die_on_any_error 9

make -j"${PARALLEL_MAKE_JOBS}" AS_FOR_TARGET="${CLFS_TARGET}-as" \
LD_FOR_TARGET="${CLFS_TARGET}-ld" 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 10
make -j"${PARALLEL_MAKE_JOBS}" install 2>&1 | tee "${STEP_LOG_DIR}/make_install.out"
die_on_any_error 11

# read again: http://www.linuxfromscratch.org/lfs/view/7.8/chapter05/gcc-libstdc++.html
# 

make -j"${PARALLEL_MAKE_JOBS}" all-target-libstdc++-v3 2>&1 | tee "${STEP_LOG_DIR}/make_all_target_libstdc++-v3.out"
die_on_any_error 12
make -j"${PARALLEL_MAKE_JOBS}" install-target-libstdc++-v3 2>&1 | tee "${STEP_LOG_DIR}/make_install_libstdc++-v3.out"
die_on_any_error 13

# libstdc++ is in "wrong" directory (find -name "libstdc++.a")

"${CLFS_CROSS_TOOLS}/bin/${CLFS_TARGET}-gcc" -print-search-dirs | sed '/^lib/b 1;d;:1;s,/[^/.][^/]*/\.\./,/,;t 1;s,:[^=]*=,:;,;s,;,;  ,g' | tr \; \\012 > "${STEP_LOG_DIR}/gcc_search_dirs.out"
die_on_any_error 14

cat "${STEP_LOG_DIR}/gcc_search_dirs.out" | sed -e $'s/:/\\\n/g' | sed 's/\/'"$TARGET_SYSTEM"'\//\/'{TARGET_SYSTEM}'\//g' | sed 's/'"$CLFS_TARGET"'/'{CLFS_TARGET}'/g'  > "${STEP_LOG_DIR}/gcc_search_dirs.diffable.out"

rm -rf ${BUILD_DIR}
die_on_any_error 15
 
remove_source_package
# -------------------------------------------
    ;;
    18)
# -------------------------------------------
# linux kernel for target
# -------------------------------------------
prepare_source_package linux-4.2.3.tar.xz

# make -d for debug

# just for beeing 100% safe
make -j"${PARALLEL_MAKE_JOBS}" distclean 2>&1 | tee "${STEP_LOG_DIR}/make_distclean.out"
die_on_any_error 0

make -j"${PARALLEL_MAKE_JOBS}" mrproper ARCH=${LINUX_ARCH} CROSS_COMPILE=${CLFS_TARGET}- 2>&1 | tee "${STEP_LOG_DIR}/make_mrproper.out"
die_on_any_error 1

# ---
# use prepared config
cp "${FILES}/${PREPARED_LINUX_CONFIG}" ./.config
die_on_any_error 100

# re-check the prepared config
make -j"${PARALLEL_MAKE_JOBS}" ARCH=${LINUX_ARCH} CROSS_COMPILE=${CLFS_TARGET}- oldconfig 2>&1 | tee "${STEP_LOG_DIR}/make_oldconfig.out"
die_on_any_error 101
# ---

## create .config from default
# make -j"${PARALLEL_MAKE_JOBS}" ARCH=${LINUX_ARCH} CROSS_COMPILE=${CLFS_TARGET}- "${LINUX_CONFIG}" 2>&1 | tee "${STEP_LOG_DIR}/make_${LINUX_CONFIG}.out"
# die_on_any_error 2

## make can't find qt4 if /cross-tools/bin/pkg-config(pgk-config-lite) is in path - temporary rename
#echo -------------
#pkg-config --exists --print-errors "QtCore"
#type pkg-config
#echo -------------
## use xconfig
#make -j"${PARALLEL_MAKE_JOBS}" ARCH=${LINUX_ARCH} CROSS_COMPILE=${CLFS_TARGET}- xconfig 2>&1 | tee "${STEP_LOG_DIR}/make_xconfig.out"
#die_on_any_error 3

make -j"${PARALLEL_MAKE_JOBS}" ARCH=${LINUX_ARCH} CROSS_COMPILE=${CLFS_TARGET}- 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 4

mkdir -pv /tools/boot
die_on_any_error 5

cp -v vmlinux /tools/boot/clfskernel-4.2.3
die_on_any_error 6

cp -v System.map /tools/boot/System.map-4.2.3
die_on_any_error 7

cp -v .config /tools/boot/config-4.2.3
die_on_any_error 8

remove_source_package
# -------------------------------------------
    ;;
    19)
# -------------------------------------------
# init hello world
# -------------------------------------------

STEP_LOG_DIR="${CLFS_LOG}/step_${STEP_STR}_init_c"
mkdir -pv "${STEP_LOG_DIR}"

cd ${CLFS_SOURCES}

cat > init.cpp << "EOF"
#include <stdio.h>
#include <iostream> 

int main() {
  printf("printf Hello World!\n");
  std::cout << "std::cout Hello World!" << std::endl;
  while(1);
  return 1;
}
EOF
die_on_any_error 0

"${CLFS_TARGET}-g++" -print-search-dirs | sed '/^lib/b 1;d;:1;s,/[^/.][^/]*/\.\./,/,;t 1;s,:[^=]*=,:;,;s,;,;  ,g' | tr \; \\012 > "${STEP_LOG_DIR}/g++_search_dirs.out"
die_on_any_error 100

cat "${STEP_LOG_DIR}/g++_search_dirs.out" | sed -e $'s/:/\\\n/g' | sed 's/\/'"$TARGET_SYSTEM"'\//\/'{TARGET_SYSTEM}'\//g' | sed 's/'"$CLFS_TARGET"'/'{CLFS_TARGET}'/g'  > "${STEP_LOG_DIR}/gcc_search_dirs.diffable.out"
die_on_any_error 200

cat "${STEP_LOG_DIR}/g++_search_dirs.out" | sed -e $'s/:/\\\n/g' > "${STEP_LOG_DIR}/gcc_search_dirs.newline.out"
die_on_any_error 300

file "${CLFS_CROSS_TOOLS}/${CLFS_TARGET}/lib/libstdc++.a"

file "${CLFS_CROSS_TOOLS}/${CLFS_TARGET}/bin/ld"

# ld path on binutils build
# "${CLFS_CROSS_TOOLS}/bin/${CLFS_TARGET}-ld"

# ld binary in use here
"${CLFS_CROSS_TOOLS}/${CLFS_TARGET}/bin/ld" --verbose | grep SEARCH_DIR | tr -s ' ;' \\012 > "${STEP_LOG_DIR}/bin_ld_SEARCHDIR.out"

# nothing happes after kernel boot if using -static-libstdc++ -static-libgcc
CMD="${CLFS_TARGET}-g++ "${BUILD64}" -static init.cpp -o init"
echo "CMD: $CMD"

$CMD 2>&1 | tee "${STEP_LOG_DIR}/compile_init_cpp.out"
die_on_any_error 1

chmod +x init
die_on_any_error 2

find init | cpio -H newc -o > /tools/boot/initrd.cpio 2>&1 | tee "${STEP_LOG_DIR}/create_initrd.cpio.out"
die_on_any_error 3

## check cpio
# cpio -idv < initramfs.cpio 
# die_on_any_error 300
# file init
# die_on_any_error 400

rm -rf init.c
die_on_any_error 4

rm -rf init
die_on_any_error 5

tree "${CLFS}/cross-tools" > "${CLFS}/cross-tools.tree"
tree "${CLFS}/tools" > "${CLFS}/tools.tree"

# -------------------------------------------
    ;;
    20)
# -------------------------------------------
# bash
# -------------------------------------------
prepare_source_package bash-4.4-beta.tar.gz

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 0
mkdir -vp ${BUILD_DIR}
die_on_any_error 1

cd ${BUILD_DIR}
die_on_any_error 2

cat > config.cache << "EOF"
ac_cv_func_mmap_fixed_mapped=yes
ac_cv_func_strcoll_works=yes
ac_cv_func_working_mktime=yes
bash_cv_func_sigsetjmp=present
bash_cv_getcwd_malloc=yes
bash_cv_job_control_missing=present
bash_cv_printf_a_format=yes
bash_cv_sys_named_pipes=present
bash_cv_ulimit_maxfds=yes
bash_cv_under_sys_siglist=yes
bash_cv_unusable_rtsigs=no
gt_cv_int_divbyzero_sigfpe=yes
EOF
die_on_any_error 3

../${PACKAGE_DIR}/configure --prefix=/tools \
    --build=${CLFS_HOST} --host=${CLFS_TARGET} \
    --without-bash-malloc --cache-file=config.cache 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 4    

make 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 5

make install 2>&1 | tee "${STEP_LOG_DIR}/make_install.out"
die_on_any_error 6

remove_source_package
# -------------------------------------------
   ;;    
   21)
# -------------------------------------------
# util-linux
# -------------------------------------------
prepare_source_package util-linux-2.27.tar.xz

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 0
mkdir -vp ${BUILD_DIR}
die_on_any_error 1

cd ${BUILD_DIR}
die_on_any_error 2

../${PACKAGE_DIR}/configure --prefix=/tools \
--build=${CLFS_HOST} --host=${CLFS_TARGET} \
--disable-makeinstall-chown --disable-makeinstall-setuid \
--without-ncurses 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 3
    
make 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 4

make install 2>&1 | tee "${STEP_LOG_DIR}/make_install.out"
die_on_any_error 5

remove_source_package
# -------------------------------------------
   ;;    
   22)
# -------------------------------------------
# coreutils
# -------------------------------------------
prepare_source_package coreutils-8.24.tar.xz

set -- man/*.x
die_on_any_error 100

touch ${@/%x/1}
die_on_any_error 200

patch -Np1 -i "${FILES}/coreutils-8.24-noman-1.patch"
die_on_any_error 300

BUILD_DIR="../${STEP_PACKAGE_NAME}-build"
rm -rf ${BUILD_DIR}
die_on_any_error 0
mkdir -vp ${BUILD_DIR}
die_on_any_error 1

cd ${BUILD_DIR}
die_on_any_error 2

cat > config.cache << EOF
fu_cv_sys_stat_statfs2_bsize=yes
gl_cv_func_working_mkstemp=yes
EOF
die_on_any_error 3

../${PACKAGE_DIR}/configure --prefix=/tools \
--build=${CLFS_HOST} --host=${CLFS_TARGET} \
--enable-install-program=hostname --cache-file=config.cache 2>&1 | tee "${STEP_LOG_DIR}/configure.out"
die_on_any_error 4

make 2>&1 | tee "${STEP_LOG_DIR}/make.out"
die_on_any_error 5

make install 2>&1 | tee "${STEP_LOG_DIR}/make_install.out"
die_on_any_error 6

remove_source_package
# -------------------------------------------
  ;;    
  23)
# -------------------------------------------
# big initrd
# -------------------------------------------
BIG_INITRD=${CLFS}/big_initrd

rm -rf ${BIG_INITRD}
die_on_any_error 0
mkdir -p ${BIG_INITRD}/tools
die_on_any_error 1

rm -f ${CLFS}/big_initrd.cpio
die_on_any_error 2

cp -r ${CLFS}/tools ${BIG_INITRD}
die_on_any_error 3

cd ${BIG_INITRD}
die_on_any_error 4
  
# relative links
ln -r -s ./tools/bin ${BIG_INITRD}/bin
die_on_any_error 5
ln -r -s ./tools/sbin ${BIG_INITRD}/sbin
die_on_any_error 6
ln -r -s ./tools/lib ${BIG_INITRD}/lib
die_on_any_error 7

rm -f init
die_on_any_error 8

find . | cpio -H newc -o > ${CLFS}/big_initrd.cpio
die_on_error 9
  
# -------------------------------------------
  ;;   
  esac
done

