# Start search
$rows.Searchbar.Add_TextChanged({
    if ($rows.Searchbar.Text -match '[\r\n]') {
        $PrevCursor = $rows.Searchbar.SelectionStart - 2
        $rows.Searchbar.Text = $rows.Searchbar.Text -replace '[\r\n]'
        $rows.Searchbar.SelectionStart = $PrevCursor
        
        $Parameters = @{
            SearchText = $rows.Searchbar.Text
            SearchFrom = $csv
            InputAlias  = $config.InputAlias
            OutputAlias = $config.OutputAlias
            Alias       = $csvAlias 
        }
        Search-CSV @Parameters
    }
})

$rows.OutputAlias.Add_Click({
    $Parameters = @{
        SearchText = $rows.Searchbar.Text
        SearchFrom = $csv
        InputAlias  = $config.InputAlias
        OutputAlias = $config.OutputAlias
        Alias       = $csvAlias 
    }
    Search-CSV @Parameters
})

$rows.Search.Add_Click({
    $Parameters = @{
        SearchText = $rows.Searchbar.Text
        SearchFrom = $csv
        InputAlias  = $config.InputAlias
        OutputAlias = $config.OutputAlias
        Alias       = $csvAlias 
    }
    Search-CSV @Parameters
})

# Set preview on row change
$rows.Grid.Add_SelectionChanged({
    # Expand <ColumnName> notation
    $Preview = Expand-Path $config.PreviewPath
    $Regex   = '(?<=<)(.+?)(?=>)'
    $Match   = $Preview | Select-String $Regex -AllMatches
    $Match.Matches.Value.ForEach({
        $Preview = $Preview.Replace("<$_>", $rows.Grid.SelectedItem.$_)
    })

    if (Test-Path $Preview) {
        $rows.Preview.Source = $Preview
    } else {
        $rows.Preview.Source = $null
    }
})

# Copy preview
$rows.PreviewCopy.Add_Click({
    # ' '+ to prevent InvokeMethodOnNull exception
    $Preview = ' '+$rows.Preview.Source

    if ($Preview -match 'file:///') {
        [Windows.Forms.Clipboard]::SetImage([Drawing.Image]::FromFile(
            $Preview.Replace('file:///','')
        ))
    }
})
