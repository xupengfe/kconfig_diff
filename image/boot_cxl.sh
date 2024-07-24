#!/bin/bash

bzimage=$1
KERNEL="vmlinuz-6.10.0-2024-07-15-intel-next-qemucxl+"
INITRAMFS="initramfs-6.10.0-2024-07-15-intel-next-qemucxl+.img"
IMAGE="/root/image/cxl_x2.img"
[[ -z "$PORT" ]] && PORT=10026


#[[ -z "$bzimage" ]] && bzimage="./bzImage_5.13-rc5m"
[[ -z "$bzimage" ]] && bzimage="./bzImage_6.10i_xpf"

qemu-system-x86_64 \
	-machine q35,accel=kvm,nvdimm=on,cxl=on \
	-m 8192M,slots=4,maxmem=40964M -smp 8,sockets=2,cores=2,threads=2 \
	-display none \
	-cpu host \
	-nographic \
	-drive if=pflash,format=raw,unit=0,file=OVMF_CODE.fd,readonly=on \
	-drive if=pflash,format=raw,unit=1,file=OVMF_VARS.fd \
	-debugcon file:uefi_debug.log \
	-global isa-debugcon.iobase=0x402 \
	-drive file=${IMAGE},format=raw,media=disk \
	-kernel $KERNEL \
	-initrd $INITRAMFS \
	-append "selinux=0 audit=0 console=tty0 console=ttyS0 root=/dev/sda2 ignore_loglevel rw memory_hotplug.memmap_on_memory=force cxl_acpi.dyndbg=+fplm cxl_pci.dyndbg=+fplm cxl_core.dyndbg=+fplm cxl_mem.dyndbg=+fplm cxl_pmem.dyndbg=+fplm cxl_port.dyndbg=+fplm cxl_region.dyndbg=+fplm cxl_test.dyndbg=+fplm cxl_mock.dyndbg=+fplm cxl_mock_mem.dyndbg=+fplm memmap=2G!4G efi_fake_mem=2G@6G:0x40000" \
	-device e1000,netdev=net0,mac=52:54:00:12:34:56 \
	-netdev user,id=net0,hostfwd=tcp::${PORT}-:22 \
	-object memory-backend-file,id=cxl-mem0,share=on,mem-path=cxltest0.raw,size=256M \
	-object memory-backend-file,id=cxl-mem1,share=on,mem-path=cxltest1.raw,size=256M \
	-object memory-backend-file,id=cxl-mem2,share=on,mem-path=cxltest2.raw,size=256M \
	-object memory-backend-file,id=cxl-mem3,share=on,mem-path=cxltest3.raw,size=256M \
	-object memory-backend-file,id=cxl-lsa0,share=on,mem-path=lsa0.raw,size=128K \
	-object memory-backend-file,id=cxl-lsa1,share=on,mem-path=lsa1.raw,size=128K \
	-object memory-backend-file,id=cxl-lsa2,share=on,mem-path=lsa2.raw,size=128K \
	-object memory-backend-file,id=cxl-lsa3,share=on,mem-path=lsa3.raw,size=128K \
	-device pxb-cxl,id=cxl.0,bus=pcie.0,bus_nr=53 \
	-device pxb-cxl,id=cxl.1,bus=pcie.0,bus_nr=191 \
	-device cxl-rp,id=hb0rp0,bus=cxl.0,chassis=0,slot=0,port=0 \
	-device cxl-rp,id=hb0rp1,bus=cxl.0,chassis=0,slot=1,port=1 \
	-device cxl-rp,id=hb1rp0,bus=cxl.1,chassis=0,slot=2,port=0 \
	-device cxl-rp,id=hb1rp1,bus=cxl.1,chassis=0,slot=3,port=1 \
	-device cxl-upstream,port=4,bus=hb0rp0,id=cxl-up0,multifunction=on,addr=0.0,sn=12345678 \
	-device cxl-switch-mailbox-cci,bus=hb0rp0,addr=0.1,target=cxl-up0 \
	-device cxl-upstream,port=4,bus=hb1rp0,id=cxl-up1,multifunction=on,addr=0.0,sn=12341234 \
	-device cxl-switch-mailbox-cci,bus=hb1rp0,addr=0.1,target=cxl-up1 \
	-device cxl-downstream,port=0,bus=cxl-up0,id=swport0,chassis=0,slot=4 \
	-device cxl-downstream,port=1,bus=cxl-up0,id=swport1,chassis=0,slot=5 \
	-device cxl-downstream,port=2,bus=cxl-up0,id=swport2,chassis=0,slot=6 \
	-device cxl-downstream,port=3,bus=cxl-up0,id=swport3,chassis=0,slot=7 \
	-device cxl-downstream,port=0,bus=cxl-up1,id=swport4,chassis=0,slot=8 \
	-device cxl-downstream,port=1,bus=cxl-up1,id=swport5,chassis=0,slot=9 \
	-device cxl-downstream,port=2,bus=cxl-up1,id=swport6,chassis=0,slot=10 \
	-device cxl-downstream,port=3,bus=cxl-up1,id=swport7,chassis=0,slot=11 \
	-device cxl-type3,bus=swport0,volatile-memdev=cxl-mem0,id=cxl-vmem0,lsa=cxl-lsa0 \
	-device cxl-type3,bus=swport2,volatile-memdev=cxl-mem1,id=cxl-vmem1,lsa=cxl-lsa1 \
	-device cxl-type3,bus=swport4,volatile-memdev=cxl-mem2,id=cxl-vmem2,lsa=cxl-lsa2 \
	-device cxl-type3,bus=swport6,volatile-memdev=cxl-mem3,id=cxl-vmem3,lsa=cxl-lsa3 \
	-M "cxl-fmw.0.targets.0=cxl.0,cxl-fmw.0.size=4G,cxl-fmw.0.interleave-granularity=8k,cxl-fmw.1.targets.0=cxl.0,cxl-fmw.1.targets.1=cxl.1,cxl-fmw.1.size=4G,cxl-fmw.1.interleave-granularity=8k" \
	-qmp unix:/tmp/run_qemu_qmp_0,server,nowait \
	-object memory-backend-ram,id=mem0,size=2048M \
	-numa node,nodeid=0,memdev=mem0, \
	-numa cpu,node-id=0,socket-id=0 \
	-object memory-backend-ram,id=mem1,size=2048M \
	-numa node,nodeid=1,memdev=mem1, \
	-numa cpu,node-id=1,socket-id=1 \
	-object memory-backend-ram,id=mem2,size=2048M \
	-numa node,nodeid=2,memdev=mem2, \
	-object memory-backend-ram,id=mem3,size=2048M \
	-numa node,nodeid=3,memdev=mem3, \
	-numa node,nodeid=4, \
	-object memory-backend-file,id=nvmem0,share=on,mem-path=nvdimm-0,size=16384M,align=1G \
	-device nvdimm,memdev=nvmem0,id=nv0,label-size=2M,node=4 \
	-numa node,nodeid=5, \
	-object memory-backend-file,id=nvmem1,share=on,mem-path=nvdimm-1,size=16384M,align=1G \
	-device nvdimm,memdev=nvmem1,id=nv1,label-size=2M,node=5 \
	-numa dist,src=0,dst=0,val=10 \
	-numa dist,src=0,dst=1,val=21 \
	-numa dist,src=0,dst=2,val=12 \
	-numa dist,src=0,dst=3,val=21 \
	-numa dist,src=0,dst=4,val=17 \
	-numa dist,src=0,dst=5,val=28 \
	-numa dist,src=1,dst=1,val=10 \
	-numa dist,src=1,dst=2,val=21 \
	-numa dist,src=1,dst=3,val=12 \
	-numa dist,src=1,dst=4,val=28 \
	-numa dist,src=1,dst=5,val=17 \
	-numa dist,src=2,dst=2,val=10 \
	-numa dist,src=2,dst=3,val=21 \
	-numa dist,src=2,dst=4,val=28 \
	-numa dist,src=2,dst=5,val=28 \
	-numa dist,src=3,dst=3,val=10 \
	-numa dist,src=3,dst=4,val=28 \
	-numa dist,src=3,dst=5,val=28 \
	-numa dist,src=4,dst=4,val=10 \
	-numa dist,src=4,dst=5,val=28 \
	-numa dist,src=5,dst=5,val=10 2>&1 | tee vm3.log

