# armv7_bootstrap
QEMU ARMv7 bare metal examples aimed at bootstrapping an OS kernel

## building and running
  - build: `make`
  - run an example: `./run.sh 00_helloworld/kernel.elf`
    - press Ctrl-A, then press X to exit QEMU
  - debug a running example: `./debugger.sh 00_helloworld/kernel.elf`

## TODOs
### done
  - hello world
  - exception/vector handler
  - timer
  - interrupt handler
  - basic MMU setup, fault handler
  - audio
### not done
  - storage/disk/sdcard (raw, no filesystem)
  - USB keyboard, mouse
  - video
  - networking?
  - multiple CPU cores?

2018-2019 David DiPaola
licensed under CC0 (public domain, see https://creativecommons.org/publicdomain/zero/1.0/)

