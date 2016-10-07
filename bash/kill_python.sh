#!/bin/bash

pid=`ps -aux | sed -n '/ python /p' | head -n1 | awk '{print $2}'`
echo $pid
if [ $pid != 0 ] ; then
	kill -9 $pid
else
	echo "No python process is found"
fi
