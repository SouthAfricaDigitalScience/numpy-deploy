#!/bin/bash -e
. /etc/profile.d/modules.sh
SOURCE_FILE=$NAME-$VERSION.tar.gz

module add ci
module add gcc/${GCC_VERSION}
module add openblas/0.2.15-gcc-${GCC_VERSION}
module add python/${PYTHON_VERSION}-gcc-${GCC_VERSION}

export VERSION_MAJOR=${PYTHON_VERSION:0:1} # Should be 2 or 3
export VERSION_MINOR=${PYTHON_VERSION:0:3} # Should be 2.7 or 3.4 or similar
echo $LD_LIBRARY_PATH
echo ""
cd $WORKSPACE/$NAME-$VERSION
#python${VERSION_MINOR} setup.py test

echo $?
if [ $? != 0 ] ; then
  exit 1
fi
export PYTHONPATH=${SOFT_DIR}/lib/python${VERSION_MINOR}/site-packages/
python${VERSION_MINOR} setup.py install --prefix=$SOFT_DIR
echo "making module"
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
setenv       NUMPY_DIR           /apprepo/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION
prepend-path LD_LIBRARY_PATH   $::env(NUMPY_DIR)/lib
prepend-path PYTHONPATH       $::env(NUMPY_DIR)/lib/python${VERSION_MINOR}/site-packages
MODULE_FILE
) > modules/$VERSION-python-${PYTHON_VERSION}-gcc-${GCC_VERSION}

mkdir -p $LIBRARIES_MODULES/$NAME
cp modules/$VERSION-python-${PYTHON_VERSION}-gcc-${GCC_VERSION} $LIBRARIES_MODULES/$NAME
echo "module inserted"
##  check the numpy module load
echo "running test"
## run numpy full test suite (needs nose)
cd /tmp
python${VERSION_MINOR} -c 'import numpy; numpy.version()'
