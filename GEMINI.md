# Antigravity Workspace Configuration & Rules

## Project: YoRHa Rainmeter Telemetry Skins
- **Target Platform**: Rainmeter (Windows)
- **Shell**: PowerShell 7 (`pwsh`)
- **Aesthetic**: NieR:Automata UI (tactical military HUD, warm muted sand-beige, dark charcoal `#2B2924`, amber accents `#E5A93C`)

## File Handling & Encoding Rules
1. **Rainmeter Encodings**: Rainmeter natively supports UTF-16 LE and UTF-8 with BOM. When creating or writing skin `.ini` and `@Resources\Variables-*.inc` files, ensure they are formatted cleanly so Rainmeter parses all special characters (e.g., `°C`, `//`, box-drawing lines) accurately.
2. **Direct File Tools**: Prefer `write_to_file` and `replace_file_content` for editing workspace assets directly.

## Terminal & Execution Guidelines
1. **PowerShell 7 Execution**: Standard commands run natively through `pwsh` within the workspace.
2. **Safe Workspace Operations**: Keep all commands non-destructive, scoped within the project directory, and focused on asset generation, verification, and Rainmeter refresh commands.
