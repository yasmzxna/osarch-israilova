\# Lab 0 — Inventory your own machine



Student: Yasmina Israilova

Pair: Individual work; no partner.

Driver: Yasmina Israilova throughout the session.

Machine: Machcreator L16A; Windows 11 Pro, 64-bit, version 10.0.26200.

Guest: None.

Date: 19.10.2026



\## What I did



I used Windows PowerShell to inventory my laptop. I collected all hardware values using commands, without using graphical system information windows. I saved the commands and their output as text files in the evidence folder.



\### CPU



```powershell

Get-CimInstance Win32\_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors | Format-List

```



\### Memory



```powershell

Get-CimInstance Win32\_PhysicalMemory | Select-Object DeviceLocator, Capacity, Speed, ConfiguredClockSpeed | Format-List

Get-CimInstance Win32\_PhysicalMemory | Measure-Object -Property Capacity -Sum | Format-List Count, Sum

```



\### Disk and free space



```powershell

Get-PhysicalDisk | Select-Object FriendlyName, MediaType, BusType | Format-List

Get-Volume | Where-Object { $\_.DriveLetter -and $\_.DriveType -eq "Fixed" } | Select-Object DriveLetter, @{Name="Total\_GiB";Expression={\[math]::Round($\_.Size / 1GB, 2)}}, @{Name="Free\_GiB";Expression={\[math]::Round($\_.SizeRemaining / 1GB, 2)}} | Format-Table -AutoSize

```



\### Firmware



```powershell

Get-ComputerInfo -Property BiosFirmwareType | Format-List

Get-CimInstance Win32\_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate | Format-List

```



\### Virtualization



```powershell

Get-CimInstance Win32\_Processor | Select-Object Name, VMMonitorModeExtensions, VirtualizationFirmwareEnabled, SecondLevelAddressTranslationExtensions | Format-List

Get-CimInstance Win32\_ComputerSystem | Select-Object HypervisorPresent | Format-List

```



\### Host identification



```powershell

Get-CimInstance Win32\_ComputerSystem | Select-Object Manufacturer, Model | Format-List

Get-CimInstance Win32\_OperatingSystem | Select-Object Caption, Version, OSArchitecture | Format-List

```



\## Result



| What | Value | Where I got it |

|---|---|---|

| CPU model | AMD Ryzen 7 7735HS with Radeon Graphics | `Get-CimInstance Win32\_Processor` — Name |

| CPU cores | 8 | `Get-CimInstance Win32\_Processor` — NumberOfCores |

| CPU threads / logical processors | 16 | `Get-CimInstance Win32\_Processor` — NumberOfLogicalProcessors |

| Total installed memory | 16 GiB (17,179,869,184 bytes) | `Get-CimInstance Win32\_PhysicalMemory` piped to `Measure-Object -Property Capacity -Sum` — Sum |

| Installed memory devices reported by Windows | 4 devices, each 4 GiB | `Get-CimInstance Win32\_PhysicalMemory` — four Capacity entries; `Measure-Object -Property Capacity -Sum` — Count |

| Memory speed | Speed = 6400; ConfiguredClockSpeed = 6400 for all four devices, as reported by Windows | `Get-CimInstance Win32\_PhysicalMemory` — Speed, ConfiguredClockSpeed |

| Physical disk model | SSSTC CL6-8D1024 | `Get-PhysicalDisk` — FriendlyName |

| Physical disk type | NVMe SSD | `Get-PhysicalDisk` — MediaType = SSD, BusType = NVMe |

| Selected volume for future VMs | C: | `Get-Volume` — DriveLetter |

| Selected volume total size | 952.49 GiB | `Get-Volume` — Size divided by 1GB in PowerShell |

| Selected volume free space | 399.28 GiB at the time of evidence collection | `Get-Volume` — SizeRemaining divided by 1GB in PowerShell |

| Firmware type | UEFI | `Get-ComputerInfo -Property BiosFirmwareType` |

| Firmware manufacturer | American Megatrends International, LLC. | `Get-CimInstance Win32\_BIOS` — Manufacturer |

| Firmware version | 10.02 | `Get-CimInstance Win32\_BIOS` — SMBIOSBIOSVersion |

| Firmware release date | 2024-07-25 | `Get-CimInstance Win32\_BIOS` — ReleaseDate |

| Hardware virtualization supported | Yes (True) | `Get-CimInstance Win32\_Processor` — VMMonitorModeExtensions |

| Hardware virtualization enabled in firmware | Yes (True) | `Get-CimInstance Win32\_Processor` — VirtualizationFirmwareEnabled |

| Second-level address translation supported | Yes (True) | `Get-CimInstance Win32\_Processor` — SecondLevelAddressTranslationExtensions |

| Hypervisor currently present | No (False) | `Get-CimInstance Win32\_ComputerSystem` — HypervisorPresent |



Memory capacities are expressed in GiB: 1 GiB = 1,073,741,824 bytes. The four memory entries all have the same DeviceLocator, DIMM 0. Therefore, the count above is the number of memory devices reported by Windows, not proof of four removable RAM sticks or four upgradeable slots.



Get-PhysicalDisk also listed Msft Virtual Disk with BusType File Backed Virtual. I recorded it in the evidence but did not count it as a second physical drive.



Hardware virtualization is supported and already enabled. No firmware setting change was necessary. HypervisorPresent = False means that Windows did not detect a running hypervisor at the time of the check.



\## What did not work the first time



After pasting a command into PowerShell, I initially did not see its output. The command was still waiting at the prompt because I had not pressed Enter. I pressed Enter, and the command ran and displayed the result.



I also saw >> prompts while entering commands over multiple lines. These were continuation prompts, not error messages. After completing the command, PowerShell returned to the normal PS prompt.



\## Evidence



\- \[cpu.txt](evidence/cpu.txt) — CPU model, core count and logical processor count.

\- \[memory.txt](evidence/memory.txt) — Individual memory capacities, reported speeds, device count and total capacity.

\- \[disk.txt](evidence/disk.txt) — Disk model and type, volume size and free space.

\- \[firmware.txt](evidence/firmware.txt) — Firmware type, manufacturer, version and release date.

\- \[virtualization.txt](evidence/virtualization.txt) — Virtualization support, firmware enablement, SLAT and hypervisor status.

