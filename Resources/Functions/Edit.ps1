function Add-Row ($Data, $Action, $At, $Count, $Format, $Header) {
    # $Format and $Header only for $Action == 'InsertLast'

    # Prepare blank template for inserting
    $RowTemplate = [PSCustomObject] @{}
    $Header.Foreach({$RowTemplate | Add-Member NoteProperty $_ ''})
    
    if ($Action -eq 'InsertLast') {
        for ($i = 0; $i -lt $Count; $i++) {
            # Expand %x (legacy) and <x> (current) noation
            $ThisRow = $RowTemplate.PsObject.Copy()
            $ThisRow.($Header[0]) = $Format -replace
                '%D|<D>', (Get-Date -Format yyyyMMdd) -replace
                '%T|<T>', (Get-Date -Format HHmmss)   -replace
                '%#|<#>', $I
            if ($Data) {
                $Data.Add($ThisRow)
            } else {
                [System.Collections.ArrayList] $Data = @($ThisRow)
            }
        }
        $rows.CSVGrid.ScrollIntoView($rows.CSVGrid.Items[-1], $rows.CSVGrid.Columns[0])

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
    $rows.CSVGrid.ItemsSource = $Data
    $rows.CSVGrid.Items.Refresh()
}
