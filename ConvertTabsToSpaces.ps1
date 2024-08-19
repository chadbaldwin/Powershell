function Convert-TabsToSpaces {
    param (
        [Parameter(ValueFromPipeline)][string]$InputLine,
        [Parameter()][int]$TabWidth = 4
    )

    process {
        $outputLine = ''
        $position = 0

        foreach ($char in $InputLine.ToCharArray()) {
            if ($char -eq "`t") {
                $spacesToAdd = $TabWidth - ($position % $TabWidth)
                $outputLine += " " * $spacesToAdd
                $position += $spacesToAdd
            } else {
                $outputLine += $char
                $position++
            }
        }

        $outputLine
    }
}

# Usage
gci -File -Recurse -PV file |
    ? Extension -in ('.sql','.ps1','.json') |
    % {
        # split and join on /n as this will still retain /r/n
        $c = ((gc $_ -Raw) -split "`n" | Convert-TabsToSpaces -TabWidth 4) -join "`n"
        Set-Content -Value $c -Path $file -Encoding utf8 -NoNewLine
    }
