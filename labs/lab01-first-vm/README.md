# Lab 1 - Your first virtual machine

## VM configuration

- Guest OS: Ubuntu Server 26.04.1 LTS
- vCPU: 2
- Memory: 4 GB
- Disk: 25 GB, dynamically allocated
- Network: NAT

## Resource allocation

The host has an AMD Ryzen 7 7735HS processor with 8 cores and 16 threads, 16 GB of RAM, and 399.29 GiB of free disk space. I allocated 2 vCPUs and 4 GB of RAM to the VM. This leaves resources available for Windows while giving Ubuntu enough resources for the lab. The virtual disk is dynamically allocated and can grow up to 25 GB.

## Snapshot and rollback

I created the clean-install snapshot before making changes. I intentionally broke network access and confirmed that it failed. Then I restored the snapshot and confirmed that the VM booted and network access worked again.

## Evidence

- evidence/vm-settings.png - VM resource settings
- evidence/guest-release.txt - Ubuntu release information
- evidence/broken.png - VM in the broken state
- evidence/snapshot-list.png - snapshot list after rollback