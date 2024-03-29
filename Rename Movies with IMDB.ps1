function Get-CleanMovieName {
    param (
        [Parameter(ValueFromPipeline)][string]$Path
    )
    process {
        $name = Split-Path -Path $Path -LeafBase;
        $ext = Split-Path -Path $Path -Extension;

        # Find the position of the year in the title
        $match = $name -match '\d{4}';
        $year = $match ? $Matches[0] : $null;

        # If the current file is a TV episode, just skip it
        If ($name -imatch 'S\d\dE\d\d') {
            Write-Error 'TV Episode' -TargetObject $Path;
            return;
        } ElseIf ((!$match) -or ($year -lt 1900) -or ($year -gt 2050)) {
            # This is a best attempt case...obviously it will still have issues with movies like 1984, 2012, 1917
            Write-Error 'Year not found in title' -TargetObject $Path;
            return;
        }

        # Remove everything after the year, remove any unwanted characters or extra spaces and rename the file to "movie title (year).ext"
        $newName = $name.SubString(0, $name.IndexOf($year));
        $newName = $newName -replace '[\[\]{}()-.,]',' ' -replace '\s+',' ';
        $newName = $newName.Trim();

        return "${newName} (${year})${ext}";
    }
}

##########################################################
# move files to new directory for renaming
##########################################################
$source = gi 'X:\Downloads\Completed\';
# get rid of any files that aren't needed
gci -Recurse -File -Path $source -Include @('*.txt','*jpg','*.exe','*.nfo','*.sfv','*.bat','*.cmd','*.com','*.msi','*.ps1') | rm -Force -Verbose;
# move files to a prep directory
gci -Recurse -File -Path $source | mv -Destination X:\Downloads\ReadyToCopy -Verbose;
# clean out empty directories
gci -Recurse -Directory -Path $source | ? { -Not $_.GetFiles("*","AllDirectories") } | rm -Recurse -Force -Verbose;
##########################################################
pause;
##########################################################
# remove garbage from movie file names -- ignoring TV show files
##########################################################
gci | % { Rename-Item -Path $_ -NewName (Get-CleanMovieName $_) } 
##########################################################
pause;
##########################################################
# Rename all files in the current directory using IMDB

# To be run within the directory of the movie files that need to be renamed.
##########################################################
$files = Get-ChildItem -File;

ForEach ($file in $files) {
    # cleanup the file name before searching (make it URL safe)
    $searchName = $file.BaseName -replace '[()]',' ' -replace '\s+',' ';
    $searchName = $searchName.Trim();

    # search movie data from IMDB
    $searchResult = Invoke-RestMethod -Uri ('https://v2.sg.media-imdb.com/suggestion/'+$searchName.SubString(0,1).ToLower()+'/'+$searchName.Replace(' ','+')+'.json');

    if ($null -eq $searchResult.d) {
        Write-Output ('Current File: '+$file.FullName);
        Write-Output 'Error: No search results';
        Continue;
    }

    $movieData = $searchResult.d; # Add smarts to put priority on the year
    
    # todo - Add a check to see if any results match filename exactly (case-sensitive)

    ForEach ($result in $movieData) {
        # if the Relased date is populated, then use it for the filename
        if ($result.y) {
            # Clear variables at the beginning of each loop just in case any errors occur and residual values aren't hanging around
            Clear-Variable -Name baseName,movieYear,newName,renameResponse -ErrorAction SilentlyContinue;
            
            # get the movie name from the results
            $baseName = $result.l;

            # cleanup - unwanted characters, extra spaces, etc
            $baseName = $baseName -replace '&','and' -replace '[^A-Za-z0-9 ()\-]','' -replace '\s+',' ';
            $baseName = $baseName.Trim();

            # get movie year
            $movieYear = $result.y;

            # build new file name
            $newName = "$baseName ($movieYear)$($file.Extension)";
            
            # if new and old name are the same, then skip
            if ($file.Name -eq $newName) {
                if ($file.Name -cne $newName) {
                    Write-Output ("Current File: $($file.FullName)");
                    Write-Output 'New and old name are the same but different case...Fixing case...';
                    $file | Rename-Item -NewName $newName;
                } else {
                    #Write-Output 'New and old name are the same, skipping...';
                };
                Break;
            };

            # output useful info for making rename decision
            Write-Output ("Old Name: $($file.Name)");
            Write-Output ("New Name: $newName");
            Write-Output ("Actors: $($result.s)");

            # rename the file
            $renameResponse = Read-Host -Prompt 'Rename file (y/n), Skip (x)';
            if ($renameResponse -eq 'x') { Break; }
            if ($renameResponse -eq 'y') { $file | Rename-Item -NewName $newName; Break; }
        } else {
            Write-Output ("Current File: $($file.FullName)");
            Write-Output ("Error: Year not populated: $($result.y)");
        }
    }
}
##########################################################
pause;
##########################################################
# Check for duplicate movies
##########################################################
$movies = gci -Path X:\Movies\ -Recurse -File | ? Extension -NE '.srt';
$movies += gci -File;
$dups = ($movies | ? Extension -NE '.srt' | group -Property BaseName | ? Count -GT 1).Group;
$dups | select Directory, Name, Length;