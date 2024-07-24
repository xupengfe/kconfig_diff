#!/usr/bin/bash

IMG=$1
PORT=$2

[[ -z "$IMG" ]] && IMG="/sda/simics_bisect/centos9_ovmf.img"
#[[ -z "$IMG" ]] && IMG="/sdb/centos-8-stream-embargo-coreserver-202110201122.img"

[[ -z "$PORT" ]] && PORT="10026"

qemu-system-x86_64 \
  -enable-kvm \
  -machine q35 \
  -cpu host \
  -m 4G \
  -smp 6 \
  -nographic \
  -vga none \
  -drive if=pflash,format=raw,readonly=on,file=./OVMF_CODE.fd \
  -drive format=raw,file=$IMG \
  -netdev user,id=net0,hostfwd=tcp::${PORT}-:22 \
  -device e1000,netdev=net0 \
  2>&1 | tee vm.log

#  -device virtio-net-pci,netdev=mynet0,mac=00:16:3E:68:00:10 \
#  -netdev user,id=mynet0,hostfwd=tcp::${PORT}-:22

# -drive if=pflash,format=raw,readonly=on,file=./OVMF_CODE.fd \
#  -vga none \
