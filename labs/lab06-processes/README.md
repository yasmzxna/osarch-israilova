# Lab 6 — Live processes and memory pressure

Pair: Исраилова Ясмина и Ермаканов Арсен (group work) · Date: 2026-11-12 · Guests: `lab01-ubuntu` — Ubuntu 26.04.1 LTS Server, kernel 7.0.0-38, 2 GB RAM (1.6 GiB usable) + 2 GB swap file; `win11` — Windows 11 Enterprise Evaluation (build 26100), 6 GB RAM. Oracle VirtualBox.

Both guests were powered off and snapshotted as `before-lab6` before anything was changed (Step 6).

## Part 1 — One process, three tools

**Process chosen: VirtualBox Guest Additions service** — `VBoxService.exe` on Windows, `/usr/sbin/VBoxService` on Ubuntu — because it is the same program on both guests, it runs all the time as a system service (so it has a real parent, handles and threads), and it does not change much between screenshots.

On Ubuntu VBoxService was not running at first (Guest Additions were not installed on the server guest), so I installed `virtualbox-guest-utils` first — see "What did not work the first time".

All three tools were looked at in one sitting, within 8 minutes (host time, Almaty):

| Evidence | Tool | Host time |
|---|---|---|
| `evidence/task-manager.png` | Task Manager → Details, filtered on "VBoxService" | 14:44 |
| `evidence/process-explorer.png` | Process Explorer (run as administrator), tree view + lower pane = Handles | 14:48 |
| `evidence/htop.png` | htop, tree view, PPID and NLWP columns added | 14:51 |
| `evidence/ps-fd.txt` | `ps`, `ls /proc/2327/fd`, `/proc/2327/status` | 14:52 |

### Comparison table

| | Task Manager | Process Explorer | htop / ps |
|---|---|---|---|
| PID | 1988 | 1988 | 2327 |
| Parent (name and PID) | — (not shown) | `services.exe` (884), which is a child of `wininit.exe` (740) | `systemd` (1) — PPID column / tree |
| "Memory" as shown by default | Memory (active private working set) = **740 K** | Private Bytes = **2,440 K** | RES = **3712 K** (MEM% 0.2) |
| Private memory | Memory (private working set) = 740 K; Commit size = 2,436 K | WS Private = 724 K; Private Bytes = 2,440 K | no column; `/proc` RssAnon = 416 kB |
| Working set / RES | Working set (memory) = 9,496 K | Working Set = 9,500 K | RES = 3712 K (`ps` RSS = 3712), of which SHR = 3296 K |
| Virtual size | no column | Virtual Size = 2,151,780,064 K (≈ 2 TB) | VIRT = 285M (`ps` VSZ = 292100 kB) |
| Handles / file descriptors | Handles = 202 | Handles = 202 (listed in the lower pane: Desktop, Directory, Event, File, Key, Mutant, Semaphore, Thread …) | 5 fds: `0,1,2 -> /dev/null`, `3 -> /dev/vboxguest`, `4 -> socket:[19686]` |
| Threads | 14 | 14 | NLWP = 9 (`Threads: 9` in `/proc/2327/status`) |
| CPU | 00 (%) | < 0.01 (%) | CPU% = 0.0, MEM% = 0.2 |
| User | SYSTEM | (Users column not added) | root |

### Where the tools disagree

