# Ticket 2 — Kitting out the new office

## 1. What was asked

> From: Daniyar K. (Director)
> Subject: computers for the new office
>
> We are opening the second office and need four computers — accountant,
> sales, web developer, designer. Budget 3,000,000 tenge for everything.
> Everyone says we should just buy the same four machines, is that right?
> Make sure they last a few years. Monitors included.

## 2. What was actually needed

**No — four identical machines is the wrong answer.** The four people put four different loads on a computer, and each load runs out of a different resource first:

| Role | What runs out first |
|---|---|
| Accountant | screen area and data safety |
| Sales manager | memory |
| Web developer | memory, then CPU |
| Designer | a colour-accurate screen, then memory and GPU |

An identical machine has to be built for the hardest of the four or the cheapest of the four, and both fail:
- **Four copies of the designer's machine cost 4,405,480 ₸.** That is 1.4 million over budget, and the accountant would get a 290,000 ₸ graphics card that 1C never uses.
- **Four copies of the accountant's machine cost 2,706,880 ₸.** That fits, but the designer would get no graphics card and an uncalibrated screen, the developer would get 16 GB, and the sales manager would get no camera or headset.

Different machines also mean money goes where it is needed. The same 3,000,000 ₸ buys a calibrated monitor and an RTX 5060 for the designer and 32 GB for sales and the developer, because the accountant does not get them.

What *should* be identical: one motherboard model, one case, one SSD and one keyboard across all four. That makes spare parts and drivers simple. The configuration changes per role; the platform does not.

**What the request left out, and what I assumed instead:**

| Gap | What I would ask Daniyar | What I assumed |
|---|---|---|
| Operating systems | "Is there already a Microsoft licence agreement for the company?" | None. Retail Windows 11 Pro (118,650 ₸) priced per machine, Ubuntu for the developer. The OS is ~12% of the whole budget, so it cannot be "forgotten". |
| Keyboards, mice | "Are you reusing anything from the first office?" | Nothing is reused. A wireless keyboard + mouse set is priced for each machine. |
| Webcam and headset | "Does sales take calls from the desk?" | Yes, 4 hours a day. A monitor has no camera or microphone, so the sales build includes both. |
| Power cuts and backups | "Who keeps the accounting data, and is there a backup today?" | Nobody. The accountant's machine gets a UPS and a 2 TB backup drive. Losing a year of 1C data costs more than the whole PC. |
| Which software | "Does anyone need specific programs: 1C, Adobe, Windows-only tools?" | Accountant: 1C + NCALayer, so Windows. Designer: Adobe, so Windows. Developer: web stack + Docker, so Ubuntu, but this must be confirmed. If the developer needs Windows, it adds 118,650 ₸ and something else must give. |
| Software licences | "Are 1C, MS Office, Adobe CC paid separately?" | Yes, from a different budget. They are subscriptions, not hardware. |
| "Last a few years" | "How many years — 3? 5?" | 5 years, which led to the platform decision below. |
| Network | "Is the new office wired? Is there a router and switch?" | Yes, wired LAN exists. The boards have Gigabit Ethernet; no Wi-Fi cards, switch or cables are priced. |
| Delivery and assembly | "Do you want them assembled by the shop?" | I assemble them myself; no assembly fee is priced. |

**What makes this budget hard is the date, not the number of machines.** In November 2026, DDR5 memory costs about 2.4 times as much as DDR4 at the same shop on the same day (32 GB: 314,990 ₸ vs 132,490 ₸). The same four roles on the newest platform (AM5 + DDR5) come to about 3.9 million tenge. So "last a few years" cannot mean "the newest socket". Here it means the older AM4 platform with DDR4 and with room left in every machine: 2 free memory slots, a free M.2 slot, and a PCIe slot with a 650 W power supply. The price of that choice is that the CPU cannot be upgraded later. The full argument is at the top of [builds.md](builds.md).

## 3. What I did

