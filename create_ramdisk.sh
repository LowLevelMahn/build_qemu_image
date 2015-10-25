#!/bin/bash

# mkdir ~/ramdisk
sudo mount -t ramfs -o size=2G ramfs ~/ramdisk
sudo chown dl:root ~/ramdisk/
chmod 0770 ~/ramdisk/
# mkdir -pv ~/ramdisk/clfs_cross_tools

