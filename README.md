# Search Files Action
[![Release](https://github.com/JanCodeLab/action-search-files/actions/workflows/release.yml/badge.svg)](https://github.com/JanCodeLab/action-search-files/actions/workflows/release.yml)
This GitHub Action searches for files by extension and provides folder exclusion capabilities. It's built using PowerShell and can be used across your organization.

## Usage

```yaml
- name: Search for files
  uses: JanCodeLab/action-search-files@latest
  id: search
  with:
    file-extensions: 'cs,js,ts'  # Comma-separated file extensions
    directory: 'src'  # Directory to search in
    recursive: true  # Search in subdirectories
    excluded-folders: 'node_modules,bin,obj'  # Folders to exclude
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `file-extensions` | File extensions to search (comma separated) | No | `*` |
| `directory` | Directory to search within | No | `.` |
| `recursive` | Search recursively in subdirectories | No | `true` |
| `excluded-folders` | Folders to exclude from search (comma separated) | No | `''` |

## Outputs

| Output | Description |
|--------|-------------|
| `files` | files that match the search criteria in Comma-separated list |
| `match-count` | Number of files found |

## Example: Finding C# files excluding build artifacts

```yaml
jobs:
  find-cs-files:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Find C# files
        id: cs-finder
        uses: JanCodeLab/action-search-files@latest
        with:
          file-extensions: 'cs'
          excluded-folders: 'bin,obj,packages,TestResults'
          
      - name: Show results
        run: |
          echo "Found ${{ steps.cs-finder.outputs.match-count }} C# files"
          echo "${{ steps.cs-finder.outputs.files }}"
```

## Changelog
- v1.2 (latest)
  - Fixed versioning
- v1.1
  - Optimized logging
- v1
  - Initial implementation of action