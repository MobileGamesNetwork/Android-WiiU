$ErrorActionPreference = "Stop"

Clear-Host

Write-Host "========================================"
Write-Host "       GitHub APK Installer"
Write-Host "========================================"
Write-Host ""

$url = Read-Host "Paste GitHub repo URL"

if ([string]::IsNullOrWhiteSpace($url)) {
    Write-Host "No URL entered." -ForegroundColor Red
    exit 1
}

if ($url -notmatch '^https?://github\.com/([^/]+)/([^/#?]+)') {
    Write-Host "Invalid GitHub repository URL." -ForegroundColor Red
    exit 1
}

$owner = $Matches[1]
$repo = $Matches[2] -replace '\.git$', ''

Write-Host ""
Write-Host "Repository: $owner/$repo"
Write-Host ""

# Check ADB
Write-Host "Checking ADB..."

& adb get-state 2>$null | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: No Android device connected through ADB." -ForegroundColor Red
    exit 1
}

Write-Host "ADB device found."
Write-Host ""

# GitHub API headers
$headers = @{
    "User-Agent" = "GitHub-APK-Installer"
    "Accept"     = "application/vnd.github+json"
}

# ============================================================
# Find newest release INCLUDING prereleases
# ============================================================

Write-Host "Finding latest GitHub release..."

try {
    $releases = @(
        Invoke-RestMethod `
            -Uri "https://api.github.com/repos/$owner/$repo/releases?per_page=100" `
            -Headers $headers
    )
}
catch {
    Write-Host ""
    Write-Host "ERROR: Could not access GitHub releases." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

# Ignore drafts, but INCLUDE prereleases
$releases = @(
    $releases |
    Where-Object { $_.draft -eq $false }
)

if ($releases.Count -eq 0) {
    Write-Host ""
    Write-Host "ERROR: No published releases found." -ForegroundColor Red
    exit 1
}

# Releases are returned newest first
$release = $releases[0]

Write-Host "Release: $($release.name)"

if ($release.prerelease) {
    Write-Host "Type: Pre-release" -ForegroundColor Yellow
}
else {
    Write-Host "Type: Stable release"
}

Write-Host ""

# ============================================================
# Find APK assets
# ============================================================

$apks = @(
    $release.assets |
    Where-Object {
        $_.name -match '\.apk$'
    }
)

if ($apks.Count -eq 0) {
    Write-Host "No APK found in this release." -ForegroundColor Red
    Write-Host ""
    Write-Host "Trying the next release..."

    foreach ($candidate in ($releases | Select-Object -Skip 1)) {

        $candidateApks = @(
            $candidate.assets |
            Where-Object {
                $_.name -match '\.apk$'
            }
        )

        if ($candidateApks.Count -gt 0) {
            $release = $candidate
            $apks = $candidateApks

            Write-Host ""
            Write-Host "Found APK in release: $($release.name)"

            break
        }
    }
}

if ($apks.Count -eq 0) {
    Write-Host ""
    Write-Host "ERROR: No APK found in available releases." -ForegroundColor Red
    exit 1
}

# ============================================================
# Select APK
# ============================================================

Write-Host ""

if ($apks.Count -eq 1) {

    $apk = $apks[0]

}
else {

    Write-Host "Multiple APKs found:"
    Write-Host ""

    for ($i = 0; $i -lt $apks.Count; $i++) {
        Write-Host "[$($i + 1)] $($apks[$i].name)"
    }

    Write-Host ""

    do {
        $choice = Read-Host "Select APK number"
    }
    while (
        $choice -notmatch '^\d+$' -or
        [int]$choice -lt 1 -or
        [int]$choice -gt $apks.Count
    )

    $apk = $apks[[int]$choice - 1]
}

Write-Host "Selected: $($apk.name)"
Write-Host ""

# ============================================================
# Download
# ============================================================

$temp = Join-Path $env:TEMP "github_apk_installer.apk"

Write-Host "Downloading..."

try {
    Invoke-WebRequest `
        -Uri $apk.browser_download_url `
        -OutFile $temp
}
catch {
    Write-Host ""
    Write-Host "ERROR: Download failed." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

Write-Host "Download complete."
Write-Host ""

# ============================================================
# Install
# ============================================================

Write-Host "Installing APK..."
Write-Host ""

& adb install -r $temp

$result = $LASTEXITCODE

# Cleanup
Remove-Item $temp -Force -ErrorAction SilentlyContinue

Write-Host ""

if ($result -eq 0) {

    Write-Host "========================================" -ForegroundColor Green
    Write-Host "       INSTALLATION SUCCESSFUL" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green

}
else {

    Write-Host "========================================" -ForegroundColor Red
    Write-Host "         INSTALLATION FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red

}

exit $result