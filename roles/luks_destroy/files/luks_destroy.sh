#!/bin/sh
## This script kills all LUKS containers in OS
##
for dev in $(find /dev -type b | egrep -v 'loop|sr|cdrom|dm.*'); do
    cryptsetup isLuks $dev 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "$dev is a LUKS device"
        luks_version=$(cryptsetup luksDump $dev |grep Version | awk '{print $2}')

        if [ $luks_version -eq 1 ]; then
            echo "Detected LUKS version $luks_version"
            echo "Erasing $dev"
            cryptsetup -q erase $dev && shred -vz -s 2M $dev

        elif [ $luks_version -eq 2 ]; then
            echo "Detected LUKS version $luks_version"
            echo "Erasing $dev"
            cryptsetup -q erase $dev && shred -vz -s 16M $dev
        else
            echo "Can not detect LUKS version. Please check the script."
            exit 1
        fi
    else
        echo "$dev is NOT a LUKS device. Skipping..."
    fi
      ### Purge GPT at all block devices despite LUKS
        echo "Erase GPT..."
        dd if=/dev/urandom of=$dev bs=4096 count=35
        dd if=/dev/urandom of=$dev bs=4096 count=35 seek=$(($(blockdev --getsz $dev 2>/dev/null)*512/4096 - 35))
done
exit 0
