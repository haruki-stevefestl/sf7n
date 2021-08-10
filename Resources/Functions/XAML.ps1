function New-GUI ($ImportFrom, $DataContext) {
    Write-Log 'New  GUI'
    Write-Log '  - Read XAML'
    [Xml] $Xaml = Get-Content $ImportFrom

    Write-Log '  - Parse XAML'
    # $Xaml = Set-XAMLTheme $Xaml $context.Theme
    $Form = [Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::New($Xaml))

    # Populate $Hash with elements
    Write-Log '  - Identify elements'
    $Hash = [Hashtable]::Synchronized(@{})
    $Xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]").Name.ForEach({
        if ($Hash.Keys -notcontains $_) {$Hash.Add($_, $Form.FindName($_))}
    })
    # $Hash.Rows.DataContext = $DataContext
    return $Hash
}

function Set-XAMLTheme ($Xaml, $Theme) {
    Write-Log '  - Set XAML theme'
    $Theme = ".\Configurations\Themes\$Theme.ini"
    if (Test-Path $Theme) {        
        $Brushes = $Xaml.Window.'Window.Resources'.SolidColorBrush

        # ConvertFrom-StringData hates paddings so parse the .ini manually
        foreach ($Line in (Get-Content $Theme)) {
            $Data = $Line.Split('=').Trim()
            $Brush = $Data[0]
            $Value = $Data[1]

            # Apply SolidColorBrush
            $Brushes.Where({$_.Key -eq "Brush_$Brush"}).ForEach({
                $_.Color = $Value
            })
        }
    }
    return $Xaml
}
