#!/bin/bash

# Parse arguments
FILE_EXTENSIONS="*"
DIRECTORY="."
RECURSIVE="true"
EXCLUDED_FOLDERS=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --file-extensions)
      FILE_EXTENSIONS="$2"
      shift 2
      ;;
    --directory)
      DIRECTORY="$2"
      shift 2
      ;;
    --recursive)
      RECURSIVE="$2"
      shift 2
      ;;
    --excluded-folders)
      EXCLUDED_FOLDERS="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Set GitHub Actions output
set_output() {
  name=$1
  value=$2
  
  if [ -n "$GITHUB_OUTPUT" ]; then
    echo "$name=$value" >> "$GITHUB_OUTPUT"
  else
    echo "::set-output name=$name::$value"
  fi
  
  echo "Output $name: $value"
}

# Process parameters
# Convert comma-separated values to arrays
IFS=',' read -ra EXTENSION_ARRAY <<< "$FILE_EXTENSIONS"
IFS=',' read -ra EXCLUDED_FOLDERS_ARRAY <<< "$EXCLUDED_FOLDERS"

# Display search parameters
echo "Search Parameters:"
echo "  Directory: $DIRECTORY"
echo "  Extensions: $FILE_EXTENSIONS"
echo "  Recursive: $RECURSIVE"
echo "  Excluded Folders: $EXCLUDED_FOLDERS"

# Initialize results
MATCHED_FILES=()
MATCH_COUNT=0

# Check if path should be excluded
should_exclude() {
  local path="$1"
  local normalized_path=$(echo "$path" | sed 's/\\//g' | sed 's/\/$//')
  
  for excluded in "${EXCLUDED_FOLDERS_ARRAY[@]}"; do
    local normalized_excluded=$(echo "$excluded" | sed 's/\\//g' | sed 's/\/$//')
    
    if [[ "$normalized_path" == "$normalized_excluded" || "$normalized_path" == "$normalized_excluded"/* ]]; then
      return 0  # true, should exclude
    fi
  done
  
  return 1  # false, should not exclude
}

# Perform search
find_cmd="find \"$DIRECTORY\""

# Add recursive option
if [ "$RECURSIVE" != "true" ]; then
  find_cmd="$find_cmd -maxdepth 1"
fi

# Add file type
find_cmd="$find_cmd -type f"

# Add extension filter
if [ "$FILE_EXTENSIONS" != "*" ]; then
  extension_pattern=""
  for ext in "${EXTENSION_ARRAY[@]}"; do
    if [ -n "$extension_pattern" ]; then
      extension_pattern="$extension_pattern -o"
    fi
    extension_pattern="$extension_pattern -name \"*.$ext\""
  done
  find_cmd="$find_cmd -a \\( $extension_pattern \\)"
fi

# Add excluded folders
for excluded in "${EXCLUDED_FOLDERS_ARRAY[@]}"; do
  find_cmd="$find_cmd -not -path \"*/$excluded/*\""
done

# Execute the find command and store results
while IFS= read -r file; do
  MATCHED_FILES+=("$file")
done < <(eval "$find_cmd" 2>/dev/null)

MATCH_COUNT=${#MATCHED_FILES[@]}

# Format output as comma-separated list
FILES_LIST=$(IFS=,; echo "${MATCHED_FILES[*]}")

# Set outputs
set_output "files" "$FILES_LIST"
set_output "match-count" "$MATCH_COUNT"

# Display summary
echo "Found $MATCH_COUNT files matching the criteria"
for file in "${MATCHED_FILES[@]}"; do
  echo "$file"
done

exit 0