# 1. Hardcoded Directories
$jsonDir1   = "C:\Users\mkbeh\Documents\Projects\OneNote Fixes\OneNote Notebooks W11HP840\JSON\Personal (2)"
$jsonDir2   = "C:\Users\mkbeh\Documents\Projects\OneNote Fixes\Onenote Notebooks W10SB\JSON"
$scriptDir  = "C:\Users\mkbeh\Documents\Projects\OneNote Fixes"
$csvOutput  = "C:\Users\mkbeh\Documents\Projects\OneNote Fixes\Comparison_W11840_W10SB_NL (updated_py).csv"

# 2. Get unique list of all JSON filenames
$filesDir1 = Get-ChildItem -Path $jsonDir1 -Filter "*.json" | Select-Object -ExpandProperty Name
$filesDir2 = Get-ChildItem -Path $jsonDir2 -Filter "*.json" | Select-Object -ExpandProperty Name
$allUniqueFiles = ($filesDir1 + $filesDir2) | Select-Object -Unique

$report = @()

# 3. Process each unique file name
foreach ($fileName in $allUniqueFiles) {
    $path1 = Join-Path $jsonDir1 $fileName
    $path2 = Join-Path $jsonDir2 $fileName

    $existsIn1 = Test-Path $path1
    $existsIn2 = Test-Path $path2

    # 4. Gracefully handle completely missing section files
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

    # 5. Run the Python script and cleanly handle console streams
    $pythonOutput = & python "$scriptDir\Json_title_size_compare.py" "$path1" "$path2" 2>&1
    
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

        # FIXED: Instead of grouping items, create a brand new CSV row for EVERY single line item mismatch
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

# 6. Save output to CSV file
$report | Export-Csv -Path $csvOutput -NoTypeInformation
Write-Host "`nDone. Flat comparison report saved to: $csvOutput" -ForegroundColor Green
