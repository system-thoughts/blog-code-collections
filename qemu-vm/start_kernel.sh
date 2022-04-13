#!/bin/bash

#!/bin/bash

#QEMU=/usr/bin/qemu-kvm
QEMU=/home/lvying/qemu_install/bin/qemu-system-x86_64
KERNEL=/home/lvying/centos-kernel/linux-4.18.0-277.el8/arch/x86/boot/bzImage
INITRAMFS=/home/lvying/busybox-1.33.2/initramfs.cpio.gz
KERNEL_CMDLINE="console=ttyS0 hugepagesz=1G default_hugepagesz=1G hugepages=2"
SHARED_DIR=/home/lvying

${QEMU} -kernel ${KERNEL} -initrd ${INITRAMFS} -enable-kvm	\
	-nographic -append "${KERNEL_CMDLINE}" -m 12G -cpu host	\
	-fsdev local,security_model=passthrough,id=fsdev0,path=${SHARED_DIR}	\
	-device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare	\
	-netdev user,id=net0,hostfwd=tcp::5522-:5522	\
	-device virtio-net-pci,netdev=net0
