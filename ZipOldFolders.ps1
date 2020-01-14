$minMonthsOld = 12;
$7zipPath = 'C:\Program Files\7-Zip\7z.exe';

# Search each dir, and return the max LastWriteTime and the Directory object
$fileDates = gci -Directory | % { $tDir = $_; $tDir | gci -File -Recurse | sort -Property LastWriteTime -Descending | select -First 1 | select @{N="Directory";E={$tDir}}, LastWriteTime };

# Set the directory's LastWriteTime to that of it's most recent file - this is so 7zip sets the archive date correctly
$fileDates.Directory.LastWriteTime = $fileDates.LastWriteTime;

# Filter to only directories with files older than X months
$targetPaths = ($fileDates | ? LastWriteTime -lt (Get-Date).AddMonths(-$minMonthsOld)).Directory;

# Zip in place and delete source folder
ForEach ($path In $targetPaths) {
    $pathDate = $path.LastWriteTime.ToString('yyyy-MM-dd');
    $zipName = "$($path.Parent)\zz_AutoArchived_$($pathDate)_$($path.Name).zip";
    & $7zipPath a -sdel -stl ('"'+$zipName+'"') ('"'+$path.FullName+'"'); # zip in place, remove original item, set archive date to target date
};