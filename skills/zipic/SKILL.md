---
name: zipic
description: |
  Local image compression and Zipic-app expert for macOS and native Windows. Uses the Zipic CLI with JSON results, per-file saved_pct and exit codes; URL Scheme is a limited fallback.
  Use for compressing, optimizing or shrinking images, batch compression, conversion to WebP/AVIF/HEIC/JXL (including lossless JPEG XL), SVG optimization, resizing, presets and compression history. Also use for Zipic pricing, Pro features, activation, free-tier limits, troubleshooting, comparisons, CLI setup and workflow integration.
  Requires the installed Zipic GUI in the same execution environment. Windows uses the packaged zipic.exe alias and PowerShell; macOS uses Zipic.app. Format support and integrations differ by platform.
license: MIT
compatibility: macOS with Zipic.app >= 1.9.5 for CLI (>= 1.9.0 for SVG via URL Scheme), or Windows 10 build 19041+ / Windows 11 with packaged Zipic and its zipic.exe execution alias. Windows examples support PowerShell 5.1 and 7. No native Linux CLI; WSL requires Windows interop and Windows-accessible paths.
metadata:
  version: 2.3.0
  author: 十里 & FRIDAY
  homepage: https://zipic.app
  changelog: ./CHANGELOG.md
---

# Zipic

Image compression on macOS and Windows, 100% on-device. Drive the installed GUI via its CLI; URL Scheme is a fallback when the CLI is unavailable.

## Platform and shell

Identify the OS, architecture and shell **where commands execute**, rather than the user's desktop OS. Keep the GUI, CLI and input/output paths on the same host and user account.

- **macOS**: use `zipic` and POSIX shell syntax. If missing, run `bash "<skill-dir>/scripts/detect.sh"`.
- **Native Windows**: read [reference/windows.md](reference/windows.md) before setup or compression. Use PowerShell and `zipic.exe`; run `& "<skill-dir>\scripts\detect.ps1"` to resolve the executable and verify its version. The packaged CLI is `ZipicCli.exe`, exposed as the `zipic.exe` app execution alias; the GUI's `Zipic.exe` is a different executable.
- **WSL**: there is no Linux Zipic binary. Use Windows PowerShell through WSL interop with paths converted by `wslpath -w`, following the Windows reference. A Linux container or remote Linux host without Windows interop cannot invoke the Windows GUI.

Resolve `<skill-dir>` from this loaded skill's location; script paths are not relative to the user's project. On Windows use `& $exe` for a resolved executable, `$env:NAME` for environment variables, quoted paths and argument arrays. Do not copy Bash continuations, `open`, `brew` or `/tmp` paths into PowerShell.

## Compress

```text
zipic compress --json [flags] <files-or-dirs>...
```

`--json` is required — parse stdout separately from stderr. Capture the process exit code immediately (`$LASTEXITCODE` in PowerShell), then inspect `isError` and every `data.results[].state`; exit 0 alone does not prove every file succeeded. Report per-file `output_bytes`, `saved_pct` and errors. Pass directories directly; Zipic walks them recursively.

| Need                       | Flag |
| -------------------------- | ---- |
| Compression level (1–6)    | `--level 3` (1 = best quality, 6 = smallest) |
| Convert format             | `--format webp` (also `jpeg\|png\|avif\|heic\|jxl`) |
| Cap width                  | `--width 1920` (aspect kept by default) |
| Custom output directory    | `--output /tmp/out/` (auto-sets `--location custom`) |
| Mirror source tree         | `--keep-hierarchy` |
| Use a saved preset         | `--preset "Web 1x"` (explicit flags override) |
| Keep sources on conversion | `--no-overwrite` (CLI ≥ 0.2.0) or `--output <dir>` (any version) |
| Preview without running    | `--dry-run` |
| Lossless JPEG XL           | `--format jxl --jxl-lossless` (CLI ≥ 0.4.0; confirm in `--help`) |

**Source-deletion warning**: flags you don't pass inherit from the user's *active preset*, and `overwrite` (GUI default ON) means a format conversion landing next to the source with the same base name **deletes the source file**. When the user didn't ask to replace sources: pass `--no-overwrite` (CLI ≥ 0.2.0, check `zipic --version`), or write to a separate `--output` dir — safe on every version. `--dry-run --json` echoes the effective value at `data.plan.option.overwrite`. On CLI 0.1.0 there is no reliable off switch (`--no-overwrite` is unknown and swallows the next argument) — use the `--output` route. Full contract: `reference/cli.md`.

