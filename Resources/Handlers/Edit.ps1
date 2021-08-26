# Prevent Undo and Commit if ReadWrite is off
$rows.ReadWrite.Add_Click({
    $rows.Undo.IsEnabled = 
        $rows.Commit.IsEnabled =
            Get-CanEdit $undo $config.ReadWrite
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
            Get-CanEdit $undo $config.ReadWrite
})

# Each function below corresponds to a button in the GUI
$rows.Undo.Add_Click({
    if ($undo) {
        $Last = $undo[-1]
        switch ($Last.Action) {
            'Change' {$csv[$Last.RowIndex] = $Last.Original}

            'Remove' {
                if ($csv) {
                    $csv.Insert($Last.RowIndex, $Last.Original)
                } else {
                    [Collections.ArrayList] $script:csv = @($Last.Original)
                }
            }

            'Insert' {$csv.RemoveRange($Last.RowIndex, $Last.Count)}
        }
        $undo.RemoveAt($undo.Count-1)
    }

    $rows.Undo.IsEnabled = Get-CanEdit $undo $config.ReadWrite
    Update-Grid
})

$rows.InsertLast.Add_Click({
    $rows.Grid.ScrollIntoView($rows.Grid.Items[-1], $rows.Grid.Columns[0])
    $Parameters = @{
        At     = $csv.Count
        Count  = $config.AppendCount
        Header = $csvHeader
        IsTemplate     = $config.IsTemplate
        LeftCellFormat = $config.AppendFormat
    }
    Add-Row @Parameters
    Update-Grid
})

$rows.InsertAbove.Add_Click({
    $Parameters = @{
        At     = $csv.IndexOf($rows.Grid.SelectedItem)
        Count  = $rows.Grid.SelectedItems.Count
        Header = $csvHeader
        IsTemplate     = $config.IsTemplate
        LeftCellFormat = $config.AppendFormat
    }
    Add-Row @Parameters
    Update-Grid
})

$rows.InsertBelow.Add_Click({
    $Parameters = @{
        At     = $csv.IndexOf($rows.Grid.SelectedItem)
        Count  = $rows.Grid.SelectedItems.Count
        Header = $csvHeader
        IsTemplate     = $config.IsTemplate
        LeftCellFormat = $config.AppendFormat
    }
    $Parameters.At += $Parameters.Count
    Add-Row @Parameters
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
