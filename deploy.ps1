# Rapid Reporter Deployment Script
# This script copies all required files for the application to run in a different folder

param(
    [string]$DestinationPath = ".\Deploy",
    [string]$Configuration = "Debug"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Rapid Reporter Deployment Script ===" -ForegroundColor Cyan
Write-Host ""

# Source directory
$sourceDir = "Rapid Reporter\bin\$Configuration\net9.0-windows"

# Check if source exists
if (-not (Test-Path $sourceDir)) {
    Write-Host "ERROR: Build output directory not found: $sourceDir" -ForegroundColor Red
    Write-Host "Please build the solution first (dotnet build RapidReporter.sln)" -ForegroundColor Yellow
    exit 1
}

# Create destination directory
Write-Host "Creating deployment folder: $DestinationPath" -ForegroundColor Green
if (Test-Path $DestinationPath) {
    $response = Read-Host "Destination folder exists. Overwrite? (y/n)"
    if ($response -ne 'y') {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
    Remove-Item -Path $DestinationPath -Recurse -Force
}
New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null

# Copy main executable and DLLs
Write-Host "Copying main application files..." -ForegroundColor Green
$filesToCopy = @(
    "RapidReporterEx.exe",
    "RapidReporterEx.dll",
    "RapidReporterEx.pdb",
    "RapidReporterEx.runtimeconfig.json",
    "RapidReporterEx.deps.json",
    "RapidReporterEx.dll.config",
    "System.Management.dll"
)

foreach ($file in $filesToCopy) {
    $sourcePath = Join-Path $sourceDir $file
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $DestinationPath -Force
        Write-Host "  + $file" -ForegroundColor Gray
    } else {
        Write-Host "  ! $file not found (skipping)" -ForegroundColor Yellow
    }
}

# Copy runtimes folder (CRITICAL for System.Management)
Write-Host "Copying runtimes folder..." -ForegroundColor Green
$runtimesSource = Join-Path $sourceDir "runtimes"
if (Test-Path $runtimesSource) {
    Copy-Item -Path $runtimesSource -Destination $DestinationPath -Recurse -Force
    Write-Host "  + runtimes/ (with all subdirectories)" -ForegroundColor Gray
} else {
    Write-Host "  ! runtimes/ folder not found" -ForegroundColor Yellow
}

# Copy icon and image files
Write-Host "Copying icon and image files..." -ForegroundColor Green
$imageExtensions = @("*.png", "*.ico", "*.jpg", "*.bmp")
foreach ($ext in $imageExtensions) {
    $images = Get-ChildItem -Path $sourceDir -Filter $ext -ErrorAction SilentlyContinue
    foreach ($img in $images) {
        Copy-Item -Path $img.FullName -Destination $DestinationPath -Force
        Write-Host "  + $($img.Name)" -ForegroundColor Gray
    }
}

# Copy icon from Forms folder if not in build output
$formsIconPath = "Rapid Reporter\Forms\RapidReporter.ico"
if (Test-Path $formsIconPath) {
    Copy-Item -Path $formsIconPath -Destination $DestinationPath -Force
    Write-Host "  + RapidReporter.ico (from Forms)" -ForegroundColor Gray
}

# Create README in deployment folder
Write-Host "Creating README..." -ForegroundColor Green
$dateStamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$readmeText = "Rapid Reporter - Portable Deployment`r`n"
$readmeText += "=====================================`r`n`r`n"
$readmeText += "This folder contains all files needed to run Rapid Reporter.`r`n`r`n"
$readmeText += "Requirements:`r`n"
$readmeText += "- Windows 10/11 (64-bit)`r`n"
$readmeText += "- .NET 9.0 Runtime (Desktop) installed`r`n"
$readmeText += "  Download from: https://dotnet.microsoft.com/download/dotnet/9.0`r`n`r`n"
$readmeText += "To Run:`r`n"
$readmeText += "-------`r`n"
$readmeText += "Double-click RapidReporterEx.exe`r`n`r`n"
$readmeText += "Important Files:`r`n"
$readmeText += "----------------`r`n"
$readmeText += "- RapidReporterEx.exe       : Main application`r`n"
$readmeText += "- RapidReporterEx.dll       : Application library`r`n"
$readmeText += "- System.Management.dll     : System management library`r`n"
$readmeText += "- runtimes/                 : Native platform dependencies (DO NOT DELETE)`r`n"
$readmeText += "- *.png files               : UI icons`r`n"
$readmeText += "- RapidReporter.ico         : Application icon`r`n`r`n"
$readmeText += "Notes:`r`n"
$readmeText += "------`r`n"
$readmeText += "- Session files and screenshots will be saved in this folder`r`n"
$readmeText += "- A _rrlog_.log file can be created here to enable debug logging`r`n"
$readmeText += "- Do not delete the runtimes/ folder - it contains required native libraries`r`n`r`n"
$readmeText += "Deployed: $dateStamp`r`n"

Set-Content -Path (Join-Path $DestinationPath "README.txt") -Value $readmeText
Write-Host "  + README.txt created" -ForegroundColor Gray

# Summary
Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Green
Write-Host "Location: $((Resolve-Path $DestinationPath).Path)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files copied:" -ForegroundColor White
$deployedFiles = Get-ChildItem -Path $DestinationPath -Recurse -File
Write-Host "  Total: $($deployedFiles.Count) files" -ForegroundColor Gray
$totalSize = [math]::Round(($deployedFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
Write-Host "  Size: $totalSize MB" -ForegroundColor Gray
Write-Host ""
Write-Host "+ Application is ready to run from the deployment folder" -ForegroundColor Green
Write-Host "+ You can copy the entire deployment folder to any location" -ForegroundColor Green
