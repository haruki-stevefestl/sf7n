# Start search
$rows.Searchbar.Add_TextChanged({
    # Search on ENTER pressed
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

# Search on OutputAlias changed
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

# Search on search button clicked
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
    if ($rows.Preview.Source -match 'file:///') {
        [Windows.Forms.Clipboard]::SetImage([Drawing.Image]::FromFile(
            $rows.Preview.Source.ToString().Replace('file:///','')
        ))
    }
})
