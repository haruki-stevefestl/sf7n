# Enter edit mode
$rows.Grid.Add_BeginningEdit({
    $rows.Status.Text = 'Editing'
    $script:oldRow = $Args[1].Row.Item.PSObject.Copy()
})

# Change rows (add/change/remove)
$rows.Grid.Add_RowEditEnding({
    $Parameters = @{
        UndoStack = $undo
        Data      = $csv
        Operation = 'Change'
        At        = $csv.IndexOf($Args[1].Row.Item)
        OldRow    = $oldRow
        Count     = 1
    }
    
    [Collections.ArrayList] $script:undo = Add-Undo @Parameters
    $rows.Undo.IsEnabled = $true
    $rows.Commit.IsEnabled = $true
})

$rows.Undo.Add_Click({
    $script:undo, $script:csv = Invoke-Undo $undo $csv
    $rows.Undo.IsEnabled = [Boolean] $undo
    Update-Grid
})

$rows.InsertLast.Add_Click({
    Add-Row 'InsertLast' $csv.Count $config.AppendCount $csvHeader $config.AppendFormat
    Update-Grid
})

$rows.InsertAbove.Add_Click({
    $rows.Grid.ScrollIntoView($rows.Grid.Items[-1], $rows.Grid.Columns[0])
    
    $At = $csv.IndexOf($rows.Grid.SelectedItem)
    $Count = $rows.Grid.SelectedItems.Count
    Add-Row 'InsertAbove' $At $Count $csvHeader
    Update-Grid
})

$rows.InsertBelow.Add_Click({
    $At = $csv.IndexOf($rows.Grid.SelectedItem)
    $Count = $rows.Grid.SelectedItems.Count
    Add-Row 'InsertAbove' ($At+$Count) $Count $csvHeader
    Update-Grid
})

$rows.RemoveSelected.Add_Click({
    $rows.Grid.SelectedItems.ForEach({
        # Process undo
        $Parameters = @{
            UndoStack = $undo
            Data      = $csv
            Operation = 'Remove'
            OldRow    = $_
            At        = $csv.IndexOf($_)
            Count     = 1
        }
        [Collections.ArrayList] $script:undo = Add-Undo @Parameters
        $csv.Remove($_)
    })
    Update-Grid
})

$rows.Commit.Add_Click({
    Export-CustomCSV $csv $config.csvLocation
    $rows.Commit.IsEnabled = $false
})
