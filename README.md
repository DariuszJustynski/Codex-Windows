# Codex DMG -> Windows

A **Windows-friendly** runner that extracts the macOS Codex DMG and runs the Electron app on Windows. It unpacks `app.asar`, swaps mac-only native modules for Windows builds, and launches the app with a compatible Electron runtime.

It **does not** ship OpenAI binaries or assets; you must supply your own DMG and install the Codex CLI.

## Requirements

- Windows 10/11
- Node.js (LTS recommended)
- Codex CLI installed globally (`npm i -g @openai/codex`)
- 7-Zip (`7z` in PATH) — auto-installed via winget or portable download if missing

> **Windows reality:** `npm i -g @openai/codex` typically installs `codex.cmd` (not `codex.exe`). This script handles both — no workaround needed.

## Quick Start

```powershell
# 1. Allow scripts for this session (safe — process-scoped only)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 2. Install Codex CLI (if not already installed)
npm i -g @openai/codex

# 3. Run diagnostics to verify everything is set up
.\scripts\run.ps1 -Doctor

# 4. Run the main flow (place Codex.dmg in repo root first)
.\scripts\run.ps1
```

Or explicitly:

```powershell
.\scripts\run.ps1 -DmgPath .\Codex.dmg
```

Or use the shortcut launcher:

```cmd
run.cmd -DmgPath .\Codex.dmg
```

## Parameters

| Parameter | Type | Description |
|---|---|---|
| `-DmgPath` | string | Path to the Codex `.dmg` file (auto-detected from repo root) |
| `-WorkDir` | string | Working directory for extracted files (default: `.\work`) |
| `-CodexCliPath` | string | Explicit path to `codex.cmd` or `codex.exe` (auto-resolved if omitted) |
| `-Reuse` | switch | Skip extraction if `work/` already exists |
| `-NoLaunch` | switch | Extract and build only, do not launch Electron |
| `-Doctor` | switch | Print diagnostics and exit (does not require DMG or Codex CLI) |

## Troubleshooting

### `codex.exe not found` / Codex CLI not found

On Windows, npm installs Codex as `codex.cmd`, not `codex.exe`. The script handles this automatically, but if it still fails:

1. Make sure Codex CLI is installed: `npm i -g @openai/codex`
2. **Restart your terminal** (PATH changes require a new session)
3. Run `.\scripts\run.ps1 -Doctor` to see what the script can find
4. If Codex is installed in a non-standard location:
   ```powershell
   .\scripts\run.ps1 -CodexCliPath "C:\path\to\codex.cmd"
   ```

### Execution policy error

```
File cannot be loaded because running scripts is disabled on this system.
```

Run this once (safe — only affects current terminal session):
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### PATH not refreshed after npm install

If you just ran `npm i -g @openai/codex` but the script still cannot find Codex:
- Close and reopen your terminal
- Or run: `$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "Machine")`

## How It Works

The script will:
1. Extract the DMG to `work/`
2. Unpack `app.asar` from the macOS app bundle
3. Build Windows-compatible native modules (better-sqlite3, node-pty)
4. Resolve the Codex CLI (`codex`, `codex.cmd`, or `codex.exe`)
5. Launch the Electron app

## Notes

- This is not an official OpenAI project.
- Do not redistribute OpenAI app binaries or DMG files.
- The Electron version is read from the app's `package.json` to keep ABI compatibility.

## License

MIT (for the scripts only)