1. **Roles → loads.** For each person I wrote down what they run, for how long, and how much at once. Then I named the resource that runs out first. That became the Load / Bottleneck / Trade-off lines in [builds.md](builds.md).
2. **Loads → parts.** I put the money into each bottleneck: screen + UPS + backup for the accountant, memory + camera/headset for sales, memory + 8 cores for the developer, calibrated monitor + GPU for the designer. I cut where the load does not reach: the CPU for three of the four, and Windows for the developer.
3. **Platform.** I priced the AM5/DDR5 version first. It was ~905,000 ₸ over budget, so I moved everything to AM4/DDR4 and kept the upgrade headroom described above.
4. **Prices.** Every part comes from **DNS (dns-shop.kz)**, which has shops and delivery in Kazakhstan. I checked each one on 2026-11-23, and every part was in stock or orderable that day. All prices, links and dates are in [budget.csv](budget.csv), and a screenshot of each page is in `evidence/vendor-quotes/`.
5. **Compatibility and power.** I entered each build in PCPartPicker to check socket ↔ board, DDR4 ↔ board, M.2 NVMe ↔ M.2 slot, and power ↔ PSU: [evidence/pcpartpicker-links.md](evidence/pcpartpicker-links.md). PCPartPicker does not price in tenge, so it was used for compatibility only. All four lists come out compatible. Estimated draw is 159–319 W against 650 W PSUs. The only warning is a BIOS version note: the board needs BIOS F13+ for the 5700G and F14+ for the 5700X, so the shop flashes it, or I use Q-Flash Plus.

| Role | CPU | Memory | GPU | Screen | Extra | OS | Total, ₸ |
|---|---|---|---|---|---|---|---|
| Accountant | Ryzen 7 5700G | 16 GB DDR4 | integrated | 27" 1440p IPS | UPS, 2 TB backup drive | Windows 11 Pro | 676,720 |
| Sales manager | Ryzen 7 5700G | 32 GB DDR4 | integrated | 24" 1080p IPS | webcam, headset | Windows 11 Pro | 656,300 |
| Web developer | Ryzen 7 5700G | 32 GB DDR4 (2 slots free) | integrated | 27" 1440p IPS | — | Ubuntu 26.04 LTS | 551,900 |
| Designer | Ryzen 7 5700X | 32 GB DDR4 | RTX 5060 8 GB | 27" ProArt, 100% sRGB, calibrated | Gold PSU | Windows 11 Pro | 1,101,370 |
| **Total** | | | | | | | **2,986,290** (budget 3,000,000; reserve 13,710) |

All four machines share: GIGABYTE B550M AORUS ELITE board, Kingston NV3 1 TB NVMe, MONTECH X3 MESH case, a 650 W PSU, and a Logitech MK295 keyboard and mouse. Every machine meets the hard requirements: ≥16 GB memory, a 1 TB SSD, a licensed OS and its own monitor.

### Pre-built prices for comparison (DNS, 2026-11-23)

The pre-built PC that matched each role most closely on DNS on the same day. Prices are for the system unit only; monitors and peripherals are the same either way.

