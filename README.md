# YoRHa Rainmeter Telemetry Suite

A *NieR:Automata* YoRHa-themed telemetry and system monitoring skin suite for [Rainmeter](https://www.rainmeter.net/).

![YoRHa 1440p Desktop Setup](1440p-desktop.png)

<p align="center">
  <img src="preview.png" alt="YoRHa Suite Stack Preview" width="420" />
</p>

## Features

- **Full Telemetry Suite**:
  - **Clock HUD**: Digital military clock with date display and YoRHa interface accents.
  - **Weather HUD**: 24-hour meteorological chrono-telemetry array with wind symbols, conditions, and temperature trends (click Clock to toggle).
  - **Calendar**: Tactical monthly calendar with Lua-powered grid calculations and ISO week numbers.
  - **Lunar & Solar Terms HUD**: Traditional Chinese Lunar Calendar (农历) with 24 Solar Terms (二十四节气), Heavenly Stems & Earthly Branches (干支纪年), and moon phase illumination (click Calendar to toggle).
  - **CPU**: Multi-core load matrix, frequency metrics, load graphs, and temperature monitoring.
  - **GPU**: Core load, VRAM utilization, clock speeds, and thermal tracking.
  - **RAM**: Memory usage statistics and active swap/pagefile telemetry.
  - **Disks**: Multi-drive (SSD/NVMe/HDD) real-time read/write throughput rates, logarithmic I/O pie meters, and thermal gauges.
  - **Fans**: Real-time RPM tachometer gauges and cooling duty cycles.
  - **Network**: Real-time up/down bandwidth throughput gauges and IP status.
- **Dual Visual Themes**:
  - **Light Theme**: Authentic NieR:Automata sand-paper matte styling, smoky glass textures, dark tape banners, and horizon guideline accents.
  - **Dark Theme**: High-contrast tactical night HUD with translucent panels and muted bronze/gold tones.
- **Modular Widgets**: Each widget is self-contained with independent `*-Dark.ini` and `*-Light.ini` variants, allowing you to run a unified theme or mix-and-match modules across your desktop.

---

## Module Showcase

### Clock & Weather HUD
*Click anywhere on the widget or top badge to toggle between Clock and Weather modes.*

| System Clock | Weather Telemetry HUD |
| :---: | :---: |
| ![Clock](Clock/clock.png) | ![Weather](Clock/weather.png) |
| *Digital military clock with date & tactical accents* | *24-hour meteorological chrono-telemetry HUD* |

### Tactical Calendar & Lunar HUD
*Click anywhere on the widget to toggle between Gregorian matrix and Chinese Lunar / 24 Solar Terms views.*

| Gregorian Calendar | Chinese Lunar & 24 Solar Terms |
| :---: | :---: |
| ![Gregorian Calendar](Calendar/greogori.png) | ![Lunar Calendar](Calendar/lunar.png) |
| *Monthly calendar grid with ISO week numbers* | *Chinese Lunar calendar, 24 Solar Terms & moon phase* |

### Processor Telemetry

| CPU Telemetry | GPU Telemetry |
| :---: | :---: |
| ![CPU](CPU/cpu.png) | ![GPU](GPU/gpu.png) |
| *Multi-core load graphs, frequencies & thermals* | *Core load, VRAM utilization, clocks & thermals* |

### Memory & Storage

| RAM / Memory | Disks I/O & Thermals |
| :---: | :---: |
| ![RAM](RAM/memory.png) | ![Disks](Disks/disks.png) |
| *Physical RAM allocation & active swap metrics* | *Logarithmic I/O pie dials, throughput & thermals* |

### Cooling & Network

| Fans & Cooling | Network I/O |
| :---: | :---: |
| ![Fans](Fans/fans.png) | ![Network](Network/network.png) |
| *Real-time RPM tachometers & duty cycles* | *Real-time up/down bandwidth gauges & traffic* |

---

## Requirements & Fonts

The skin suite uses a defined typography hierarchy configured in `@Resources/Variables-Dark.inc` and `@Resources/Variables-Light.inc`. All typography relies on free, open-source fonts or community aliases:

### Open-Source Fonts & Community Aliases

| Variable | Role | Default / Alias | Recommended Open-Source Alternative | License |
| :--- | :--- | :--- | :--- | :--- |
| `#FontHeader#`<br>`#FontMain#`<br>`#FontTactical#` | Headers, labels, telemetry readouts & temperatures | `YorHa Gothic` | **[Zen Kaku Gothic New](https://fonts.google.com/specimen/Zen+Kaku+Gothic+New)** or **[Noto Sans JP](https://fonts.google.com/specimen/Noto+Sans+JP)** | SIL OFL |
| `#FontSub#` | Gregorian calendar day labels & secondary readouts | `YorHa Mincho` | **[Zen Antique Soft](https://fonts.google.com/specimen/Zen+Antique+Soft)** or **[M PLUS 1p](https://fonts.google.com/specimen/M+PLUS+1p)** | SIL OFL |
| `#FontClockNum#` | Large stylized clock & calendar serif numerals | `YorHa Serif` | **[Cinzel](https://fonts.google.com/specimen/Cinzel)** or **[Grenze](https://fonts.google.com/specimen/Grenze)** | SIL OFL |
| `#FontAnime#` | Futuristic tactical display numerals (calendar ISO weeks, network indices) | `YorHa Display` | **[Orbitron](https://fonts.google.com/specimen/Orbitron)** or **[Michroma](https://fonts.google.com/specimen/Michroma)** | SIL OFL |
| `#FontLunar#` | Chinese Lunar matrix, GanZhi cycle & 24 Solar Terms | **[Noto Sans SC](https://fonts.google.com/specimen/Noto+Sans+SC)** | **[Noto Sans SC](https://fonts.google.com/specimen/Noto+Sans+SC)** | SIL OFL |

*(Font files can be placed directly in `@Resources/Fonts` or installed system-wide in Windows. Free Google Fonts can be downloaded directly from the links above under the SIL Open Font License).*

### Configuring Fonts

To switch font families, edit `@Resources/Variables-Light.inc` and `@Resources/Variables-Dark.inc`:

```ini
FontMain=Zen Kaku Gothic New
FontHeader=Zen Kaku Gothic New
FontClockNum=Cinzel
FontSub=Zen Antique Soft
FontAnime=Orbitron
FontLunar=Noto Sans SC
```

---

## Quick Start & Usage

1. Clone or extract this repository into your Rainmeter skins directory:
   ```powershell
   git clone https://github.com/naimen/rainmeter-yorha-telemetry.git "Documents\Rainmeter\Skins\YorHa"
   ```
2. Ensure the required fonts are installed in Windows (or placed in `@Resources\Fonts`).
3. **Hardware Telemetry Server**: Run **[LibreHardwareMonitor](https://github.com/LibreHardwareMonitor/LibreHardwareMonitor)** with its built-in web server enabled on port `8085` (default: `http://localhost:8085/data.json`) for CPU, GPU, Disk temperatures, and Fan telemetry.
4. Open Rainmeter, refresh skins, and load your preferred theme variant for each module (`CPU\CPU-Dark.ini`, `Clock\Clock-Dark.ini`, `Disks\Disks-Dark.ini`, etc., or the `-Light.ini` counterparts).

## Author

- **naimen** ([@naimen](https://github.com/naimen))