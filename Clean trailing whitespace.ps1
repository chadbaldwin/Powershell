# get the contents of the new file as an array of strings
$contents = Get-Content -Path $newPath;
$contents = $contents.TrimEnd(); # trim trailing whitespace on each line

# convert from array into string
$contents = $contents -join "`r`n";

# write back to file
New-Item -Force -Path $newPath -Value $contents -ItemType File;
