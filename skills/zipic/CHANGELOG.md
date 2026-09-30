# Changelog

All notable changes to the `zipic` skill are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/).
Versioning follows [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

## [2.2.0] — 2026-10-01

### Added
- Native Windows execution guidance grounded in Zipic-Windows: packaged `zipic.exe` alias, PowerShell 5.1/7 invocation, UTF-8 JSON, native exit codes, GUI/session requirements and WSL interop.
- Read-only `scripts/detect.ps1` checks the installed package, executable/alias and actual CLI version without launching the GUI or modifying settings; prefers the package-scoped alias to avoid development packages hijacking the global command.
- Windows evaluation scenarios for Chinese/space-containing paths, source-preserving conversion, alias recovery, stderr-only usage errors, per-file failures and session/WSL routing.

### Fixed
- Removed macOS-only routing from the skill metadata and README; the macOS detector now routes Windows users to the native detector in the instructions.
- Documented Windows differences: unsupported `--specified`, ICO versus ICNS, system HEIC codecs, monitor depth 0–5 and preset/global setting boundaries.
- Corrected result handling: exit 0 is not a per-file success guarantee, `completed_count` counts finished inputs, and Pro context lives in `error.data`.
- Separated Windows URL Scheme syntax from macOS, including percentage `ratio` and source-deletion semantics.

### Verified
- Windows 11 x64, PowerShell 5.1, packaged Zipic 1.10.3 / CLI 0.3.0: package-scoped detection, dry-run, Chinese/space-containing path conversion to WebP (79% saved; source SHA-256 unchanged), three independent GUI pipe requests, stderr-only exit 64, structured exit 1 and mixed success/failed batch results with exit 0.
- macOS detector and skill frontmatter validation passed. PowerShell 7, Windows 10 and ARM64 were not exercised on hardware in this change.

## [2.1.0] — 2026-08-03

### Added
- **Overwrite / source-deletion contract**, the headline of this release. Documented what `overwrite` actually means (format conversion + same path stem → source file deleted, inherited from the active preset whose GUI default is ON) and added agent safety rules to SKILL.md: pass `--no-overwrite` (CLI ≥ 0.2.0) or route output to a separate `--output` dir (safe on all versions) whenever the user didn't ask to replace sources.
- CLI 0.2.0 coverage in `reference/cli.md`, with per-flag version gating against 0.1.0:
  - Full boolean pairs `--no-overwrite`, `--no-progressive`, `--no-keep-hierarchy`, plus explicit `--<flag>=true|false` forms for every pair.
  - `--keep-hierarchy`, `--tiff-compression`, `--autocopy` flagged as **silently dead on 0.1.0**, working on 0.2.0 (`--autocopy` now documents the take-over-from-GUI-global + aggregate clipboard semantics).
  - `--suffix` / `--subfolder` imply enabling their toggle on 0.2.0 (silent no-op on 0.1.0 when the inherited toggle is off).
  - `data.option` echo in the compress success response; `data.plan.option.overwrite` called out for dry-run verification.
  - `preset set-default` implemented (selects the *active* preset — the flag-less compress baseline); still `not_implemented` on 0.1.0.
  - `--scale` added to the compress and `preset create` flag tables; `preset create` flag list expanded with the boolean pairs.

### Fixed
- Socket path in `reference/cli.md` was wrong: `~/Library/Application Support/zipic/cli.sock` → `~/Library/Application Support/studio.5km.zipic/cli.sock`.
- Wrong "Default" column entries for `--overwrite`, `--progressive`, `--keep-hierarchy` (documented as fixed `off` — they are all inherited from the active preset / current settings; there are no fixed CLI defaults).

## [2.0.0] — 2026-05-08

### Added
- Support for the `zipic` CLI shipped in Zipic 1.9.5 (build 60). CLI is now the preferred invocation path because it returns structured JSON (`isError`, per-file `output_bytes` / `saved_pct`, exit codes) — dramatically more useful for AI workflows than the URL Scheme.
- Inline detection script in SKILL.md that probes OS, Zipic.app path/version, CLI presence, and GUI running state in a single composite command, then routes via a decision table.
- Version-aware routing logic with bash-native `sort -V` comparison against `1.9.5`.
- `reference/cli.md` — full CLI spec: subcommands (`compress`, `preset`, `list`), every flag with type/default, JSON response schemas, exit codes, and the `pro_required` error shape (`purchase_url`, `trial_available`, `direction`, `blocked_format`).
- `reference/url-scheme.md` — full URL Scheme spec moved out of SKILL.md, including the parameter table, path-encoding helpers, and a CLI-vs-URL-Scheme limitations matrix.
- `description` trigger keywords: `preset`, `compression history`.
- `reference/resources.md` — official site, docs, AI-friendly index (`zipic.app/llms.txt`), `llms-full.txt`, and a per-section deep-link table covering all 20 docs pages (Start Here / AI / Guides / Reference / Resources) plus the `/zh-cn/` mirror convention. Lets the skill double as a Zipic-usage Q&A system without bloating SKILL.md — a one-line pointer in SKILL.md sends the AI here when the user asks about Zipic itself instead of asking for compression.

### Changed
- **BREAKING (skill consumer behavior, not a code break):** SKILL.md is now lean (~150 lines). Exhaustive flag tables moved to `reference/` so the AI loads them only when actually constructing a call — keeps the always-loaded context tight.
- Bumped minimum recommended Zipic version to 1.9.5 for the CLI path. URL Scheme still works on 1.9.0+ as the documented fallback.
- `compatibility` field updated to: `macOS only. Requires Zipic.app >= 1.9.5 for CLI; >= 1.9.0 for SVG via URL Scheme.`
- Pro awareness rewritten around the CLI's structured `pro_required` payload (with `purchase_url` and `trial_available`) instead of the prior generic Pro-feature list.

### Notes
- URL Scheme is retained as a guaranteed fallback for Zipic < 1.9.5 and for environments where the CLI symlink isn't installed.
- `preset set-default` is declared in the CLI but returns `not_implemented` in 1.9.5 — flagged in `reference/cli.md`.

### Post-2.0.0 follow-ups
- `scripts/detect.sh` — moved the inline detection block into an executable shell script that emits `key=value` lines including a precomputed `route` (`cli` / `install_cli` / `url_scheme` / `halt_no_app` / `halt_not_macos`). The skill no longer asks the AI to derive routing or run a `sort -V` version compare; both are baked into the script with a portable awk-based version comparator. Verified on macOS 25.4 with Zipic 1.9.5: emits `route=cli` correctly.
- Expanded `description` triggers to cover Zipic-usage Q&A: pricing, Pro features, activation, free-tier limits, troubleshooting, comparisons (vs ImageOptim/TinyPNG/Squoosh), CLI install, format support, Raycast/Shortcuts integration. The skill now reliably triggers when the user asks *about* Zipic, not only when they hand it images to compress.
- SKILL.md: 143 → 127 lines (Step 1–3 collapsed into a single `bash scripts/detect.sh` + route table).
- **CLI-first restructure (after running 5-eval benchmarks across 3 iterations).** Original SKILL.md presented "CLI path (preferred)" and "URL Scheme fallback" as parallel sections, which led agents on multi-parameter tasks (e.g. "convert + resize + custom output dir") to skip detection entirely and fabricate URL Scheme parameters from memory (`saveLocation=` instead of `directory=`). Rewrote SKILL.md so `zipic compress --json` is the unconditional opening recipe; URL Scheme demoted to a "Fallback" subsection only invoked when `route` says so. `scripts/detect.sh` repositioned from "Step 1, always" to "diagnostic when the CLI fails." Effect on the benchmark: with-skill pass rate **80% → 97%** (stddev 36% → 7%), end-to-end time **81s → 69s**. The fix proves the lesson that document tone matters more than directives — making CLI the obvious default beats writing "you must use CLI" in bold.
- **SKILL.md compaction (iter-4).** Trimmed 131 → 82 lines (-37%). Cut redundant sections: a `pro_required` JSON sample (already fully specified in `reference/cli.md`), a CLI exit-code table that duplicated a one-liner in the Compress section, a "Common workflows" bullet list overlapping the flag table, and a "Format guidance" section the LLM didn't need (WebP/AVIF/HEIC choice is general knowledge). Also condensed the frontmatter `description`. Re-running the same 5-eval benchmark: pass rate held at **97%** while average tokens dropped from 34.7K → 27.1K (-22%). The skill now consumes **fewer tokens than the no-skill baseline** (27.1K vs 27.9K), so loading it is strictly free at the token level — the skill pays for itself on every invocation.

## [1.1.0] — 2026-04-22

### Added
- SVG optimization support (requires Zipic 1.9.0+, Pro feature)
  - New `### SVG Optimization` workflow section with usage examples and level-specific guidance
  - SVG compression-level guide (1–2 conservative / 3–4 balanced / 5–6 aggressive)
- SVG + APNG entry in the Pro Features list
- SVG recommendation entry in the Format Recommendations section
- Trigger keywords in frontmatter `description`: `optimize SVG`, `minify SVG`

### Changed
- Bumped minimum Zipic version from "current stable" to `>= 1.9.0` (required for SVG support)
- Clarified `format=` parameter documentation: explicitly noted that `svg` is NOT a valid output value (raster → vector is impossible); SVG inputs are optimized in-place and stay as SVG

## [1.0.0] — 2026-04-22

First tagged release.

### Added
- Skill metadata in YAML frontmatter: `version`, `author`, `license`, `homepage`, `platform`, `requires`
- Standalone `CHANGELOG.md` (this file) to track version history
- Standalone `LICENSE` file (MIT)

### Skill capabilities (baseline)
- Zipic URL Scheme invocation via the `open` command
- Parameter reference: `url`, `level` (1–6), `format`, `width`, `height`, `location`, `specified`
- Pre-flight checks: OS detection + Zipic installation detection
- Workflows: basic compression, format conversion, resize + compress, batch processing
- Path handling with URL encoding for spaces and non-ASCII characters
- Pro feature awareness (free tier cap at 25/day)
- Error handling for missing Zipic app and non-existent paths
