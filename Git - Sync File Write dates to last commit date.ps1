###############################################

###############################################
# Newer version - works well with very large and long history repos
###############################################
<#
  This newer version inverts the method of the old version. Instead of grabbing each file
  and looking up its last commit date from the git history. It instead grabs the last N
  amount of time from the history, parses it into a hash table, grabs the most recent
  log for a given item, then iterates through that list to apply the dates.
  
  The only caveat here is that files that have not been touched older than the `--since`
  date supplied to git, will display a current date.
  
  One option could be to set all files to an old date first, like 1999-01-01, and then
  run this code.
#>
# gci -Recurse -File | % { (gi -LiteralPath $_).LastWriteTime = [datetime]'1999-01-01' }

$commitdate = $null

git log --name-only --pretty=format:"~~~%aI" --since="4 years ago" `
  | ? { $_ } -PV line <# remove blank lines #>`
  | % { <# parse lines #>
      if ($line -match '^~~~') {
        $commitdate = [datetime]($line -replace '^~~~')
        return
      }
      [pscustomobject]@{
        commitdate = $commitdate
        filepath = $line
      }
    } `
  | group filepath `
  | % { $_.Group | sort commitdate -Desc -Top 1 } `
  | ? { Test-Path -LiteralPath $_.filepath } `
  | % {
      $_.filepath
      (gi -LiteralPath $_.filepath).LastWriteTime = $_.commitdate
    }
###############################################

###############################################
# Older version - works well with lower number of files/folders/shorter history
###############################################
gci -Recurse -File |
    % {
        $_.FullName;
        $fileDate = git log -1 --pretty="format:%cI" $_.FullName;
        $_.LastWriteTime = [datetime]$fileDate;
    }
