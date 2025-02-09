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

LOG "=== GPU passthrough script started ==="

# Convert PCI address to virsh format
function lspci_to_virsh() {
  sed 's/\(..\):\(..\)\.\(.\)/pci_0000_\1_\2_\3/' <<< "$1"
}

# Convert virsh PCI address to lspci format
function virsh_to_lspci() {
  sed 's/pci_\(....\)_\(..\)_\(..\)_\(.\)/\1:\2:\3.\4/' <<< "$1"
}

# First unload NVIDIA modules if any
if lsmod | grep -q nvidia; then
    LOG "Unloading NVIDIA modules..."
    rmmod nvidia_drm
    rmmod nvidia_modeset
    rmmod nvidia_uvm
    rmmod nvidia

    # Wait for modules to unload
    sleep 3
else
    LOG "NVIDIA modules not loaded"
fi

# Load VFIO module if not loaded
if ! lsmod | grep -q vfio_pci; then
    LOG "Loading VFIO modules..."
    modprobe vfio
    modprobe vfio_pci
    modprobe vfio_iommu_type1

    # Wait for VFIO modules
    sleep 3
else
    LOG "VFIO modules already loaded"
fi

# Now try to bind
echo "10de 2230" > /sys/bus/pci/drivers/vfio-pci/new_id
echo "10de 1aef" > /sys/bus/pci/drivers/vfio-pci/new_id

LOG "=== GPU bind script completed ==="