```bash
# Convert + resize + custom output
zipic compress --json --level 3 --format webp --width 1920 --output /tmp/out/ /path/photo.png

# Batch a folder
zipic compress --json --format webp --output /tmp/out/ /path/folder
```

**Lossless JXL** (CLI ≥ 0.4.0): confirm `zipic --help` lists `jxl-lossless` before using it. On a CLI without the flag, the bare form swallows the next argument. Lossless sources become pixel-exact JXL and JPEGs are reversibly transcoded; already-lossy sources (lossy JXL/WebP, HEIC, AVIF, JPEG-in-TIFF) come back as `state: "skipped"` with `skip_reason`, with no output and the source untouched. Report skips separately from failures; re-run only those inputs with `--no-jxl-lossless` if the user accepts lossy, warning them that this often grows the file. Details: `reference/cli.md` → JXL lossless mode.

**Exit codes**: `0` request completed / `1` runtime — read `error.code` from JSON / `64` bad args (may be stderr only) / `65` GUI unavailable after auto-launch. **`pro_required`** returns upgrade/trial context in `error.data` (`purchase_url`, `trial_available` when present) — surface it, don't bypass. Format gates vary by platform; Windows uses ICO rather than macOS ICNS. Per-file quota/failure states must also be reported.

For preset / history / dry-run / `pro_required` schema: `reference/cli.md`.

## When the CLI fails

On **macOS**, if `zipic` isn't on `$PATH`, or exit 65 persists after one retry, run from the skill directory:

```bash
bash scripts/detect.sh
```

Read the `route` field:

| `route`          | Action |
| ---------------- | ------ |
| `cli`            | Re-run the CLI; it auto-launches Zipic and waits ~8 s for the socket. |
| `install_cli`    | CLI binary missing — tell user: Zipic menu bar → "Install zipic CLI". Use Fallback below for now. |
| `url_scheme`     | Zipic < 1.9.5, no CLI exists — tell user to upgrade. Use Fallback below. |
| `halt_no_app`    | Zipic not installed — suggest `brew install --cask zipic` or https://zipic.app. |
| `halt_not_macos` | This Bash detector is macOS-only. On Windows switch to `scripts/detect.ps1`; on WSL read the Windows reference. |

On **Windows**, use the detection routes in [reference/windows.md](reference/windows.md). There is no separate CLI installer: check the app execution alias and `$env:LOCALAPPDATA\Microsoft\WindowsApps` before reinstalling. The CLI auto-launches the packaged GUI and waits about 8 seconds; on persistent exit 65, open Zipic in the same user's desktop session and retry once. Do not repeatedly retry failed compression batches or run the GUI's executable as a CLI.

## Fallback: URL Scheme

On macOS, use only when `route` is `install_cli` or `url_scheme`; on Windows, repair the alias first and use a URL only if CLI recovery is unavailable. URL Scheme has no result JSON or compression exit code. **Load [reference/url-scheme.md](reference/url-scheme.md) before constructing the URL**: parameter names and semantics differ by platform (`ratio` is particularly different). Percent-encode paths, use a separate output directory and inspect actual files afterward. Launching the URL does not prove compression succeeded.

## SVG and presets quick notes

- **SVG optimization** (Pro; macOS Zipic ≥ 1.9.0, also supported on Windows): pass `.svg` files like any other input. Output stays SVG — never set `--format` on SVG. Level 1–2 conservative, 3–4 balanced, 5–6 may simplify paths visibly.
- **Presets** (CLI only): `zipic preset list --json`, `zipic preset show "<name>" --json`, `zipic preset create --name "Web 2x" --level 3 --format webp --width 2400`. `zipic preset set-default "<name>"` (CLI ≥ 0.2.0) selects the active preset — the baseline a flag-less `compress` inherits. Free users may keep at most 1 custom preset.
- **History** (CLI only): `zipic list --json --limit 20` / `zipic list clear`.

## Zipic-usage questions

For pricing, Pro features, troubleshooting, activation, comparisons, etc. — load `reference/resources.md`. It indexes https://zipic.app, https://docs.zipic.app, the AI-friendly index at https://zipic.app/llms.txt, and per-topic deep links (incl. Chinese mirrors). Fetch the canonical page; don't guess.
