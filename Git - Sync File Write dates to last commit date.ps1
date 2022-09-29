gci -Recurse -File |
    % {
        $_.FullName;
        $fileDate = git log -1 --pretty="format:%cI" $_.FullName;
        $_.LastWriteTime = [datetime]$fileDate;
    }
