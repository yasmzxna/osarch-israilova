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

## 3. How the evidence was recorded

Every `.txt` file in `evidence/` contains the **command line** (`$ command`) followed by its exact output.
They were written with a small shell helper, so nothing was retyped by hand:

```bash
ev() { f=$1; shift; { echo "\$ $*"; "$@"; echo; } 2>&1 | tee -a "$f"; }
# example: ev array-healthy.txt sudo mdadm --detail /dev/md0
```

Each state was captured **at the moment it happened** (see the `date` line at the top of every file), not reconstructed at the end.

## 4. What was done

```bash
# --- build (9 Nov) ---
sudo parted -s /dev/sdb mklabel gpt mkpart raid 1MiB 100% set 1 raid on
sudo parted -s /dev/sdc mklabel gpt mkpart raid 1MiB 100% set 1 raid on
sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb1 /dev/sdc1
sudo mkfs.ext4 /dev/md0
sudo mount /dev/md0 /mnt/mirror
echo "OSArch Lab 4 - Israilova - RAID1 proof file" | sudo tee /mnt/mirror/proof.txt
sudo parted -s /dev/sdd mklabel gpt mkpart raid 1MiB 100% set 1 raid on

# --- recorded run (12 Nov), array = sdb1 + sdd1 ---
sudo dd if=/dev/urandom of=/mnt/mirror/random.bin bs=1M count=100   # 100 MB of random data
sha256sum /mnt/mirror/proof.txt /mnt/mirror/random.bin              # checksum-before.txt

sudo mdadm --manage /dev/md0 --fail   /dev/sdb1                     # fail one half
sudo mdadm --manage /dev/md0 --remove /dev/sdb1
sudo sysctl vm.drop_caches=3                                        # force reads from the surviving disk
sha256sum /mnt/mirror/proof.txt /mnt/mirror/random.bin              # checksum-after-failure.txt

sudo mdadm --manage /dev/md0 --add /dev/sdc1                        # third disk -> rebuild
sudo mdadm --wait /dev/md0
```

## 5. The three states of the array

| State | Time (UTC) | `/proc/mdstat` | mdadm State | Members | Events | Evidence |
|---|---|---|---|---|---|---|
| Healthy | 05:49:22 | `[2/2] [UU]` | clean | sdb1, sdd1 | 45 | `array-healthy.txt`, `linux-03-array-healthy.png` |
| Degraded | 05:53:16 | `[2/1] [_U]` | clean, degraded | removed + sdd1 | 47 | `array-degraded.txt`, `linux-05-array-degraded.png` |
| Rebuilding | 05:54:35 | `[2/1] [_U]`, `recovery = 6.2%` | — | sdc1 (recovering) + sdd1 | — | `array-rebuilt.txt`, `linux-07-rebuild-progress.png` |
| Rebuilt | 05:54:41 | `[2/2] [UU]` | clean | sdc1, sdd1 | 67 | `array-rebuilt.txt`, `linux-08-array-rebuilt.png` |

Same array UUID `f938d367:36ff4a70:7efb6972:5b03e995` in all states. The kernel log at the end of `array-rebuilt.txt` shows the whole sequence:
`Disk failure on sdb1, disabling device` → `Operation continuing on 1 devices` (05:53:18) → `recover of RAID array md0` (05:54:36) → `md0: recover done` (05:54:41). The rebuild of the third disk took about 5 seconds at ~65 MB/s.

## 6. Proof that the data survived

Two files were checksummed: a recognisable text file and 100 MB of random data.

| File | Before failure (`checksum-before.txt`) | After failure (`checksum-after-failure.txt`) | After rebuild (`array-rebuilt.txt`) |
|---|---|---|---|
| `proof.txt` | `e4f80b2e…3b5440bb` | `e4f80b2e…3b5440bb` | `e4f80b2e…3b5440bb` |
| `random.bin` | `029cc08f…b47e0f5a` | `029cc08f…b47e0f5a` | `029cc08f…b47e0f5a` |

Full hashes:
```
e4f80b2e198af20988cd2ba76d51e470806f0d4ad92e725ea6af60ee3b5440bb  /mnt/mirror/proof.txt
029cc08f35aa94df3e66cbabac06b1352c2d9f31e201b9c9df1c2d26b47e0f5a  /mnt/mirror/random.bin
```

