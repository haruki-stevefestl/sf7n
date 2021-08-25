# Prevent Undo and Commit if ReadWrite is off
$rows.ReadWrite.Add_Click({
    $rows.Undo.IsEnabled = 
        $rows.Commit.IsEnabled =
            Get-CanEnableEditing $undo $config.ReadWrite
})

# Enter edit mode
$rows.Grid.Add_BeginningEdit({
    $rows.Status.Text = 'Editing'
    $script:oldRow = $Args[1].Row.Item.PSObject.Copy()
})

# Commit change into $undo
$rows.Grid.Add_RowEditEnding({
    $Parameters = @{
        UndoStack = $undo
        Operation = 'Change'
        At        = $csv.IndexOf($Args[1].Row.Item)
        OldRow    = $oldRow
        Count     = 1
    }
    
    $rows.Rows.Title = 'Rows  -  Unsaved changes'
    [Collections.ArrayList] $script:undo = Add-Undo @Parameters
    $rows.Undo.IsEnabled = 
        $rows.Commit.IsEnabled =
            Get-CanEnableEditing $undo $config.ReadWrite
})

# Each function below corresponds to a button in the GUI
$rows.Undo.Add_Click({
    $script:undo, $script:csv = Invoke-Undo $undo $csv
    $rows.Undo.IsEnabled = Get-CanEnableEditing $undo $config.ReadWrite
    Update-Grid
})

$rows.InsertLast.Add_Click({
    $rows.Grid.ScrollIntoView($rows.Grid.Items[-1], $rows.Grid.Columns[0])
    Add-Row $csv.Count $config.AppendCount $csvHeader $config.IsTemplate $config.AppendFormat
    Update-Grid
})

$rows.InsertAbove.Add_Click({
    $At = $csv.IndexOf($rows.Grid.SelectedItem)
    $Count = $rows.Grid.SelectedItems.Count
    Add-Row $At $Count $csvHeader $config.IsTemplate $config.AppendFormat
    Update-Grid
})

$rows.InsertBelow.Add_Click({
    $At = $csv.IndexOf($rows.Grid.SelectedItem)
    $Count = $rows.Grid.SelectedItems.Count
    Add-Row ($At+$Count) $Count $csvHeader $config.IsTemplate $config.AppendFormat
    Update-Grid
})

$rows.RemoveSelected.Add_Click({
    $rows.Grid.SelectedItems.ForEach({
        $Parameters = @{
            UndoStack = $undo
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
    $rows.Rows.Title = 'Rows'
})
