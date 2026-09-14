# Typography & Fonts Guide

Due to copyright and licensing policies, proprietary font binaries are not bundled directly in this repository.

## Typography Roles & Aliases

The skin suite is configured to use the following font variables and community aliases:

1. **Headers & Tactical Labels** (`#FontHeader#`, `#FontMain#`, `#FontTactical#`): `YorHa Gothic` (`YorHa-Gothic.otf`)
2. **Calendar Grids & Secondary Text** (`#FontSub#`): `YorHa Mincho` (`YorHa-Mincho.otf`)
3. **Clock & Calendar Serif Numerals** (`#FontClockNum#`): `YorHa Serif` (`YorHa-Serif.ttf`)
4. **Futuristic Tactical Display Numerals** (`#FontAnime#`): `YorHa Display` (`YorHa-Display.ttf`)
5. **Chinese Lunar Calendar & Solar Terms** (`#FontLunar#`): `Noto Sans SC`

*(Place your font files in this `@Resources/Fonts` directory, or install them system-wide in Windows).*

---

## Free Open-Source Drop-in Alternatives

You can also use 100% free and open-source Google Fonts (SIL Open Font License) as drop-in replacements:

| Variable | Role | Community Alias | Recommended Open-Source Alternative | License |
| :--- | :--- | :--- | :--- | :--- |
| `#FontHeader#`<br>`#FontMain#`<br>`#FontTactical#` | Headers, labels, telemetry readouts & temperatures | `YorHa Gothic` | **[Zen Kaku Gothic New](https://fonts.google.com/specimen/Zen+Kaku+Gothic+New)** or **[Noto Sans JP](https://fonts.google.com/specimen/Noto+Sans+JP)** | SIL OFL |
| `#FontSub#` | Gregorian calendar day labels & secondary readouts | `YorHa Mincho` | **[Zen Antique Soft](https://fonts.google.com/specimen/Zen+Antique+Soft)** or **[M PLUS 1p](https://fonts.google.com/specimen/M+PLUS+1p)** | SIL OFL |
| `#FontClockNum#` | Large stylized clock & calendar serif numerals | `YorHa Serif` | **[Cinzel](https://fonts.google.com/specimen/Cinzel)** or **[Grenze](https://fonts.google.com/specimen/Grenze)** | SIL OFL |
| `#FontAnime#` | Futuristic tactical display numerals (calendar ISO weeks, network indices) | `YorHa Display` | **[Orbitron](https://fonts.google.com/specimen/Orbitron)** or **[Michroma](https://fonts.google.com/specimen/Michroma)** | SIL OFL |
| `#FontLunar#` | Chinese Lunar matrix, GanZhi cycle & 24 Solar Terms | **[Noto Sans SC](https://fonts.google.com/specimen/Noto+Sans+SC)** | **[Noto Sans SC](https://fonts.google.com/specimen/Noto+Sans+SC)** | SIL OFL |

### Configuring Fonts

To switch or customize fonts, edit `@Resources/Variables-Light.inc` or `@Resources/Variables-Dark.inc`:

```ini
FontMain=Zen Kaku Gothic New
FontHeader=Zen Kaku Gothic New
FontClockNum=Cinzel
FontSub=Zen Antique Soft
FontAnime=Orbitron
FontLunar=Noto Sans SC
```