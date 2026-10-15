# Zipic CLI Reference

Shared CLI contract for macOS and Windows. macOS Zipic.app >= 1.9.5 uses a UDS socket at `~/Library/Application Support/studio.5km.zipic/cli.sock`. Windows packaged Zipic exposes `zipic.exe` (target: `ZipicCli.exe`) and uses `\\.\pipe\Zipic.Cli.<Windows-user-SID>`. Both auto-launch the GUI and wait for it. For Windows setup, PowerShell/UTF-8 handling, desktop-session requirements and differences, read [windows.md](windows.md).

## Versions

**This section is the only place CLI version numbers are recorded.** Everything else in the skill describes the current contract and points here. One CLI version means one contract on macOS and Windows; a row applies to whichever platform reports that version. The CLI version is independent of the app version: never infer a flag from the app's marketing version.

How to gate, in order:

1. **A flag** — check that the top-level `zipic --help` lists it (e.g. the text contains `max-size`). This works on every version and is the rule to use for any flag. Never probe with `zipic <command> --help`: before 0.5.1 that form errors without a file, and with a file it **runs the command**.
2. **A behavior that help can't show** (strictness, `saved_pct` on non-success rows, launch wait) — read `zipic --version` and use the table.

| Since | Adds or changes | On an older CLI |
| ----- | --------------- | --------------- |
| 0.1.0 | First macOS CLI: `compress`, `preset`, `list`. | — |
| 0.2.0 | `--no-overwrite`, `--no-progressive`, `--no-keep-hierarchy` and the explicit `--<flag>=true\|false` form; `--keep-hierarchy`, `--tiff-compression`, `--autocopy` take effect; `--suffix`/`--subfolder` imply their toggles; invalid values exit 64; `data.option` echo on real runs; `preset set-default`. | `--overwrite` has no off switch (`--no-overwrite` is unknown and swallows the next argument; `=false` is dropped) — keep sources with a separate `--output` directory. The three flags are accepted but dead. `preset set-default` returns `not_implemented`. |
| 0.3.0 | `config` and `monitor` command families. Earliest CLI seen on Windows. | Commands absent. |
| 0.4.0 | JXL lossless: `--jxl-lossless` / `--no-jxl-lossless`, `skip_reason` / `skip_detail`, `data.skipped_count`, `list --status skipped`. | Bare `--jxl-lossless` swallows the next argument; `--jxl-lossless=true` is ignored and yields a lossy JXL. `list --status skipped` exits 64. |
| 0.5.0 | Max file size: `--max-size` / `--no-max-size`, `--keep-dimensions` / `--no-keep-dimensions`, `max_size_met`. | `--max-size 500KB` is dropped without an error (no cap applied); the bare booleans swallow the next argument. |
| 0.5.1 | Strict flags: an unknown flag, a value flag without its value, or a value on a boolean-only flag (`--json=1`, `--off=false`) exits 64 naming the flag, and nothing reaches the app; `--dry-run` is accepted only by `compress` and `config import`. `--help`/`-h` anywhere after a command prints help and exits 0. `saved_pct` is real only on `success` rows, 0 elsewhere. Rows that wrote nothing (`failed`, both kinds of `skipped`) carry `output: ""` and `output_bytes: 0`. An already-optimized or 0-byte file returns a `skipped` row on both platforms (it never enters `zipic list`); a file that is not a decodable image returns `failed`. `completed_count` counts successful primary outputs only. GUI launch wait raised to 30 s. | Unknown flags pass silently and may swallow the next argument (`compress --lossless a.png b.jpg` processes only `b.jpg`, exit 0). `compress --help` exits 64 and `compress <file> --help` compresses the file. Windows `failed`/`skipped` rows report `output_bytes: 0, saved_pct: 100`. macOS puts the **source path** in `output` of a JXL-lossless `skipped` row and returns no row at all for an already-optimized file. Windows counts every primary row in `completed_count`, reports a corrupt PNG as `skipped`, and can copy a corrupt or 0-byte file into the output directory unchanged — on that CLI a file existing at the output path does not prove it was compressed. Launch wait is about 8 s — a cold start can exit 65 while the GUI still comes up; retry once. |
| 0.6.0 | PDF → images: `--pdf-to-image` / `--no-pdf-to-image`, `--pdf-dpi 72\|150\|300`, per-page result rows (`page`, `page_count`), dry-run `plan.pdf_pages`, `config` keys `PDF-Rasterize-Enabled` / `PDF-Rasterize-DPI`. PDF **input** is Pro: a free user's PDF returns `pro_required` (`blocked_format: "PDF"`, `direction: "input"`). | No way to rasterize PDF pages: a PDF is always compressed as a PDF, whatever `--format` says, and the flags are unknown (exit 64 on a 0.5.1 CLI). A free user's PDF was compressed without a gate. Not on Windows yet — gate on help. |

