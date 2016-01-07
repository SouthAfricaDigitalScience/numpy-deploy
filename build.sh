#!/bin/bash -e
source /usr/share/modules/init/bash
SOURCE_FILE=$NAME-$VERSION.tar.gz

module load ci
module add fftw/3.3.4-gcc-5.1.0-mpi-1.8.8
module add lapack
#module add python/${PYTHON_VERSION}

echo $LD_LIBRARY_PATH
echo $LAPACK_DIR
echo $FFTW_DIR
ls $FFTW_DIR/lib
ls $LAPACK_DIR/lib

# according to: http://www.scipy.org/scipylib/building/linux.html
export LAPACK="$LAPACK_DIR"
export ATLAS="$ATLAS_DIR"
export FFTW3="$FFTW_DIR"


echo "REPO_DIR is "
echo $REPO_DIR
echo "SRC_DIR is "
echo $SRC_DIR
echo "WORKSPACE is "
echo $WORKSPACE
echo "SOFT_DIR is"
echo $SOFT_DIR

mkdir -p $WORKSPACE
mkdir -p $SRC_DIR
mkdir -p $SOFT_DIR

#  Download the source file

if [[ ! -e $SRC_DIR/$SOURCE_FILE ]] ; then
  echo "seems like this is the first build - let's get the source"
  mkdir -p $SRC_DIR
  wget http://downloads.sourceforge.net/project/numpy/NumPy/${VERSION}/${SOURCE_FILE} -O $SRC_DIR/$SOURCE_FILE
else
  echo "continuing from previous builds, using source at " $SRC_DIR/$SOURCE_FILE
fi
tar -xz --keep-newer-files -f $SRC_DIR/$SOURCE_FILE -C $WORKSPACE
cd $WORKSPACE/$NAME-$VERSION
rm -rf build/
# We have to generate the site.cfg file by hand on the fly
cat << EOF > site.cfg
[DEFAULT]
libraries = fftw3,lapack,blas
library_dirs = ${FFTW_DIR}/lib:${LAPACK_DIR}/lib
include_dirs = ${FFTW_DIR}/include
search_static_first = true
EOF


export LAPACK_SRC=$LAPACK_DIR/
python setup.py build
