# Security Model — Codex-Windows (Granite Core)

## Overview

Codex is an AI agent capable of reading and writing files, spawning system processes, and generating source code. This makes it a **high-privilege tool by design**.

On Windows, where applications commonly run with broad filesystem and process access, **explicit sandboxing is required** to make this safe and trustworthy.

This document describes the security assumptions, threat model, and planned sandboxing strategy for this project.

## Core Principle: Granite Core

> **Assume the AI is untrusted by default.**

All access must be:
- **explicit** — no ambient authority, no hidden capabilities
- **minimal** — only what the current task requires
- **auditable** — every action logged and reviewable
- **revocable** — permissions can be withdrawn at any point

## Threat Model

### In scope

| Threat | Description |
|---|---|
| Unintended filesystem access | Reading or modifying files outside the target repository, accessing user home or system paths |
| Uncontrolled process execution | Spawning arbitrary commands, chaining shell execution (`cmd`, `powershell`, `curl`) |
| Prompt injection | Instructions embedded in repo content or generated text that attempt to escape intended scope |
| Credential exposure | Leaking API keys or tokens to files, logs, or environment variables persisted beyond session |

### Out of scope

The following are explicitly **not** goals of this sandbox:

- Kernel-level isolation or exploit mitigation
- Protection against a fully compromised operating system
- DRM or anti-reverse-engineering measures
- Antivirus or malware detection

This is an **application-level sandbox**, not a security boundary against the OS itself.

## Architecture (Planned)

### 1. Electron renderer hardening

- `sandbox: true`, `contextIsolation: true`
- No `nodeIntegration`, no `enableRemoteModule`
- Renderer has zero access to `fs`, `child_process`, `process.env`

### 2. Preload as trust boundary

- Preload script exposes a minimal, explicit API
- No dynamic execution (`eval`, `Function()`)
- No raw path passing from UI to main process
- Clearly marked in code: `// SECURITY: TRUST BOUNDARY`

### 3. Per-session filesystem sandbox

Each Codex session runs inside an isolated workspace:

```
%LOCALAPPDATA%/CodexSandbox/sessions/<session-id>/
  repo-copy/     # writable copy of the target repo
  output/        # generated artifacts
  logs/          # session logs (actions, spawns)
```

Rules:
- Original repos are **never modified directly**
- Write access only inside the session directory
- All paths validated against the sandbox root

### 4. Spawn policy

All child processes go through a policy-controlled wrapper:

- Allowlist of binaries (`codex`, `node`, `git`)
- Argument validation (no arbitrary flags)
- Timeouts and output size limits
- No arbitrary shell execution

### 5. Execution modes

| Mode | Behavior |
|---|---|
| `plan` (default) | Read-only. Codex describes intended changes, no writes. |
| `apply` | Sandboxed writes. Changes only inside session workspace. |
| `export` | Documentation and metadata generation only. |

Default workflow: **plan > review > apply**.

### 6. Secrets handling

- API tokens kept **in memory only**
- No secrets written to disk
- `.env` files never copied into sandbox
- Logs scrubbed of sensitive data

## Current Status

| Layer | Status |
|---|---|
| CLI resolution + spawn patching | Done (v1.0.0) |
| Electron renderer hardening | Planned |
| Preload trust boundary | Planned |
| Filesystem sandbox | Planned |
| Spawn policy wrapper | Planned |
| Execution modes | Planned |
| Audit logs | Planned |
| Secret hygiene | Planned |

See the [Roadmap in README.md](README.md#roadmap) for the full checklist.

## Design Philosophy

This project does not attempt to hide what Codex can do. Instead, it makes all powerful actions **visible, constrained, and explainable**.

Security here is based on explicit boundaries and minimal authority — not obscurity.

## Contributing

Security-related PRs are welcome. If you find a vulnerability or have suggestions for the sandbox design, please open an issue or submit a PR. For sensitive disclosures, contact the maintainer directly.
