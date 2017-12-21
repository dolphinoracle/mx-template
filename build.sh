#!/bin/bash
# Building .debs with custom names

# Name the package using the folder name, otherwise use the name provide as argument
NAME="$(basename $(pwd))"
[ "$1" ] && NAME="$1"

ORIG_DIR="$(pwd)"
TMP_DIR=$(mktemp -d /tmp/build.XXXXXXXX) # Tried to use /run/shm but it's mounted with noexec
BUILD_DIR=$TMP_DIR/src # Build in a subdirectory because the produced files are placed in /..
mkdir $BUILD_DIR

# Get title name (with spaces and capitalized)
NAME_MX="${NAME/#mx-/MX" "}" # for MX programs replaces mx- with MX
NAME_SPACES="${NAME_MX//-/" "}"
ARRAY=($NAME_SPACES)
TITLE_NAME="${ARRAY[@]^}"

lupdate *.pro

cd $BUILD_DIR
rsync -av $ORIG_DIR/ . --exclude='.git' --exclude='*.changes' --exclude='*.dsc' --exclude='*.deb' --exclude="build.sh" --exclude="$NAME.tar.xz" --exclude="*.pro.user*"

# Cleanup code
make clean
rm Makefile

# Rename files
rename "s/CUSTOMPROGRAMNAME/$NAME/" *
rename "s/CUSTOMPROGRAMNAME/$NAME/" translations/*


# Rename strings
find . -type f -exec sed -i "s/CUSTOMPROGRAMNAME/$NAME/g" {} +
find . -type f -exec sed -i "s/Custom_Program_Name/$TITLE_NAME/g" {} +

# Build
[ $(arch) == "x86_64" ] && debuild && cd ..
[ $(arch) != "x86_64" ] && debuild -B && cd ..

# Move files to original folder
cd $TMP_DIR
mv *.dsc *.deb *.changes *.tar.xz $ORIG_DIR
cd $ORIG_DIR

# Cleanup
[ $TMP_DIR="/tmp/build.*" ] && rm -r $TMP_DIR