| Role | Pre-built | Price, ₸ | Fix needed to meet the brief | Pre-built total, ₸ | My build (system unit, OS incl.), ₸ |
|---|---|---|---|---|---|
| Accountant | [DEXP Aquilon O373](https://www.dns-shop.kz/product/2ca1bf2bda2ad9cb/pk-dexp-aquilon-o373/) — i5-12400, 16 GB DDR4, 512 GB SSD, Windows 11 Pro | 301,990 | 512 GB fails "1 TB SSD": + Kingston NV3 1 TB (82,690) | 384,680 | 490,990 |
| Sales manager | same DEXP Aquilon O373 | 301,990 | + 1 TB SSD (82,690); has 16 GB, not the 32 GB this role needs | 384,680 (16 GB) | 563,410 |
| Web developer | [ASUS TUF Gaming T500MV](https://www.dns-shop.kz/product/6f60be4b00fad9cb/pk-asus-tuf-gaming-t500mv-05210h0680-90pf05h2-m02cc0/) — Core 5 210H, 32 GB DDR5, RTX 5060, 1 TB, no OS | 703,990 | none (Ubuntu on it), but pays for a gaming GPU the role does not use | 703,990 | 444,760 |
| Designer | [ARDOR GAMING NEO M307](https://www.dns-shop.kz/product/1ff07db854b8d582/pk-ardor-gaming-neo-m307/) — Ryzen 5 7500F, 32 GB DDR5, RTX 5060, 1 TB, no OS | 810,690 | + Windows 11 Pro (118,650) | 929,340 | 833,670 |
| **All four** | | | | **2,402,690** | **2,332,830** |

My build totals come from budget.csv: accountant rows 2–9, sales rows 15–22, developer rows 28–35, designer rows 39–47.

### The director's three questions

**1. Which machine will you upgrade first, eighteen months from now, and why?**
The **web developer's memory**, from 32 GB to 64 GB, by adding a second 2×16 GB DDR4 kit into the two free slots (132,490 ₸ at today's price). Memory is this role's bottleneck, and the load only grows: every new project brings another `docker compose` stack and another database, and none of them get smaller. The board was chosen with 4 slots so this costs a kit, not a rebuild. Second in line is the designer's storage: 1 TB fills up with project archives and video, and the free M.2 slot takes a second NVMe drive.

**2. Price the same four as pre-built machines. What does the company gain and what does it lose by not building them?**
The table above shows the honest result: **it depends on the role.**
- *Office roles (accountant, sales).* The pre-built DEXP is about 106,000 ₸ cheaper even after adding the 1 TB SSD the brief requires. Most of the difference is Windows: the pre-built comes with an OEM licence, while I priced the retail box at 118,650 ₸.
- *Developer and designer.* Building is cheaper (by 259,230 ₸ and 95,670 ₸). The pre-builts also put money in the wrong place: a gaming GPU for the developer, a 6-core CPU on a basic A620 board for the designer.

What the company **gains** with pre-built:
- One warranty per box from one shop, and if it fails you return the whole PC instead of diagnosing which part died.
- The machines arrive assembled and tested, which saves a day of my time.
- Windows is already activated.

What it **loses**:
- Choice of parts. I cannot put the money into the bottleneck: no calibrated screen budget, no 32 GB on the office machines, no 4-slot board.
- The upgrade path. Unknown slot count and a 350 W PSU on the DEXP; "16 GB → 64 GB later" is not guaranteed.
- Knowing exactly what is inside, which matters for spares across four machines.

**3. One of these four people will complain about performance within a month. Which one, and about what?**
**The web developer, about memory.** Specifically: the moment the developer runs the full project stack in Docker, plus two browsers for testing, plus a VM or Android emulator, 32 GB is used up. Ubuntu starts swapping, `npm run build` takes twice as long, and the browser tabs reload. This is my own trade-off hurting: 64 GB was the right size for this load, and I deferred it to stay in budget. When the complaint comes, I would not wait 18 months; the second memory kit is the first purchase from the next budget.

## 4. Evidence

| File | What it proves |
|---|---|
| [budget.csv](budget.csv) | Every part: role, model, price in tenge, vendor link, date the price was taken (2026-11-23). Per-role totals and the grand total ≤ 3,000,000 ₸. |
| [builds.md](builds.md) | Load → bottleneck → trade-off → alternative not taken, for each of the four machines. |
| [evidence/README.md](evidence/README.md) | Index of the evidence folder: one line per file saying what it proves. |
| [evidence/pcpartpicker-links.md](evidence/pcpartpicker-links.md) | One PCPartPicker list per build: the parts are compatible (socket, memory type, M.2, power). It also explains the BIOS note and every substitution. PCPartPicker was not used for prices. |
| [evidence/budget-check.txt](evidence/budget-check.txt) | The PowerShell command that sums budget.csv, and its output: each role total matches its TOTAL row, the grand total is 2,986,290 ≤ 3,000,000 ₸, and no row is missing a date. |
| [evidence/pcpartpicker/](evidence/pcpartpicker/) | Each PCPartPicker list as text: parts, estimated wattage, warnings, which slots are used and which are free. |
| [evidence/vendor-quotes/](evidence/vendor-quotes/) | A screenshot of each DNS product page used in budget.csv, with the address bar and the date visible, named after the part (`shared-cpu-5700g.png`, `designer-monitor.png`, …). The list of files is in [evidence/vendor-quotes/README.md](evidence/vendor-quotes/README.md). |
## 5. What I would do differently

1. **I would price the pre-built office PCs before designing the office builds, not after.** I found too late that a DEXP pre-built with an OEM Windows licence is about 106,000 ₸ cheaper per office machine than my build with a retail Windows box. Buying the accountant's and sales manager's machines pre-built (plus a 1 TB SSD each, plus a 16 GB DDR4 stick for sales, if the DEXP board has a free slot) would have freed roughly 225,000 ₸. That is enough to give the developer 64 GB on day one, which would remove the complaint I predicted in question 3.
2. **I would ask Daniyar about existing licences first.** At 118,650 ₸ each, Windows is the second most expensive "part" in three of the four machines. A company volume licence or OEM keys would change the budget more than any hardware choice.
