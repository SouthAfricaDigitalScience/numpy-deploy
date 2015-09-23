module load ci
module load python/2.7.9
module add gcc/4.8.2
module add lapack
module add fftw3/3.3.4
VERSION_MAJOR=${PYTHON_VERSION:0:3} # Should be 2.7 or 3.4 or similar
echo $LD_LIBRARY_PATH
echo ""
cd $WORKSPACE/$NAME-$VERSION
python setup.py check

echo $?
if [ $? != 0 ] ; then
  exit 1
fi

python setup.py install --prefix=$SOFT_DIR

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
prepend-path PYTHONPATH   $::env(NUMPY_DIR)/lib/python${VERSION_MAJOR}/site-packages
MODULE_FILE
) > modules/$VERSION

mkdir -p $LIBRARIES_MODULES/$NAME
cp modules/$VERSION $LIBRARIES_MODULES/$NAME

##  check the numpy module load

## run numpy full test suite (needs nose)
# python -c 'import numpy; numpy.test()'
