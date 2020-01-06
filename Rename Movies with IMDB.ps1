##########################################################
# move files to new directory for renaming
##########################################################
# get rid of any files that aren't needed
gci -Recurse -File -Path X:\Downloads\Completed -Include @('*.txt','*jpg','*.exe','*.nfo') | rm -Verbose;
# move files to a prep directory
gci -Recurse -File -Path X:\Downloads\Completed | mv -Destination X:\Downloads\ReadyToCopy  -Verbose;
# clean out empty directories
gci -Recurse -Directory -Path $folder | ? {-Not $_.GetFiles("*","AllDirectories")} | rm -Recurse -Verbose;
##########################################################

##########################################################
# remove garbage from movie file names -- ignoring TV show files
##########################################################
gci -File | ? Name -NotLike '* ([0-9][0-9][0-9][0-9]).*' | % {
	# If for some reason an error occurs in the previous loop, I want to make sure I staart clean every time
	Clear-Variable -Name match -ErrorAction SilentlyContinue;
	Clear-Variable -Name idxYear -ErrorAction SilentlyContinue;
	Clear-Variable -Name newName -ErrorAction SilentlyContinue;

	# If the current file is a TV episode, just skip it
    If ($_.BaseName -match '[Ss][0-9][0-9][Ee][0-9][0-9]') {
		Write-Host ('TV Episode. Skipping ' + $_.Name);
        return;
    }

    # Find the position of the year in the title...KNOWN ISSUE - Movies whose name IS a year...example movies "1922 (2017)" or "2012 (2009)"
    $match = $_.BaseName -match '[0-9][0-9][0-9][0-9]';
    $idxYear = $_.BaseName.IndexOf($matches[0]);

    # Remove everything after the year, remove any unwanted characters or extra spaces and rename the file to "movie title (year).ext"
	$newName = $_.BaseName.SubString(0,$idxYear);
    $newName = $newName -replace '[\[\]{}()-.,]',' ' -replace '\s+', ' ';
    $newName = $newName.Trim();
    $newName = $newName+' ('+$matches[0]+')'+$_.Extension;
	
	$_ | ren -NewName $newName -Confirm -Verbose;
}
##########################################################

##########################################################
# Rename all files in the current directory using IMDB

# To be run within the directory of the movie files that need to be renamed.
##########################################################
$files = Get-ChildItem -File -Recurse;

ForEach ($file in $files) {
	Write-Output '';
    Write-Output ('Current File: '+$file.FullName);
	
	# cleanup the file name before searching (make it URL safe)
	$searchName = $file.BaseName -replace '[()]',' ' -replace '\s+',' ';
	$searchName = $searchName.Trim();

    # search movie data from IMDB
	Write-Output ('Searching IMDB: '+$searchName.Replace(' ','+'));
    $searchResult = Invoke-RestMethod -Uri ('https://v2.sg.media-imdb.com/suggestion/'+$searchName.SubString(0,1).ToLower()+'/'+$searchName.Replace(' ','+')+'.json');

	# Older API
    #$content = Invoke-RestMethod -Uri ('https://sg.media-imdb.com/suggests/'+$searchName.SubString(0,1).ToLower()+'/'+$searchName.Replace(' ','+')+'.json');
    #$searchResult = $content.Substring($content.IndexOf('(')+1, $content.Length-$content.IndexOf('(')-2) | ConvertFrom-Json; # IMDB uses 

    if ($null -eq $searchResult.d) {
        Write-Output 'Error: No search results';
        Continue;
    }

    $movieData = $searchResult.d;
	
	# todo - Add a check to see if any results match filename exactly (case-sensitive)

    ForEach ($result in $movieData) {
        # if the Relased date is populated, then use it for the filename
        if ($result.y) {
			# Clear variables at the beginning of each loop just in case any errors occur and residual values aren't hanging around
			Clear-Variable -Name baseName -ErrorAction SilentlyContinue;
			Clear-Variable -Name movieYear -ErrorAction SilentlyContinue;
			Clear-Variable -Name newName -ErrorAction SilentlyContinue;
			Clear-Variable -Name renameResponse -ErrorAction SilentlyContinue;
			
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
					Write-Output 'New and old name are the same but different case...Fixing case...';
					$file | Rename-Item -NewName $newName;
				} else {
					Write-Output 'New and old name are the same, skipping...';
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
            Write-Output ('Error: Year not populated: ' + $result.y);
        }
    }
}