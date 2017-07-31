#!/bin/bash

# The script here implements auto image download to eMMC and SPI flash on ClearFog Base.

echo "Writing ARMBIAN image to eMMC data partition..."
dd if=Armbian_5.32_Clearfogbase_Ubuntu_xenial_default_4.4.68.img of=/dev/mmcblk0 bs=4M

sleep 1

echo "Disable WP of eMMC boot partitions."
echo 0 > /sys/block/mmcblk0boot0/force_ro
echo 0 > /sys/block/mmcblk0boot1/force_ro

echo "Writing U-Boot binary to eMMC boot partitions..."
dd if=/usr/lib/linux-u-boot-clearfogbase_5.32_armhf/u-boot.mmc of=/dev/mmcblk0boot0
dd if=/usr/lib/linux-u-boot-clearfogbase_5.32_armhf/u-boot.mmc of=/dev/mmcblk0boot1

sleep 1

echo "Enable WP of eMMC boot partitions."
echo 1 > /sys/block/mmcblk0boot0/force_ro
echo 1 > /sys/block/mmcblk0boot1/force_ro

echo "Writing U-Boot binary to SPI flash..."
sudo dd if=/usr/lib/linux-u-boot-clearfogbase_5.32_armhf/u-boot.flash of=/dev/mtdblock0

sleep 1

echo "Sync disks."
sync

echo " "
echo " "
echo "All operations complete!"