The CLI ships inside the app and has no upgrade path of its own: when a gate fails, or `zipic --version` is behind the last row, the fix is to update Zipic — on macOS through the app's update check or a fresh download from https://zipic.app (the `/usr/local/bin/zipic` symlink follows the app, no reinstall), on Windows through the Microsoft Store. Say that instead of working around a missing flag.

A build may carry a flag before its version number moves (pre-release builds did), which is why flags are gated on help text rather than on the number. Do not apply the 0.1.0 limitations to Windows. Platform differences that are not version-related (`--specified`, monitor depth scale, global-only flags on preset/monitor) are in the Windows reference.

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
| `--version`  | Print CLI version (`zipic <x.y.z>`) and exit.        |
| `--help`     | Print built-in help and exit. Use this top-level form to probe flags. |

## Exit codes

| Code | Constant          | Meaning                                                  |
| ---- | ----------------- | -------------------------------------------------------- |
| 0    | success           | Request completed; still inspect every per-file state.    |
| 1    | businessError     | Runtime/business failure (e.g. `pro_required`, `not_found`, `internal_error`). |
| 64   | usageError        | Invalid arguments (bad flag, wrong enum, missing required value). |
| 65   | guiNotRunning     | Couldn't reach the Zipic GUI socket/pipe and auto-launch failed. |

