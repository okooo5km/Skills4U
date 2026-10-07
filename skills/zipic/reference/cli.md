# Zipic CLI Reference

Shared CLI contract, with historical macOS 0.1.0/0.2.0 behavior below. macOS Zipic.app >= 1.9.5 uses a UDS socket at `~/Library/Application Support/studio.5km.zipic/cli.sock`. Windows packaged Zipic exposes `zipic.exe` (target: `ZipicCli.exe`) and uses `\\.\pipe\Zipic.Cli.<Windows-user-SID>`. Both auto-launch the GUI and wait about 8 seconds. For Windows setup, PowerShell/UTF-8 handling, desktop-session requirements and differences, read [windows.md](windows.md).

Check `zipic --version` and `--help`; CLI versions are independent of app versions. The historical macOS generations are:

- **0.1.0** (Zipic 1.9.5): baseline. `--overwrite` is one-way (no off switch), `--keep-hierarchy` / `--tiff-compression` / `--autocopy` are accepted but **silently dead**, `--<flag>=false` forms are silently dropped, and `preset set-default` returns `not_implemented`.
- **0.2.0** (later Zipic builds): full boolean pairs (`--no-overwrite`, `--no-progressive`, `--no-keep-hierarchy`) plus explicit `--<flag>=true|false` forms, the three dead flags actually work, invalid values exit 64 instead of being ignored, compress responses echo the resolved option, and `preset set-default` works.

