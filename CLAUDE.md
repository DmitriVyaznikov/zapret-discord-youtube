# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**zapret-discord-youtube** is a Windows DPI (Deep Packet Inspection) circumvention tool for bypassing network-level blocking of Discord, YouTube, and Google services. It wraps the [bol-van/zapret](https://github.com/bol-van/zapret) engine (`winws.exe`) with pre-configured strategy files and a service manager.

The project is primarily written in **Windows Batch** (`.bat`) and **PowerShell** (`.ps1`). There is no traditional build system — binaries are pre-compiled and distributed in `bin/`.

## Architecture

### Execution Flow

1. User runs a strategy `.bat` file (e.g., `general.bat`)
2. Strategy calls `service.bat` helper functions (`status_zapret`, `check_updates`, `load_game_filter`)
3. Strategy launches `bin/winws.exe` with filter chains specifying:
   - TCP/UDP port filters (80, 443, Discord voice ports, game ports)
   - Domain hostlists and IP sets from `lists/`
   - DPI desync techniques (`fake`, `multisplit`, `fakedsplit`)
   - TLS/QUIC packet templates from `bin/*.bin`
4. WinDivert kernel driver (`bin/WinDivert64.sys`) intercepts matching traffic
5. `winws.exe` applies desync/spoofing to bypass DPI inspection

### Key Components

- **Strategy files** (root `*.bat`, 19 variants): Each file is a different combination of DPI evasion parameters for `winws.exe`. `general.bat` is the default; ALT/FAKE TLS AUTO/SIMPLE FAKE variants use different techniques.
- **`service.bat`** (~600 lines): Menu-driven service manager handling Windows service install/remove, game filter toggle, IPSet toggle, auto-updates, diagnostics, and test execution. Also exposes helper functions called by strategy files via command-line arguments (`status_zapret`, `check_updates`, `load_game_filter`).
- **`bin/`**: Pre-compiled binaries — `winws.exe` (DPI engine), `WinDivert.dll`/`WinDivert64.sys` (kernel driver), `cygwin1.dll` (runtime), and `.bin` files (TLS ClientHello / QUIC Initial packet templates).
- **`lists/`**: Domain lists (`list-general.txt`, `list-google.txt`), exclusion lists (`list-exclude.txt`), and IP sets (`ipset-all.txt`, `ipset-exclude.txt`). These are the most frequently updated files via PRs.
- **`.service/`**: Windows service support files — hosts file entries for Discord, service-mode IP set, version tracking.
- **`utils/`**: PowerShell test script (`test zapret.ps1`) and test targets (`targets.txt`).

### Strategy File Structure

All strategy `.bat` files follow the same pattern:
1. Set codepage to UTF-8 (`chcp 65001`)
2. Call `service.bat` helpers for status/updates/game filter
3. Set `BIN` and `LISTS` path variables
4. Launch `winws.exe` with `--new`-separated filter chains

Filter chains are processed in order; each `--new` starts a new independent filter rule. Chains use `--filter-tcp`/`--filter-udp` for port matching, `--hostlist`/`--ipset` for target matching, and `--dpi-desync-*` for the evasion technique.

## Git Conventions

- `.gitattributes` enforces CRLF line endings for `.bat` and `.ps1` files
- Test results are gitignored (`/utils/test results`)
- Documentation and list updates are the most common PR types
- README and UI strings are in Russian

## Running and Testing

All execution is Windows-only and requires administrator privileges.

- **Run default strategy**: Double-click `general.bat` (or run as admin from cmd)
- **Run alternative strategy**: Double-click any `general (ALT*).bat` variant
- **Service manager**: Run `service.bat` — provides interactive menu for install/remove service, toggle filters, run diagnostics
- **Run tests**: Use option in `service.bat` menu, or run `utils/test zapret.ps1` directly in PowerShell
- **Test targets**: Defined in `utils/targets.txt` (Discord, YouTube, Google, Cloudflare endpoints)