Capture stdout and stderr separately. Local argument errors may emit only stderr even with `--json`; capture the native exit code before attempting JSON parsing. A successful response can contain failed/cancelled/quota-exceeded rows; `completed_count` counts successful primary outputs only (`success` and `kept_source`); `failed`, `skipped` and extra-output rows are not in it. An older Windows CLI counts every primary row ([Versions](#versions)), so still read each row's `state`.

## Subcommand: `compress`

```
zipic compress [flags] <files-or-dirs>...
```

Positional args are files or directories. Directories are walked recursively for image files.

### compress flags

Every flag not given on the command line **inherits** from `--preset`, or, without it, from the GUI's currently *active* preset / current settings. There are no fixed CLI defaults. Boolean pairs also accept the explicit form `--<flag>=true|false`. Older CLIs lack some flags below — see [Versions](#versions).

| Flag                                              | Type                                       | Default          | Notes |
| ------------------------------------------------- | ------------------------------------------ | ---------------- | ----- |
| `--level <1-6>`                                   | int 1–6                                    | inherited        | 1 = best quality, 6 = smallest. |
| `--format <value>`                                | `original\|jpeg\|png\|webp\|avif\|heic\|jxl` | inherited       | `avif` and `jxl` are Pro-only output formats; gated server-side. SVG is **not** an output value (SVG inputs stay SVG). |
| `--width <px>`                                    | int                                        | 0 (auto)         | 0 = no resize on this axis. Invalid values exit 64. |
| `--height <px>`                                   | int                                        | 0 (auto)         | Same as `--width`. |
| `--scale <1-99>`                                  | int                                        | —                | Percentage resize; overrides `--width`/`--height`. |
| `--keep-aspect` / `--no-keep-aspect`              | bool                                       | keep             | Lock aspect ratio when one axis is set. |
| `--preserve-metadata` / `--no-metadata`           | bool                                       | inherited        | EXIF/ICC retention. `--no-metadata` is Pro-only. |
| `--progressive` / `--no-progressive`              | bool                                       | inherited        | Progressive JPEG. |
| `--jxl-lossless` / `--no-jxl-lossless`            | bool                                       | inherited        | JPEG XL lossless mode; only acts when the output is JXL. **Probe `--help` first** — see [JXL lossless mode](#jxl-lossless-mode). |
| `--max-size <size>` / `--no-max-size`             | size                                       | inherited        | Pro. Hard cap per output file; `--no-max-size` drops an inherited cap. **Probe `--help` first** — see [Max file size](#max-file-size). |
| `--keep-dimensions` / `--no-keep-dimensions`      | bool                                       | allow scaling    | With a size cap: never scale down, only lower quality. |
| `--pdf-to-image` / `--no-pdf-to-image`            | bool                                       | GUI setting      | Pro. Turn each PDF page into an image in the `--format` target. **Probe `--help` first** — see [PDF to images](#pdf-to-images). |
| `--pdf-dpi <72\|150\|300>`                        | enum                                       | GUI setting (150) | Pro. Render resolution for PDF pages. |
| `--tiff-compression <lzw\|zip>`                   | enum                                       | inherited        | TIFF output codec. |
| `--location <original\|custom>`                   | enum                                       | inherited        | `original` = save next to input; `custom` = `--output`. Auto-set to `custom` if `--output` is given without explicit `--location`. |
| `--output <dir>`                                  | path                                       | —                | Output directory. Forces `--location custom` when set. |
| `--suffix <text>`                                 | string                                     | inherited        | Filename suffix. Implies `--add-suffix`. |
| `--add-suffix` / `--no-suffix`                    | bool                                       | inherited        | Toggle suffix usage. |
| `--subfolder <name>`                              | string                                     | inherited        | Output subfolder under destination. Implies `--add-subfolder`. |
| `--add-subfolder` / `--no-subfolder`              | bool                                       | inherited        | Toggle subfolder usage. |
| `--keep-hierarchy` / `--no-keep-hierarchy`        | bool                                       | inherited        | Mirror the source directory tree under `--output`. |
| `--overwrite` / `--no-overwrite`                  | bool                                       | inherited        | Replace-the-source on format conversion — see the contract below. |
| `--autocopy <off\|path\|file\|markdown>`          | enum                                       | inherit GUI global | An explicit value takes over from the GUI's per-file autocopy: `off` suppresses clipboard writes, the others write one aggregate entry after the run (`path` = newline-joined paths, `file` = file objects, `markdown` = `![](path)` lines). |
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

- User didn't ask to replace sources → pass `--no-overwrite` when `zipic --help`
  lists it, or use `--output <separate-dir>` — a different directory never
  triggers deletion and is safe on every CLI version.
- A CLI whose help lacks `--no-overwrite` has **no reliable off switch** — use
  the `--output` route ([Versions](#versions)).
- Verify with `--dry-run --json` → `data.plan.option.overwrite`; a real run
  echoes the same via `data.option.overwrite`.

### JXL lossless mode

Gate on `zipic --help` listing `--jxl-lossless`; passing it to a CLI without it loses an input path or silently yields a lossy JXL ([Versions](#versions)). If the probe fails, tell the user lossless JXL needs a newer Zipic instead of guessing.

The value is inherited from the active preset like every other boolean, so pass `--no-jxl-lossless` when the user explicitly wants lossy JXL. It applies when the output is JXL (`--format jxl`, or `--format original` on a JXL source) and requires Pro like any JXL output. `--level` does not trade quality in this mode. Zipic routes each input by what it actually contains:

| Source | Result |
| --- | --- |
| PNG, TIFF (uncompressed/LZW/ZIP), lossless WebP, lossless JXL | Pixel-exact JXL; 16-bit depth kept. |
| JPEG | Reversible JPEG transcode — the original JPEG can be reconstructed byte-for-byte. With resizing, or a JPEG libjxl cannot transcode, it falls back to pixel-exact encoding of the decoded image. `--no-metadata` strips EXIF/XMP/comments first but keeps ICC and orientation. |
| Lossy JXL, JPEG-reconstruction JXL, lossy WebP, HEIC, AVIF, JPEG-compressed TIFF | **Skipped**: no output written, source kept. Lossless can't recover lost detail and would only grow the file. |

A skipped row is not a failure and not a success. Nothing new was written: its `output` is `""` with `output_bytes: 0` (an older macOS CLI repeats the source path there, see [Versions](#versions)) — never treat the `output` of a non-success row as a produced file. Report it with its `skip_reason`. If the user still wants those files as JXL, re-run **only the skipped inputs** with `--no-jxl-lossless` (lossy). Warn them first: re-encoding an already-lossy WebP/HEIC/AVIF to JXL often makes it **larger** and loses a little more quality. Don't re-run the whole batch. Lossless output is often larger than the lossy alternative and can exceed the source for already-tight PNGs; read `saved_pct`/`kept_source` rather than promising savings.

### Max file size

Pro. Gate on `zipic --help` listing `--max-size`; a CLI without it drops the cap without any error ([Versions](#versions)). If the probe fails, tell the user a size cap needs a newer Zipic; don't emulate it by looping over `--level`.

**Value**: 1000-based like Finder — `500KB`, `1.5MB`, `2GB`, also `K`/`M`/`G`, case-insensitive, optional space (`"2 mb"`), decimals allowed; a bare number is bytes (`800000`). Range 1KB–10GB. `500KiB`, a bare `500` or `--max-size` together with `--no-max-size` exit 64 with a stderr-only message.

**What it does**, per output file:

1. Encodes once at `--level`. If that already fits, the result is identical to a run without the cap — the level acts as a quality ceiling, never raised to fill the budget.
2. Otherwise searches for the highest quality that fits, re-encoding a few times (AVIF and JXL get a smaller budget because each encode is slow, so they may land further under the cap).
3. If the lowest quality is still too big, **scales the image down** and retries a few rounds. The output then has smaller pixel dimensions than the source — say so in the report. `--keep-dimensions` forbids this step.

An explicit `--width`/`--height`/`--scale`/`--longest-side` is applied first; the cap then works on the resized image. Combining a resize with the cap is the predictable way to hit a small budget at a known size. PNG has little quality range, so a tight PNG cap reaches for scaling early (observed: a 2400×1600 PNG capped at 500KB came back 1007×671); prefer `--format webp`/`jpeg` or a looser cap when dimensions matter.

**Ignored** (no cap, no `max_size_met`): TIFF, PDF and SVG output, ICNS (macOS) / ICO (Windows), and JXL lossless mode. Pages from [PDF to images](#pdf-to-images) are ordinary image outputs, so the cap applies to each page.

**Result contract** — the cap never fails a file:

- A row whose format honors the cap gains `max_size_met`. `true`: `output_bytes` ≤ cap. `false`: Zipic wrote its smallest attempt, which is **over** the cap (text mode appends `[over size limit]`). It is still `state: "success"`, exit 0 and counted in `completed_count`.
- Misses happen with `--keep-dimensions`, or with caps too small for any image (1KB on a photo gave a 31×21, 3.7KB file). Report each miss with its actual `output_bytes`, then offer: allow scaling, a more compact format (WebP/AVIF), an explicit resize, or a larger cap. Do not silently retry.
- No `max_size_met` on a successful row means no cap was applied to it (ignored format, no cap in effect, or a CLI that dropped the flag) — never report that as "fits".
- `data.option` / `data.plan.option` echo `max_size` (bytes) and `keep_dimensions` only while a cap is in effect; `--dry-run` confirms the parsed value before a real run.

**Inheritance and Pro**: like every option the cap is inherited from `--preset` or the active preset, so pass `--no-max-size` when the user wants an uncapped run. A free user passing `--max-size` gets `pro_required` (`error.data.blocked_option: "max-size"`, `feature: "max_file_size"`); a cap merely inherited from a preset is ignored for free users without an error. `preset create/update` and `monitor add/set` take the same four flags; `preset update --no-max-size` clears a saved cap. The GUI-wide default lives in `config` keys `Compression-MaxFileSize` (bytes or `500KB`), `Compression-MaxFileSize-Enabled` and `Compression-MaxFileSize-KeepDimensions` — change them only when the user asks for a persistent default.

```bash
# Hard cap, sources kept; check max_size_met per row
zipic compress --json --format webp --max-size 500KB --no-overwrite --output /tmp/out/ /path/photo.png

# Must keep pixel dimensions: quality only, may miss the cap
zipic compress --json --max-size 200KB --keep-dimensions --no-overwrite --output /tmp/out/ /path/photo.jpg
```

### PDF to images

Pro. Gate on `zipic --help` listing `--pdf-to-image`. Without it, Zipic only compresses PDFs as PDFs ([Versions](#versions)). If the probe fails, tell the user page export needs a newer Zipic.

**When it applies:** all three of these must hold:
- conversion is on, through `--pdf-to-image` or the GUI setting `PDF-Rasterize-Enabled`;
- the input is a PDF;
- the effective `--format` is not `original`.

Otherwise the PDF is compressed as a PDF, as before. An explicit `--pdf-to-image` with `--format original` (given or inherited) returns `invalid_arguments` (exit 64). `--no-pdf-to-image` forces PDF compression for one run.

**Output.** Each page is rendered from the vector source at `--pdf-dpi`; an A4 page is 1240×1754 at the default 150 DPI. The page then goes through the normal pipeline, so `--level`, `--max-size` and `--suffix` (including `{width}`-style tokens) apply per page.
- An absolute resize (`--width` / `--height` / `--longest-side`) renders straight at that size, sharp, and may exceed the DPI size.
- `--scale` scales the DPI size.
- File names: `<name>-p01.<ext>` … `<name>-pNN.<ext>`, zero-padded to at least two digits. A single-page PDF gets `<name>.<ext>` with no page number. The suffix goes after the page number: `report-p01-min.webp`.
- The source PDF is never modified or deleted, whatever `--overwrite` says.

**All-or-nothing.** If any page fails, or the run is cancelled, no page is written and the PDF returns one `failed` row whose `error` starts with the page number. A password-protected PDF fails this way; an empty-password one converts. Zipic also refuses to overwrite a file it did not create: if a page's target name is already taken by such a file (say, the user's own `report.png` next to `report.pdf`), the row fails and nothing is written. Pages from an earlier Zipic run are replaced.

**Rows.** A converted PDF returns **one row per page**:
- `input` is the PDF, `output` / `file_name` is the page.
- `input_bytes` is the whole PDF and `output_bytes` the page, so `saved_pct` is always 0. Report the page count and sizes, not a saving.
- `page` (1-based) and `page_count` are added; `max_size_met` appears only under a cap.
- Every row's `id` is `<id>#p<N>`.
- `completed_count` counts the PDF once.
- `zipic list` shows the same page rows, and leaves them out of `storage_saved_bytes`.
- `--autocopy` copies every page.

**Dry run.** `--dry-run` adds `data.plan.pdf_pages: {"/p/report.pdf": 12}`, but only for PDFs that would be converted. Use it to warn before a large export.

**Persistent default.** `config` keys `PDF-Rasterize-Enabled` (bool) and `PDF-Rasterize-DPI` (72/150/300). Change them only when the user asks. They are global settings, not preset fields: `preset create|update` and `monitor add|set` reject the two flags with exit 64.

**Pro.** An explicit `--pdf-to-image` or `--pdf-dpi` from a free user returns `pro_required` (`feature: "pdf_to_image"` / `"pdf_dpi"`). Before that, the PDF input gate already blocks any PDF for free users.

```bash
# Export every page as WebP at 300 DPI into a separate folder
zipic compress --json --pdf-to-image --format webp --pdf-dpi 300 --no-overwrite --output /tmp/pages/ /path/report.pdf
```

```json
{ "id": "UUID#p2", "input": "/path/report.pdf", "output": "/tmp/pages/report-p02.webp",
  "file_name": "report-p02.webp", "input_bytes": 2100000, "output_bytes": 281000,
  "saved_pct": 0, "state": "success", "variant_index": 0, "page": 2, "page_count": 12,
  "started_at": "2026-10-16T10:00:00Z" }
```

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
        "max_size_met": true,        // only when a size cap applied to this row
        "started_at": "2026-05-08T10:00:00Z"
      }
    ],
    "completed_count": 1,
    "skipped_count": 0,
    "total_urls": 1,
    "option": { "level": 3, "output_format": "webp", "overwrite": false,
                "add_suffix": true, "suffix": "-min", "...": "..." }
  }
}
```

`data.option` echoes the fully resolved option the run actually used —
check `option.overwrite` to know whether a conversion deleted its sources.

`state` values (inspect each result, not just top-level `isError`):
- `success` — compressed, output file written. With a size cap, also read `max_size_met`: `false` means the file was written but is over the cap.
- `kept_source` — compressed result was larger than the input, so the original was kept.
- `skipped` — nothing was written and the source is untouched. Two kinds, told apart by `skip_reason`:
  - **with `skip_reason`** (`lossy_jxl` \| `jpeg_reconstructed_jxl` \| `lossy_source`, plus an English `skip_detail`): JXL lossless mode declined an already-lossy source.
  - **without `skip_reason`**: the file is empty (0 bytes) or already carries Zipic's "optimized with these exact settings" mark and `--skip-optimized` (default on) left it alone. Not a failure, and the JXL remedy does not apply; pass `--no-skip-optimized` only if the user really wants a recompress. An older macOS CLI produces **no row at all** for such a file ([Versions](#versions)).
  - `data.skipped_count` totals both kinds. Only the first kind appears in `zipic list --status skipped`; an already-optimized skip exists only in the `compress` result.
- `failed`, `cancelled`, `quota_exceeded` — incomplete or failed output; surface the result's `error` text when present. Do not label unknown states as success.

Reading the totals:

- **Report `saved_pct` only for `success` rows.** On other states the value is not meaningful ([Versions](#versions)).
- `total_urls` counts the path arguments you passed, not files: one directory holding 24 images returns `completed_count: 24, total_urls: 1`. Never use it as a denominator.
- **Empty `results` with exit 0 is not "done".** A path with nothing Zipic can process (empty directory, non-image file) returns `results: []` and no error, and so does an in-place run on an older macOS CLI whose files were all already optimized (current CLIs return `skipped` rows instead). Tell the user nothing was processed and why that may be; compare the rows you got against the files you expected.
- The already-optimized mark is written on the **output** file, so that skip only shows up when overwriting in place (`--no-suffix --no-subfolder --location original`) or when a previous output is fed back in.

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
| `set-default <name-or-id>`                              | Select the *active* preset — the baseline a flag-less `compress` inherits. Does not move the seeded `is_default` badge. |
| `import <file>`                                         | Import preset JSON; auto-renames on name collision (`<name> (Imported)`, `(Imported 2)`, …). |
| `export <name-or-id> --output <file>`                   | Export to JSON.                                 |

`create` accepts the same `--level/--format/--width/--height/--scale/--suffix/--subfolder/--output/--location/--max-size` flags as `compress`, plus the boolean pairs `--keep-aspect/--no-keep-aspect`, `--overwrite/--no-overwrite`, `--progressive/--no-progressive`, `--add-suffix/--no-suffix`, `--add-subfolder/--no-subfolder`, and `--jxl-lossless/--no-jxl-lossless`, `--keep-dimensions/--no-keep-dimensions` and `--no-max-size` where `--help` lists them (`monitor add/set` accept them too). They're baked into the preset; unspecified values inherit from the GUI's current settings. Current Windows rejects `--preserve-metadata/--no-metadata` here because metadata retention is global, not stored in presets; use it only on `compress` for a one-run override.

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
| `--status <v>`   | enum | `all`   | Filter by `success` / `failed` / `skipped` (`skipped`: see [Versions](#versions)). |

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
| `not_implemented`   | A command this CLI generation lacks, e.g. `preset set-default` on the first macOS CLI. Exit 1. |
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
- Input file is SVG / APNG / animated PNG / AVIF / TIFF / ICNS / JXL / PDF while not activated → `direction: "input"` (PDF gated from CLI 0.6.0, see [Versions](#versions)).
- Explicit `--pdf-to-image` / `--pdf-dpi` while not activated → `feature: "pdf_to_image"` / `"pdf_dpi"`.
- Free-tier daily quota exceeded → `remaining` / `requested` populated.
- `preset create` while user already has 1 custom preset → quota-style payload.
- Explicit `--max-size` on `compress` / `preset create` / `preset update` while not activated → `blocked_option: "max-size"`, `feature: "max_file_size"`.

## CLI vs URL Scheme matrix

| Capability                              | CLI | URL Scheme |
| --------------------------------------- | --- | ---------- |
| Per-file structured results (sizes, %)  | ✅  | ❌         |
| Exit code / `isError`                   | ✅  | ❌         |
| Dry run                                 | ✅  | ❌         |
| Size cap with `max_size_met` per file   | ✅  | cap only, no result (macOS) |
| PDF pages to images, per-page rows      | ✅  | export only, no result (macOS) |
| Presets (list/show/create/delete/...)   | ✅  | ❌         |
| Compression history (`list`)            | ✅  | ❌         |
| Pro gate as structured error            | ✅  | (silent / GUI alert) |
| Auto-launch Zipic.app                   | ✅  | (LaunchServices) |
| Path encoding required                  | ❌  | ✅ (`urllib.parse.quote`) |
| Available on Zipic < 1.9.5              | ❌  | ✅         |

When in doubt, prefer CLI. Fall back to URL Scheme only when `app_version < 1.9.5` or `command -v zipic` is empty.
