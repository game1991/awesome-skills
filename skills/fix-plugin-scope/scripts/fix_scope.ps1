# Fix kscc installed_plugins.json scope bug
# Custom marketplace plugins are incorrectly marked as "scope": "project"
# causing "not cached at (not recorded)" errors in user-level sessions.
# This script corrects all project-scoped entries to user scope.

$ErrorActionPreference = "Stop"

$pluginFile = Join-Path $env:USERPROFILE ".claude\plugins\installed_plugins.json"

if (-not (Test-Path $pluginFile)) {
    Write-Host "ERROR [FIX_PLUGIN_SCOPE]: File not found: $pluginFile" -ForegroundColor Red
    Write-Host "HINT: Check if kscc is installed and has plugins configured."
    exit 1
}

try {
    $raw = Get-Content -Path $pluginFile -Raw -Encoding UTF8
    $data = $raw | ConvertFrom-Json
} catch {
    Write-Host "ERROR [FIX_PLUGIN_SCOPE]: Failed to parse JSON: $pluginFile" -ForegroundColor Red
    Write-Host "DETAIL: $_" -ForegroundColor Red
    Write-Host "HINT: The file may be corrupted. Consider backing up and reinstalling plugins."
    exit 1
}

if (-not ($data.PSObject.Properties.Name -contains "plugins")) {
    Write-Host "ERROR [FIX_PLUGIN_SCOPE]: Unexpected JSON structure in $pluginFile" -ForegroundColor Red
    Write-Host "HINT: Expected a top-level 'plugins' object. The file may be from an incompatible kscc version."
    exit 1
}

$fixed = 0
foreach ($key in $data.plugins.PSObject.Properties.Name) {
    $entries = $data.plugins.$key
    if ($entries -is [System.Array]) {
        for ($i = 0; $i -lt $entries.Count; $i++) {
            if ($entries[$i].scope -eq "project") {
                $entries[$i].scope = "user"
                if ($entries[$i].PSObject.Properties.Match("projectPath").Count -gt 0) {
                    $entries[$i].PSObject.Properties.Remove("projectPath") | Out-Null
                }
                $fixed++
            }
        }
    } elseif ($entries -is [PSCustomObject]) {
        if ($entries.scope -eq "project") {
            $entries.scope = "user"
            if ($entries.PSObject.Properties.Match("projectPath").Count -gt 0) {
                $entries.PSObject.Properties.Remove("projectPath") | Out-Null
            }
            $fixed++
        }
    }
}

if ($fixed -eq 0) {
    Write-Host "OK [FIX_PLUGIN_SCOPE]: No project-scoped plugins found. Everything looks good!" -ForegroundColor Green
    exit 0
}

# Atomic write: write to temp file then replace original
$tmpFile = "$pluginFile.tmp"
try {
    $output = $data | ConvertTo-Json -Depth 10
    Set-Content -Path $tmpFile -Value $output -Encoding UTF8
    Move-Item -Path $tmpFile -Destination $pluginFile -Force
} catch {
    Write-Host "ERROR [FIX_PLUGIN_SCOPE]: Failed to write file: $pluginFile" -ForegroundColor Red
    Write-Host "DETAIL: $_" -ForegroundColor Red
    Write-Host "HINT: kscc may be running and locking the file. Close kscc and retry."
    if (Test-Path $tmpFile) {
        Remove-Item -Path $tmpFile -Force -ErrorAction SilentlyContinue
    }
    exit 1
}

# Verify written file is valid JSON
try {
    $verify = Get-Content -Path $pluginFile -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    Write-Host "ERROR [FIX_PLUGIN_SCOPE]: File verification failed after write: $pluginFile" -ForegroundColor Red
    Write-Host "DETAIL: $_" -ForegroundColor Red
    Write-Host "HINT: The write may have been interrupted. Re-run this script."
    exit 1
}

Write-Host "OK [FIX_PLUGIN_SCOPE]: Fixed $fixed plugin entries (project -> user scope)" -ForegroundColor Green
Write-Host "NEXT: Restart kscc session and run /plugins to verify the fix."
exit 0
