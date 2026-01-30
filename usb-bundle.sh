#!/bin/bash
set -e
IMG="/tmp/alis-usb-200mb.img"
MNT="/mnt/alis-usb"

echo "==== ALIS F-35 USB Bundle  ==="

# Clean 
sudo rm -f $IMG
sudo umount $MNT 2>/dev/null || true
sudo rm -rf $MNT
sudo mkdir -p $MNT

# Create
sudo dd if=/dev/zero of=$IMG bs=1M count=200 status=progress
sudo mkfs.ext4 -L "ALIS-UPDATES" $IMG
sudo mount $IMG $MNT

# Copy repo
sudo cp -r /var/www/html/repos/alis-shipboard-packages/*  $MNT/

#FIX ALL PERMISISONS
sudo chmod -R 755 $MNT/ 
sudo chmod 644 $MNT/Packages/*.rpm 
sudo restorecon -R $MNT/ 2>/dev/null || true

# Correct Manifest
PKGS=$(sudo ls $MNT/Packages/*.rpm 2>/dev/null | wc -l)
SIZE=$(sudo du -sh $MNT | cut -f1) 
cat <<MANIFEST | sudo tee $MNT/MANIFEST.txt
ALIS F-35 SHIPBOARD USB BUNDLE
Date: $(date)
Packages: $PKGS
Size: $SIZE
Repo: /var/www/html/repos/ais-shipboard-packages
MANIFEST

# Display results
echo ""
echo "=== USB BUNDLE COMPLETE ==="
sudo cat $MNT/MANIFEST.txt
echo ""
sudo ls -lh $MNT/Packages/*.rpm | head -3

sudo umount $MNT
ls -lh $IMG
echo "USB ready: $IMG"
