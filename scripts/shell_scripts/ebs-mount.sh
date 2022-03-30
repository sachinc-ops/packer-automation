#/bin/bash

###########################
# Author     : Sachin.C   #
###########################

# Mounting newly added EBS volumes
set -e

run_shell () {
    device_no=0
    EXTRA_EBS_VOLS=$(sudo lsblk -ndp --output NAME | awk '{system("sudo file -s "$1)}' | egrep -v 'sector|filesystem'  | cut -d: -f1)
    echo -e "Additional Volumes :\n$EXTRA_EBS_VOLS"
    sudo cp /etc/fstab /etc/fstab.bak

    for volume in $EXTRA_EBS_VOLS; do
        device_no=$((device_no+1))
        sudo mkdir /mnt/drive_$device_no
        sudo mkfs.ext4 $volume > /dev/null
        echo "$volume      /mnt/drive_$device_no  ext4    defaults,nofail        0       0" | sudo tee -a /etc/fstab > /dev/null
        sudo mount -a && echo "$volume mounted on /mnt/drive_$device_no"
    done
}

skip_shell() {
    echo "Skipping Extra EBS Volume Mounting.."
}


[[ "$INPUT" == "run" ]] && run_shell || skip_shell
