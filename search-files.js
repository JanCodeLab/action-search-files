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


  // Helper function to normalize paths for consistent comparison across platforms
  const normalizePath = (pathStr) => {
    return pathStr
      .replace(/\\/g, '/') // Convert all backslashes to forward slashes
      .replace(/\/$/g, '')  // Remove trailing slash
      .toLowerCase();       // Case-insensitive comparison for Windows
  };

  // Helper function to check if a path should be excluded
  const shouldExclude = (filePath) => {
    if (!excludedFoldersList.length) return false;

    const normalizedPath = normalizePath(filePath);
    
    // Check each excluded folder
    return excludedFoldersList.some(excluded => {
      const normalizedExcluded = normalizePath(excluded);

      // Check if path is exactly the excluded folder
      if (normalizedPath === normalizedExcluded) return true;

      // Check if path is a subfolder of the excluded folder
      // Ensure proper path boundary by checking for slash
      if (normalizedPath.startsWith(normalizedExcluded + '/')) return true;

      // For root level paths, handle Windows drive letters
      const isRootLevel = normalizedExcluded.indexOf('/') === -1;
      if (isRootLevel) {
        const pathParts = normalizedPath.split('/');
        return pathParts.includes(normalizedExcluded);
      }

      return false;
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
    // Skip excluded directories
    if (shouldExclude(dir)) {
      core.info(`Skipping excluded directory: ${dir}`);
      return matchedFiles;
    }

    try {
      const items = fs.readdirSync(dir, { withFileTypes: true });
      
      for (const item of items) {
        const fullPath = path.join(dir, item.name);
        
        if (item.isDirectory()) {
          // For directories, check if it should be excluded
          if (recursive && !shouldExclude(fullPath)) {
            searchFiles(fullPath, matchedFiles);
          }
        } else if (item.isFile() && hasMatchingExtension(item.name, extensions)) {
          // For files, add to results if extension matches
          matchedFiles.push(fullPath);
        }
      }
    } catch (err) {
      core.warning(`⚠️Error reading directory ${dir}: ${err.message}`);
    }
    
    return matchedFiles;
  };

  // Perform search
  const startDir = path.resolve(directory);
  core.info(`🔍 Starting search in resolved directory: ${startDir}`);
  
  const matchedFiles = searchFiles(startDir);
  const matchCount = matchedFiles.length;

  // Format results 
  const filesList = matchedFiles.join(',');

  // Set outputs
  core.setOutput('files', filesList);
  core.setOutput('match-count', matchCount);

  // Display summary
  core.info(`✅ Found ${matchCount} files matching the criteria`);
  matchedFiles.forEach(file => core.info(`📄 ${file}`));

} catch (error) {
  core.setFailed(`Action failed: ${error.message}`);
}