# Ticket 2 — four builds, each from its load

All prices are from **DNS (dns-shop.kz)**, taken on **2026-11-23**. DNS has its own shops and delivery inside Kazakhstan, so every price comes from a vendor that ships here. Row numbers refer to lines of [budget.csv](budget.csv) (line 1 is the header).

## The decision that shaped all four builds: AM4 + DDR4, not AM5 + DDR5

Memory is the most expensive part of an office PC in November 2026. Same shop, same day:

| | DDR4-3200 | DDR5-5600 | Difference |
|---|---|---|---|
| 32 GB (2×16) | 132,490 ₸ (G.Skill Aegis) | 314,990 ₸ (Kingston FURY Beast) | DDR5 costs **2.4×** as much |
| 16 GB | 60,070 ₸ (2×8, ADATA XPG) | 148,190 ₸ (1×16, Kingston FURY Beast) | 2.5× |

I first priced the same four roles on AM5 (Ryzen 5 8600G or Ryzen 7 7700, B650M board, DDR5). The total came to about **3,904,850 ₸**, which is 905,000 ₸ over budget. Even before monitors, memory alone would have eaten almost half the money. So all four machines use the **AM4 socket with DDR4**: one board model (GIGABYTE B550M AORUS ELITE) and different CPU, memory, GPU and screen per role.

**What "lasts a few years" means on this platform.** I assumed 5 years. AM4 gets no new CPUs, so the CPU ceiling is reached on day one. Each machine still has headroom where these loads actually grow:
- **4 DIMM slots and up to 128 GB.** Every build leaves 2 slots free, so memory can be added without throwing any away.
- **A second free M.2 slot** for more storage.
- **A PCIe x16 slot and a 650 W PSU**, so any of the office machines can take a graphics card later.

Trade-off: if a role outgrows an 8-core Ryzen 5000 within 5 years, the board must be replaced with the CPU. For these four loads I don't expect that. The bottlenecks below are memory, screen and GPU, not CPU.

Shared parts in every build: Kingston NV3 1 TB NVMe, MONTECH X3 MESH case, Logitech MK295 keyboard and mouse. The OEM CPUs ship without a cooler, so each gets an ID-COOLING SE-214-XT. Compatibility (socket AM4 ↔ B550, DDR4 ↔ board, M.2 NVMe ↔ M.2 slot, power) was checked on PCPartPicker: [evidence/pcpartpicker-links.md](evidence/pcpartpicker-links.md).

---

### Build 1 — accountant

**Load:** 1C:Enterprise (Kazakhstan configuration), Excel, a bank client and the tax portal in a browser (about 10 tabs), and NCALayer for the digital signature. 8 hours a day, every day. This is roughly 8–10 GB of memory and very little CPU.

**Bottleneck:** not the CPU or memory. The two real limits are:
1. **The screen.** A ledger next to a bank statement next to Excel does not fit on a 24-inch 1080p display.
2. **Data safety.** A power cut while 1C is posting documents can damage the infobase, and the accounting data exists only on this machine.

**Trade-off:** minimum memory (16 GB DDR4 as 2×8, dual channel for the integrated graphics, 2 slots free). The money went into the screen (a 27-inch 2560×1440 IPS shows about 78% more pixels than 1920×1080), a UPS so 1C can close cleanly, and a 2 TB external drive for backups. Windows 11 Pro is required, because 1C and NCALayer are Windows software and Pro adds BitLocker for the financial data. The 8-core 5700G is more CPU than this role needs. The cheaper 6-core 5600G (60,850 ₸ OEM) was out of stock at DNS today.

**Alternative not taken:** two 24-inch monitors (2 × Xiaomi A24i = 91,780 ₸, +4,490 ₸ over the single 27-inch). Rejected because one larger screen does the same job with one cable and one stand. Two outputs would also need checking on the board.

**Total:** 676,720 ₸ (budget.csv, rows 2–14)

---

### Build 2 — sales manager

**Load:** CRM in a browser with 30–40 tabs, Excel, and about 4 hours of video calls a day, often all at once.

**Bottleneck:** memory, not CPU. Chrome with forty tabs plus a video call uses about 11–12 GB. On 16 GB that leaves almost nothing for Windows and Excel, and the machine starts paging in the middle of a customer call (the same effect I saw in Lab 2 when the host ran out of RAM). The request also forgot the call equipment: a monitor has no camera and no microphone.

