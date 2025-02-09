#!/bin/bash

if ! ps aux | grep -q "[q]emu-system"; then
    # No QEMU processes found, check if VFIO is still bound
    if readlink -f /sys/class/pci_bus/0000:41/device/0000:41:00.0/driver | \
            grep -q "vfio-pci"; then
        echo "No QEMU VMs running, unbinding VFIO and restoring NVIDIA"
        /etc/libvirt/hooks/qemu.d/nvidia-container-toolkit/release/end/unbind_vfio.sh
    else
        echo "GPU is not bound to VFIO"
    fi
fi
