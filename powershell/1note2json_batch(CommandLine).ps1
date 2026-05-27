<#
.SYNOPSIS
    OneNote Batch to JSON Converter
.DESCRIPTION
    Converts a folder of '.one' files into parsed '.json' equivalents.
    Assumes '1note2json.py' resides in the same directory as this script.
.EXAMPLE
    .\Convert-Notebooks.ps1 -InputDir "C:\MyNotebooks" -OutputDir "C:\MyNotebooks\JSON"
#>

param (
    [Parameter(Mandatory = $true, HelpMessage = "Path to the directory containing the source .one files")]
    [string]$InputDir,

    [Parameter(Mandatory = $true, HelpMessage = "Path to the directory where JSON outputs should be saved")]
    [string]$OutputDir
)

# --- 1. Python Helper Script Verification ---
# Automatically look in the exact same directory where this .ps1 file is saved
$pythonScriptPath = Join-Path $PSScriptRoot "1note2json.py"

if (-not (Test-Path $pythonScriptPath)) {
    Write-Host "`n[ERROR] Dependency Missing!" -ForegroundColor Red
    Write-Host "The required Python converter script '1note2json.py' was not found." -ForegroundColor Yellow
    Write-Host "Please ensure both this PowerShell script and the Python script are kept in the same folder.`n" -ForegroundColor Yellow
    
    Write-Host "Expected location: $pythonScriptPath" -ForegroundColor Cyan
    Exit 1
}

# --- 2. Input Directory Validation ---
if (-not (Test-Path $InputDir)) {
    Write-Host "`n[ERROR] Input directory path does not exist: '$InputDir'" -ForegroundColor Red
    Write-Host "`n=== Usage Guide ===" -ForegroundColor Cyan
    Write-Host ".\Convert-Notebooks.ps1 -InputDir <Path> -OutputDir <Path>" -ForegroundColor Cyan
    Write-Host "`nParameters:"
    Write-Host "  -InputDir   [Required] Path to your source folder containing raw .one files."
    Write-Host "  -OutputDir  [Required] Path where you want the processed JSON outputs saved."
    Exit 1
}

# --- 3. Create Output Directory ---
# Create the output directory automatically if it does not exist
if (-not (Test-Path $OutputDir)) {
    Write-Host "Creating output directory: $OutputDir" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "Starting batch conversion..." -ForegroundColor Green
Write-Host "Scanning: $InputDir"
Write-Host "Saving to: $OutputDir`n"

# --- 4. Process .one Files ---
$oneFiles = Get-ChildItem -Path $InputDir -Filter "*.one"

if ($oneFiles.Count -eq 0) {
    Write-Host "No '.one' files found in the target input directory." -ForegroundColor Yellow
    Exit 0
}

foreach ($file in $oneFiles) { 
    # Build the output path inside the dedicated output folder
    $jsonFileName = [System.IO.Path]::ChangeExtension($file.Name, ".json")
    $jsonFile     = Join-Path $OutputDir $jsonFileName

    if (Test-Path $jsonFile) { 
        Write-Host "Skipping $($file.Name) (already exists)" -ForegroundColor Gray
        continue 
    }

    Write-Host "Converting $($file.Name) ..." -ForegroundColor Cyan
    
    # Runs the python script using relative script execution location
    python "$pythonScriptPath" --output "$jsonFile" "$($file.FullName)" 
}

Write-Host "`nDone. All sections processed." -ForegroundColor Green