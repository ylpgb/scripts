#!/bin/bash

DATE=`date +%Y%m%d`
BAKNAME=/home/yanleipo/project/git/git.bak_$DATE

SRCNAME=u-blox@192.168.1.31:/home/u-blox/work/git

mkdir -p $BAKNAME
echo "rsync -az $SRCNAME $BAKNAME/"
rsync -az $SRCNAME $BAKNAME/