- **0.4.0** (Zipic 1.10.4 on macOS; Windows is adopting the same contract): JPEG XL lossless — `--jxl-lossless` / `--no-jxl-lossless`, the `skipped` result state with `skip_reason`, and `list --status skipped`. Confirm with `zipic --help` containing `jxl-lossless` as well: some pre-release 1.10.4 builds already had the flag while still printing `0.3.0`. See [JXL lossless mode](#jxl-lossless-mode).

Windows currently implements CLI 0.3.0, including the boolean pairs and `preset set-default`; do not apply the macOS 0.1.0 limitations to it. Newer CLIs add commands not catalogued in this historical table; use installed `--help`. On Windows `--specified` is rejected, monitor depth uses 0–5, and preset/monitor commands reject global-only overrides such as metadata retention. See the Windows reference.

Flags marked "0.2.0" below require the newer CLI.

macOS install path: `/usr/local/bin/zipic` (symlink into `Zipic.app/Contents/Resources/zipic`). Installed via Zipic menu bar → "Install zipic CLI" (one-time admin password prompt). Windows registers the execution alias during package installation; no separate CLI install menu applies.

## Synopsis

```
zipic <command> [arguments]
zipic --version | -v
zipic --help    | -h
```

## Global flags

| Flag         | Effect                                                 |
| ------------ | ------------------------------------------------------ |
| `--json`     | Emit a single JSON line on stdout. Required for AI use. |
| `--dry-run`  | (compress only) Return the resolved plan, no work done. |
| `--version`  | Print CLI version (e.g. `zipic 0.2.0`) and exit.        |
| `--help`     | Print built-in help and exit.                           |

## Exit codes

| Code | Constant          | Meaning                                                  |
| ---- | ----------------- | -------------------------------------------------------- |
| 0    | success           | Request completed; still inspect every per-file state.    |
| 1    | businessError     | Runtime/business failure (e.g. `pro_required`, `not_found`, `internal_error`). |
| 64   | usageError        | Invalid arguments (bad flag, wrong enum, missing required value). |
| 65   | guiNotRunning     | Couldn't reach the Zipic GUI socket/pipe and auto-launch failed. |

Capture stdout and stderr separately. Local argument errors may emit only stderr even with `--json`; capture the native exit code before attempting JSON parsing. A successful response can contain failed/cancelled/quota-exceeded rows; `completed_count` is not a success count.

## Subcommand: `compress`

```
zipic compress [flags] <files-or-dirs>...
```

Positional args are files or directories. Directories are walked recursively for image files.

### compress flags

Every flag not given on the command line **inherits** from `--preset`, or, without it, from the GUI's currently *active* preset / current settings. There are no fixed CLI defaults. Boolean pairs also accept the explicit form `--<flag>=true|false` (0.2.0; on 0.1.0 the `=false` form is silently dropped — never rely on it there).

| Flag                                              | Type                                       | Default          | Notes |
| ------------------------------------------------- | ------------------------------------------ | ---------------- | ----- |
| `--level <1-6>`                                   | int 1–6                                    | inherited        | 1 = best quality, 6 = smallest. |
| `--format <value>`                                | `original\|jpeg\|png\|webp\|avif\|heic\|jxl` | inherited       | `avif` and `jxl` are Pro-only output formats; gated server-side. SVG is **not** an output value (SVG inputs stay SVG). |
| `--width <px>`                                    | int                                        | 0 (auto)         | 0 = no resize on this axis. Invalid values exit 64 on 0.2.0 (silently ignored on 0.1.0). |
| `--height <px>`                                   | int                                        | 0 (auto)         | Same as `--width`. |
| `--scale <1-99>`                                  | int                                        | —                | Percentage resize; overrides `--width`/`--height`. |
| `--keep-aspect` / `--no-keep-aspect`              | bool                                       | keep             | Lock aspect ratio when one axis is set. |
| `--preserve-metadata` / `--no-metadata`           | bool                                       | inherited        | EXIF/ICC retention. `--no-metadata` is Pro-only. |
| `--progressive` / `--no-progressive`              | bool                                       | inherited        | Progressive JPEG. `--no-progressive` needs 0.2.0. |
| `--jxl-lossless` / `--no-jxl-lossless`            | bool                                       | inherited        | JPEG XL lossless mode; only acts when the output is JXL. **Probe `--help` first** — see [JXL lossless mode](#jxl-lossless-mode). |
| `--tiff-compression <lzw\|zip>`                   | enum                                       | inherited        | TIFF output codec. **Dead on 0.1.0**; works on 0.2.0. |
| `--location <original\|custom>`                   | enum                                       | inherited        | `original` = save next to input; `custom` = `--output`. Auto-set to `custom` if `--output` is given without explicit `--location`. |
| `--output <dir>`                                  | path                                       | —                | Output directory. Forces `--location custom` when set. |
| `--suffix <text>`                                 | string                                     | inherited        | Filename suffix. Implies `--add-suffix` on 0.2.0 (on 0.1.0 it silently does nothing when the inherited toggle is off). |
| `--add-suffix` / `--no-suffix`                    | bool                                       | inherited        | Toggle suffix usage. |
| `--subfolder <name>`                              | string                                     | inherited        | Output subfolder under destination. Implies `--add-subfolder` on 0.2.0. |
| `--add-subfolder` / `--no-subfolder`              | bool                                       | inherited        | Toggle subfolder usage. |
| `--keep-hierarchy` / `--no-keep-hierarchy`        | bool                                       | inherited        | Mirror the source directory tree under `--output`. **Dead on 0.1.0**; works on 0.2.0. |
| `--overwrite` / `--no-overwrite`                  | bool                                       | inherited        | Replace-the-source on format conversion — see the contract below. `--no-overwrite` needs 0.2.0. |
| `--autocopy <off\|path\|file\|markdown>`          | enum                                       | inherit GUI global | **Dead on 0.1.0.** On 0.2.0 an explicit value takes over from the GUI's per-file autocopy: `off` suppresses clipboard writes, the others write one aggregate entry after the run (`path` = newline-joined paths, `file` = file objects, `markdown` = `![](path)` lines). |
| `--preset <name-or-id>`                           | string                                     | —                | Use a saved preset as base; explicit flags override its values. UUID match wins; falls back to name; "default" matches the seeded default preset regardless of locale. |
| `--dry-run`                                       | bool                                       | off              | Returns `data.plan` without compressing. |

### Overwrite / source-deletion contract

`overwrite` does **not** mean "replace existing output files". It means: on a
**format conversion** whose output lands at the **same path stem** as the source
(same directory, same base name — i.e. no suffix, no subfolder,
`location=original`), Zipic writes the converted file and **deletes the source**.
Example: `zipic compress photo.png --format webp --no-suffix --no-subfolder`
with overwrite in effect writes `photo.webp` and removes `photo.png`.

Because the value is inherited from the user's active preset (GUI default is
ON), an agent must never assume it is off. Safety rules:

- User didn't ask to replace sources → pass `--no-overwrite` (0.2.0), or use
  `--output <separate-dir>` — a different directory never triggers deletion and
  is safe on every CLI version.
- On CLI 0.1.0 there is **no reliable off switch** (`--no-overwrite` is unknown
  there and swallows the next argument; `--overwrite=false` is silently
  dropped) — use the `--output` route.
- Verify with `--dry-run --json` → `data.plan.option.overwrite`; a real run
  echoes the same via `data.option.overwrite` (0.2.0).

### JXL lossless mode

Requires CLI 0.4.0; gate on `zipic --help` listing `--jxl-lossless`. On a CLI without it the flag is unknown: bare `--jxl-lossless` **swallows the next argument** (e.g. eats an input path), and `--jxl-lossless=true` is silently ignored, producing an ordinary lossy JXL. If the probe fails, tell the user lossless JXL needs a newer Zipic instead of guessing.

The value is inherited from the active preset like every other boolean, so pass `--no-jxl-lossless` when the user explicitly wants lossy JXL. It applies when the output is JXL (`--format jxl`, or `--format original` on a JXL source) and requires Pro like any JXL output. `--level` does not trade quality in this mode. Zipic routes each input by what it actually contains:

| Source | Result |
| --- | --- |
| PNG, TIFF (uncompressed/LZW/ZIP), lossless WebP, lossless JXL | Pixel-exact JXL; 16-bit depth kept. |
| JPEG | Reversible JPEG transcode — the original JPEG can be reconstructed byte-for-byte. With resizing, or a JPEG libjxl cannot transcode, it falls back to pixel-exact encoding of the decoded image. `--no-metadata` strips EXIF/XMP/comments first but keeps ICC and orientation. |
| Lossy JXL, JPEG-reconstruction JXL, lossy WebP, HEIC, AVIF, JPEG-compressed TIFF | **Skipped**: no output written, source kept. Lossless can't recover lost detail and would only grow the file. |

A skipped row is not a failure and not a success. Its `output` is the **source path itself** (nothing new was written), and it is excluded from `completed_count`. Report it with its `skip_reason`. If the user still wants those files as JXL, re-run **only the skipped inputs** with `--no-jxl-lossless` (lossy). Warn them first: re-encoding an already-lossy WebP/HEIC/AVIF to JXL often makes it **larger** and loses a little more quality. Don't re-run the whole batch. Lossless output is often larger than the lossy alternative and can exceed the source for already-tight PNGs; read `saved_pct`/`kept_source` rather than promising savings.

### compress JSON response

Success (after a real run):

```json
{
  "tool": "compress",
  "isError": false,
  "version": "<protocol-version>",
  "data": {
    "results": [
      {
        "id": "UUID",
        "input": "/path/to/in.png",
        "output": "/path/to/out.png",
        "file_name": "in.png",
        "input_bytes": 123456,
        "output_bytes": 56789,
        "saved_pct": 54,
        "state": "success",          // or "kept_source" | "failed" | other
        "started_at": "2026-05-08T10:00:00Z"
      }
    ],
    "completed_count": 1,
    "skipped_count": 0,             // 0.4.0
    "total_urls": 1,
    "option": { "level": 3, "output_format": "webp", "overwrite": false,
                "add_suffix": true, "suffix": "-min", "...": "..." }
  }
}
```

`data.option` (0.2.0) echoes the fully resolved option the run actually used —
check `option.overwrite` to know whether a conversion deleted its sources.

`state` values (inspect each result, not just top-level `isError`):
- `success` — compressed, output file written.
- `kept_source` — compressed result was larger than the input, so the original was kept.
- `skipped` — JXL lossless mode declined an already-lossy source; no output was written and the source is untouched. The row carries `skip_reason` (stable machine code: `lossy_jxl` \| `jpeg_reconstructed_jxl` \| `lossy_source`) and `skip_detail` (English explanation, not localized). `data.skipped_count` totals them.
- `failed`, `cancelled`, `quota_exceeded` — incomplete or failed output; surface the result's `error` text when present. Do not label unknown states as success.

Dry run:

```json
{
  "tool": "compress", "isError": false,
  "data": {
    "plan": {
      "urls": ["/p/a.png", "/p/b.jpg"],
      "option": { "level": 3, "output_format": "webp", "width": 1920, "height": 0,
                  "keep_aspect_ratio": true, "location": "custom",
                  "output_directory": "/Users/.../out", "...": "..." }
    }
  }
}
```

## Subcommand: `preset`

```
zipic preset <subcommand> [args]
```

| Subcommand                                              | Arguments                                       |
| ------------------------------------------------------- | ----------------------------------------------- |
| `list`                                                  | — Lists all presets.                            |
| `show <name-or-id>`                                     | Show one preset including resolved options.     |
| `create --name <text> [compress flags]`                 | Create a preset from current options + overrides. Free users limited to 1 custom preset (returns `pro_required`). |
| `delete <name-or-id>`                                   | Delete a custom preset (default cannot be deleted — returns `not_allowed`). |
| `duplicate <name-or-id>`                                | Clone an existing preset.                       |
| `set-favorite <name-or-id> [--off]`                     | Toggle favorite flag; `--off` forces unfavorite. |
| `set-default <name-or-id>`                              | Select the *active* preset — the baseline a flag-less `compress` inherits. Does not move the seeded `is_default` badge. Returns `not_implemented` on Zipic 1.9.5 (CLI 0.1.0). |
| `import <file>`                                         | Import preset JSON; auto-renames on name collision (`<name> (Imported)`, `(Imported 2)`, …). |
| `export <name-or-id> --output <file>`                   | Export to JSON.                                 |

`create` accepts the same `--level/--format/--width/--height/--scale/--suffix/--subfolder/--output/--location` flags as `compress`, plus the boolean pairs `--keep-aspect/--no-keep-aspect`, `--overwrite/--no-overwrite`, `--progressive/--no-progressive`, `--add-suffix/--no-suffix`, `--add-subfolder/--no-subfolder` (negative forms need 0.2.0), and `--jxl-lossless/--no-jxl-lossless` where `--help` lists it (`monitor add/set` accept it too). They're baked into the preset; unspecified values inherit from the GUI's current settings. Current Windows rejects `--preserve-metadata/--no-metadata` here because metadata retention is global, not stored in presets; use it only on `compress` for a one-run override.

### preset JSON response

`preset list`:

```json
{ "tool": "preset.list", "isError": false, "data": { "presets": [
  { "id": "UUID", "name": "Default", "is_default": true, "is_favorite": false,
    "created_at": "ISO8601", "last_modified": "ISO8601",
    "option": { "level": 3, "output_format": "original", "...": "..." } }
]}}
```

`preset show / create / duplicate / import` return `data.preset = { ... }` with the same shape as a list entry.

`preset delete` returns `data: { "deleted": true, "name": "...", "id": "UUID" }`.

`preset set-favorite` returns the updated preset.

`preset export` returns `data: { "path": "/abs/out.json" }`.

## Subcommand: `list`

Reflects the GUI's current compression list, deduplicated by source path (re-compressing replaces the previous entry — it's a snapshot, not an append-only log).

