function New-GUI ($ImportFrom, $DataContext) {
    Write-Log 'New  GUI'
    Write-Log '  - Read XAML'
    [Xml] $Xaml = Get-Content $ImportFrom

    Write-Log '  - Parse XAML'
    $Form = [Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::New($Xaml))

    # Populate $Hash with elements
    Write-Log '  - Identify elements'
    $Hash = [Hashtable]::Synchronized(@{})
    $Xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]").Name.ForEach({
        if ($Hash.Keys -notcontains $_) {$Hash.Add($_, $Form.FindName($_))}
    })
    
    return $Hash
}