1. **Parent.** Task Manager has no parent column at all. Process Explorer shows it as the line one level up in the tree: `services.exe` (PID 884), the Service Control Manager, starts every Windows service. On Linux the parent is PID 1 `systemd`, because systemd is the service manager there. Same role, different process, and only two of the three tools show it.
2. **"Memory" is three different numbers for the same process.** Task Manager's default "Memory" column is the *active private working set* (740 K): private pages that are in RAM right now. Process Explorer's default is *Private Bytes* (2,440 K): all private memory the process has committed, including pages that are not in RAM. htop's RES (3712 K) counts every page in RAM, shared ones included: 3296 K of it is SHR, file-backed shared library pages. On Linux only RssAnon = 416 kB is really private. So the defaults are not comparable, and Windows shows the smallest number by default.
3. **Same thing under different names.** *Commit size* (Task Manager, 2,436 K) is *Private Bytes* (Process Explorer, 2,440 K). *Memory (private working set)* (740 K) is *WS Private* (724 K). *Working set* is the Windows name for what Linux calls *RSS / RES* (9,496 K vs 9,500 K). The small gaps (2,436 vs 2,440, 740 vs 724, 9,496 vs 9,500) come from the 4 minutes between the two screenshots; the service allocates and frees a little. htop has no column for committed private memory at all.
4. **Virtual size.** Task Manager does not show it. Process Explorer shows ≈ 2 TB for a service that uses 9 MB, because on 64-bit Windows the reserved address space (including the Control Flow Guard bitmap) counts. htop's VIRT (285 MB) is also mostly reserved, not used. VIRT is address space, not memory in use.
5. **Handles ≠ file descriptors.** Windows reports 202 handles but Linux only 5 fds, for the same program. A Windows handle is a reference to *any* kernel object: registry keys, events, mutexes, semaphores and even its own threads (the lower pane lists `Thread VBoxService.exe(1988): 1992 …`). A Linux fd only points to things in the file namespace: files, devices (`/dev/vboxguest`), sockets.
6. **Threads.** The two Windows tools agree (14). The Linux build of the same service runs 9 threads (htop needs `NLWP` added to show this; it hides userland threads in its default view).
7. **CPU %.** The service is idle, so all three show about zero, but the scale is different. Task Manager rounds to whole percent ("00") and counts the *whole machine* as 100 %. Process Explorer shows two decimals ("< 0.01"), also of the whole machine. htop counts *one core* as 100 %: on the 2-CPU Ubuntu guest a process can reach 200 %. You can see this during the experiment, where `/usr/bin/time` reports `Percent of CPU this job got: 191%` for stress-ng (`evidence/stress-ng.txt`).
8. **Name.** Windows shows only the image name `VBoxService.exe` (the path is in Image properties). htop shows the full command `/usr/sbin/VBoxService`.

## Part 2 — Memory pressure

Guest RAM: 2048 MB in VirtualBox, `free -h` total = 1.6 GiB (not lowered: it was already 2 GB, as the guide recommends) · swap: `/swap.img` file, 2 GiB, priority -1 · `vm.swappiness = 60`, `vm.overcommit_memory = 0`.