```
zipic list [--limit N] [--status all|success|failed|skipped]
zipic list clear
```

| Flag             | Type | Default | Notes                                |
| ---------------- | ---- | ------- | ------------------------------------ |
| `--limit <N>`    | int  | 0 (all) | Cap the returned items.              |
| `--status <v>`   | enum | `all`   | Filter by `success` / `failed` / `skipped` (`skipped` needs 0.4.0; older CLIs exit 64). |

`list` JSON:

```json
{ "tool": "list", "isError": false, "data": {
  "items": [
    { "id": "UUID", "input": "/p/a.png", "output": "/p/a-min.png",
      "file_name": "a.png", "input_bytes": 100, "output_bytes": 60,
      "saved_pct": 40, "state": "success", "started_at": "ISO8601" }
  ],
  "summary": { "count": 1, "skipped": 0, "storage_saved_bytes": 40, "total": 1 }
}}
```

`list clear` returns `data: { "cleared": true }`.

## Error response shape

```json
{ "tool": "<tool>", "isError": true, "version": "<v>",
  "error": { "code": "<code>", "message": "<human readable>", "data": { ... optional ... } } }
```

Common `error.code` values:

| Code                | Meaning                                           |
| ------------------- | ------------------------------------------------- |
| `invalid_arguments` | Missing/invalid argument. Exit 64.                |
| `not_found`         | Preset / file not found. Exit 1.                  |
| `not_allowed`       | E.g. trying to delete the default preset. Exit 1. |
| `not_implemented`   | E.g. `preset set-default` on Zipic 1.9.5 (CLI 0.1.0). Exit 1. |
| `internal_error`    | Unexpected. Exit 1.                               |
| `gui_not_running`   | Auto-launch failed. Exit 65.                      |
| `io_error`          | Socket / IO problem. Exit 1.                      |
| `pro_required`      | Free-tier gate hit. Exit 1.                       |

