# Lab 4 — Partition, mirror, fail, recover

**Course:** OSArch · **Week:** 5 · **Outcome:** CLO 1
**Guests:** `win11` (Windows 11) and `lab01-ubuntu` (Ubuntu 26.04 LTS Server), Oracle VirtualBox

## 1. Windows: partition, format, drive letter

A 1 GB virtual disk (`win-extra.vdi`) was attached to the Windows guest and appeared as **Disk 1**.
In Disk Management it was initialized as **GPT**, one simple volume was created, formatted **NTFS**,
labelled `LAB4` and assigned the letter **E:**. Windows 11 automatically enabled BitLocker device encryption on the new volume.

| Disk | Size | Partition style | Role |
|---|---|---|---|
| Disk 0 | 64 GB | GPT | System disk (EFI System Partition, C:) |
| Disk 1 | 1 GB | GPT | New data disk, volume `LAB4 (E:)` NTFS |

**MBR or GPT, and why:** the disk is **GPT**. The VM boots in UEFI mode (Disk 0 is GPT and has an EFI System Partition), and GPT is the modern standard: it supports disks larger than 2 TB and up to 128 partitions, and it keeps a backup copy of the partition table at the end of the disk. MBR is only needed for legacy BIOS systems.

Evidence: `evidence/win-01-disk-management.png`, `evidence/win-02-get-disk-volume.png`

## 2. Linux: layout before

Three 1 GB virtual disks (`raid1.vdi`, `raid2.vdi`, `raid3.vdi`) were attached to the Ubuntu guest (full output: `evidence/lsblk-before.txt`, screenshot `evidence/linux-01-lsblk-before.png`):

```
sda        25G disk            <- system disk, not touched
├─sda1      1M part
├─sda2      2G part /boot
└─sda3     23G part
  └─ubuntu--vg-ubuntu--lv 11.5G lvm /
sdb         1G disk            <- empty
sdc         1G disk            <- empty
sdd         1G disk            <- empty
```

## 3. What was done

```bash
# partition two disks (GPT, one partition flagged as RAID)
sudo parted -s /dev/sdb mklabel gpt mkpart raid 1MiB 100% set 1 raid on
sudo parted -s /dev/sdc mklabel gpt mkpart raid 1MiB 100% set 1 raid on

# build the mirror, format it, mount it
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb1 /dev/sdc1
sudo mkfs.ext4 /dev/md0
sudo mount /dev/md0 /mnt/mirror

# write a recognisable file and record its checksum
echo "OSArch Lab 4 - Israilova - RAID1 proof file" | sudo tee /mnt/mirror/proof.txt
sha256sum /mnt/mirror/proof.txt

# fail and remove one half of the mirror
sudo mdadm --manage /dev/md0 --fail /dev/sdc1
sudo mdadm --manage /dev/md0 --remove /dev/sdc1

# add the third disk and rebuild
sudo parted -s /dev/sdd mklabel gpt mkpart raid 1MiB 100% set 1 raid on
sudo mdadm --manage /dev/md0 --add /dev/sdd1
```

## 4. The three states of the array

| State | `/proc/mdstat` | mdadm State | Members | Evidence |
|---|---|---|---|---|
| Healthy | `[2/2] [UU]` | clean | sdb1, sdc1 | `array-healthy.txt`, `linux-03-array-healthy.png` |
| Degraded | `[2/1] [U_]` | clean, degraded | sdb1 + removed | `array-degraded.txt`, `linux-05-array-degraded.png` |
| Rebuilt | `[2/2] [UU]` | clean | sdb1, sdd1 | `array-rebuilt.txt`, `linux-08-array-rebuilt.png` |

Each state was captured separately, at the moment it happened. The kernel log appended to `array-rebuilt.txt` shows the full history: `resync of RAID array md0` → `Disk failure on sdc1` → `Operation continuing on 1 devices` → `recover of RAID array md0` → `md0: recover done`.

## 5. Proof that the data survived

| When | SHA-256 of `/mnt/mirror/proof.txt` |
|---|---|
| Before failure (`checksum-before.txt`) | `e4f80b2e198af20988cd2ba76d51e470806f0d4ad92e725ea6af60ee3b5440bb` |
| After failure (`checksum-after-failure.txt`) | `e4f80b2e198af20988cd2ba76d51e470806f0d4ad92e725ea6af60ee3b5440bb` |

The checksums are identical: with one disk failed and removed, the filesystem stayed mounted and readable and the file is unchanged.

## 6. Layout after

Full output: `evidence/lsblk-after.txt`, screenshot `evidence/linux-09-lsblk-after.png`

```
sdb         1G disk
└─sdb1   1022M part
  └─md0  1021M raid1 /mnt/mirror
sdc         1G disk
└─sdc1   1022M part            <- failed and removed from the array
sdd         1G disk
└─sdd1   1022M part
  └─md0  1021M raid1 /mnt/mirror
```

## 7. Question: a colleague deleted the wrong file from the mirror an hour ago. Does RAID 1 help?

No, RAID 1 does not help in this case. A mirror writes every change to both disks at the same time, so the deletion was copied to the second disk immediately and no older copy of the file exists on the array. RAID 1 protects against a disk hardware failure, not against human error, so the file can only be recovered from a backup or a snapshot taken before it was deleted.

## Evidence files

```
evidence/
├── lsblk-before.txt
├── array-healthy.txt
├── array-degraded.txt
├── checksum-before.txt
├── checksum-after-failure.txt
├── array-rebuilt.txt
├── lsblk-after.txt                     (extra)
├── win-01-disk-management.png
├── win-02-get-disk-volume.png
├── linux-01-lsblk-before.png
├── linux-02-partitions.png
├── linux-03-array-healthy.png
├── linux-04-checksum-before.png
├── linux-05-array-degraded.png
├── linux-06-checksum-after-failure.png
├── linux-08-array-rebuilt.png
└── linux-09-lsblk-after.png
```
