#!/bin/sh

if [ -z "$QEMU" ] || [ ! -f "$(which $QEMU)" ]; then
	QEMU='qemu-system-arm'
fi
if [ ! -f "$(which $QEMU)" ]; then
	echo 'ERROR: please install "qemu-system-arm"' 2>&1
	exit 1
fi

ARG_KERNEL="$1"
ARG_PAUSED="$2"
if [ ! -f "$ARG_KERNEL" ]; then
	echo "syntax: $(basename $0) <kernel> [paused]" 2>&1
	exit 2
fi

if [ "$ARG_PAUSED" == 'paused' ]; then
	PAUSED=-S
fi

$QEMU \
	-gdb 'tcp::1234' $PAUSED \
	-nographic \
	-machine 'vexpress-a15' -cpu 'cortex-a7' \
	-m '32M' \
	-kernel "$ARG_KERNEL"

