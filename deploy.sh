#!/bin/bash -e
. /etc/profile.d/modules.sh
SOURCE_FILE=$NAME-$VERSION.tar.gz

module add deploy
module add gcc/${GCC_VERSION}
module add openblas/0.2.19-gcc-${GCC_VERSION}
module add fftw/3.3.4-gcc-${GCC_VERSION}-mpi-1.8.8

module add python/${PYTHON_VERSION}-gcc-${GCC_VERSION}
module add openssl/1.0.2j

VERSION_MAJOR=${PYTHON_VERSION:0:1} # Should be 2.7 or 3.4 or similar
VERSION_MINOR=${PYTHON_VERSION:0:3} # Should be 2.7 or 3.4 or similar
echo $LD_LIBRARY_PATH
echo ""
cd $WORKSPACE/$NAME-$VERSION
#python${VERSION_MINOR} setup.py clean
(
cat <<SITECFG
[default]
library_dirs = ${OPENBLAS_DIR}/lib
include_dirs = ${OPENBLAS_DIR}/include/
ATLAS=none
BLAS=${OPENBLAS_DIR}/lib/libopenblas.so
LAPACK=${OPENBLAS_DIR}/lib/libopenblas.so
[openblas]
libraries = openblas
openblas_libs = openblas
library_dirs = ${OPENBLAS_DIR}/lib/

[lapack]
lapack_libs = openblas
library_dirs = ${OPENBLAS_DIR}/lib/

[fft]
libraries = fftw3
library_dirs = ${FFTW_DIR}/lib/
include_dirs = ${FFTW_DIR}/include/
SITECFG
) > site.cfg

export LDFLAGS="$LDFLAGS -shared"

mkdir -p modules
(
cat <<MODULE_FILE
#%Module1.0
## $NAME modulefile
##
proc ModulesHelp { } {
    puts stderr "       This module does nothing but alert the user"
    puts stderr "       that the [module-info name] module is not available"
}

module-whatis   "$NAME $VERSION."
setenv       NUMPY_VERSION       $VERSION
setenv       NUMPY_DIR           $::env(CVMFS_DIR)/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION-python-${PYTHON_VERSION}-gcc-${GCC_VERSION}
prepend-path LD_LIBRARY_PATH     $::env(NUMPY_DIR)/lib
prepend-path PYTHONPATH          $::env(NUMPY_DIR)/lib/python${VERSION_MINOR}/site-packages
MODULE_FILE
) > modules/$VERSION-python-${PYTHON_VERSION}-gcc-${GCC_VERSION}

mkdir -p $LIBRARIES/$NAME
cp modules/$VERSION-python-${PYTHON_VERSION}-gcc-${GCC_VERSION} $LIBRARIES/${NAME}
##  check the numpy module load
module add  ${NAME}/${VERSION}-python-${PYTHON_VERSION}-gcc-${GCC_VERSION}
python${VERSION_MAJOR} setup.py build
python${VERSION_MAJOR} setup.py install  --prefix=${SOFT_DIR}-python-${PYTHON_VERSION}-gcc-${GCC_VERSION}

## run numpy full test suite (needs nose)
cd /tmp
python${VERSION_MINOR} -c 'import numpy as np; print np.version.version ;'
