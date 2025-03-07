#!/usr/bin/env pwsh

param(
    [string]$FileExtensions = '*',
    
    [string]$Directory = '.',
    
    [bool]$Recursive = $true,
    
    [string]$ExcludedFolders = ''
)

# Set up environment variables for GitHub Actions
function Set-ActionOutput {
    param(
        [string]$Name,
        [string]$Value
    )
    
    # Support for different GitHub Actions environments
    if ($env:GITHUB_OUTPUT) {
        # GitHub Actions v2
        Add-Content -Path $env:GITHUB_OUTPUT -Value "$Name=$Value"
    } else {
        # GitHub Actions v1
        Write-Output "::set-output name=$Name::$Value"
    }
    
    # Also output to console for debugging
    Write-Output "$Name=$Value"
}

# Process file extensions
$extensions = $FileExtensions.Split(',') | ForEach-Object { $_.Trim() }
$extensionFilters = if ($FileExtensions -eq '*') { @('*') } else { $extensions | ForEach-Object { "*.$_" } }

# Process excluded folders
$excludedFoldersList = @()
if ($ExcludedFolders) {
    $excludedFoldersList = $ExcludedFolders.Split(',') | ForEach-Object { $_.Trim() }
}

# Display search parameters
Write-Output "Search Parameters:"
Write-Output "  Directory: $Directory"
Write-Output "  Extensions: $FileExtensions"
Write-Output "  Recursive: $Recursive"
Write-Output "  Excluded Folders: $($excludedFoldersList -join ', ')"

# Initialize results
$matchedFiles = @()
$matchCount = 0

# Helper function to check if path should be excluded
function Should-Exclude {
    param (
        [string]$Path
    )
    
    foreach ($excludedFolder in $excludedFoldersList) {
        # Normalize paths for comparison
        $normalizedPath = $Path.Replace('\', '/').TrimEnd('/')
        $normalizedExcluded = $excludedFolder.Replace('\', '/').TrimEnd('/')
        
        # Check if path is or is within an excluded folder
        if ($normalizedPath -eq $normalizedExcluded -or 
            $normalizedPath.StartsWith("$normalizedExcluded/")) {
            return $true
        }
    }
    
    return $false
}

# Perform search
foreach ($filter in $extensionFilters) {
    # Get all files matching extension filter
    $files = Get-ChildItem -Path $Directory -Filter $filter -File -Recurse:$Recursive
    
    # Filter out files from excluded folders
    $filteredFiles = $files | Where-Object {
        -not (Should-Exclude -Path $_.DirectoryName)
    }
    
    $matchedFiles += $filteredFiles
    $matchCount += $filteredFiles.Count
}

# Format the output as JSON for structured data
$filesList = $matchedFiles | ForEach-Object { $_.FullName } | ConvertTo-Json -Compress
Set-ActionOutput -Name "files" -Value $filesList
Set-ActionOutput -Name "match-count" -Value $matchCount

# Display summary
Write-Output "Found $matchCount files matching the criteria"
$matchedFiles | ForEach-Object { Write-Output $_.FullName }