Before computing the "after failure" checksums the page cache was dropped (`vm.drop_caches=3`), so both files were really read from the single surviving disk. A `diff` of the two checksum files printed `CHECKSUMS MATCH` (`linux-06-checksum-after-failure.png`).

## 7. Layout after

Full output: `evidence/lsblk-after.txt`, screenshot `evidence/linux-09-lsblk-after.png`

```
sdb         1G disk
└─sdb1   1022M part            <- failed and removed from the array
sdc         1G disk
└─sdc1   1022M part
  └─md0  1021M raid1 /mnt/mirror
sdd         1G disk
└─sdd1   1022M part
  └─md0  1021M raid1 /mnt/mirror
```

## 8. What did not work the first time

| # | Problem | Cause | Fix |
|---|---|---|---|
| 1 | Windows VM could not take another disk | The SATA controller of `win11` had only 2 ports, both in use (`win11.vdi` and the Guest Additions ISO) | Raised "Port count" to 3 in VirtualBox → Storage, then attached `win-extra.vdi` |
| 2 | `parted -s /dev/sdc/ …` → `Error: Could not stat device /dev/sdc/ - Not a directory` | Trailing slash: a block device is a file, not a directory | Re-ran with `/dev/sdc` |
| 3 | `sudo ndadm --create …` → `command not found` | Typo (`ndadm` instead of `mdadm`) | Re-ran with the correct name |
| 4 | `sudo tee /mt/mirror/proof.txt` → `No such file or directory` | Typo in the mount point (`/mt` instead of `/mnt`) | Checked with `ls -la /mnt/mirror`, re-ran with the right path |
| 5 | The shell showed `>` and waited | Enter was pressed before the closing `"` of the `echo` string | Ctrl+C, typed the command again |
| 6 | The VM console has no copy/paste, so long commands were error-prone | Ubuntu Server runs in a text console (tty) | For the recorded run, logged in over SSH from Windows PowerShell (`ssh -p 2222 yasmina@127.0.0.1`, NAT port forwarding) |
| 7 | `scp`/`ssh` → `Permission denied` | Password typed with the Russian keyboard layout | Switched to English layout |
| 8 | `ssh` → `Connection refused` | The VM was still booting | Waited and retried |
| 9 | After the reboot the mirror was not mounted and the old disk came back by itself: `md0 : active raid1 sdc1[1](S) sdb1[0] sdd1[2]` | No `/etc/fstab` entry for `/mnt/mirror`; `sdc1` still had its RAID superblock, so mdadm re-assembled it as a **spare**. With a spare present, a failed disk would be replaced instantly and the degraded state could not be captured | `sudo mount /dev/md0 /mnt/mirror`, then `mdadm --remove /dev/sdc1` and `mdadm --zero-superblock /dev/sdc1` so it became a clean third disk |
| 10 | On mount the kernel logged `EXT4-fs (md0): recovery complete` | The VM had been powered off without unmounting the mirror, so ext4 replayed its journal | Nothing lost (checksums identical); lesson: `umount` before shutting the VM down |
| 11 | First submission (9 Nov): only `proof.txt` was checksummed and the `.txt` files had no command lines | Evidence was saved with plain `cmd \| tee file` | Repeated the fail/rebuild cycle on 12 Nov with `random.bin` and the `ev` helper (section 3); this time a different disk (`sdb1`) was failed and `sdc1` was used as the replacement |

## 9. Question: a colleague deleted the wrong file from the mirror an hour ago. Does RAID 1 help?

No, RAID 1 does not help in this case. A mirror writes every change to both disks at the same time, so the deletion was copied to the second disk immediately and no older copy of the file exists on the array. RAID 1 protects against a disk hardware failure, not against human error, so the file can only be recovered from a backup or a snapshot taken before it was deleted.

## Evidence files

```
evidence/
├── lsblk-before.txt
├── array-healthy.txt
├── checksum-before.txt
├── array-degraded.txt
├── checksum-after-failure.txt
├── array-rebuilt.txt
├── lsblk-after.txt
├── win-01-disk-management.png
├── win-02-get-disk-volume.png
├── linux-01-lsblk-before.png
├── linux-02-partitions.png
├── linux-03-array-healthy.png
├── linux-04-checksum-before.png
├── linux-05-array-degraded.png
├── linux-06-checksum-after-failure.png
├── linux-07-rebuild-progress.png
├── linux-08-array-rebuilt.png
└── linux-09-lsblk-after.png
```
