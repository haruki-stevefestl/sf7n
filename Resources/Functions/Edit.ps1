function Add-Row ($Data, $Action, $At, $Count, $Format, $Header) {
    # $Format and $Header only for $Action == 'InsertLast'
    # Prepare blank template for inserting
    $RowTemplate = [PSCustomObject] @{}
    $Header.Foreach({$RowTemplate | Add-Member NoteProperty $_ ''})
    
    if ($Action -eq 'InsertLast') {
        for ($i = 0; $i -lt $Count; $i++) {
            # Expand <x> noation
            $Now = Get-Date
            $ThisRow = $RowTemplate.PsObject.Copy()
            $ThisRow.($Header[0]) = $Format -replace
                '<D>', $Now.ToString('yyyyMMdd') -replace
                '<T>', $Now.ToString('HHmmss')   -replace
                '<#>', $I
            if ($Data) {
                $Data.Add($ThisRow)
            } else {
                [Collections.ArrayList] $Data = @($ThisRow)
            }
        }
        $rows.Grid.ScrollIntoView($rows.Grid.Items[-1], $rows.Grid.Columns[0])

    } else {
        # InsertAbove/InsertBelow
        # Max & Min to prevent under/overflowing
        for ($i = 0; $i -lt $Count; $i++) {
            $Data.Insert(
                [Math]::Max(0, [Math]::Min($At,$Data.Count)),
                $RowTemplate.PSObject.Copy()
            )
        }
    }

    $rows.Commit.IsEnabled = $true
    $rows.Grid.ItemsSource = $Data
    $rows.Grid.Items.Refresh()
}
