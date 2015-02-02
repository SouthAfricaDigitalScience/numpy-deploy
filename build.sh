#!/bin/bash -e
SOURCE_FILE=$NAME-$VERSION.tar.gz

module load ci
module load python
module add gcc/4.8.2
module add lapack

echo $LD_LIBRARY_PATH
echo $LAPACK_DIR
ls $LAPACK_DIR/lib

# according to: http://www.scipy.org/scipylib/building/linux.html
export LAPACK="$LAPACK_DIR/lib/liblapack.so"
export BLAS="$LAPACK_DIR/lib/libblas.so"


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
  wget http://mirror.ufs.ac.za/numpy/NumPy/$VERSION/$SOURCE_FILE -O $SRC_DIR/$SOURCE_FILE
else
  echo "continuing from previous builds, using source at " $SRC_DIR/$SOURCE_FILE
fi
tar -xzf $SRC_DIR/$SOURCE_FILE -C $WORKSPACE
cd $WORKSPACE/$NAME-$VERSION
cp ../site.cfg .
export LAPACK_SRC=$LAPACK_DIR/
python setup.py build