**Trade-off:** 32 GB on DDR4 (132,490 ₸) instead of DDR5 (314,990 ₸). This saves 182,500 ₸ and loses nothing this role would notice. A webcam and a USB headset (27,150 ₸ together) are included because 4 hours of calls a day on built-in nothing is not a working setup. The screen is a plain 24-inch 1080p IPS, because a CRM and a call window do not need more.

**Alternative not taken:** 16 GB (ADATA 2×8, 60,070 ₸). It would save 72,420 ₸, but it is exactly the case where the bottleneck shows up daily.

**Total:** 656,300 ₸ (budget.csv, rows 15–27)

---

### Build 3 — web developer

**Load:** VS Code, Docker running the project stack (app + PostgreSQL + Redis, several containers), 2–3 browsers open for testing, Node/npm builds, sometimes a VM. Typical working set is about 16–20 GB, with peaks above 24 GB when a VM or a second project stack runs.

**Bottleneck:** memory first, then CPU during builds. Containers and browsers run out of RAM long before 8 cores run out of work.

**Trade-off:**
- 8 cores and 32 GB DDR4 now, with 2 DIMM slots left free for 64 GB later. 64 GB today would push the total 118,780 ₸ over budget.
- **Ubuntu 26.04 LTS instead of Windows (saves 118,650 ₸).** Ubuntu is free for commercial use (GPL software, Canonical's licence policy allows it in a business), so it is licensed. It is also more suitable here: Docker runs natively with no WSL2 virtual machine eating memory, and it is the same OS family as the servers the code is deployed to.

**Alternative not taken:**
- 64 GB now (a second G.Skill Aegis kit, +132,490 ₸). Over budget, so it is deferred.
- Windows 11 Pro (+118,650 ₸), in case the developer needs Windows-only tools. That is a question for Daniyar (see README section 2).

**Total:** 551,900 ₸ (budget.csv, rows 28–38)

---

### Build 4 — designer

**Load:** Photoshop and Illustrator with large multi-layer files (1–4 GB each), Figma in a browser, and sometimes short promo videos. Work is judged by colour: what is on screen has to match what gets printed or published.

**Bottleneck:**
1. **The screen first.** An uncalibrated office monitor shows wrong colours, and every wrong print costs money and a day.
2. **Memory second.** Photoshop wants several times the file size in RAM.
3. **The GPU third.** It handles GPU-accelerated filters, smooth canvas zoom and hardware video encoding.

**Trade-off:**
- The biggest single item is the screen: ASUS ProArt PA278QV, 100% sRGB, factory calibrated (247,850 ₸).
- A real GPU, RTX 5060 8 GB (289,990 ₸). The Ryzen 7 5700X has no integrated graphics, so a card is required anyway.
- The platform is AM4/DDR4 instead of AM5/DDR5: Ryzen 7 5700X + B550M + 32 GB DDR4 = 280,470 ₸, against Ryzen 7 7700 + B650M + 32 GB DDR5 = 609,470 ₸. That is 329,000 ₸ saved. The cost is no CPU upgrade path and the card runs at PCIe 4.0 instead of 5.0, which matters little for an 8-lane card.
- 32 GB, not 64 GB, and a 1 TB SSD, not 2 TB.
- The PSU is a Gold 650 W unit. This is the only machine with a real power draw: CPU about 76 W plus GPU about 145 W plus the rest is about 270 W. PCPartPicker estimates 319 W, which is still under half of 650 W.

**Alternative not taken:**
- No graphics card and a Ryzen 7 5700G instead (saves about 260,000 ₸). Rejected because the integrated Vega graphics would make video work painful.
- A cheaper 27-inch IPS (Xiaomi A27Qi, saves 160,560 ₸). Rejected because colour accuracy is the job.

**Total:** 1,101,370 ₸ (budget.csv, rows 39–50)

---

## Budget

| Role | Total, ₸ | Rows |
|---|---|---|
| Accountant | 676,720 | 2–14 |
| Sales manager | 656,300 | 15–27 |
| Web developer | 551,900 | 28–38 |
| Designer | 1,101,370 | 39–50 |
| **All four, incl. monitors and OS** | **2,986,290** | 51 |
| Budget | 3,000,000 | 52 |
| Reserve | 13,710 | 53 |

The reserve is only 13,710 ₸ (0.5%). Memory and SSD prices move noticeably within a month, so the order should be placed within days of these prices. If memory rises, the first thing I would drop is the accountant's 2 TB backup drive (58,260 ₸), and I would back up to a cloud folder instead.
