#!/bin/bash

# A Script to build raspberry pi 2 sscard images and configure them
# Allows for passing in parameters to modify default values

tarFile="${1}"
image="${2}"
size="${3}"
loopdev=""

if [ -z "${tarFile}" ]; then
	tarFile="ArchLinuxARM-rpi-2-latest.tar.gz"
fi

if [ -z "${image}" ]; then
	image="rpi_2.img"
fi

if [ -z "${3}"]; then 
	size="7400"
fi

# path to root file system
if [ ! -f "${tarFile}" ]; then
	exec `wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-2-latest.tar.gz`
fi

if [ ! -f  "${image}" ]; then
	echo "Creating image file: "
	echo "dd if=/dev/zero of=./${image} bs=1M count=${size}"
	dd if=/dev/zero of=./${image} bs=1M count=${size}
fi


# Run commands below as superuser
# We need to pass in vars and values so they remain in scope.

sudo image="${image}" tarFile="${tarFile}" bash << 'EOF'
echo "$(whoami)"
loopdev="$(losetup -f --show "${image}")"
success="${?}"

if [ "${success}" -eq 0 ]; then
	echo Loop device created as "${loopdev}"
else 
	echo "Failed creating loop device"
fi

parted --script "${loopdev}" mklabel msdos
parted --script "${loopdev}" mkpart primary fat32 0% 128M
parted --script "${loopdev}" mkpart primary ext4 128M 100%

mkfs.vfat -F32 "${loopdev}"p1
mkfs.ext4 -F "${loopdev}"p2

umount -f root
rm -rf root 
sync
mkdir root
mount -t ext4 "${loopdev}"p2 root

umount -f boot
rm -rf boot
sync
mkdir boot
mount -t vfat "${loopdev}"p1 boot

echo "bsdtar -xpf "${tarFile}" -C root"
bsdtar -xpf "${tarFile}" -C root
echo "${?}" extraction status
sync
echo "${?}" sync status

mv root/boot/* boot
sync
echo "${?}" sync status

sudo umount root
sudo umount boot


EOF
