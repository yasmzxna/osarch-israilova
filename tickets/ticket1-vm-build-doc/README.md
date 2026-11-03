# Ticket 1 — New developer starts Monday, needs a test machine

Author: Israilova · Host: laptop, AMD Ryzen 7 7735HS, 16 GB LPDDR5 (soldered), Windows 11, VirtualBox 7.2.20
Built on: Lab 1 (Ubuntu guest) and Lab 2 (Windows guest + network), re-written as a document for a non-technical reader.

## 1. What was asked

> From: Aigerim T. (Office Manager)
> Subject: test machine for new dev
>
> Hi, we have someone starting on Monday and he needs a test computer
> set up. Nothing special, just so he can try things without breaking
> anything. Can you write down how to do it so I can do the next one
> myself? Thanks

## 2. What was actually needed

**The real deliverable is the document, not the machine.** The last sentence — "so I can do the next one
myself" — matters more than the first. A machine I build once helps one developer; a document Aigerim can
follow without me helps every future one. So the bar is not "it works on my laptop" but "an office manager
who has never opened VirtualBox can repeat it". That is why [BUILD.md](BUILD.md) explains *why* at every
step and ends each step with a check she can verify herself.

**Where the request is wrong.**

1. **"A test computer."** He does not need another physical computer — he needs a *virtual* one on the
   computer he already has. That is cheaper, ready by Monday, and only a virtual machine can be rolled back.
2. **"Nothing special."** Windows 11 is not "nothing special": it refuses to install without EFI, TPM 2.0,
   Secure Boot and at least 4 GB of RAM, none of which are fully set by default. Getting two guests to see
   each other also needs a non-default network mode. Steps 3, 6, 8 and 11 of BUILD.md exist because of this.
3. **"Try things without breaking anything"** is not a property of the machine, it is a property of the
   *snapshot*. A test machine without a clean snapshot breaks just like a real one. So the snapshot and the
   restore procedure (Steps 13–14) are part of the job even though the request does not mention them.

**What the request left out, what I would have asked, and what I assumed instead.**

| Missing information | What I would ask Aigerim | What I assumed |
|---|---|---|
| Which operating system | "What will he be testing — Linux, Windows, or both?" | **Both**: Ubuntu Server 26.04 LTS and Windows 11. A developer most often deploys to Linux but the office runs Windows. |
| How big the host is | "Which computer will he be using, and how much memory does it have?" | The machine is my own laptop: 16 GB, **soldered** (cannot be upgraded), 8.4 GB free with nothing running ([16-host-memory-before.txt](evidence/16-host-memory-before.txt)). Because the next host may be smaller, BUILD.md Step 0 gives a rule based on *Available* memory instead of fixed numbers. |
| Internet / network | "Does he need internet inside the test machine? Should the machines talk to each other?" | **Both yes** — a developer needs to install packages, and a Linux server talking to a Windows client is the usual test. |
| Licensing | "Do we have a spare Windows licence?" | **No** — used Windows 11 Enterprise **Evaluation**, which is legal and free but expires after **90 days**. Flagged in Step 2 so this does not become a surprise in February. |
| Remote access | "Will anyone need to reach the VM from another computer?" | **No**, so NAT Network instead of Bridged (see section 3). |
| Who sets it up the first time | — | Aigerim is a confident computer user but not technical: every step is written as clicks and copy-paste commands, never "configure the network". |

## 3. What I did

1. **Measured the host** before choosing any number (PowerShell, from Lab 2):
   ```powershell
   Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors
   Get-CimInstance Win32_PhysicalMemory | Select-Object DeviceLocator, @{n='CapacityGB';e={$_.Capacity/1GB}}, Speed
   Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, @{n='FreeGB';e={[math]::Round($_.SizeRemaining/1GB,1)}}
   (Get-CimInstance Win32_ComputerSystem).HypervisorPresent
   ```
   Result ([15-host-specs.txt](evidence/15-host-specs.txt)): 8 cores / 16 threads, 4 × 4 GB at 6400 MT/s,
   390 GB free on C:, `HypervisorPresent : False` (VirtualBox can use AMD-V directly).

