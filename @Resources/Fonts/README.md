# Typography & Fonts Guide

Due to copyright and licensing policies, font binaries are not bundled directly in this repository.

## Community Typography Aliases

The skin is configured to use the following community font aliases:

1. **Headers & Tactical Labels**: `YorHa Gothic` (`YorHa-Gothic.otf`)
2. **Calendar Grids & Secondary Text**: `YorHa Mincho` (`YorHa-Mincho.otf`)
3. **Clock & Calendar Serif Numerals**: `YorHa Serif` (`YorHa-Serif.ttf`)

*(Place your font files in this `@Resources/Fonts` directory, or install them system-wide in Windows).*

---

## Free Open-Source Drop-in Alternatives

You can also use 100% free and open-source Google Fonts (SIL Open Font License) as drop-in replacements:

| Role | Community Font Name | Recommended Open-Source Alternative | License |
| :--- | :--- | :--- | :--- |
| **Headers & Tactical** | `YorHa Gothic` | **[Zen Kaku Gothic New](https://fonts.google.com/specimen/Zen+Kaku+Gothic+New)** or **[Noto Sans JP](https://fonts.google.com/specimen/Noto+Sans+JP)** | SIL OFL |
| **Secondary / Calendar** | `YorHa Mincho` | **[Zen Antique Soft](https://fonts.google.com/specimen/Zen+Antique+Soft)** or **[M PLUS 1p](https://fonts.google.com/specimen/M+PLUS+1p)** | SIL OFL |
| **Numerals / Serifs** | `YorHa Serif` | **[Cinzel](https://fonts.google.com/specimen/Cinzel)** or **[Grenze](https://fonts.google.com/specimen/Grenze)** | SIL OFL |

### Configuring Fonts

To switch or customize fonts, edit `@Resources/Variables-Light.inc` or `Variables-Dark.inc`:

```ini
FontHeader=Zen Kaku Gothic New
FontClockNum=Cinzel
```