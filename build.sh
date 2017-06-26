#!/bin/bash -e
. /etc/profile.d/modules.sh
SOURCE_FILE=v${VERSION}.tar.gz

module add ci
module add gcc/${GCC_VERSION}
module add openblas/0.2.19-gcc-${GCC_VERSION}
module add fftw/3.3.4-gcc-${GCC_VERSION}-mpi-1.8.8
module add python/${PYTHON_VERSION}-gcc-${GCC_VERSION}
module add openssl/1.0.2j
export VERSION_MAJOR=${PYTHON_VERSION:0:1} # Should be 2.7 or 3.4 or similar
export VERSION_MINOR=${PYTHON_VERSION:0:3} # Should be 2.7 or 3.4 or similar

mkdir -p $WORKSPACE
mkdir -p $SRC_DIR
mkdir -p $SOFT_DIR

#  Download the source file

if [ ! -e ${SRC_DIR}/${SOURCE_FILE}.lock ] && [ ! -s ${SRC_DIR}/${SOURCE_FILE} ] ; then
  touch ${SRC_DIR}/${SOURCE_FILE}.lock
  echo "seems like this is the first build - let's get the source"
  mkdir -p $SRC_DIR
  wget https://github.com/numpy/numpy/archive/${SOURCE_FILE} -O $SRC_DIR/$SOURCE_FILE
  echo "releasing lock"
  rm -v ${SRC_DIR}/${SOURCE_FILE}.lock
elif [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; then
  # Someone else has the file, wait till it's released
  while [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; do
    echo " There seems to be a download currently under way, will check again in 5 sec"
    sleep 5
  done
else
  echo "continuing from previous builds, using source at " ${SRC_DIR}/${SOURCE_FILE}
fi
tar -xz --keep-newer-files -f ${SRC_DIR}/${SOURCE_FILE} -C ${WORKSPACE}
# we keep a site.cfg in change control.
# cp site.cfg ${WORKSPACE}/${NAME}-${VERSION}
# This is not working due to python not reading the variables in site.cfg
# Not sure how to get the variables to be interpreted within the config,
# so unfortunately, we have to generate site.cfg on the fly.
(
cat <<SITECFG
[DEFAULT]
library_dirs = ${OPENBLAS_DIR}/lib
include_dirs = ${OPENBLAS_DIR}/include/
ATLAS=none
BLAS=${OPENBLAS_DIR}/lib/libopenblas.so
LAPACK=${OPENBLAS_DIR}/lib/libopenblas.so
[openblas]
libraries = openblas
runtime_library_dirs = ${OPENBLAS_DIR}/lib/

[fft]
libraries = fftw3
library_dirs = ${FFTW_DIR}/lib/
include_dirs = ${FFTW_DIR}/include/
SITECFG
) > ${NAME}-${VERSION}/site.cfg
cd ${WORKSPACE}/${NAME}-${VERSION}
# See https://github.com/Homebrew/homebrew-python/commit/d94eceddbbaace19fb95ebc0d6e484b1942b7c29
# and https://github.com/Homebrew/homebrew-python/issues/209
export LDFLAGS="$LDFLAGS -shared"

# Follow instructions at http://docs.scipy.org/doc/numpy-1.10.1/user/install.html#linux

python${VERSION_MINOR} setup.py build_ext --inplace
