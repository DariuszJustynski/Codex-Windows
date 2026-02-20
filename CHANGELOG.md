# Changelog

## [Unreleased]

### Fixed
- **Codex CLI resolution on Windows**: The script no longer requires `codex.exe` specifically. It now resolves `codex`, `codex.cmd`, and `codex.exe` using `Get-Command`, `where.exe`, and common npm global install paths (`%APPDATA%\npm\`, `%LOCALAPPDATA%\npm\`). This fixes the hard failure most Windows users hit after `npm i -g @openai/codex`.
- **`spawn EFTYPE` crash on Windows**: The bundled Electron main process tried to spawn `codex.cmd` directly via `child_process.spawn()` without `shell: true`, causing an immediate crash. A new `Patch-MainSpawn` step patches the bundled JS to add `shell: true` conditionally when the resolved CLI path is a `.cmd` or `.bat` file on Windows.

### Added
- **`-Doctor` diagnostics mode**: Run `.\scripts\run.ps1 -Doctor` to print PowerShell version, execution policy, Node/npm availability, npm prefix, Codex CLI search results, and WSL/7-Zip status. Works even if Codex or Node are not installed.

### Improved
- **Error messages**: When Codex CLI cannot be found, the error now explains *why* (npm installs `codex.cmd` on Windows, PATH may need refreshing) and gives step-by-step fix instructions with copy-pasteable diagnostic commands.
- **README**: Added Quick Start with safe execution policy snippet, parameter reference table, and troubleshooting section for common Windows issues.
- **`run.cmd`**: Updated usage help to show `-Doctor` flag.
