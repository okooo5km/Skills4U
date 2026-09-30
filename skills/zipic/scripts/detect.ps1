# Created by okooo5km(十里).
# Read-only detection for native Windows PowerShell 5.1 / PowerShell 7.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$result = [ordered]@{
    os = [Environment]::OSVersion.VersionString
    architecture = $env:PROCESSOR_ARCHITECTURE
    shell_version = $PSVersionTable.PSVersion.ToString()
    app_path = $null
    app_version = $null
    cli = $null
    cli_version = $null
    cli_supported = $false
    running = $false
    route = 'halt_unsupported_platform'
    diagnostic = $null
}
if ($env:PROCESSOR_ARCHITEW6432) {
    $result.architecture = $env:PROCESSOR_ARCHITEW6432
}
if ($env:OS -ne 'Windows_NT') {
    $result | ConvertTo-Json -Compress
    return
}

$packageChecked = $false
$package = $null
try {
    $packages = @(Get-AppxPackage -Name '640355km.Zipic' -ErrorAction Stop)
    $packageChecked = $true
    $package = $packages | Sort-Object Version -Descending | Select-Object -First 1
    if ($package) {
        $result.app_path = $package.InstallLocation
        $result.app_version = $package.Version.ToString()
    }
} catch {
    $result.diagnostic = 'Package discovery unavailable: ' + $_.Exception.Message
}
$result.running = @(Get-Process -Name Zipic -ErrorAction SilentlyContinue).Count -gt 0

$candidate = $null
# Prefer the registered package's scoped alias: a development package can own
# the global zipic.exe alias while the production package is also installed.
if ($package -and $env:LOCALAPPDATA) {
    $scopedAlias = Join-Path $env:LOCALAPPDATA ('Microsoft\WindowsApps\' + $package.PackageFamilyName + '\zipic.exe')
    if (Test-Path -LiteralPath $scopedAlias) { $candidate = $scopedAlias }
}
if (-not $candidate) {
    $command = Get-Command zipic.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { $candidate = $command.Source }
}
if (-not $candidate -and $env:LOCALAPPDATA) {
    $aliasPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\zipic.exe'
    if (Test-Path -LiteralPath $aliasPath) { $candidate = $aliasPath }
}

if ($candidate) {
    $result.cli = $candidate
    $previousEncoding = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
        $versionOutput = & $candidate --version
        $versionExit = $LASTEXITCODE
        $versionText = ($versionOutput -join "`n").Trim()
        if ($versionExit -eq 0 -and $versionText -match '^zipic (\d+\.\d+\.\d+)$') {
            $result.cli_version = $Matches[1]
            $result.cli_supported = $true
            $result.route = 'cli'
        } else {
            $result.route = 'repair_cli'
            $result.diagnostic = 'CLI version probe failed; exit=' + $versionExit
        }
    } catch {
        $result.route = 'repair_cli'
        $result.diagnostic = $_.Exception.Message
    } finally {
        [Console]::OutputEncoding = $previousEncoding
    }
} elseif ($result.app_path) {
    $result.route = 'enable_alias'
} elseif ($packageChecked) {
    $result.route = 'halt_no_app'
} else {
    $result.route = 'cli_unavailable'
}

# cli verifies --version only; it does not prove that the GUI pipe is reachable.
$result | ConvertTo-Json -Compress
