#!/bin/bash

rm -rf initramfs.cpio.gz initramfs
mkdir initramfs
cd initramfs
cp ../_install/* -rf ./
mkdir dev proc sys share etc mnt
sudo cp -a /dev/{null,console,tty,tty1,tty2,tty3,tty4} dev/
#sudo cp -a /lib64/libnss_* lib64
ssh_pub=$(cat ~/.ssh/id_rsa.pub)

cat << EOF > init
#!/bin/busybox sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t 9p -o trans=virtio,version=9p2000.L hostshare /share
mkdir -p /mnt/hugepage
mount -t hugetlbfs pagesize=1G,none /mnt/hugepage

ip link set eth0 up
udhcpc -i eth0 -s /etc/udhcp/simple.script

# Note: SSHd will fail without /dev/pts
[ -d /dev/pts ] || mkdir --mode=755 /dev/pts 
[ -c /dev/ptmx ] || mknod -m 666 /dev/ptmx c 5 2 
mount -t devpts none /dev/pts

exec /sbin/init
EOF

chmod +x init

mkdir -p etc/udhcp
cp ../examples/udhcp/simple.script etc/udhcp/simple.script

cat << EOF > dropbear.sh
#!/bin/busybox sh

#ping -c 512 -A 10.0.2.2 >/dev/null 2>/dev/null

if [ ! -e /etc/passwd ]; then
    touch /etc/passwd
fi

if [ ! -e /etc/group ]; then
	    touch /etc/group
fi

adduser root -u 0

if [ ! -e /etc/dropbear ]; then
	    mkdir /etc/dropbear
fi
echo "${ssh_pub}" > /etc/dropbear/authorized_keys

if [ ! -e /home/root ]; then
	    mkdir /home /home/root
fi

dropbear -p 5522 -R -B -a
EOF

chmod +x dropbear.sh

find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
