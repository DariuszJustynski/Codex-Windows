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

## Roadmap

Codex is an AI agent that can read/write files and spawn processes. On Windows, where apps run with broad system access by default, **application-level sandboxing is essential**. The planned architecture follows the **Granite Core** principle: assume the AI is untrusted by default — all access must be explicit, minimal, auditable, and revocable.

See [`SECURITY.md`](SECURITY.md) for the full threat model and architecture design.

### Sandbox model (Granite Core)

- [ ] **Renderer hardening** — enforce `sandbox: true`, `contextIsolation: true`, disable `nodeIntegration` and `enableRemoteModule` in Electron `BrowserWindow`
- [ ] **Preload trust boundary** — restrict `preload.js` to a minimal, explicit API surface; no `eval`, no dynamic path passing from UI; mark boundary with `// SECURITY: TRUST BOUNDARY`
- [ ] **Per-session workspace sandbox** — create isolated session directories at `%LOCALAPPDATA%/CodexSandbox/sessions/<uuid>/` with `repo-copy/`, `output/`, `logs/`; original repo stays read-only
- [ ] **Path validation helpers** — implement `assertPathInSandbox(path)` that denies any access outside the session sandbox root
- [ ] **Spawn policy wrapper** — replace raw `child_process.spawn` with `spawnWithPolicy()` that enforces an allowlist of binaries (`codex`, `node`, `git`), validates arguments, applies timeouts and output limits, and blocks arbitrary shell execution

### Sensitive data encapsulation

- [ ] **In-memory-only token handling** — API keys and tokens never written to disk, passed only via `stdin` or environment within session lifetime
- [ ] **Log scrubbing** — prevent token/key patterns from appearing in any log output
- [ ] **No `.env` in sandbox** — exclude `.env`, `.pem`, credential files from repo copies into sandbox workspace
- [ ] **Safe config rules** — document what is allowed in `config.toml` (UI preferences) vs. what is forbidden (secrets, tokens)
- [ ] **Secret hygiene in `-Doctor`** — add checks for exposed secrets (`.env` in repo root, tokens in config files, keys in environment) to the diagnostics output

### Execution modes & auditability

- [ ] **Plan mode** (default) — Codex describes intended changes without writing anything; user reviews before any action
- [ ] **Apply mode** — sandboxed writes only inside session workspace; no modifications to original repo
- [ ] **Export mode** — documentation and metadata generation only (README, CHANGELOG, architecture docs)
- [ ] **Session metadata** — generate `session.json` per run with timestamp, repo hash, scope of operations, execution mode
- [ ] **Deterministic logs** — produce `actions.log` (file operations) and `spawn.log` (executed processes) for post-hoc review and security auditing

### PR plan

Each roadmap area maps to a focused, independently-mergeable PR:

| PR | Scope | Status |
|---|---|---|
| 1. `docs: add SECURITY.md and threat model` | Security baseline, zero code changes | This release |
| 2. `security: harden Electron renderer` | BrowserWindow sandbox + isolation | Planned |
| 3. `security: restrict preload API surface` | Trust boundary in preload | Planned |
| 4. `security: session-based filesystem sandbox` | Workspace isolation + path validation | Planned |
| 5. `security: spawn policy wrapper` | Process allowlist + limits | Planned |
| 6. `security: execution modes + audit logs` | Plan/apply/export + session logs | Planned |

## Notes

- This is not an official OpenAI project.
- Do not redistribute OpenAI app binaries or DMG files.
- The Electron version is read from the app's `package.json` to keep ABI compatibility.

## License

MIT (for the scripts only)
