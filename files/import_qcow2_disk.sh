#!/usr/bin/bash

set -e

ID=9010

# Import qcow2 disk to for template VM 
qm importdisk $ID /home/ansible/ocp-ansible-proxmox/osimg/fedora-coreos-35.20220116.2.0-qemu.x86_64.qcow2 nvme-lvm

# Set imported disk as scsi0
qm set $ID --scsihw virtio-scsi-pci --scsi0 nvme-lvm:vm-$ID-disk-0,ssd=1

# Resize disk with +95G
#qm resize $ID scsi0 +95G

# Set imported scsi disk as boot device - maybe use proxmox module for this
qm set $ID --boot c --bootdisk scsi0

# Mark VM as template
# qm template $ID

# Set trim for cloned disks (no option via module yet)
qm set $ID -agent 1,fstrim_cloned_disks=1