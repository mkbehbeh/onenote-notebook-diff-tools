$inputDir  = "C:\Users\mkbeh\Documents\Projects\OneNote Fixes\OneNote Notebooks W10HP850"
$outputDir = "C:\Users\mkbeh\Documents\Projects\OneNote Fixes\OneNote Notebooks W10HP850\JSON"
$scriptDir = "C:\Users\mkbeh\Documents\Projects\OneNote Fixes\OneNote Notebooks W10HP850"

# Create the output directory automatically if it does not exist
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

Get-ChildItem -Path $inputDir -Filter "*.one" | ForEach-Object { 
    # Build the output path inside the dedicated output folder
    $jsonFileName = [System.IO.Path]::ChangeExtension($_.Name, ".json")
    $jsonFile     = Join-Path $outputDir $jsonFileName

    if (Test-Path $jsonFile) { 
        Write-Host "Skipping $($_.Name) (already exists)" 
        return 
    }

    Write-Host "Converting $($_.Name) ..." 
    # Runs the python script using explicit input, output, and script paths
    python "$scriptDir\1note2json.py" --output $jsonFile $_.FullName 
}

Write-Host "Done."