2. **Calculated the resources.**

   | | RAM | vCPU | Disk |
   |---|---|---|---|
   | Host total | 15.2 GB usable | 16 threads | 390 GB free |
   | Host uses itself, idle | 6.9 GB | — | — |
   | **Free for guests** | **8.4 GB** | — | — |
   | win11 | 6 GB | 4 | 64 GB dynamic |
   | ubuntu | 2 GB | 2 | 25 GB dynamic |
   | **Guests total** | **8 GB** (≤ 8.4 ✔) | **6** (host keeps 10) | **89 GB max** (23 % of free space) |

   8 GB for guests is the ceiling on this laptop. I proved this the hard way in Lab 2: promising 18 GB froze
   the laptop and VirtualBox killed the Ubuntu guest with `VERR_NO_PAGE_MEMORY` (see section "What went
   wrong" below). That is why BUILD.md starts with Step 0 rather than with "click New".

3. **Settings that differ from the VirtualBox defaults, and why.**

   | Setting | Default | Mine | Why |
   |---|---|---|---|
   | Network adapter (both) | NAT | **NAT Network "NatNetwork" 10.0.2.0/24** | Plain NAT isolates each guest; the guests could not ping each other |
   | Unattended install | on | **skipped** | Unattended Ubuntu install can create a user without sudo; I hit a sudo problem in Lab 1 |
   | Ubuntu RAM | 2048 MB (wizard suggests 2–4 GB) | **2048 MB** | No GUI; leaves room for Windows (Lab 1 used 4 GB; reduced in Lab 2 once both guests had to fit) |
   | Windows RAM | 4096 MB | **6144 MB** | 4 GB installs but is barely usable |
   | Windows vCPU | 2 | **4** | Windows updates and installers are CPU-heavy; host keeps 10 threads |
   | Windows TPM / Secure Boot | off on some VirtualBox versions | **TPM 2.0, Secure Boot on** | Windows 11 refuses to install otherwise |
   | Disks | dynamic | **dynamic (kept)** | Deliberately kept: only used space is taken |
   | Windows firewall | blocks inbound ICMP | **one rule: allow ICMPv4 type 8, profile Any** | Needed for guest-to-guest ping without turning the firewall off |
   | Windows account | Microsoft account | **local account** | Not tied to anyone's personal email |
   | Snapshot | none | **`clean-install`** | The "without breaking anything" requirement |

4. **Network:** created NatNetwork, attached both adapters, added the firewall rule:
   ```powershell
   New-NetFirewallRule -DisplayName "Allow ICMPv4 Echo In" -Protocol ICMPv4 -IcmpType 8 -Direction Inbound -Action Allow -Profile Any
   ```

5. **Verified** both directions and the internet (`ping` from each guest to the other, to 8.8.8.8 and to
   google.com), then took the `clean-install` snapshot.

6. **Took the missing screenshots and `uname`.** The first `ssh` attempt failed with `Permission denied` —
   the password was mistyped (it is not echoed on screen); the second attempt worked:
   ```powershell
   ssh -p 2222 yasmina@127.0.0.1 "uname -a" | Out-File -Encoding utf8 04-guest-uname.txt
   ```

7. **Wrote [BUILD.md](BUILD.md)** as 15 steps (0–14), each with: what to click, a screenshot, *why this
   option and not another*, and a **Check** line. Finished with a troubleshooting table built from the
   problems I actually hit.

### Decisions and the alternatives I rejected

**Network mode.** I compared all five VirtualBox modes against the two requirements:

| Mode | Guests see each other | Internet | Verdict |
|---|---|---|---|
| NAT (default) | no | yes | fails |
| Host-only | yes | no | fails |
| Internal | yes | no | fails |
| Bridged | yes | yes | works at home, but office/campus Wi-Fi can reject the guest's MAC address |
| **NAT Network** | **yes** | **yes** | **chosen** |

The trade-off I accepted: behind NAT Network nobody outside the laptop can reach the guests without
port-forwarding. For one developer testing on his own machine that does not matter, and in exchange the
setup works on *any* network Aigerim's next computer is plugged into.

**Firewall: one rule vs. turning it off.** Turning the Windows firewall off is one click and would be easier
to document. I did not, because the document will be repeated by someone who will not know to turn it back
on, and the machine would then sit on the office network unprotected. One narrow rule costs one extra
copy-paste command.

**VirtualBox vs. Hyper-V.** Hyper-V is built into Windows and slightly faster, but only on Pro/Enterprise
editions, and it disables VirtualBox's direct AMD-V access when switched on. VirtualBox works on Windows
Home, macOS and Linux, so the document stays valid whatever computer the next person gets.

**Windows evaluation vs. a licensed copy.** Evaluation costs nothing and is ready by Monday; the cost is the
90-day expiry. I chose it and made the expiry visible in Step 2 instead of hiding it.

**Dynamic vs. fixed disk.** Fixed is a little faster but takes all 89 GB immediately; dynamic takes what is
written — measured: 6.3 GB + 22.1 GB = 28.4 GB ([18-disk-info.txt](evidence/18-disk-info.txt)). For a test machine the space matters more than the speed.

### What went wrong and how I resolved it

**The host froze when I gave the guests more memory than it had.** While working out how much RAM the
guests could have, I promised 10 GB to Windows and 8 GB to Ubuntu (18 GB) on a laptop with 15.2 GB usable.
About a minute into a memory load in Ubuntu the laptop stopped responding, and VirtualBox stopped Ubuntu:

```
PGM: Failed to procure handy pages; rc=VERR_NO_PAGE_MEMORY
Changing the VM state from 'RUNNING' to 'GURU_MEDITATION'
```

I ended the stuck `VirtualBoxVM` process, pulled the reason out of `VBox.log`, and repeated with a milder
over-promise while Task Manager was open: available memory fell from 8.4 GB to 47.6 MB and disk activity
rose from 7 % to 75 % as Windows paged to disk. Resolution: total guest RAM capped at what Task Manager shows
as *Available* (6 + 2 = 8 GB), and that rule became **Step 0** of BUILD.md — the most important line in the
document for someone repeating it on an unknown computer. Full log and figures: Lab 2,
`labs/lab02-windows-vm/evidence/vbox-log-extract.txt` and `host-memory-after.png`.

**Checking the machines with `VBoxManage` showed my report was wrong in two places.** I had assumed the
settings from my notes were still true. Reading them back from VirtualBox instead:

```powershell
$vb = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
& $vb showvminfo win11 | Select-String "Memory size|Number of CPUs|Firmware|Secure Boot|NIC 1:"
& $vb snapshot win11 list
```

| Expected (from my notes) | Got | Concluded |
|---|---|---|
| win11 6144 MB, lab01-ubuntu 2048 MB | **10240 MB and 8192 MB** | the Lab 2 overcommit run 1 values were never set back — starting both guests now would freeze the laptop again |
| `clean-install` on both guests | win11: *This machine does not have any snapshots* | only Ubuntu (from Lab 1) had one; "without breaking anything" was not true for Windows |

Fixed with both guests powered off, then re-read into [17-vm-settings.txt](evidence/17-vm-settings.txt) and
[06b-snapshot-list.txt](evidence/06b-snapshot-list.txt):

```powershell
& $vb modifyvm win11 --memory 6144
& $vb modifyvm lab01-ubuntu --memory 2048
& $vb snapshot win11 take clean-install --description "Clean install, before handing to the developer"
```

A dead end on the way: `showmediuminfo` with the disk *path* failed with `VERR_PATH_NOT_FOUND`, because my
user folder `C:\Users\Ясмина` has Cyrillic letters and the path was garbled when passed through the pipe.
Passing the disk's UUID instead of its path worked.

Two smaller problems also went into the troubleshooting table: Linux → Windows ping was **100 % lost**
until the firewall rule was added ([11-ping-blocked-before-rule.txt](evidence/11-ping-blocked-before-rule.txt),
[12-firewall-profile.txt](evidence/12-firewall-profile.txt)), and an SSH port-forward I had pointed at the
network address `10.0.2.0` instead of the guest `10.0.2.3` gave `Connection refused`.

## 4. Evidence

| File | What it proves |
|---|---|
| [evidence/01-new-vm-wizard.png](evidence/01-new-vm-wizard.png) | New VM wizard, step 4: name `test-ubuntu`, the Ubuntu 26.04.1 ISO, automatic installation **off** |
| [evidence/01b-new-vm-hardware.png](evidence/01b-new-vm-hardware.png) | Same wizard, hardware section: 2048 MB memory, 2 CPUs, EFI off — the figures from the resource calculation |
| [evidence/02-disk-settings.png](evidence/02-disk-settings.png) | Disk size set to 25 GB (Step 5). It does not show the pre-allocate box; that the disks are dynamic is proven by `18-disk-info.txt` |
| [evidence/03a-nat-network-manager.png](evidence/03a-nat-network-manager.png) | NatNetwork exists with IPv4 prefix 10.0.2.0/24 and DHCP enabled (Step 3) |
| [evidence/03-network-adapter.png](evidence/03-network-adapter.png) | The **Ubuntu** guest's Adapter 1 is on *NAT Network → NatNetwork* (Step 6). Its MAC `080027AFFD30` is the same as in `09-ip-addr-linux.txt`, so this is the same machine that got 10.0.2.3 |
| [evidence/03b-network-adapter-win11.png](evidence/03b-network-adapter-win11.png) | The **Windows** guest's adapter is on the same NatNetwork. MAC `08002723A13C` matches `10-ipconfig-windows.txt` (10.0.2.4) |
| [evidence/04-guest-uname.txt](evidence/04-guest-uname.txt) | The Ubuntu guest boots and runs a Linux kernel: `uname -a` taken over SSH from the host and saved as UTF-8 text |
| [evidence/05-ping-between-guests.txt](evidence/05-ping-between-guests.txt) | Both guests reach each other in both directions (0 % loss, TTL 128 = Windows, TTL 64 = Linux) **and** reach 8.8.8.8 and google.com — including the blocked first attempt, so it shows how the result was reached |
| [evidence/06-snapshot-list.png](evidence/06-snapshot-list.png) | The Ubuntu snapshot in the VirtualBox window (Step 13) |
| [evidence/06b-snapshot-list.txt](evidence/06b-snapshot-list.txt) | **Both** guests now have a `clean-install` snapshot, as text from `VBoxManage snapshot … list` — win11's was taken during this ticket (see "What went wrong") |
| [evidence/07-win11-settings-summary.png](evidence/07-win11-settings-summary.png) | Windows guest as configured: 6144 MB, 4 CPUs, 64 GB, EFI / TPM 2.0 / Secure Boot, NAT Network (Step 8) |
| [evidence/08-ubuntu-settings-summary.png](evidence/08-ubuntu-settings-summary.png) | Ubuntu guest settings summary |
| [evidence/09-ip-addr-linux.txt](evidence/09-ip-addr-linux.txt) | Ubuntu got 10.0.2.3/24 from the NatNetwork DHCP |
| [evidence/10-ipconfig-windows.txt](evidence/10-ipconfig-windows.txt) | Windows got 10.0.2.4 on the same /24, gateway 10.0.2.1 — the two are on one network |
| [evidence/11-ping-blocked-before-rule.txt](evidence/11-ping-blocked-before-rule.txt) | Before the firewall rule, Linux → Windows ping was 100 % lost (the problem existed) |
| [evidence/12-firewall-profile.txt](evidence/12-firewall-profile.txt) | Windows classified the network as **Public** — why `-Profile Any` is needed |
| [evidence/13-firewall-rule.txt](evidence/13-firewall-rule.txt) | The fix is one narrow rule (inbound, allow, ICMPv4), not a disabled firewall |
| [evidence/14-host-memory-before.png](evidence/14-host-memory-before.png) | Host with guests off: 6.9 / 15.2 GB in use, 8.4 GB available — the figure the RAM calculation is based on |
| [evidence/15-host-specs.txt](evidence/15-host-specs.txt) | Host CPU (8C/16T), 4 × 4 GB memory, 390 GB free on C:, no other hypervisor present |
| [evidence/16-host-memory-before.txt](evidence/16-host-memory-before.txt) | Same memory state as text: 8,120 MB available, page file barely used |
| [evidence/17-vm-settings.txt](evidence/17-vm-settings.txt) | Actual settings from `VBoxManage showvminfo`, as text: lab01-ubuntu 2048 MB / 2 CPUs / BIOS, win11 6144 MB / 4 CPUs / EFI / Secure Boot enabled, both NIC 1 on NAT Network 'NatNetwork' — the numbers in this report are read from the machines, not remembered |
| [evidence/18-disk-info.txt](evidence/18-disk-info.txt) | Both base disks are `dynamic default`: Ubuntu uses 6,323 of 25,600 MB, Windows 22,140 of 65,536 MB — the measured saving behind the dynamic-disk decision. The two `differencing` disks are the snapshots |
| [review/](review/) | Week 5: the first step at which a peer, following BUILD.md literally, got stuck — and the correction made |

## 5. What I would do differently

- **Write BUILD.md during the build, not after.** I built the machines in Labs 1–2 and wrote the
  document afterwards, so several screenshots had to be retaken and I had to remember why I picked
  options I had clicked weeks earlier. Screenshot + one sentence of "why" at the moment of each click
  would have taken less time in total.
- **Save PowerShell output as UTF-8 from the start.** `Tee-Object` in Windows PowerShell 5 writes UTF-16,
  which GitHub shows as unreadable text; I had to convert `host-specs.txt` and `host-memory-before.txt`.
  Next time: `| Out-File -Encoding utf8 file.txt`.
- **Capture the whole settings section, not a cropped strip.** My disk screenshot shows the 25 GB size but
  not the *pre-allocate* checkbox, so the one decision it was meant to prove (dynamic disk) is stated in the
  text but not visible in the evidence.
- **Read the settings back from the machine before writing them down.** My report said 6 GB + 2 GB and
  a snapshot on both guests; `VBoxManage` showed 10 GB + 8 GB and no Windows snapshot. One `showvminfo`
  after the Lab 2 experiment would have caught it the same day.
- **Test Step 0 on a smaller computer.** My laptop has 16 GB; I only reasoned about what happens on an 8 GB
  office PC. Following the document once on such a machine would show whether "run one guest at a time" is
  really enough.
