#!/bin/bash -e
. /etc/profile.d/modules.sh
SOURCE_FILE=$NAME-$VERSION.tar.gz

module add ci
module add gcc/${GCC_VERSION}
module add openblas/0.2.15-gcc-${GCC_VERSION}
module add python/${PYTHON_VERSION}-gcc-${GCC_VERSION}
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
  wget http://downloads.sourceforge.net/project/numpy/NumPy/${VERSION}/${SOURCE_FILE} -O $SRC_DIR/$SOURCE_FILE
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
cp site.cfg ${WORKSPACE}/${NAME}-${VERSION}
cd ${WORKSPACE}/${NAME}-${VERSION}
python${VERSION_MINOR} setup.py build -j2
