# Changelog

## [1.1.0] - 2025-02-21

### Added
- **`SECURITY.md`**: Granite Core security model with threat model, architecture design, and sandbox roadmap covering Electron hardening, filesystem isolation, spawn policy, execution modes, and secrets handling.
- **Roadmap in README**: Actionable TODO checklist with 15 items across 3 areas (sandbox model, sensitive data encapsulation, execution modes & auditability), plus a PR plan mapping each area to a focused, independently-mergeable pull request.

## [1.0.0] - 2025-02-21

First release of the Windows-friendly fork. Codex runs natively on Windows without manual workarounds.

### Fixed
- **Codex CLI resolution on Windows**: The script no longer requires `codex.exe` specifically. It resolves the native vendor binary first (`codex-win32-x64/.../codex.exe`), then falls back to `codex.cmd`, using `Get-Command`, `where.exe`, and common npm global paths (`%APPDATA%\npm\`, `%LOCALAPPDATA%\npm\`).
- **`spawn EFTYPE` crash on Windows**: Two root causes fixed:
  1. PowerShell's `Get-Command "codex"` returned `codex.ps1` (not spawnable by Node.js). Resolver now searches only `.exe` and `.cmd` candidates.
  2. If `codex.cmd` is used as fallback, `Patch-MainSpawn` patches the bundled Electron JS to add `shell: true` conditionally for `.cmd`/`.bat` files on Windows.

### Added
- **`Launch-Codex.cmd`**: Double-click desktop launcher that runs Codex with `-Reuse` (no re-extraction needed after first setup).
- **`-Doctor` diagnostics mode**: Run `.\scripts\run.ps1 -Doctor` to print PowerShell version, execution policy, Node/npm availability, npm prefix, Codex CLI search results, resolved binary type, and WSL/7-Zip status.
- **Actionable error messages**: When Codex CLI is not found, the error explains *why* it fails on Windows and gives step-by-step fix instructions with diagnostic commands.

### Improved
- **README**: Complete rewrite with Quick Start, parameter table, file reference, troubleshooting for 4 common issues, platform status table.
- **`run.cmd`**: Updated usage help to show `-Doctor` and all available flags.
