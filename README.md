# Codex-Windows

**Windows-friendly Codex CLI bootstrapper** — extracts the macOS Codex DMG and runs the Electron app natively on Windows. Handles all Windows-specific quirks: `codex.cmd` vs `codex.exe`, `spawn EFTYPE`, ExecutionPolicy, native module rebuilds.

It **does not** ship OpenAI binaries or assets; you must supply your own DMG and install the Codex CLI.

## Requirements

- Windows 10/11
- Node.js (LTS recommended)
- Codex CLI installed globally (`npm i -g @openai/codex`)
- 7-Zip (`7z` in PATH) — auto-installed via winget or portable download if missing

> **Windows reality:** `npm i -g @openai/codex` installs `codex.cmd` (not `codex.exe`). The script finds the native binary automatically — no workaround needed.

## Quick Start

### First time setup

```powershell
# 1. Allow scripts for this session (safe — process-scoped only)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 2. Install Codex CLI (if not already installed)
npm i -g @openai/codex

# 3. Run diagnostics to verify everything is set up
.\scripts\run.ps1 -Doctor

# 4. Place Codex.dmg in the repo root, then run:
.\scripts\run.ps1
```

### After first setup

**Double-click `Launch-Codex.cmd`** — that's it. It reuses the already-extracted app and launches Codex instantly.

Or from terminal:
```powershell
.\scripts\run.ps1 -Reuse
```

## Parameters

| Parameter | Type | Description |
|---|---|---|
| `-DmgPath` | string | Path to the Codex `.dmg` file (auto-detected from repo root) |
| `-WorkDir` | string | Working directory for extracted files (default: `.\work`) |
| `-CodexCliPath` | string | Explicit path to `codex.cmd` or `codex.exe` (auto-resolved if omitted) |
| `-Reuse` | switch | Skip extraction if `work/` already exists (used by `Launch-Codex.cmd`) |
| `-NoLaunch` | switch | Extract and build only, do not launch Electron |
| `-Doctor` | switch | Print diagnostics and exit (does not require DMG or Codex CLI) |

## Files

| File | Purpose |
|---|---|
| `Launch-Codex.cmd` | **Double-click launcher** — runs Codex with `-Reuse` (no re-extraction) |
| `run.cmd` | CLI launcher with argument pass-through |
| `scripts/run.ps1` | Main PowerShell script (extraction, patching, launching) |

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

Or just use `Launch-Codex.cmd` which bypasses this automatically.

### `spawn EFTYPE` crash

This error means Electron tried to spawn a non-executable file (`.ps1` or `.cmd` without shell). The script automatically:
- Resolves the native `codex.exe` binary (best path)
- Patches the Electron bundle to handle `.cmd` fallback

If you still see it:
1. Delete the `work/` folder and re-run (ensures a fresh patch)
2. Run `.\scripts\run.ps1 -Doctor` to verify the CLI path shows `(native binary - best)`
3. If using `-Reuse`, try without it once to force re-patching

### PATH not refreshed after npm install

If you just ran `npm i -g @openai/codex` but the script still cannot find Codex:
- Close and reopen your terminal
- Or run: `$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "Machine")`

## How It Works

1. Extract the DMG to `work/` using 7-Zip
2. Unpack `app.asar` from the macOS app bundle
3. Build Windows-compatible native modules (better-sqlite3, node-pty)
4. **Patch the Electron bundle** to handle `.cmd`/`.bat` spawning on Windows
5. **Resolve the Codex CLI** — finds the native PE binary first, falls back to `.cmd`
6. Launch the Electron app

### Platform status

| Platform | Status |
|---|---|
| Windows 10/11 (x64) | Fully supported |
| Windows (ARM64) | Should work (untested) |
| macOS | Use the official DMG directly |
| Linux / WSL | Not yet supported by this fork |

## Notes

- This is not an official OpenAI project.
- Do not redistribute OpenAI app binaries or DMG files.
- The Electron version is read from the app's `package.json` to keep ABI compatibility.

## License

MIT (for the scripts only)
