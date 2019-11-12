$files = Get-ChildItem -Recurse -File | Where-Object Name -NotLike '* ([0-9][0-9][0-9][0-9]).*'

ForEach ($file in $files) {
    Write-Output ('Current File: '+$file.Name);

    # search movie data from IMDB
    $content = Invoke-RestMethod -Uri ('https://sg.media-imdb.com/suggests/'+$file.BaseName.SubString(0,1).ToLower()+'/'+$file.BaseName.Replace(' ','+')+'.json')
    $searchResult = $content.Substring($content.IndexOf('(')+1, $content.Length-$content.IndexOf('(')-2) | ConvertFrom-Json

    if ($null -eq $searchResult.d) {
        Write-Output 'Error: No search results';
        Continue;
    }

    $movieData = $searchResult.d;

    ForEach ($result in $movieData) {
        # if the Relased date is populated, then use it for the filename
        if ($result.y) {
            $baseName = $result.l

            $baseName = $baseName -replace '&', 'and'
            # remove bad characters
            $baseName = $baseName -replace '[^A-Za-z0-9 ]', '';
            # remove extra spaces
            $baseName = $baseName.Trim() -replace '\s+', ' ';
            # get movie year
            $movieYear = $result.y;

            # build new file name
            $newName = $baseName + ' (' + $movieYear + ')' + $file.Extension;

            Write-Output ('Old Name: '+$file.Name);
            Write-Output ('New Name: '+$newName);
            
            # output list of actor names
            $result.s;

            # rename the file
            $renameResponse = Read-Host -Prompt 'Rename file (y/n), Skip (x): ';

            if ($renameResponse -eq 'x') { Break; }
            if ($renameResponse -eq 'y') { $file | Rename-Item -NewName $newName -WhatIf; Break; }
        } else {
            Write-Output ('Error: Year not populated: ' + $result.y);
        }
    }
}