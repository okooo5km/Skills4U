# Zipic on Windows

Use the installed **packaged** Zipic app and its native CLI. No Bash, Python, Node.js or .NET SDK is required. The package requires Windows 10 build 19041 or later, or Windows 11. Check the installed package architecture; do not infer full ARM64 engine availability from the project's ARM64 build target.

## Discover and recover the CLI

From the actual skill location, in PowerShell 5.1 or 7:

```powershell
$skillDir = 'C:\path\to\skills\zipic' # Replace with the loaded skill directory.
$detected = (& (Join-Path $skillDir 'scripts\detect.ps1')) | ConvertFrom-Json
$detected
```

The detector checks the current user's `640355km.Zipic` package and prefers its scoped alias at `$env:LOCALAPPDATA\Microsoft\WindowsApps\<PackageFamilyName>\zipic.exe`. It then falls back to `Get-Command zipic.exe` and the global WindowsApps alias. It runs `--version` without launching the GUI or changing settings. `running` is informational; `route=cli` verifies the executable, not a working GUI connection.

This order matters when development and production packages coexist: the global `zipic.exe` alias can belong to an old development package, so `--version` works while auto-launch opens the wrong GUI. Use the installed package's scoped alias when present; do not rewrite aliases, unregister packages or reset application data to resolve that conflict.

