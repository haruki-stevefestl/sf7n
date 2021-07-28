# Start search
$wpf.Searchbar.Add_TextChanged({
    if ($wpf.Searchbar.Text -match '[\r\n]') {
        $PrevCursor = $wpf.Searchbar.SelectionStart - 2
        $wpf.Searchbar.Text = $wpf.Searchbar.Text -replace '[\r\n]'
        $wpf.Searchbar.SelectionStart = $PrevCursor

        Search-CSV $wpf.Searchbar.Text $csv
    }
})

$wpf.Search.Add_Click({Search-CSV $wpf.Searchbar.Text $csv})

# Set preview on cell change
$wpf.CSVGrid.Add_SelectionChanged({
    # Expand <ColumnName> notation
    $Preview = Expand-Path $context.PreviewPath
    $Regex   = '(?<=<)(.+?)(?=>)'
    ($Preview | Select-String $Regex -AllMatches).Matches.Value.ForEach({
        $Preview = $Preview.Replace("<$_>", $wpf.CSVGrid.SelectedItem.$_)
    })
    
    if (Test-Path $Preview) {$wpf.Preview.Source = $Preview}
})

# Copy preview
$wpf.PreviewCopy.Add_Click({
    $Preview = $wpf.Preview.Source.ToString()
    $Preview = $Preview.Replace('file:///','')

    if (Test-Path $Preview) {
        [Windows.Forms.Clipboard]::SetImage([Drawing.Image]::FromFile(
            $Preview
        ))
    }
})
