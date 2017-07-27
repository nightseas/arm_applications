# Getting Started with ClearFog Base

By Xiaohai Li (haixiaolee@gmail.com)

This is a very simple guide, or note actually, reviewing the steps required to get Debian or Ubuntu (Armbian) working on the ClearFog Base platform with eMMC assembled A388 SoM.

The reason why I'm writing this is because the crude documents of Solid-run. And on the Armbian official download page for ClearFog, they ask you to look into forum threads and find the way to flash the system image to an eMMC among the discussions. As myself didn't find the answer.

## Before We Start

### Prebuilt Armbian Image

Download Debian or Ubuntu bootable image for ClearFog Base from [Armbian Server](https://dl.armbian.com/clearfogbase/). 

Please choose 'default' images, while the 'next' images are not stable. Notice that the account for first login:

|   Username    |   Password    |
|   ---         |   ---         |       
|   root        |   1234        |

### Boot Selection

The boot source is select by a 5-bit dip switch (SW1). The processor will detect the status of the switch and boot from the relative source during reset. So to take, reset or power cycle is needed after changing the source effect.

I have double checked the picture below with A38x datasheet and ClearFog schematics. This works for both ClearFog Base and Pro. White part is the position of the dip and black part is the background.

![Boot Selection](https://raw.githubusercontent.com/nightseas/arm_applications/master/pic/clearfog_base_boot_sel.jpg)

## Boot from Micro SD Card

This is the easiest way to make things done, only if your A38x SoM ordered from Solid-Run doesn't contain an eMMC flash.

Uncompress the downloaded archive and write it to the Micro SD card, use [Etcher](https://www.etcher.io/) on any OS, or dd on Linux if you like (sdX stands for your card):

```sh
sudo dd if=./your-image-file of=/dev/sdX bs=4M
```

 - Configure the dip switch to boot from SD/eMMC. 
 - Connect ClearFog Base's micro USB interface (a serial-to-USB interface) to your PC with a micro USB cable and power on your board. 
 - With a terminal tool like putty or SecureCRT you'll be able to see the console output and Armbian login session at end of boot.

## What If I Have the Damn eMMC?

### Boot from UART

Before talking about eMMC boot you need to know how to boot from UART interface. It's a necessary process to write system image to the eMMC.

Connect the USB serial port of ClearFog Base your PC. Configure the dip switch to boot from UART.

Use this [serial download script](https://github.com/nightseas/arm_applications/blob/master/script/clearbase-download-serial.sh) from Solid-Run to load a special U-Boot  binary to the board with Xmodem protocol. 

```sh
./clearbase-download-serial.sh /dev/ttyUSB0 ???uboot-uart.mmc
```

Run the script and power on the board. After loading, you can stop the boot sequence and access U-Boot CLI.


### Where to Find the U-Boot Binary

The U-Boot binary is stored in the Armbian image. Located at:

```
/usr/lib/linux-uboot-?????/uboot-uart.????
```

There are two ways to get the binary out:

 1. Write Armbian image to a SD card and mount the rootfs partition.
 2. Directly mount the rootfs partition in the image file with loop mode (1048576 means the offset in bytes of the rootfs partition, that's 512 * 2048 in this case):

```sh
sudo mount -o loop,offset=1048576 ./your-image-file /mnt/
```

### Boot from USB Disk -- Download Armbian to eMMC

After booting to U-Boot from UART interface, you can now boot the Armbian Linux system from a USB dsik.

Write the same Armbian image to USB disk just like write to the SD card. Insert the disk to USB 3.0 port on ClearFog Base, run the predefined script in U-Boot command line:

```
run usbboot
```

After login to Linux, get the Armbian image to your board from network (like FTP or SFTP), or copy from another USB disk. Then write the image to eMMC (before that you may need to insert a SD card to the card slot to let the system find the eMMC, due to a software bug).

```
sudo dd if=./your-image-file of=/dev/emmcblk0 bs=4M
```

Mount the rootfs partition on eMMC and edit armbianEnv.txt to fix that eMMC detection bug. Change the line 'emmc_fix=off' to 'emmc_fix=on', or add a new line if emmc_fix not exist:

```sh
sudo mount /dev/mmcblk0p1 /mnt
sudo nano /mnt/boot/armbianEnv.txt
# ( change emmc_fix=off to emmc_fix=on )
sudo umount /mnt
sudo poweroff
```

### Finally! Boot from eMMC

After the previous steps, you'll be able to boot Armbian from eMMC. Just remember to change the dip-switch configuration.

## Boot from SATA (M.2 SSD)

Boot to Linux from any source (SD, eMMC or USB), copy Armbian image to your board and write it to SSD.  

```sh
sudo dd if=./your-image-file of=/dev/sdX bs=4M
```

Then write a the U-Boot binary for SATA to the reserve area on the SSD. The address is the second 512-byte logic sector on SSD where the Marvell main header should located at (again checked both Armbian image and Marvell doc).

```sh
sudo dd if=/usr/lib/linux-uboot-????/uboot.sata???? of=/dev/sdX bs=512 seek=1
```

## Boot from SPI Flash

You can't boot the entire Armbian image from a SPI flash. Just due to the limitation of size (only 4M Bytes on my A388 SoM). But perhaps it is enough for a customized Linux with ramdisk rootfs.
Boot to Linux and write the relative U-Boot binary to the SPI Flash.

```sh
sudo dd if=/usr/lib/linux-uboot-????/uboot.flash???? of=/dev/mtdblk0????
```