| Route | Next action |
| --- | --- |
| `cli` | Set `$exe = $detected.cli`; invoke `& $exe --version`, then the requested JSON command. |
| `enable_alias` | Zipic is installed but the alias is missing. Search Windows Settings for “App execution aliases” and enable Zipic's `zipic.exe`; open a fresh terminal and detect again. |
| `repair_cli` | An executable was found but its version probe failed. Read `diagnostic`, check the alias/package and open Zipic from Start. Do not treat an existing alias file as proof the CLI runs. |
| `halt_no_app` | Install Zipic from [the official Windows download page](https://zipic.app/download/) in the user account that will run it, then detect again. |
| `cli_unavailable` | Package discovery failed and no CLI was found. Read `diagnostic`; confirm the execution account/session and package installation before concluding the app is absent. |
| `halt_unsupported_platform` | This detector is for native Windows. Use the macOS detector or the WSL bridge below. |

If PATH has not refreshed, invoke the resolved alias directly with `& $exe`. No macOS “Install zipic CLI” menu or Homebrew command applies. **Do not run the GUI's `Zipic.exe` with CLI arguments**, or copy executables out of the MSIX package: the registered `zipic.exe` alias targets `ZipicCli.exe` with package identity.

If the host blocks `.ps1` execution, inspect the script and perform its read-only checks inline, or follow the host's permitted script mechanism. Do not change execution policy globally just to run detection.

## Invoke, decode and verify

Quote Windows paths and use argument arrays; use no Bash `\` continuations, CMD `%LOCALAPPDATA%` or literal POSIX paths. Do not assign to PowerShell's reserved `$input` or `$HOME` variables.

```powershell
$exe = $detected.cli
if ($detected.route -ne 'cli') { throw "Resolve Zipic first: $($detected.route)" }
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$sourcePath = 'C:\Images\产品 photo.png'
$outDir = Join-Path $env:TEMP 'zipic-output'
$zipicArgs = @('compress', '--json', '--level', '3', '--format', 'webp', '--no-overwrite', '--output', $outDir, $sourcePath)
$stdout = & $exe @zipicArgs
$exitCode = $LASTEXITCODE # Capture before running any other native command.
if ($exitCode -eq 64) { throw 'Invalid CLI arguments; read stderr and correct the command.' }
if (-not $stdout) { throw "Zipic returned no JSON (exit $exitCode); inspect stderr." }
$response = ($stdout -join "`n") | ConvertFrom-Json
if ($exitCode -ne 0 -or $response.isError) {
    $response.error | ConvertTo-Json -Depth 10
    throw "Zipic failed (exit $exitCode)."
}
$response.data.results | Select-Object input, output, state, output_bytes, saved_pct, error
foreach ($row in $response.data.results) {
    if ($row.state -eq 'success' -and -not (Test-Path -LiteralPath $row.output)) {
        throw "Reported output is missing: $($row.output)"
    }
}
```

The CLI writes UTF-8 stdout; set the PowerShell console decoder before capturing Chinese paths. Keep stderr separate (do not merge `2>&1` into the JSON). `$ErrorActionPreference='Stop'` alone is not a substitute for checking native `$LASTEXITCODE`. Local usage errors can return exit 64 with **only stderr**, even with `--json`.

Exit 0 and `isError=false` mean the request completed. Inspect every result: `success`, `kept_source` and `skipped` are different outcomes; `failed`, `cancelled` and `quota_exceeded` must be surfaced. A failed result can include `error` (for example a missing codec). Verify output paths/sizes and source preservation before claiming success. `completed_count` counts finished inputs, not successful outputs.

`--dry-run` uses the same arguments and returns `data.plan`; check its paths and effective `option.overwrite` before conversion. Use a separate output directory and `--no-overwrite` unless source replacement was requested. Do not re-run a whole batch when only some rows failed.

For UTF-8 JSON files, capture stdout then use `Set-Content -LiteralPath $jsonPath -Value ($stdout -join "`n") -Encoding UTF8`. PowerShell 5.1's bare `>` can produce UTF-16. For preset/config export, prefer the CLI's own export command. If a `.ps1` contains Chinese text and must run in PowerShell 5.1, save the script itself as UTF-8 with BOM; the bundled detector uses that encoding.

## GUI and session requirements

The CLI contacts `\\.\pipe\Zipic.Cli.<Windows-user-SID>`, automatically opens the packaged GUI and waits about 8 seconds. It is a client of the desktop app, not a headless compressor.

After exit 65 / `gui_not_running`, check which package owns the executable alias, then open the intended installed Zipic **in the same user's interactive desktop**, let startup finish, and retry once. A read-only package lookup can resolve its Start entry without guessing an obsolete package ID:

```powershell
$package = Get-AppxPackage -Name '640355km.Zipic'
if (-not $package) { throw 'Installed Zipic package was not found.' }
Start-Process explorer.exe -ArgumentList "shell:AppsFolder\$($package.PackageFamilyName)!App"
```

SSH, services and scheduled jobs without an interactive desktop can fail GUI auto-launch even though `--version` succeeds. A remote agent must verify a real JSON command in the intended session before reporting readiness. Do not repeatedly relaunch, elevate, reset application data or alter licenses to repair a connection.

## Platform differences

- `--specified` and `--no-specified` return exit 64 on Windows. Use `--output <directory>`.
- Windows supports ICO; genuine `.icns` input is unsupported. SVG remains SVG; do not pass `--format` for SVG optimization.
- HEIC uses Windows system codecs; HEIF Image Extensions and HEVC Video Extensions may be needed. Report the per-file failure and follow Zipic's codec-install guidance rather than declaring all HEIC inputs/outputs available.
- `monitor --max-depth` uses **0–5** on Windows: 0 means root only, 1 includes direct child folders. Do not transfer the macOS depth scale.
- `preset create/update` and `monitor add/set` reject global-only flags `--preserve-metadata/--no-metadata`, `--skip-optimized/--no-skip-optimized` and `--jpeg-background`. They can be one-run `compress` overrides; persistent changes use `config set` only when requested.
- Raycast, App Intents/Siri, Apple Shortcuts and iCloud integration are macOS features. Do not recommend them as Windows steps.
- Windows URL Scheme differs from macOS (notably `ratio`); read [url-scheme.md](url-scheme.md) before using it. The CLI provides reliable result inspection and should remain the first route.

## WSL bridge

WSL does not run a Linux Zipic GUI. With Windows interop enabled, bridge to the Windows app using a native Windows process and paths:

```bash
source_win=$(wslpath -w '/mnt/c/Images/product photo.png')
output_win=$(wslpath -w '/mnt/c/Images/zipic-output')
# powershell.exe may also be invoked by its /mnt/c/... absolute path if not on PATH.
windows_command='
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$exe = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\zipic.exe"
$package = Get-AppxPackage -Name "640355km.Zipic"
if ($package) {
    $candidate = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\$($package.PackageFamilyName)\zipic.exe"
    if (Test-Path -LiteralPath $candidate) { $exe = $candidate }
}
& $exe compress --json --no-overwrite --format webp --output $env:ZIPIC_OUTPUT $env:ZIPIC_SOURCE
exit $LASTEXITCODE
'
ZIPIC_SOURCE="$source_win" ZIPIC_OUTPUT="$output_win" WSLENV="${WSLENV:+$WSLENV:}ZIPIC_SOURCE:ZIPIC_OUTPUT" powershell.exe -NoProfile -NonInteractive -Command "$windows_command"
exit_code=$?
```

Capture stdout/stderr separately, preserve the bridge exit code and parse UTF-8 JSON. `WSLENV` forwards these two path values as process environment variables, rather than inserting paths into PowerShell source text. Prefer input/output files on Windows-mounted drives (`/mnt/c/...`). Files in WSL's Linux filesystem convert to UNC paths; do not assume the GUI/codec pipeline supports them—copy an authorized working file to a Windows-accessible directory if needed. Without interop or an accessible Windows desktop, this route is unavailable. This bridge guidance was not exercised in the Windows hardware check for this change.

## Sources

The Windows contract is grounded in Zipic-Windows `Package.appxmanifest`, `ZipicCli/Program.cs`, `Help.cs`, `GuiLauncher.cs`, `WindowsOnlyFlagGuards.cs`, `ResponseHandling.cs`, `Services/Cli/CliToolRouter.cs` and `Services/Protocol/ZipicCompressRequest.cs`. CLI and app versions are independent; probe `--version` and `--help` rather than inferring supported flags from the marketing version.

Execution guidance follows [PowerShell encoding](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding) and [native exit-code variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables#lastexitcode). Environment requirements use the [Agent Skills compatibility field](https://agentskills.io/specification#compatibility-field).
