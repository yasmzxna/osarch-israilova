# Lab 2 — A Windows guest, and a network between them

Pair: Israilova / Donayeva  Driver first half: Israilova
Machine: laptop, AMD Ryzen 7 7735HS, 16 GB LPDDR5, Windows 11, VirtualBox 7.2.20
Guests: `win11` (Windows 11 Enterprise Evaluation), `lab01-ubuntu` (Ubuntu Server from Lab 1)
Date: 03.11.2026

## What I did

### 1. Host check

```powershell
Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors
Get-CimInstance Win32_PhysicalMemory | Select-Object DeviceLocator, @{n='CapacityGB';e={$_.Capacity/1GB}}, Speed, ConfiguredClockSpeed
Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, @{n='FreeGB';e={[math]::Round($_.SizeRemaining/1GB,1)}}
(Get-CimInstance Win32_ComputerSystem).HypervisorPresent
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --version
```

| What | Value |
|---|---|
| CPU | AMD Ryzen 7 7735HS, 8 cores / 16 threads |
| Memory | 16 GB = 4 × 4 GB LPDDR5 at 6400 MT/s, 15.2 GB usable; Task Manager reports form factor "Other", 4 of 4 slots — the memory is soldered and cannot be upgraded |
| Free space on C: (NVMe SSD) | 390 GB |
| HypervisorPresent | False — VirtualBox can use AMD-V directly |
| VirtualBox | 7.2.20 |

### 2. Windows 11 evaluation VM

Built from the Windows 11 Enterprise **evaluation** ISO (no licence key entered). Unattended install skipped,
local account created through *Sign-in options → Domain join instead*. Guest Additions installed for the
shared clipboard.

| VM | vCPU | RAM | Disk | Firmware |
|---|---|---|---|---|
| win11 | 4 | 6144 MB | 64 GB, dynamic | EFI, TPM 2.0, Secure Boot |
| lab01-ubuntu | 2 | 2048 MB | from Lab 1 | — |

**Why these numbers.** The host has 15.2 GB of usable RAM and with no guests running already uses about
6.9 GB, leaving 8.4 GB available ([host-memory-before.png](evidence/host-memory-before.png)). Windows 11
refuses to install with less than 4 GB; I gave it 6 GB so it is usable rather than barely bootable. Ubuntu
Server has no graphical shell and runs in 2 GB. Together that is 8 GB — almost exactly what the host has
free, so this is the ceiling for this laptop: guests rarely touch their whole allocation, but with a browser
open on the host there is no room for more. On CPU, the guests take 6 of 16 threads and the host keeps 10.
Because the memory is soldered, the only way to get more room is to give the guests less, not to add a module.

### 3. Network: VirtualBox NAT Network

```
Tools → Network → NAT Networks → Create
  Name: NatNetwork   Prefix: 10.0.2.0/24   DHCP: on
Both VMs → Settings → Network → Adapter 1 → Attached to: NAT Network → NatNetwork
```

| Mode | Guests see each other | Internet | Verdict |
|---|---|---|---|
| NAT (default) | no — each guest is alone in its own 10.0.2.0/24 | yes | fails the task |
| Host-only | yes | no | fails the task |
| Internal | yes | no | fails the task |
| Bridged | yes | yes | depends on the outside network; campus MAC filtering can drop the guest |
| **NAT Network** | **yes** | **yes** | **chosen** |

NAT Network is the only mode that gives both things without depending on the network the laptop happens to
be on: the guests share one virtual subnet behind a virtual router (10.0.2.1) that NATs them to the
internet. A port forward was added so I could SSH into Ubuntu from the host and copy output as text:

```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" natnetwork modify --netname NatNetwork --port-forward-4 "ssh-ubuntu:tcp:[127.0.0.1]:2222:[10.0.2.3]:22"
ssh -p 2222 yasmina@127.0.0.1
```

```
                 Internet
                     │
        ┌────────────┴─────────────┐
        │ Host laptop (Wi-Fi)      │
        │ VirtualBox NAT Network   │
        │ "NatNetwork" 10.0.2.0/24 │
        │ gateway 10.0.2.1         │
        └─────┬──────────────┬─────┘
              │              │
     ┌────────┴──────┐  ┌────┴───────────┐
     │ lab01-ubuntu  │  │ win11          │
     │ 10.0.2.3      │◄►│ 10.0.2.4       │
     └───────────────┘  └────────────────┘
```

Addresses:

```bash
ip addr | tee ip-addr-linux.txt                       # Ubuntu: 10.0.2.3/24
```
```powershell
ipconfig /all | Tee-Object ipconfig-windows.txt       # Windows: 10.0.2.4, gateway 10.0.2.1
```

### 4. Connectivity in both directions

The first ping from Linux to Windows failed:

```bash
ping -c 4 10.0.2.4 | tee ping-linux-to-win-blocked.txt    # 100% packet loss
```

