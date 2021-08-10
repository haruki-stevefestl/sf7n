# Start search
$rows.Searchbar.Add_TextChanged({
    if ($rows.Searchbar.Text -match '[\r\n]') {
        $PrevCursor = $rows.Searchbar.SelectionStart - 2
        $rows.Searchbar.Text = $rows.Searchbar.Text -replace '[\r\n]'
        $rows.Searchbar.SelectionStart = $PrevCursor
        
        $Parameters = @{
            SearchText = $rows.Searchbar.Text
            SearchFrom = $csv
            InputAlias  = $context.InputAlias
            OutputAlias = $context.OutputAlias
            Alias       = $csvAlias 
        }
        Search-CSV @Parameters
    }
})

$rows.Search.Add_Click({
    $Parameters = @{
        SearchText = $rows.Searchbar.Text
        SearchFrom = $csv
        InputAlias  = $context.InputAlias
        OutputAlias = $context.OutputAlias
        Alias       = $csvAlias 
    }
    Search-CSV @Parameters
})

# Set preview on cell change
$rows.CSVGrid.Add_SelectionChanged({
    # Expand <ColumnName> notation
    $Preview = Expand-Path $context.PreviewPath
    $Regex   = '(?<=<)(.+?)(?=>)'
    ($Preview | Select-String $Regex -AllMatches).Matches.Value.ForEach({
        $Preview = $Preview.Replace("<$_>", $rows.CSVGrid.SelectedItem.$_)
    })
    
    if (Test-Path $Preview) {$rows.Preview.Source = $Preview}
})

# Copy preview
$rows.PreviewCopy.Add_Click({
    $Preview = $rows.Preview.Source.ToString()
    $Preview = $Preview.Replace('file:///','')

    if (Test-Path $Preview) {
        [Windows.Forms.Clipboard]::SetImage([Drawing.Image]::FromFile(
            $Preview
        ))
    }
})