Steps, in order (Ubuntu guest; times are guest clock, UTC = host time − 5 h):
```
free -h; swapon --show                                         # BEFORE, 09:56:45
while true; do echo "=== $(date +%T) ==="; free -h; sleep 3; done >> memory-pressure.txt   # recorder, background
vmstat -t 2 > vmstat.txt                                       # si/so, background
stress-ng --vm 2 --vm-bytes 70%  --timeout 60s                 # 09:59:25 – 10:00:26
stress-ng --vm 2 --vm-bytes 90%  --timeout 60s                 # 10:00:36 – 10:01:36
stress-ng --vm 2 --vm-bytes 120% --timeout 90s                 # 10:01:46 – 10:03:28  (no OOM)
stress-ng --vm 2 --vm-bytes 150% --timeout 90s                 # 10:06:06 – 10:07:37  (no OOM)
stress-ng --vm 1 --vm-bytes 4G --vm-keep --timeout 120s        # 10:07:55 – 10:10:02  (OOM killer)
free -h; swapon --show                                         # AFTER, 10:12:38
```
Full record: `evidence/memory-pressure.txt` (a `free -h` every 3 s), `evidence/stress-ng.txt` (stress-ng's own output), `evidence/vmstat.txt` (si/so), `evidence/responsiveness.txt` (SSH round-trip times). htop during the OOM phase: `evidence/htop-during-pressure.png`.

| | Before (09:56:45) | During (worst) | After (10:12:38) |
|---|---|---|---|
| Available | 1.2 Gi | **9.8 Mi** (10:09:56) | 1.3 Gi |
| Swap used | 0 B | **1.9 Gi** of 2.0 Gi (10:08:37, 10:09:15) | 82 Mi |

What happened:
- **70 % / 90 % / 120 % (09:59–10:03):** available dropped from 1.2 Gi to as low as 389 Mi (10:03:07) and came back after every run. Swap used went above zero only for a few seconds at a time (239 Mi at 10:00:44 during the 90 % run, 352 Mi at 10:02:00 during the 120 % run) and was back near 0 straight away. All runs `passed`, no OOM. The guest stayed responsive (SSH round trip 0.5–0.8 s, one spike to 9.8 s at 10:01:58). Between runs, at 10:04:21–10:04:41, SSH also took 12–14 s while nothing was stressing the guest and swap was 0; I cannot explain that from the guest's figures and think it was the host being busy.
- **150 % (10:06–10:07):** available went down to about 114 Mi (10:07:30) and swap used went up to 272 Mi. Still `passed`, no OOM.
- **4G, one worker (10:07:55 – 10:10:02):** available dropped to **50 Mi within 6 s** (10:08:01) and stayed at 10–50 Mi for two minutes.
- **When swap used started to grow:** at the start of the 4G run, 6.7 Mi at 10:07:55, then 368 Mi (10:08:01), 765 Mi (10:08:04), 1.1 Gi (10:08:08), 1.4 Gi (10:08:11). From there it stayed at **1.7–1.9 Gi** until the run ended. During this phase vmstat shows `so` (pages swapped out) at about **250,000 KB/s** (10:09:50–10:10:00) with `sy` ≈ 83 % and `wa` 11–15 %: the CPU was busy moving pages, not running the program (thrashing).
- **Responsiveness** (measured from the host every ~10 s, `evidence/responsiveness.txt`): a simple SSH command took 0.6 s before. During the 4G phase it took 2–8 s (8.2 s at 10:07:55, 4.2 s at 10:08:19). The 3-second recorder missed beats: gaps of 10–19 s at 10:10:02 → 10:10:21 and 10:11:34 → 10:11:51. The htop on the console stopped redrawing properly and printed garbage (`Uptime:441:25:19`, `Mem 85.3G`, see `htop-during-pressure.png`).
- **The process:** the kernel killed the `stress-ng-vm` worker **7 times**, at 10:08:17, 10:08:38, 10:08:59, 10:09:16, 10:09:30, 10:09:42 and 10:09:53. Each time the stress-ng parent started a new worker, so `stress-ng` itself reported `successful run completed` but with **0 bogo ops**: the worker never finished one pass over its memory before being killed. After each kill available jumped back to 0.7–1.3 Gi for a few seconds.

### What the kernel did

`evidence/kernel-log-extract.txt` was produced with the guide's exact command:
```
journalctl -k --since "30 min ago" | grep -i -E -B3 -A8 "out of memory|oom-kill"
```
The first kill:
```
Nov 12 10:08:17 lab01-israilova kernel: systemd invoked oom-killer: gfp_mask=0x140cca(GFP_HIGHUSER_MOVABLE|__GFP_COMP), order=0, oom_score_adj=0
Nov 12 10:08:17 lab01-israilova kernel: oom-kill:constraint=CONSTRAINT_NONE,nodemask=(null),cpuset=/,mems_allowed=0,global_oom,task_memcg=/user.slice/user-1000.slice/session-58.scope,task=stress-ng-vm,pid=6855,uid=1000
Nov 12 10:08:17 lab01-israilova kernel: Out of memory: Killed process 6855 (stress-ng-vm) total-vm:3732628kB, anon-rss:1407792kB, file-rss:584kB, shmem-rss:0kB, UID:1000 pgtables:6864kB oom_score_adj:1000
Nov 12 10:08:17 lab01-israilova systemd-journald[542]: Under memory pressure, flushing caches.
```
- **Which process:** `stress-ng-vm`, PID 6855 (then 6952, 7070, 7203, 7329, 7407, 7542: each respawned worker).
- **Why that one:** it had by far the largest memory: `anon-rss:1407792kB` (≈ 1.34 GB of private RAM) plus ≈ 2 GB it had pushed out to swap (513,527 swap entries in the task table). The next biggest process in the same table, `unattended-upgr`, had rss 3417 pages ≈ 13 MB. The kernel scores each task by RAM + swap + page tables and adds `oom_score_adj`. stress-ng sets its workers to `oom_score_adj:1000`, the maximum, so they are chosen first.
- **Why it happened:** `CONSTRAINT_NONE … global_oom`. The whole machine (RAM and swap) was out of memory, not a cgroup limit. A normal page-fault allocation (`GFP_HIGHUSER_MOVABLE`) by `systemd` (PID 1, `oom_score_adj=0`) could not be satisfied, so that allocation triggered the OOM killer. The victim was not the process that asked for memory.
- **When:** 10:08:17 for the first one. In `memory-pressure.txt` available is 30 Mi at 10:08:14 and **673 Mi at 10:08:17**, the exact second the 1.4 GB worker was killed. The same jump repeats at 10:08:40 (806 Mi), 10:08:59 (877 Mi), 10:09:30 (1.3 Gi) and so on, matching each `Killed process` line.
- Before the OOM kills the log also shows `__vm_enough_memory: pid: 6855, comm: stress-ng-vm, bytes: 4294967296 not enough memory for the allocation` (10:07:56). The kernel's overcommit check refused one 4 GB request outright, and stress-ng then allocated in smaller pieces until real memory ran out.

### Windows

On the Windows guest (PowerShell, 2026-11-12 11:22 guest time):
```
PS C:\Users\yasmin> Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Resource-Exhaustion-Detector'} -MaxEvents 5 | Format-List TimeCreated, Id, Message
Get-WinEvent : No events were found that match the specified selection criteria.
    + FullyQualifiedErrorId : NoMatchingEventsFound,Microsoft.PowerShell.Commands.GetWinEventCommand
```
Screenshot: `evidence/windows-event-log.png`.

**Result: no events.** This is a valid result. The Windows guest has 6 GB RAM and its commit charge was only about 42 % during the lab (Process Explorer status bar: `Commit Charge: 41.97%`), so it has never run low on memory.

I also searched the System log by ID only (`Id=2004`) and found exactly one event. It is **not** a memory event: `11/4/2026 12:22:23 AM, Id 2004, ProviderName Microsoft-Windows-Setup, "Successfully logged OS information"` (`evidence/windows-event-2004.png`). Event IDs are only unique per provider, so the filter must include the provider name.

What I would expect, and when: Windows does **not** kill processes like the Linux OOM killer. When the *commit charge* approaches the *commit limit* (RAM + page file), new allocations start failing (programs get "out of memory" errors or crash themselves). Windows tries to grow the page file and shows a low-memory warning. The **Resource-Exhaustion-Detector** then writes event **2004** in the System log: "Windows successfully diagnosed a low virtual memory condition. The following programs consumed the most virtual memory: …", naming the processes with the largest commit. So Linux *acts* (kills a process, logs `Out of memory: Killed process`), and Windows *reports* (refuses allocations, logs who used the most). On Windows you could cause this with Sysinternals `testlimit64.exe -d 512` on a snapshotted guest. I did not run it.

## Clean-up

The Ubuntu guest RAM was not changed (it was already 2 GB). All guest files were copied to `evidence/` before anything else. The `before-lab6` snapshots stay on both guests, so either one can be restored. The recorder and vmstat loops were stopped (`free -h` AFTER shows swap draining back to 82 Mi).

## What did not work the first time

- **VBoxService was not running on Ubuntu.** `pgrep -a VBoxService` printed nothing: the server guest had no Guest Additions. I installed `virtualbox-guest-utils` (`sudo apt install -y virtualbox-guest-utils`), after which `VBoxService` ran as PID 2327 under systemd, so the same program could be compared on both guests.
- **70 / 90 / 120 % did not trigger the OOM killer, and neither did 150 %.** stress-ng's `--vm-bytes 120%` is a percentage of *available* memory at start-up (`total 784.20MB of 651.50MB available memory`), not of RAM + swap. With 1.6 GiB RAM + 2 GiB swap the kernel simply swapped a little and the runs `passed`. Only one worker with `--vm-bytes 4G --vm-keep` (more than RAM + swap together) exhausted memory and got killed.
- **htop ignored my column config.** Writing `fields=PID PPID …` (and then numeric field IDs) to `~/.config/htop/htoprc` had no effect, because htop 3.4 reads columns from a `screen:Main=…` line. With `screen:Main=PID PPID USER … NLWP Command` and `tree_view=1` the PPID and thread columns appeared.
- **`pkill -f "while true; do echo"` killed my own SSH command** (exit code 127, no output). The pattern also matched the command line of the shell that was running `pkill`. I checked with `pgrep -af` that the recorder had stopped and only then wrote the AFTER block.
