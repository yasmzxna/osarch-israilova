# evidence/ — what each file proves

All evidence was collected on **2026-11-23**. Text is used wherever the source allows it. Screenshots are used only for vendor price pages, where the brief requires the address bar and the date to be visible.

## Compatibility and power (text)

| File | What it proves |
|---|---|
| [pcpartpicker-links.md](pcpartpicker-links.md) | The four PCPartPicker links in one table, with compatibility, estimated wattage vs PSU, the BIOS note and how it is handled, and every place where a list differs from budget.csv (with the reason). |
| [pcpartpicker/accountant.txt](pcpartpicker/accountant.txt) | Accountant build: every part fits (AM4 socket, DDR4 in RAM_1/2, NVMe in M2_1, ATX PSU in the case). Estimated draw is 159 W against 650 W. RAM_3/4, M2_2 and the x16 slot are free. |
| [pcpartpicker/sales.txt](pcpartpicker/sales.txt) | Sales build: the same platform with 32 GB fits. Estimated draw is 174 W against 650 W. 2 memory slots are still free. |
| [pcpartpicker/webdev.txt](pcpartpicker/webdev.txt) | Web developer build: fits, 174 W. RAM_3/4 are free, which is what makes the planned 32 → 64 GB upgrade (README, question 1) possible without replacing memory. |
| [pcpartpicker/designer.txt](pcpartpicker/designer.txt) | Designer build: the RTX 5060 fits the x16 slot and takes one PCIe 8-pin of the PSU. Estimated draw is 319 W, 49% of the 650 W PSU. |

## Prices (screenshots)

| File | What it proves |
|---|---|
| [vendor-quotes/README.md](vendor-quotes/README.md) | Index of all 29 screenshots: each file → product → price → budget.csv rows → URL. |
| `vendor-quotes/accountant-*.png`, `sales-*.png`, `webdev-*.png`, `designer-*.png`, `shared-*.png` (21 files) | Each one shows that the price in budget.csv for that part is the price on **dns-shop.kz** (a Kazakhstan shop with delivery in Kazakhstan) on **23.11.2026**: the address bar shows the product URL, the price block shows the tenge price and stock, and the taskbar clock shows the date. |
| `vendor-quotes/prebuilt-*.png` (3 files) | The pre-built PC prices used in README question 2 (DEXP O373, ASUS TUF T500MV, ARDOR NEO M307), same shop, same date. |
| `vendor-quotes/alt-*.png` (5 files) | The prices behind the "alternative not taken" figures and the AM4-vs-AM5 decision in builds.md. Example: DDR5 32 GB at 314,990 ₸ against DDR4 32 GB at 132,490 ₸. |

## Budget check (text)

| File | What it proves |
|---|---|
| [budget-check.txt](budget-check.txt) | The totals in budget.csv are computed, not typed by hand. The file holds the PowerShell command that sums `price_kzt` per role (TOTAL rows excluded) and its output: each role total matches its TOTAL row, and the grand total 2,986,290 ₸ is ≤ 3,000,000 ₸. |
