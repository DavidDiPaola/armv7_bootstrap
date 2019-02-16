#!/bin/sh

if [ -z "$GDB" ] || [ ! -f "$(which $GDB)" ]; then
	GDB='gdb-multiarch'
fi
if [ ! -f "$(which $GDB)" ]; then
	GDB='arm-none-eabi-gdb'
fi
if [ ! -f "$(which $GDB)" ]; then
	echo 'ERROR: please install GDB for ARM' 2>&1
	exit 1
fi

ARG_KERNEL="$1"
if [ ! -f "$ARG_KERNEL" ]; then
	echo "syntax: $(basename $0) <kernel>" 2>&1
	exit 2
fi

$GDB \
	--command=gdbinit \
	"$ARG_KERNEL"

