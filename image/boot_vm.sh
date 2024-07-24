#!/bin/bash

bzimage=$1
SERIAL_LOG=$2
PORT=$3

IMAGE_FILE="/root/image/centos9_4.img"

#KERNEL="/root/os.linux.intelnext.kernel/"
#KERNEL="/home/intel-next-kernel"

#[[ -z "$bzimage" ]] && bzimage="./bzImage_5.13-rc5m"
#[[ -z "$bzimage" ]] && bzimage="/var/www/html/bzimage/bzImage_a3fe9a2e1692a413d887a6a0f1184c26481d6a2b"
[[ -z "$bzimage" ]] && bzimage="/root/image/bzImage_5.13-rc5m"

[[ -z "$PORT" ]] && PORT="10024"

[[ -z "$SERIAL_LOG" ]] && SERIAL_LOG="/root/image/vm4.log"

qemu-system-x86_64 \
        -m 2G \
        -smp 2 \
        -kernel "$bzimage" \
        -append "console=ttyS0 root=/dev/sda earlyprintk=serial net.ifnames=0 thunderbolt.dyndbg" \
        -drive file=${IMAGE_FILE},format=raw \
        -net user,host=10.0.2.10,hostfwd=tcp:127.0.0.1:"$PORT"-:22 \
        -cpu host \
        -net nic,model=e1000 \
        -enable-kvm \
        -nographic \
        2>&1 | tee "$SERIAL_LOG"

#       -drive if=pflash,format=raw,readonly=on,file=./OVMF_CODE.fd \
#       -device vfio-pci,host=00:07.0,id=hostdev1,addr=0x4 \
#       -kernel $KERNEL/arch/x86/boot/bzImage \
#       -kernel /root/image/bzImage_513rc5_thomas_0622 \
