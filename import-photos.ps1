# Photo Import and Upload Automation Script
# For: Omm Dhal

$ErrorActionPreference = "Stop"

# Source and Destination paths
$sourceDir = "D:\Photos"
$destDir = "$PSScriptRoot\images\src"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "     Omm Dhal's Photo Import Bridge       " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Verify source directory exists
if (-not (Test-Path -Path $sourceDir)) {
    Write-Error "Source directory '$sourceDir' not found! Please make sure D:\Photos exists and contains your photos."
    Exit
}

# 2. Ensure destination directory exists
if (-not (Test-Path -Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Write-Host "Created source image folder: $destDir" -ForegroundColor Yellow
}

# 3. Find image files
$imageExtensions = @("*.jpg", "*.jpeg", "*.png", "*.webp", "*.tiff")
$filesToCopy = Get-ChildItem -Path $sourceDir -File -Include $imageExtensions -Recurse

if ($filesToCopy.Count -eq 0) {
    Write-Host "No images (*.jpg, *.jpeg, *.png, *.webp, *.tiff) found in $sourceDir." -ForegroundColor Yellow
    Write-Host "Please place your new photos in D:\Photos and run this script again!" -ForegroundColor White
    Exit
}

Write-Host "Found $($filesToCopy.Count) new image(s) in $sourceDir." -ForegroundColor Green
Write-Host "Copying images to $destDir..." -ForegroundColor Yellow

# 4. Copy files
foreach ($file in $filesToCopy) {
    $targetPath = Join-Path -Path $destDir -ChildPath $file.Name
    Copy-Item -Path $file.FullName -Destination $targetPath -Force
    Write-Host "  [+] Copied: $($file.Name)" -ForegroundColor Gray
}

Write-Host "Copy complete!" -ForegroundColor Green

# 5. Git Commit & Push
Write-Host "Checking git status..." -ForegroundColor Yellow

# Verify git repository
if (-not (Test-Path -Path "$PSScriptRoot\.git")) {
    Write-Host "[WARNING] This directory is not a Git repository or Git is not initialized. Please verify you pushed it to GitHub." -ForegroundColor Red
    Exit
}

try {
    # Check if there are changes to stage
    git add "$PSScriptRoot/images/src"
    
    $status = git status --porcelain
    if ($null -ne $status -and $status -ne "") {
        Write-Host "Staging new images and pushing to GitHub..." -ForegroundColor Cyan
        git commit -m "feat: upload new photos from Omm's D:\Photos for processing"
        
        Write-Host "Syncing with cloud (downloading generated thumbnails)..." -ForegroundColor Yellow
        git config merge.directoryRenames false
        git pull origin main --no-rebase
        
        git push origin main
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host "SUCCESS! Your photos have been uploaded to GitHub!" -ForegroundColor Green
        Write-Host "GitHub Actions will now resize them, generate thumbnails," -ForegroundColor Green
        Write-Host "archive them, and deploy your live photography site!" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green
    } else {
        Write-Host "No changes detected in Git. Everything is up-to-date!" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] Failed to push changes to GitHub. Please check your internet connection or git permissions." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "Press any key to exit..."
[void]$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
