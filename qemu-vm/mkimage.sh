#!/bin/bash

rm -rf initramfs.cpio.gz initramfs
mkdir initramfs
cd initramfs
cp ../_install/* -rf ./
mkdir dev proc sys share etc mnt
sudo cp -a /dev/{null,console,tty,tty1,tty2,tty3,tty4} dev/

cat << EOF > init
#!/bin/busybox sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t 9p -o trans=virtio,version=9p2000.L hostshare /share
mkdir -p /mnt/hugepage
mount -t hugetlbfs pagesize=1G,none /mnt/hugepage

exec /sbin/init
EOF

chmod +x init

mkdir -p etc/udhcp
cp ../examples/udhcp/simple.script etc/udhcp/simple.script

#cat << EOF > etc/network/interfaces
#auto eth0
#iface eth0 inet dhcp
#EOF

find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
