#!/bin/bash
exec 1>> /var/log/libvirt/hook-nvidia.log 2>&1
set -x

define -r NVIDIA_VENDOR_ID="10de"

function LOG() {
  echo "[$(date)]: $*"
}

function WARN() {
  LOG "WARNING: $*"
}

function ERROR() {
  LOG "ERROR: $*"
}

LOG "=== GPU restore script started ==="

# First remove VFIO bindings
if [ -e /sys/bus/pci/drivers/vfio-pci/0000:41:00.0 ]; then
    LOG "Unbinding GPU from VFIO..."
    echo 0000:41:00.0 > /sys/bus/pci/drivers/vfio-pci/unbind
    echo 0000:41:00.1 > /sys/bus/pci/drivers/vfio-pci/unbind
fi

# Remove the VFIO device IDs
if [ -e /sys/bus/pci/drivers/vfio-pci/remove_id ]; then
    LOG "Removing VFIO device IDs..."
    echo "10de 2230" > /sys/bus/pci/drivers/vfio-pci/remove_id
    echo "10de 1aef" > /sys/bus/pci/drivers/vfio-pci/remove_id
fi

# Unload VFIO modules
if lsmod | grep -q vfio_pci; then
    LOG "Unloading VFIO modules..."
    modprobe -r vfio-pci
    modprobe -r vfio_iommu_type1
    modprobe -r vfio
    sleep 3
else
    LOG "VFIO modules not loaded"
fi

# Load NVIDIA modules in correct order
LOG "Loading NVIDIA modules..."
modprobe nvidia
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia_drm

LOG "=== GPU unbind script completed ==="
