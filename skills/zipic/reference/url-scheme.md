# Zipic URL Scheme Reference

Fallback path for macOS Zipic < 1.9.5 or hosts where the `zipic` CLI is unavailable. Windows supports the scheme too, but repair its packaged execution alias first. Fire-and-forget — there is no result data, compression exit code or structured error. Never switch to URL Scheme to bypass a CLI `pro_required` error.

## Format

```
zipic://compress?key=value&key=value&...
```

Invoke with `open` on macOS:

```bash
open "zipic://compress?url=/path/to/image.png&level=3"
```

Multiple files use repeated `url=` parameters:

```bash
open "zipic://compress?url=/p/a.png&url=/p/b.jpg&level=3"
```

Folders can be passed directly — Zipic walks them recursively.

## Windows invocation

In PowerShell, percent-encode the entire Windows path, including backslashes, spaces and Chinese characters. Use a distinct output directory; verify actual files after launch.

```powershell
$sourcePath = 'C:\Images\产品 photo.png'
$outDir = Join-Path $env:TEMP 'zipic-url-output'
if (-not (Test-Path -LiteralPath $sourcePath)) { throw 'Input is missing.' }
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$sourceEncoded = [Uri]::EscapeDataString($sourcePath)
$outputEncoded = [Uri]::EscapeDataString($outDir)
$uri = "zipic://compress?url=$sourceEncoded&level=3&format=webp&overwrite=false&location=custom&directory=$outputEncoded"
Start-Process -FilePath $uri
# After Zipic finishes, inspect output files; Start-Process does not return the result.
Get-ChildItem -LiteralPath $outDir -File
```

Windows accepts output formats `original/jpeg/png/webp/avif/heic/jxl`; do not copy the broader macOS scheme list below. On Windows `ratio=1..99` means **percentage scaling**, not an aspect-ratio boolean; use `width`/`height` for target dimensions or `longestSide` for a no-enlargement long-edge cap. `specified` has no Windows setting. Free Windows users may have unsupported option overrides silently downgraded by this scheme; inspect the actual output instead of assuming every requested option took effect.

## Parameters

| Parameter      | Type / Values                                                | Default | Notes |
| -------------- | ------------------------------------------------------------ | ------- | ----- |
| `url`          | path string (repeatable)                                     | —       | File or folder. URL-encode (`%20` for spaces, percent-encode CJK). At least one `url` or `data` required. |
| `data`         | URL-encoded JSON: `{"urls":["/p/a.png","/p/b.jpg"]}`         | —       | Alternative to repeated `url=`. Each entry must be an existing file/dir; non-image files and app bundles are silently skipped. |
| `level`        | int 1–6                                                      | current setting | Compression level. |
| `format`       | `jpeg\|png\|webp\|heic\|avif\|gif\|tiff\|icns\|pdf\|jxl`     | keep original | Output format. **Not** a valid value: `svg` — SVG inputs are optimized in-place and stay SVG. AVIF/JXL require Pro. |
| `width`        | int (pixels)                                                 | 0 (auto) |  |
| `height`       | int (pixels)                                                 | 0 (auto) |  |
| `ratio`        | macOS: bool (`true`/`false`); Windows: int 1–99                | platform-dependent | macOS: keep aspect ratio; Windows: percentage scaling. |
| `directory`    | absolute path string                                         | —       | Output directory (use with `location=custom`). |
| `location`     | `original\|custom`                                           | inherited | `original` = save next to input; `custom` = use `directory`. |
| `overwrite`    | bool                                                         | inherited | Can delete the source after conversion at the same directory/base name. Use `false` and a separate output directory to preserve sources. |
| `addSuffix`    | bool                                                         | inherited | Toggle suffix usage. |
| `suffix`       | string                                                       | inherited | Filename suffix. |
| `addSubfolder` | bool                                                         | inherited | Toggle subfolder usage. |
| `subfolder`    | string                                                       | inherited | Subfolder name under destination. |
| `specified`    | bool                                                         | false   | macOS only. Windows has no corresponding setting; use `location=custom&directory=...`. |
| `progressive`  | bool                                                         | inherited | Progressive JPEG. |
| `jxlLossless`  | bool                                                         | inherited | JPEG XL lossless mode (newer builds; `jxl-lossless` also accepted). Lossy sources are skipped and kept, with no result reported back — prefer the CLI to see `skip_reason`. |

Anything Zipic doesn't recognize is ignored. Bool values must be the literals `true` or `false`.

## macOS path encoding

Required for spaces and non-ASCII (CJK, accents, etc.). The CLI does NOT need this; URL Scheme does.

```bash
encoded=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe='/'))" "$path")
open "zipic://compress?url=${encoded}&level=3"
```

Batch:

```bash
params=""
for f in /path/to/folder/*.{png,jpg,jpeg,webp}; do
  encoded=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe='/'))" "$f")
  params="${params}&url=${encoded}"
done
open "zipic://compress?${params:1}&level=3&format=webp"
```

`safe='/'` keeps the path separator unencoded; everything else (spaces, `?`, CJK, etc.) gets percent-encoded.

## macOS examples

```bash
# 1. Compress one file at level 3, keep format
open "zipic://compress?url=/path/to/image.png&level=3"

# 2. Batch, repeated url=
open "zipic://compress?url=/p/a.png&url=/p/b.jpg&url=/p/c.jpeg&level=3"

# 3. Convert to WebP (good for web)
open "zipic://compress?url=/p/photo.png&format=webp&level=3"

# 4. Resize to 1920px wide, keep aspect, save to custom dir
open "zipic://compress?url=/p/photo.png&width=1920&ratio=true&level=3&location=custom&directory=/Users/me/out"
```

## Limitations vs CLI

- ❌ No structured response (no per-file output paths or sizes).
- ❌ No exit code; failures are silent. Pre-check `[ -e "$path" ]` and that Zipic is installed.
- ❌ No preset access. No history queries.
- ❌ No dry-run.
- ❌ Pro-gate hits surface as a GUI alert / silent skip, not as parseable output.
- ✅ Available before the macOS CLI (SVG requires macOS Zipic >= 1.9.0), and in packaged Windows Zipic.

For any task where you need to know whether compression succeeded, by how much, or for which files — use the CLI.