Windows Firewall drops inbound ICMP Echo Requests by default, and the new adapter was classified as a
**Public** network ([firewall-profile.txt](evidence/firewall-profile.txt)), the strictest profile. The
firewall was **not** turned off — one inbound rule was added for ICMPv4 type 8 (echo request) only.
`-Profile Any` keeps the rule working however Windows classifies the network:

```powershell
Get-NetConnectionProfile
New-NetFirewallRule -DisplayName "Allow ICMPv4 Echo In" -Protocol ICMPv4 -IcmpType 8 -Direction Inbound -Action Allow -Profile Any
Get-NetFirewallRule -DisplayName "Allow ICMPv4 Echo In" | Format-List DisplayName,Enabled,Direction,Action,Profile
```

Then both directions and the internet:

```bash
ping -c 4 10.0.2.4
ping -c 4 8.8.8.8
ping -c 4 google.com
```
```powershell
ping -n 4 10.0.2.3
ping -n 4 8.8.8.8
ping -n 4 google.com
```

### 5. Memory overcommitment

Before: both guests off, Task Manager → Performance → Memory
([host-memory-before.png](evidence/host-memory-before.png)) and a PowerShell measurement
([host-memory-before.txt](evidence/host-memory-before.txt)):

```powershell
& {
  "=== $(Get-Date) ==="
  Get-CimInstance Win32_OperatingSystem | Select-Object @{n='TotalMB';e={[int]($_.TotalVisibleMemorySize/1KB)}}, @{n='FreeMB';e={[int]($_.FreePhysicalMemory/1KB)}}
  Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory | Select-Object AvailableMBytes, @{n='CommittedMB';e={[int]($_.CommittedBytes/1MB)}}, @{n='CommitLimitMB';e={[int]($_.CommitLimit/1MB)}}, PercentCommittedBytesInUse, PagesPerSec
  Get-CimInstance Win32_PageFileUsage | Select-Object Name, AllocatedBaseSize, CurrentUsage, PeakUsage
} | Format-List | Tee-Object host-memory-before.txt
```

Before the load: 15,614 MB total, 8,120 MB available, 13,063 of 28,414 MB committed (45 %), 0 pages/sec,
page file 12,800 MB allocated with only 396 MB in use.

**Run 1 — hard overcommit.** win11 **10240 MB** + lab01-ubuntu **8192 MB** = 18 GB promised on a host with
15.2 GB usable, of which the host itself already used 6.9 GB. Both guests started, then in Ubuntu:

```bash
sudo apt install -y stress
stress --vm 2 --vm-bytes 3G --vm-keep --timeout 180
```

About one minute after `stress` started, the laptop froze completely, before any measurement could be
taken. Ubuntu was stopped by VirtualBox; the record was pulled from its log
([vbox-log-extract.txt](evidence/vbox-log-extract.txt)):

```powershell
Select-String -Path "$HOME\VirtualBox VMs\lab01-ubuntu\Logs\VBox.log" -Pattern "Guru|VERR_|NO_MEMORY|Allocated pages|Changing the VM state" | Select-Object -Last 30
```

**Run 2 — milder overcommit, so the host could still be measured.** win11 **6144 MB** + lab01-ubuntu
**8192 MB** = 14 GB promised, on top of the ~7 GB the host uses itself. Same `stress` with a smaller load:

```bash
stress --vm 2 --vm-bytes 2500M --vm-keep --timeout 90
```

Task Manager was captured during the load ([host-memory-after.png](evidence/host-memory-after.png)).
The host was so slow that a PowerShell measurement could not be completed, so the figures below are read
from the two Task Manager screenshots.

Afterwards the allocations were returned to 6144 MB / 2048 MB.

## Result

**Network:** both guests reach each other and the internet ([ping-both-ways.txt](evidence/ping-both-ways.txt)).

| From → To | Result | TTL in reply |
|---|---|---|
| Linux → Windows, before rule | 100% loss | — |
| Linux → Windows, after rule | 0% loss, ~0.67 ms | 128 (Windows) |
| Windows → Linux | 0% loss, <1 ms | 64 (Linux) |
| Linux → 8.8.8.8 / google.com | 0% loss, 119–1086 ms | — |
| Windows → 8.8.8.8 / google.com | 0% loss, 117–355 ms | — |

Guest-to-guest replies come back in under a millisecond; internet latency is high and jumpy because the host
was on Wi-Fi.

**Memory overcommitment (Task Manager, host):**

| Metric | Before (guests off) | Run 2, during load |
|---|---|---|
| In use | 6.9 / 15.2 GB (45 %) | **15.2 / 15.2 GB (100 %)** |
| Available | 8.4 GB | **47.6 MB** |
| Committed | 12.5 / 27.7 GB | **24.1 / 27.7 GB** |
| Cached | 884 MB | **58 MB** |
| Compressed | 584 MB | 642 MB |
| Disk C: (NVMe) activity | 7 % | **75 %** |

What the host did:

