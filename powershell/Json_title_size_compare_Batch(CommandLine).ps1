<#
.SYNOPSIS
    OneNote JSON Comparison Orchestrator
.DESCRIPTION
    Compares two directories containing OneNote JSON exports and generates a flat CSV report.
    Assumes 'Json_title_size_compare.py' resides in the same directory as this script.
.EXAMPLE
    .\Compare-OneNote.ps1 -JsonDir1 "C:\Data\Set1" -JsonDir2 "C:\Data\Set2" -CsvOutput "C:\Reports\Diff.csv"
#>
param (
    [Parameter(Mandatory = $true, HelpMessage = "Path to the first JSON directory (Dir 1)")]
    [string]$JsonDir1,
[Parameter(Mandatory = $true, HelpMessage = "Path to the second JSON directory (Dir 2)")]
    [string]$JsonDir2,
[Parameter(Mandatory = $false, HelpMessage = "Output path for the CSV report")]
    [string]$CsvOutput = ".\Comparison_Report.csv"
)
# --- 1. Python Helper Script Verification ---
# Automatically look in the exact same directory where this .ps1 file is saved
$pythonScriptPath = Join-Path $PSScriptRoot "Json_title_size_compare.py"
if (-not (Test-Path $pythonScriptPath)) {
    Write-Host "`n[ERROR] Dependency Missing!" -ForegroundColor Red
    Write-Host "The required Python helper script 'Json_title_size_compare.py' was not found." -ForegroundColor Yellow
    Write-Host "Please ensure both this PowerShell script and the Python script are kept in the same folder.`n" -ForegroundColor Yellow
    
    Write-Host "Expected location: $pythonScriptPath" -ForegroundColor Cyan
    Exit 1
}
# --- 2. Input Directory Validation ---
$validationFailed = $false
if (-not (Test-Path $JsonDir1)) {
    Write-Host "Error: JsonDir1 path does not exist: '$JsonDir1'" -ForegroundColor Red
    $validationFailed = $true
}
if (-not (Test-Path $JsonDir2)) {
    Write-Host "Error: JsonDir2 path does not exist: '$JsonDir2'" -ForegroundColor Red
    $validationFailed = $true
}
if ($validationFailed) {
    Write-Host "`n=== Usage Guide ===" -ForegroundColor Cyan
    Write-Host ".\Compare-OneNote.ps1 -JsonDir1 <Path> -JsonDir2 <Path> [-CsvOutput <Path>]" -ForegroundColor Cyan
    Write-Host "`nParameters:"
    Write-Host "  -JsonDir1   [Required] Path to your first folder of OneNote JSON files."
    Write-Host "  -JsonDir2   [Required] Path to your second folder of OneNote JSON files."
    Write-Host "  -CsvOutput  [Optional] Where to save the CSV. Defaults to '.\Comparison_Report.csv'"
    Exit 1
}
# Ensure the parent directory for the CSV output exists
$csvParentDir = Split-Path $CsvOutput -Parent
if ($csvParentDir -and -not (Test-Path $csvParentDir)) {
    New-Item -ItemType Directory -Path $csvParentDir -Force | Out-Null
}
Write-Host "Starting OneNote comparison..." -ForegroundColor Green
Write-Host "Dir 1: $JsonDir1"
Write-Host "Dir 2: $JsonDir2"
Write-Host "Report target: $CsvOutput`n"
# --- 3. Get unique list of all JSON filenames ---
$filesDir1 = Get-ChildItem -Path $JsonDir1 -Filter "*.json" | Select-Object -ExpandProperty Name
$filesDir2 = Get-ChildItem -Path $JsonDir2 -Filter "*.json" | Select-Object -ExpandProperty Name
$allUniqueFiles = ($filesDir1 + $filesDir2) | Select-Object -Unique
$report = @()
# --- 4. Process each unique file name ---
foreach ($fileName in $allUniqueFiles) {
    $path1 = Join-Path $JsonDir1 $fileName
    $path2 = Join-Path $JsonDir2 $fileName
    $existsIn1 = Test-Path $path1
    $existsIn2 = Test-Path $path2
# Gracefully handle completely missing section files
    if (-not $existsIn1) {
        Write-Host "Mismatched: $fileName is missing from Directory 1" -ForegroundColor Yellow
        $report += [PSCustomObject]@{ 
            SectionFile        = $fileName; 
            Status             = "Mismatched Section";
            DiscrepancyDetails = "Entire section file is only found in Directory 2" 
        }
        continue
    }
    if (-not $existsIn2) {
        Write-Host "Mismatched: $fileName is missing from Directory 2" -ForegroundColor Yellow
        $report += [PSCustomObject]@{ 
            SectionFile        = $fileName; 
            Status             = "Mismatched Section";
            DiscrepancyDetails = "Entire section file is only found in Directory 1" 
        }
        continue
    }
# Run the Python script and cleanly handle console streams
    $pythonOutput = & python "$pythonScriptPath" "$path1" "$path2" 2>&1
    
    $hasMismatches = $false
    $currentSectionContext = ""
foreach ($line in $pythonOutput) {
        $trimmedLine = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmedLine)) { continue }
        
        # Display the text output line directly to the terminal
        Write-Host $line
# Match onto the Python category markers
        if ($trimmedLine -like "--- Pages in Dir 1 only*") {
            $currentSectionContext = "[Only in Dir 1]"
            continue
        }
        elseif ($trimmedLine -like "--- Pages in Dir 2 only*") {
            $currentSectionContext = "[Only in Dir 2]"
            continue
        }
        elseif ($trimmedLine -like "--- Same title, different content*") {
            $currentSectionContext = "[Content Differs]"
            continue
        }
        elseif ($trimmedLine -like "--- Summary*") {
            $currentSectionContext = ""
            continue
        }
# Create a brand new CSV row for EVERY single line item mismatch
        if ($currentSectionContext -ne "" -and $line -like "  *") {
            $hasMismatches = $true
            $report += [PSCustomObject]@{
                SectionFile        = $fileName; 
                Status             = "Page Mismatch Found";
                DiscrepancyDetails = "$currentSectionContext $trimmedLine" 
            }
        }
    }
# If the file finished scanning and had zero page discrepancies, log it once as Identical
    if (-not $hasMismatches) {
        $report += [PSCustomObject]@{ 
            SectionFile        = $fileName; 
            Status             = "Identical"; 
            DiscrepancyDetails = "All internal titles and sizes match completely" 
        }
    }
}
# --- 5. Save output to CSV file ---
$report | Export-Csv -Path $CsvOutput -NoTypeInformation
Write-Host "`nDone. Flat comparison report saved to: $CsvOutput" -ForegroundColor Green