#!/system/bin/sh
echo "*************************************************"
echo "*** Build Magisk kernel for Samsung Galaxy S3 ***"
echo "*************************************************"
echo "WARNING: This script will update the device's kernel-partition /dev/block/mmcblk0p5."
echo "         When something goes wrong you need to restore this via ODIN."
echo ""
echo "INFO:    Magisk expects a valid boot.img in this partition which consist of zImage and ramdisk.img."
echo "         This script creates a valid boot.img based on fresh build ROM so Magisk can be installed via TWRP recovery."
echo "         After flashing Magisk, this script continues and extracts the ramdisk.img and rebuilds the kernel with Magisk modified ramdisk.img."
echo "         Finally it flashes /dev/block/mmcblk0p5 with the Magisk patched kernel."
echo ""
echo "IMPORTANT: Original /dev/block/mmcblk0p5 is written to /sdcard/boot_orig.img"
echo "           Magisk reflashable file is written to /sdcard/boot_magisk.img"
echo ""
echo "*** CONNECT YOUR PHONE AND MAKE SURE TWRP-RECOVERY IS RUNNING ***"
echo -n "OK to build and flash Magisk on your device (y/N)?"
read USERINPUT
case $USERINPUT in
 y|Y)
	echo "Backup /dev/block/mmcblk0p5 to /sdcard/boot_orig.img..."
	cout
	adb shell dd if=/dev/block/mmcblk0p5 of=/sdcard/boot_orig.img
	echo "Backup /dev/block/mmcblk0p5 to /sdcard/boot_orig.img... Done!"
	echo ""

	echo "Install Magisk in TWRP now!"
	echo "If you stop now, you need to flash /sdcard/boot_orig.img before booting your phone!"
	read -p "Press [ENTER] to continue"
	echo ""

	echo "Extracting modified Magisk-ramdisk from /dev/block/mmcblk0p5..."
	adb shell dd if=/dev/block/mmcblk0p5 of=/sdcard/boot.img.magisk
	adb pull /sdcard/boot.img.magisk
	abootimg -x boot.img.magisk
	adb shell rm /sdcard/boot.img.magisk
	rm ramdisk.img
	rm bootimg.cfg
	rm boot.img.magisk
	rm zImage
	mv initrd.img ramdisk.img
	echo "Extracting modified Magisk-ramdisk from /dev/block/mmcblk0p5... Done!"
	echo ""

	echo "Rebuilding kernel with Magisk modified ramdisk..."
	croot

	BUILDSPECFILE=buildspec.mk
	if test -f "$BUILDSPECFILE"; then
	        cp buildspec.mk buildspec.mk.org
	fi

	echo "WITH_MAGISKRAMDISK:=true" >>buildspec.mk
	mka bootimage
	echo "Rebuilding kernel with Magisk modified ramdisk... Done!"

	cout
	echo "Flashing Magisk-kernel to /dev/block/mmcblk0p5..."
	adb push boot.img /dev/block/mmcblk0p5
	echo "Flashing Magisk-kernel to /dev/block/mmcblk0p5... Done!"

	echo "Pushing flashable /sdcard/boot_magisk.img..."
	adb push boot.img /sdcard/boot_magisk.img
	echo "Pushing flashable /sdcard/boot_magisk.img... Done!"
	echo ""
	croot
	rm buildspec.mk

	BUILDSPECFILE=buildspec.mk.org
	if test -f "$BUILDSPECFILE"; then
		mv buildspec.mk.org buildspec.mk
	fi

	echo "*** You can now reboot your Magisk-enabled device. ***"
 ;;
 *)
	echo "Aborted"
 ;;
esac

