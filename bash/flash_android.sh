#!/bin/bash

[[ $# < 2 ]] && { echo "Usage: flash_android.sh /dev/mmcblkx N"; echo "N is size of /dev/mmcblkx in GB"; exit 1; }

DEV=$1
SIZE=$2

if [ "$DEV" == "/dev/sda" ] || [ "$DEV" == "" ] ; then
  echo "Cannot flash $DEV!!!"
  exit 1
fi


DEV_SIZE=`sudo blockdev --getsize64 $DEV`
DEV_SIZE=$((DEV_SIZE/1024/1024/1024))
if (($DEV_SIZE >= $SIZE)) ; then
  echo "$DEV_SIZE GB is greater than specified size. Do it manually"
  exit 1
fi

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "Flashing device $DEV, Size $DEV_SIZE GB Are you sure(y,n)"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "Confirm by y..."
read confirmation

if [ "$confirmation" != "y" ] ; then
  echo "Operation aborted"
  exit 1
fi

if [[ "$DEV" == "/dev/mmcblk"* ]] ; then
  PPFEX="p"
else
  PPFEX=""
fi

#IMAGE_DIR=/home/u-blox/work/nxp/sabreAI/android/myandroid/out/target/product/sabreauto_6q
#IMAGE_DIR=/home/yanleipo/project/nxp/myandroid/out/target/product/sabreauto_6q
IMAGE_DIR=/home/u-blox/work/nxp/sabreAI/android6/myandroid/out/target/product/sabreauto_6q

cd $IMAGE_DIR

#echo "Erase 1KB from 384th block ..."
#sudo dd if=/dev/zero of=/dev/mmcblk0 bs=1k seek=384 count=129

PARTITION=$DEV
echo "Flash u-boot $PARTITION ..."
#sudo dd if=u-boot-imx6q.imx of=$PARTITION bs=1k seek=1; sync

PARTITION=$DEV$PPFEX"1"
echo "Flash boot image $PARTITION ..."
#sudo dd if=boot-imx6q.img of=/dev/mmcblk0p1; sync
sudo dd if=boot-imx6q.img of=$PARTITION; sync

PARTITION=$DEV$PPFEX"5"
echo "Flash system image $PARTITION ..."
rm system_raw.img ; simg2img system.img system_raw.img
#sudo dd if=system_raw.img of=/dev/mmcblk0p5; sync
sudo dd if=system_raw.img of=$PARTITION; sync

PARTITION=$DEV$PPFEX"2"
echo "Flash recovery image $PARTITION ..."
#sudo dd if=recovery-imx6q.img of=/dev/mmcblk0p2; sync
sudo dd if=recovery-imx6q.img of=$PARTITION; sync