### Pro-gate (`pro_required`) shape

```json
{ "isError": true, "error": {
  "code": "pro_required",
  "message": "Converting to AVIF is a Pro-only feature. Upgrade to Pro to enable it.",
  "data": {
    "purchase_url": "https://...",
    "trial_available": true,
    "trial_issue_url": "https://trial.zipic.app/issue",
    "blocked_format": "AVIF",       // when format-related
    "direction": "output",          // "output" or "input"
    "blocked_input": "/p/x.svg",    // when input-format-related
    "remaining": 3,                 // when quota-related
    "requested": 12                 //
  }
}}
```

Triggers:
- `--format avif` or `--format jxl` while not activated → `direction: "output"`.
- Input file is SVG / APNG / animated PNG / AVIF / TIFF / ICNS / JXL while not activated → `direction: "input"`.
- Free-tier daily quota exceeded → `remaining` / `requested` populated.
- `preset create` while user already has 1 custom preset → quota-style payload.

## CLI vs URL Scheme matrix

| Capability                              | CLI | URL Scheme |
| --------------------------------------- | --- | ---------- |
| Per-file structured results (sizes, %)  | ✅  | ❌         |
| Exit code / `isError`                   | ✅  | ❌         |
| Dry run                                 | ✅  | ❌         |
| Presets (list/show/create/delete/...)   | ✅  | ❌         |
| Compression history (`list`)            | ✅  | ❌         |
| Pro gate as structured error            | ✅  | (silent / GUI alert) |
| Auto-launch Zipic.app                   | ✅  | (LaunchServices) |
| Path encoding required                  | ❌  | ✅ (`urllib.parse.quote`) |
| Available on Zipic < 1.9.5              | ❌  | ✅         |

When in doubt, prefer CLI. Fall back to URL Scheme only when `app_version < 1.9.5` or `command -v zipic` is empty.
