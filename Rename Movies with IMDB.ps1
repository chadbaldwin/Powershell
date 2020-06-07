##########################################################
# move files to new directory for renaming
##########################################################
# get rid of any files that aren't needed
gci -Recurse -File -Path X:\Downloads\temp -Include @('*.txt','*jpg','*.exe','*.nfo','*.sfv','*.bat','*.cmd','*.com','*.msi','*.ps1') | rm -Force -Verbose;
# move files to a prep directory
gci -Recurse -File -Path X:\Downloads\temp | mv -Destination X:\Downloads\ReadyToCopy -Verbose;
# clean out empty directories
gci -Recurse -Directory -Path X:\Downloads\temp | ? {-Not $_.GetFiles("*","AllDirectories")} | rm -Recurse -Force -Verbose;
##########################################################
pause;
##########################################################
# remove garbage from movie file names -- ignoring TV show files
##########################################################
gci -File | ? Name -NotLike '* ([0-9][0-9][0-9][0-9]).*' | % {
	$_.Name;

	# If for some reason an error occurs in the previous loop, I want to make sure I staart clean every time
	Clear-Variable -Name match,idxYear,newName,Matches -ErrorAction SilentlyContinue;

	# Find the position of the year in the title
    $match = $_.BaseName -match '[0-9]{4}';

    # If the current file is a TV episode, just skip it
	If ($_.BaseName -match '[Ss][0-9][0-9][Ee][0-9][0-9]') {
		Write-Host ('TV Episode. Moving ' + $_.Name);
		$_ | mv -Destination .\TV
		return;
	} ElseIf (!$match) {
		Write-Host ('Year not found in title, skipping...')
		return;
	# This is a best attempt case...obviously it will still have issues with movies like 1984, 2012, 1917
	} ElseIf (($Matches[0] -lt 1900) -or ($Matches[0] -gt 2050)) {
		Write-Host ('Year not found in title, skipping...')
		return;
	}

	$year = $matches[0];
	$idxYear = $_.BaseName.IndexOf($matches[0]);

    # Remove everything after the year, remove any unwanted characters or extra spaces and rename the file to "movie title (year).ext"
	$newName = $_.BaseName.SubString(0,$idxYear);
    $newName = $newName -replace '[\[\]{}()-.,]',' ' -replace '\s+', ' ';
    $newName = $newName.Trim();
    $newName = $newName+' ('+$matches[0]+')'+$_.Extension;
	
	$_ | ren -NewName $newName -Confirm -Verbose;
}
##########################################################
pause;
##########################################################
# Rename all files in the current directory using IMDB

# To be run within the directory of the movie files that need to be renamed.
##########################################################
$files = Get-ChildItem -File;

ForEach ($file in $files) {
	#Write-Output '';
    #Write-Output ('Current File: '+$file.FullName);
	
	# cleanup the file name before searching (make it URL safe)
	$searchName = $file.BaseName -replace '[()]',' ' -replace '\s+',' ';
	$searchName = $searchName.Trim();

    # search movie data from IMDB
	#Write-Output ('Searching IMDB: '+$searchName.Replace(' ','+'));
    $searchResult = Invoke-RestMethod -Uri ('https://v2.sg.media-imdb.com/suggestion/'+$searchName.SubString(0,1).ToLower()+'/'+$searchName.Replace(' ','+')+'.json');

	# Older API
    #$content = Invoke-RestMethod -Uri ('https://sg.media-imdb.com/suggests/'+$searchName.SubString(0,1).ToLower()+'/'+$searchName.Replace(' ','+')+'.json');
    #$searchResult = $content.Substring($content.IndexOf('(')+1, $content.Length-$content.IndexOf('(')-2) | ConvertFrom-Json; # IMDB uses 

    if ($null -eq $searchResult.d) {
		Write-Output ('Current File: '+$file.FullName);
        Write-Output 'Error: No search results';
        Continue;
    }

    $movieData = $searchResult.d;
	
	# todo - Add a check to see if any results match filename exactly (case-sensitive)

    ForEach ($result in $movieData) {
        # if the Relased date is populated, then use it for the filename
        if ($result.y) {
			# Clear variables at the beginning of each loop just in case any errors occur and residual values aren't hanging around
			Clear-Variable -Name baseName,movieYear,newName,renameResponse -ErrorAction SilentlyContinue;
			
			# get the movie name from the results
            $baseName = $result.l;

            # cleanup - unwanted characters, extra spaces, etc
            $baseName = $baseName -replace '&', 'and';
            $baseName = $baseName -replace '[^A-Za-z0-9 ()\-]', '';
            $baseName = $baseName.Trim() -replace '\s+', ' ';

            # get movie year
            $movieYear = $result.y;

            # build new file name
            $newName = $baseName + ' (' + $movieYear + ')' + $file.Extension;
			
			# if new and old name are the same, then skip
			if ($file.Name -eq $newName) {
				if ($file.Name -cne $newName) {
					Write-Output ('Current File: '+$file.FullName);
					Write-Output 'New and old name are the same but different case...Fixing case...';
					$file | Rename-Item -NewName $newName;
				} else {
					#Write-Output 'New and old name are the same, skipping...';
				};
				Break;
			};

            Write-Output ('Old Name: '+$file.Name);
            Write-Output ('New Name: '+$newName);
            
            # output list of actor names
            $result.s;

            # rename the file
            $renameResponse = Read-Host -Prompt 'Rename file (y/n), Skip (x)';

            if ($renameResponse -eq 'x') { Break; }
            if ($renameResponse -eq 'y') { $file | Rename-Item -NewName $newName; Break; }
        } else {
			Write-Output ('Current File: '+$file.FullName);
            Write-Output ('Error: Year not populated: ' + $result.y);
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