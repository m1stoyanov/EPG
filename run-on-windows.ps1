# Get the directory where the script is located
$AppDir = $PSScriptRoot

# Set the working location to the script directory
Set-Location -Path $AppDir

# Define the path to the executable
$ExePath = Join-Path -Path $AppDir -ChildPath "bin\app.exe"

# Execute the application with arguments
# & is the call operator used to run commands or executables
& $ExePath grab -f "$AppDir\config" -o "$AppDir" -l 0

Write-Host "[LOG] Execution of app.exe completed." -ForegroundColor Gray

# --- Configuration ---
$Today = Get-Date
$Yesterday = $Today.AddDays(-1)

$TagToday = "v$($Today.ToString('dd.MM.yyyy'))"
$TagYesterday = "v$($Yesterday.ToString('dd.MM.yyyy'))"

# Your full list of files
$FileList = @(
    "epg.xml.gz", 
    "all-2days.basic.epg.xml.gz", 
    "all-2days.details.epg.xml.gz", 
    "all-2days.full.epg.xml.gz", 
    "all-3days.basic.epg.xml.gz", 
    "all-3days.details.epg.xml.gz", 
    "all-3days.full.epg.xml.gz", 
    "bulgarian.3days.full.epg.xml.gz", 
    "sport.epg.xml.gz", 
    "tivibg.xml.gz", 
    "vivacom.xml.gz"
    "a1.xml.gz"
)

$Title = "EPG Bundle ($($Today.ToString('dd.MM.yyyy')))"
$Notes = "Automated upload of Bulgarian and Global EPG files. Updated at $($Today.ToString('HH:mm:ss'))."

Write-Host "[LOG] Starting Process: $($Today.ToString())" -ForegroundColor Cyan
Write-Host "[LOG] Today's Tag: $TagToday"
Write-Host "[LOG] Yesterday's Tag for cleanup: $TagYesterday"

# --- 1. Cleanup Yesterday's Release ---
Write-Host "[LOG] Checking for yesterday's release ($TagYesterday)..."
gh release view $TagYesterday 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "[LOG] Found yesterday's release. Deleting..." -ForegroundColor Yellow
    gh release delete $TagYesterday --yes
} else {
    Write-Host "[LOG] No release found for yesterday. Skipping cleanup."
}

# --- 2. Process Today's Release ---
Write-Host "[LOG] Checking if today's release ($TagToday) exists..."
gh release view $TagToday 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "[LOG] MATCH FOUND: Updating existing release with $($FileList.Count) files..." -ForegroundColor Green
    gh release upload $TagToday $FileList --clobber
    gh release edit $TagToday --title $Title --notes $Notes
} else {
    Write-Host "[LOG] NO MATCH: Creating new release with $($FileList.Count) files..." -ForegroundColor Green
    gh release create $TagToday $FileList --title $Title --notes $Notes
}

Write-Host "[SUCCESS] Operation completed at $(Get-Date)" -ForegroundColor Green

Copy-Item report.js -Destination ..\harrygg.github.io\EPG\report.js
Write-Host "[LOG] Copied report.js to repository dir" -ForegroundColor Cyan

# Navigate to the sibling directory (equivalent to %APPDIR%..\harrygg.github.io)
$RepoDir = Join-Path -Path $AppDir -ChildPath "..\harrygg.github.io"

Write-Host "[LOG] Moving to repository dir: $RepoDir" -ForegroundColor Cyan
Set-Location -Path $RepoDir

# Execute Git commands
Write-Host "[LOG] Pulling latest changes..."
git pull

Write-Host "[LOG] Current status before update:"
git status

Write-Host "[LOG] Staging all changes..."
git add -A

Write-Host "[LOG] Committing changes..."
git commit -m "Scheduled daily update"

Write-Host "[LOG] Pushing to GitHub..."
git push

Write-Host "[LOG] Final repository status:"
git status

# Return to the original application directory
Write-Host "[LOG] Returning to $AppDir" -ForegroundColor Cyan
Set-Location -Path $AppDir