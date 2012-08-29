#!/bin/sh
#
# run-test.sh
# synthaway
#
# Copyright (c) 2012 Inkling Systems, Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# use the latest Clang for compiling
CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"

if [ $# -ne 2 ]
then
	echo "Usage: `basename $0` <synthaway path> <full path of test file>"
	exit 1
fi

if [ ! -e $1 ]
then
	echo "Error: synthaway does not exist at '$1'"
	exit 1
fi

if [ ! -e $2 ]
then
	echo "Error: file '$2' does not exsit"
	exit 1
fi

# make a temporary environment as if the synthaway binary was installed in /usr/local/bin/
TMPUSR=`mktemp -d synthaway-usr.XXXXXX`
mkdir -p $TMPUSR/bin
cp $1 $TMPUSR/bin/
ln -s /usr/local/lib $TMPUSR/lib
BASE=`basename $1`
SYNTHBIN="$TMPUSR/bin/$BASE"

SRC="$2"
ORIG="$2.orig"
BAK="$2.bak"
OUT="${SRC%.*}"

echo "(TEST) Backing up $SRC"
cp "$SRC" "$ORIG"

echo "(TEST) Compiling $SRC"
"$CC" -Qunused-arguments -o "$OUT" "$SRC" -framework Foundation 
if [ $? -ne 0 ]
then
	echo "(TEST) Failed"
	cp "$ORIG" "$SRC"
	rm -f "$ORIG" "$BAK" "$OUT"
	rm -rf $TMPUSR
	exit 1
fi

echo "(TEST) Running $OUT"
$OUT
if [ $? -ne 0 ]
then
	echo "(TEST) Failed"
	cp "$ORIG" "$SRC"
	rm -f "$ORIG" "$BAK" "$OUT"
	rm -rf $TMPUSR
	exit 1
fi


echo "(TEST) Refactoring $SRC"
$SYNTHBIN $2 -- $CC -Qunused-arguments -c
if [ $? -ne 0 ]
then
	echo "(TEST) Failed"
	cp "$ORIG" "$SRC"
	rm -f "$ORIG" "$BAK" "$OUT"
	rm -rf $TMPUSR
	exit 1
fi

echo "(TEST) Showing the diff between $ORIG and $SRC"
diff $ORIG $SRC

echo "(TEST) Making sure the refactored $SRC compile"
$CC -Qunused-arguments -o "$OUT" "$SRC" -framework Foundation
if [ $? -ne 0 ]
then
	echo "(TEST) Failed"
	cp "$ORIG" "$SRC"
	rm -f "$ORIG" "$BAK" "$OUT"
	rm -rf $TMPUSR
	exit 1
fi

echo "(TEST) Running $OUT after refactoring"
$OUT
if [ $? -ne 0 ]
then
	echo "(TEST) Failed"
	cp "$ORIG" "$SRC"
	rm -f "$ORIG" "$BAK" "$OUT"
	rm -rf $TMPUSR
	exit 1
fi

if [ -e $BAK ]
then
	echo "(TEST) Restoring $SRC"
	diff $ORIG $BAK
	if [ $? -ne 0 ]
	then
		echo "(TEST) Failed"
		cp "$ORIG" "$SRC"
		rm -f "$ORIG" "$BAK" "$OUT"
		rm -rf $TMPUSR
		exit 1
	fi
else
	echo "(TEST) No refactoring output (expected)"
fi

cp "$ORIG" "$SRC"
rm -f "$ORIG" "$BAK" "$OUT"
rm -rf $TMPUSR
echo "(TEST) Successfully tested on $SRC"
