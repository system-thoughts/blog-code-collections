## kernel config
qemu vm与host之间共享文件，9p virtio fs可以完成此项工作，9p是网络文件系统，用于共享目录。qemu中使用9p是用于host和guest中共享目录，也不需要网络的支持，而是需要virtio的支持。
要求vm内核支持9p virtio fs相关内核项配置：
```
CONFIG_NET_9P=y
CONFIG_9P_FS=y
CONFIG_VIRTIO_PCI=y
CONFIG_NET_9P_VIRTIO=y
CONFIG_9P_FS_POSIX_ACL=y
```

## busybox initramfs
将busybox以静态链接编译
```shell
make -j$(nproc)
make install
mkdir initramfs
cd initramfs
cp ../_install/* -rf ./
mkdir dev proc sys share
cp -a /dev/{null,console,tty,tty1,tty2,tty3,tty4} dev/

cat << EOF > init
#!/bin/busybox sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t 9p -o trans=virtio,version=9p2000.L hostshare /share

exec /sbin/init
EOF

chmod +x init

find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
```

## qemu
qemu 启动参数需要添加 :
```
-fsdev local,security_model=passthrough,id=fsdev0,path=/tmp/share \
-device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare
```
如果遇到报错：
```
'virtio-9p-pci' is not a valid device model name
```
需要重新编译qemu，让qemu支持virtfs：
```bash
mkdir build
cd build
../configure --enable-kvm --enable-virtfs --prefix=/opt/qemu
make -j$(nproc)
make install
```
CentOS需要安装
```
dnf install libcap-ng-devel libattr-devel -y
```

使用qemu启动内核:
```bash
#!/bin/bash

QEMU=/opt/qemu/bin/qemu-system-x86_64
KERNEL=/opt/linux/arch/x86/boot/bzImage
INITRAMFS=initramfs.cpio.gz
KERNEL_CMDLINE="console=ttyS0"
SHARED_DIR=/opt

${QEMU} -kernel ${KERNEL} -initrd ${INITRAMFS} \
	-nographic -append ${KERNEL_CMDLINE}	\
	-fsdev local,security_model=passthrough,id=fsdev0,path=${SHARED_DIR}	\
	-device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare
```

进入系统后，执行:
```bash
mount -t 9p -o trans=virtio,version=9p2000.L hostshare /share
```
如果已经在`init`脚本中执行挂载操作，则忽略此步