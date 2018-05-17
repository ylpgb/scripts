#!/bin/sh

sudo route del default
sudo route add default gw 192.168.1.253  dev eth0
