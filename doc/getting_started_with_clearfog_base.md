# Getting Started with ClearFog Base

By Xiaohai Li (haixiaolee@gmail.com)

This is a very simple guide, or note actually, reviewing the steps required to get Debian or Ubuntu (Armbian) working on the ClearFog Base platform with eMMC assembled A388 SoM.

The reason why I'm writing this is because the crude documents of Solid-run. And on the Armbian official download page for ClearFog, they ask you to look into forum threads and find the way to flash the system image to an eMMC among the discussions. As myself didn't find the answer.

My test environment:

 - ClearFog Base + A388 SoM (with 8GB eMMC)
 - Armbian 5.32 Debian Jessie or Ubuntu Xenial Image (Also did verification on 5.30)
 - Host PC: Xeon X5650 workstation + Ubuntu Mate 16.04

## Before We Start

### Prebuilt Armbian Image

Download Debian or Ubuntu bootable image for ClearFog Base from [Armbian Server](https://dl.armbian.com/clearfogbase/). 

Please choose 'default' images, while the 'next' images are not stable. Notice that the account for first login:

|   Username    |   Password    |
|   ---         |   ---         |       
|   root        |   1234        |

### Boot Selection

The boot source is select by a 5-bit dip switch (SW1). The processor will detect the status of the switch and boot from the relative source during reset. So, to take effect, reset or power cycle is needed after changing the source effect.

I have double checked the picture below with A38x datasheet and ClearFog schematics. This works for both ClearFog Base and Pro. White part is the position of the dip and black part is the background.

![Boot Selection](https://raw.githubusercontent.com/nightseas/arm_applications/master/pic/clearfog_base_boot_sel.jpg)

We can take a look at the details (skip this part if you are not interested). Here's a list of all the GPIOs that involved in boot selection.

|   GPIO        |   Function    |   Register:Bit    |
|   ---         |   ---         |   ---             |
|   MPP7        |   Boot0       |   0x18600:4       |
|   MPP8        |   Boot1       |   0x18600:5       |
|   MPP9        |   Boot2       |   0x18600:6       |
|   MPP57       |   Boot3       |   0x18600:7       |
|   MPP42       |   Boot4       |   0x18600:8       |
|   MPP56       |   Boot5       |   0x18600:9       |

In Marvell's document, I found the meanings of the config, in the format: 

Config code ( Logic level of Boot[5:0] -> Dip-switch status 0=off, 1=on): Descriptions.

- 0x36 (11_0110 -> 0_0000): Default. Internal pull-up/down in the processor.
- 0x28 (10_1000 -> 1_1110): UART0, mapped to MPP[1:0], USB-to-UART.
- 0x2A (10_1010 -> 1_1100): SATA0, mapped to Serdes0, M.2 SSD
- 0x31 (11_0001 -> 0_0111): SDIO0, mapped to MPP[40:37,28:24,21], eMMC on SoM or Micron SD slot on carrier board
- 0x34 (11_0100 -> 0_0010): SPI1, 24-bit addr NOR, mapped to MPP[59:56], SPI Flash on SoM

## Boot from Micro SD Card

This is the easiest way to make things done, only if your A38x SoM ordered from Solid-Run doesn't contain an eMMC flash.

Uncompress the downloaded archive and write it to the Micro SD card, use [Etcher](https://www.etcher.io/) on any OS, or dd on Linux if you insist (sdX, such as sdc, stands for your card):

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

Use this [serial download script](https://github.com/nightseas/arm_applications/blob/master/script/clearfogbase-download-serial.sh) from Solid-Run to load a special U-Boot  binary to the board with Xmodem protocol (in my experiment, it doesn't matter I choose u-boot-uart.mmc, u-boot-uart.sata or u-boot-uart.flash). 

```sh
./clearbase-download-serial.sh /dev/ttyUSB0 u-boot-uart.mmc
```

Run the script and power on the board. After loading, you can stop the boot sequence and access U-Boot CLI.


### Where to Find the U-Boot Binary

The U-Boot binary is stored in the Armbian image. Located at:

```
/usr/lib/linux-u-boot-clearfogbase_5.32_armhf/
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
sudo dd if=./your-image-file of=/dev/mmcblk0 bs=4M
```

Mount the rootfs partition on eMMC and edit armbianEnv.txt to fix that eMMC detection bug. Change the line 'emmc_fix=off' to 'emmc_fix=on', or add a new line if emmc_fix does not exist:

```sh
sudo mount /dev/mmcblk0p1 /mnt
sudo nano /mnt/boot/armbianEnv.txt
# ( change emmc_fix=off to emmc_fix=on )
sudo umount /mnt
sudo poweroff
```

There's a special thing for eMMC, which is the boot partition. It’s an independent flash space in eMMC and can be accessed from U-Boot or Linux, usually shows up as two block devices /dev/mmcblk0boot0 and /dev/mmcblk0boot1. The Marvell BootROM will look for U-Boot images in those areas. So before reboot to eMMC, you should write the bootloader to the boot partitions.

The boot partitions of eMMC have write protection (WP), and you need to disable the WP, then write the MMC U-Boot to both partitions (it’s called redundancy). Also, It's a good habit to recover the WP after modifications.

```sh
echo 0 > /sys/block/mmcblk0boot0/force_ro
echo 0 > /sys/block/mmcblk0boot1/force_ro

sudo dd if=/usr/lib/linux-u-boot-clearfogbase_5.32_armhf/u-boot.mmc of=/dev/mmcblk0boot0
sudo dd if=/usr/lib/linux-u-boot-clearfogbase_5.32_armhf/u-boot.mmc of=/dev/mmcblk0boot1

echo 1 > /sys/block/mmcblk0boot0/force_ro
echo 1 > /sys/block/mmcblk0boot1/force_ro
```

And here's a script for lazy guys (remember to change the Armbian image version).

[eMMC and SPI flash download script](https://github.com/nightseas/arm_applications/blob/master/script/clearfogbase-download-emmc-spi.sh)

### Finally! Boot from eMMC

After the previous steps, you'll be able to boot Armbian from eMMC. Just remember to change the dip-switch configuration.

## Boot from SATA (M.2 SSD)

Boot to Linux from any source (SD, eMMC or USB), copy Armbian image to your board and write it to SSD.  

```sh
sudo dd if=./your-image-file of=/dev/sdX bs=4M
```

Then write a specific U-Boot binary for SATA to the reserve area on the SSD. The address is the second 512-byte logic sector on SSD where the Marvell main header should be located at (again checked both Armbian image and Marvell doc).

```sh
sudo dd if=/usr/lib/linux-u-boot-clearfogbase_5.32_armhf/u-boot.sata of=/dev/sdX bs=512 seek=1
```

## Boot from SPI Flash

You can't boot the entire Armbian image from a SPI flash. Just due to the limitation of size (only 4M Bytes on my A388 SoM). But perhaps it is enough for a customized Linux with RAM disk rootfs.
Boot to Linux and write the relative U-Boot binary to the SPI Flash, which is abstracted to a MTD block device.

```sh
sudo dd if=/usr/lib/linux-u-boot-clearfogbase_5.32_armhf/u-boot.flash of=/dev/mtdblock0
```
