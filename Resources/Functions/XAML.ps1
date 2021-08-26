function New-GUI ($ImportFrom) {
    Write-Log 'New  GUI'
    Write-Log '  - Read XAML'
    [Xml] $Xaml = Get-Content $ImportFrom

    Write-Log '  - Parse XAML'
    $Form = [Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::New($Xaml))

    # Populate $Hash with elements
    Write-Log '  - Identify elements'
    $Hash = [Hashtable]::Synchronized(@{})
    $Xaml.SelectNodes('//*[@Name]').Name.ForEach({
        $Hash[$_] = $Form.FindName($_)
    })
    
    return $Hash
}