1. **Ran out of physical memory.** Available memory fell from 8.4 GB to 47.6 MB — less than one browser tab.
2. **Threw away its file cache** — 884 MB down to 58 MB — to hand the pages to the guests.
3. **Paged to disk.** The NVMe system disk went from 7 % to 75 % activity: memory was being written out to
   the page file. Committed memory rose to 24.1 of 27.7 GB; the limit is 16 GB of RAM plus the page file.
4. **Became unusable.** In run 2 every program on the host lagged badly; in run 1 the laptop froze entirely
   about a minute into the load.
5. **Lost a guest.** In run 1 VirtualBox could not get pages for Ubuntu and stopped it:
   ```
   PGM: Failed to procure handy pages; rc=VERR_NO_PAGE_MEMORY
   Changing the VM state from 'RUNNING' to 'GURU_MEDITATION'
   ```
   This happened 3 min 25 s after the VM started. At that point Ubuntu had 0x15dbaf = 1,432,495 pages ×
   4 KB ≈ **5.5 GB** actually backed by the host, out of the 8 GB it had been promised.

Conclusion: overcommitment holds only while guests leave their memory unused. Once they use it, the host
gives up its cache, pages to disk, stops responding to its user, and finally the hypervisor fails a guest.
On a 16 GB laptop with soldered memory there is very little margin: 6 GB + 2 GB is the practical limit.

## What did not work the first time

**1. SSH to Ubuntu: `Connection refused`.**
*What I saw:* `ssh -p 2222 yasmina@127.0.0.1` was refused, although `systemctl status ssh` in Ubuntu showed
the service waiting on `ssh.socket`, which is normal on current Ubuntu.
*What it was:* `VBoxManage natnetwork list` showed the port-forward rule pointing at `10.0.2.0:22` — the
network address, not the guest — so nothing answered.
*What I did:*
```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" natnetwork modify --netname NatNetwork --port-forward-4 delete ssh-ubuntu
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" natnetwork modify --netname NatNetwork --port-forward-4 "ssh-ubuntu:tcp:[127.0.0.1]:2222:[10.0.2.3]:22"
```

**2. Ping from Linux to Windows: 100 % packet loss.**
Expected — Windows Firewall blocks inbound echo requests on a Public network. Fixed with one ICMPv4 type 8
rule instead of disabling the firewall ([ping-linux-to-win-blocked.txt](evidence/ping-linux-to-win-blocked.txt),
[firewall-rule.txt](evidence/firewall-rule.txt)).

**3. The first overcommit run froze the host before it could be measured.**
*What I saw:* about a minute after `stress` started the laptop stopped responding, Ubuntu went into Guru
Meditation, and afterwards it would not power off — VirtualBox hung at "Stopping".
*What it was:* 18 GB promised on a 15.2 GB host that already used 6.9 GB itself; the commit charge reached
the limit and VirtualBox could not get memory for the guest (`VERR_NO_PAGE_MEMORY`).
*What I did:* ended the stuck `VirtualBoxVM` process, pulled the reason from `VBox.log` before restarting
the VM (so the log would not be rotated), then repeated the experiment with less memory promised
(6 GB + 8 GB) and with Task Manager already open, so the "after" state could be captured.

## Evidence

- [evidence/host-specs.txt](evidence/host-specs.txt) — host CPU, memory modules, free space, hypervisor state
- [evidence/vm-settings.png](evidence/vm-settings.png) — win11 as configured: 6144 MB, 4 CPUs, 64 GB, EFI/TPM 2.0/Secure Boot, NAT Network
- [evidence/ipconfig-windows.txt](evidence/ipconfig-windows.txt) — Windows guest got 10.0.2.4 on NatNetwork, gateway 10.0.2.1
- [evidence/ip-addr-linux.txt](evidence/ip-addr-linux.txt) — Ubuntu guest got 10.0.2.3 on the same /24
- [evidence/ping-linux-to-win-blocked.txt](evidence/ping-linux-to-win-blocked.txt) — first attempt, blocked by the firewall
- [evidence/firewall-profile.txt](evidence/firewall-profile.txt) — Windows guest network classified as Public
- [evidence/firewall-rule.txt](evidence/firewall-rule.txt) — the ICMPv4 echo rule: enabled, inbound, allow, any profile
- [evidence/ping-both-ways.txt](evidence/ping-both-ways.txt) — both directions and the internet, after the fix
- [evidence/host-memory-before.txt](evidence/host-memory-before.txt) — host memory with both guests off, from PowerShell
- [evidence/host-memory-before.png](evidence/host-memory-before.png) — host memory with both guests off, Task Manager
- [evidence/host-memory-after.png](evidence/host-memory-after.png) — host memory at 100 % during overcommit (run 2)
- [evidence/vbox-log-extract.txt](evidence/vbox-log-extract.txt) — VirtualBox log, run 1: `VERR_NO_PAGE_MEMORY` → Guru Meditation
