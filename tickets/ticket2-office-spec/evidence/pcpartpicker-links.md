# PCPartPicker lists — compatibility and power check

**PCPartPicker does not price in tenge**, and it does not list Kazakhstan shops. The dollar prices on these lists are US prices and were **not** used anywhere in the report. I used PCPartPicker only for two things:
1. **Compatibility:** CPU socket ↔ board socket, memory type ↔ board, M.2 NVMe ↔ M.2 slot, CPU cooler ↔ socket, case ↔ board and PSU form factor.
2. **Power:** PCPartPicker's estimated wattage ↔ the PSU.

All prices come from DNS and are in [../budget.csv](../budget.csv). Lists made on 2026-11-23.

## Summary

| Build | PCPartPicker list | Compatibility | Estimated wattage | PSU |
|---|---|---|---|---|
| Accountant | https://pcpartpicker.com/list/ZXff2k | Compatible. One BIOS note (A) | 159 W | 650 W |
| Sales manager | https://pcpartpicker.com/list/nCwXh9 | Compatible. One BIOS note (A) | 174 W | 650 W |
| Web developer | https://pcpartpicker.com/list/4mLByF | Compatible. One BIOS note (A) | 174 W | 650 W |
| Designer | https://pcpartpicker.com/list/WR4v2k | Compatible. One BIOS note (A) | 319 W | 650 W |

Every build draws at most about half of its 650 W PSU. The designer machine, the only one with a graphics card, is at 319 W, which is 49% of the PSU. PCPartPicker also confirms each list leaves **2 of 4 memory slots and 1 of 2 M.2 slots free**, which is the upgrade headroom builds.md relies on.

## The one warning PCPartPicker shows, and what I do about it

**(A) BIOS version.** For the B550M AORUS ELITE, PCPartPicker says the board supports:
- the **Ryzen 7 5700G from BIOS F13**;
- the **Ryzen 7 5700X from BIOS F14**.

If the board ships with an older BIOS, it must be updated before the CPU will work. This is not a physical incompatibility: socket, memory and power all fit. It is a firmware version check.

What I would do:
- Ask DNS for a board with a current BIOS. DNS also sells a "component installation" service.
- Otherwise, use the board's Q-Flash Plus button, which on Gigabyte boards updates the BIOS from a USB stick without a CPU installed.

PCPartPicker also shows a general disclaimer that it does not check some physical constraints, such as RAM height under a large CPU cooler. Our memory (ADATA XPG D35G, G.Skill Aegis) is low-profile, so this is not a concern with the SE-214-XT tower cooler.

## Where the lists differ from budget.csv, and why

| Part in budget.csv | On the PCPartPicker list | Why |
|---|---|---|
| MONTECH BETA 650 (650 W Bronze), office builds | MONTECH GAMMA II 650 W Gold | BETA 650 is not in PCPartPicker's database. GAMMA II 650 is the same brand, the same 650 W rating and the same ATX form factor, so the compatibility and power check is equivalent. The designer build uses the GAMMA II for real. |
| ID-COOLING SE-214-XT BLACK | ID-COOLING SE-214-XT | Closest model in the database: same cooler family and the same AM4 mounting. |
| Xiaomi A27Qi 2026 / Xiaomi A24i monitors | not on the list | Not in PCPartPicker's database. A monitor does not affect compatibility or power, because it has its own power supply. |
| Ubuntu 26.04 LTS (web developer) | no OS on the list | Ubuntu is free and is not sold as a product. |
| UPS, backup drive, webcam, headset, keyboard and mouse | not on the lists | External USB devices. They do not affect compatibility or the PSU. |

## Parts on each list

**Accountant ([ZXff2k](https://pcpartpicker.com/list/ZXff2k)):** AMD Ryzen 7 5700G · ID-COOLING SE-214-XT · Gigabyte B550M AORUS ELITE · ADATA XPG SPECTRIX D35G 16 GB (2×8 GB) DDR4-3200 CL16 · Kingston NV3 1 TB · Montech X3 Mesh · Montech GAMMA II 650 W · Windows 11 Pro Retail USB

**Sales manager ([nCwXh9](https://pcpartpicker.com/list/nCwXh9)):** same as the accountant, but memory is G.Skill Aegis 32 GB (2×16 GB) DDR4-3200 CL16

**Web developer ([4mLByF](https://pcpartpicker.com/list/4mLByF)):** same as sales, without Windows (Ubuntu)

**Designer ([WR4v2k](https://pcpartpicker.com/list/WR4v2k)):** AMD Ryzen 7 5700X · ID-COOLING SE-214-XT · Gigabyte B550M AORUS ELITE · G.Skill Aegis 32 GB (2×16 GB) DDR4-3200 CL16 · Kingston NV3 1 TB · MSI VENTUS 2X OC GeForce RTX 5060 8 GB · Montech X3 Mesh · Montech GAMMA II 650 W · Windows 11 Pro Retail USB · Asus ProArt PA278QV
