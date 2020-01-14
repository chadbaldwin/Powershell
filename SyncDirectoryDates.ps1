###############################################

###############################################
# Newer version - works better-ish for lots of files and directories
	# This newer version reduces the number of overall scans.
	# First it scans the deepest directories, and sets all directory dates
	# then it works its way down to the shallowest directories
###############################################
# Get all folders
$allFolders = gci -Directory -Recurse;

# Determine folder depth
$folderDepths = $allFolders | select @{N="FolderDepth";E={$_.FullName.ToSTring().Split('\').Count}}, @{N="Directory"; E={$_}};

# Get a unique list of folder depths
$depths = $folderDepths | group -Property FolderDepth | select @{N="FolderDepth"; E={[int]$_.Name}} | sort -Property FolderDepth -Descending;

ForEach ($depth in $depths.FolderDepth) {
	$directoryList = ($folderDepths | ? FolderDepth -eq $Depth).Directory;

	ForEach ($dir in $directoryList) {
		$dirLWT = ($dir | gci | sort -Property LastWriteTime -Descending | select -First 1).LastWriteTime;
		"" | select {$dir.FullName}, {$dirLWT};
		$dir.LastWriteTime = $dirLWT;
	};
};
###############################################

###############################################
# Older version - works well with lower number of files/folders
###############################################
# Sync directory LastWriteTime with newest recursive file LastWriteTime
gci -Directory -Recurse |
    % {
        $tDir = $_;
        $tDir |
            gci -File -Recurse |
                sort -Property LastWriteTime -Descending |
                    select -First 1 |
                        select @{N="Directory";E={$tDir}}, LastWriteTime
    } |
        % { $_.Directory.LastWriteTime = $_.LastWriteTime };