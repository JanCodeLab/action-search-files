const fs = require('fs');
const path = require('path');
const core = require('@actions/core');

try {
  // Get inputs
  const fileExtensions = core.getInput('file-extensions');
  const directory = core.getInput('directory');
  const recursive = core.getInput('recursive') === 'true';
  const excludedFolders = core.getInput('excluded-folders');

  // Process inputs
  const extensions = fileExtensions === '*' ? ['*'] : fileExtensions.split(',').map(ext => ext.trim());
  const excludedFoldersList = excludedFolders ? excludedFolders.split(',').map(folder => folder.trim()) : [];

  // Log search parameters
  console.log('Search Parameters:');
  console.log(`  Directory: ${directory}`);
  console.log(`  Extensions: ${fileExtensions}`);
  console.log(`  Recursive: ${recursive}`);
  console.log(`  Excluded Folders: ${excludedFoldersList.join(', ')}`);

  // Helper function to check if a path should be excluded
  const shouldExclude = (filePath) => {
    const normalizedPath = filePath.replace(/\\/g, '/').replace(/\/$/g, '');
    
    return excludedFoldersList.some(excluded => {
      const normalizedExcluded = excluded.replace(/\\/g, '/').replace(/\/$/g, '');
      return normalizedPath === normalizedExcluded || 
             normalizedPath.startsWith(normalizedExcluded + '/');
    });
  };

  // Helper function to check if file has matching extension
  const hasMatchingExtension = (file, exts) => {
    if (exts.includes('*')) return true;
    const fileExt = path.extname(file).toLowerCase().substring(1);
    return exts.some(ext => ext.toLowerCase() === fileExt);
  };

  // Search function that works across platforms
  const searchFiles = (dir, matchedFiles = []) => {
    if (shouldExclude(dir)) return matchedFiles;

    const items = fs.readdirSync(dir, { withFileTypes: true });
    
    for (const item of items) {
      const fullPath = path.join(dir, item.name);
      
      if (item.isDirectory()) {
        if (recursive && !shouldExclude(fullPath)) {
          searchFiles(fullPath, matchedFiles);
        }
      } else if (item.isFile() && hasMatchingExtension(item.name, extensions)) {
        matchedFiles.push(fullPath);
      }
    }
    
    return matchedFiles;
  };

  // Perform search
  const startDir = path.resolve(directory);
  const matchedFiles = searchFiles(startDir);
  const matchCount = matchedFiles.length;

  // Format results 
  const filesList = matchedFiles.join(',');

  // Set outputs
  core.setOutput('files', filesList);
  core.setOutput('match-count', matchCount);

  // Display summary
  console.log(`Found ${matchCount} files matching the criteria`);
  matchedFiles.forEach(file => console.log(file));

} catch (error) {
  core.setFailed(`Action failed: ${error.message}`);
}