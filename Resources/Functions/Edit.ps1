function Update-Grid {
    $rows.Undo.IsEnabled   = $true
    $rows.Commit.IsEnabled = $true
    $rows.Grid.ItemsSource = $csv
    $rows.Grid.Items.Refresh()
}

function Add-Undo ($UndoStack, $Data, $Operation, $At, $OldRow, $Count) {
    $ToAdd = [PSCustomObject] @{
        Action   = $Operation
        RowIndex = $At
        Original = $OldRow.PSObject.Copy()
        Count    = $Count
    }

    if ($UndoStack) {
        # Add to undo stack if any one of requirements satisfied
        #   - row value changed
        #   - row index changed
        $ToAdd.Original.PSObject.Properties.ForEach({
            if ($_.Value -ne $UndoStack[-1].Original.($_.Name)) {
                $UndoStack.Add($ToAdd)
                return $UndoStack
            }
        })

        if ($ToAdd.RowIndex -ne $UndoStack[-1].RowIndex) {
            $UndoStack.Add($ToAdd)
            return $UndoStack
        }
        
    } else {
        # @($null, ) since PSv5 (only) cannot handle single element
        # https://github.com/PowerShell/PowerShell/issues/2208
        [Collections.ArrayList] $UndoStack = @($null, $ToAdd)
        return $UndoStack
    }
}

function Invoke-Undo ($UndoStack, $Data) {
    if ($UndoStack) {
        $Last = $UndoStack[-1]

        switch -regex ($Last.Action) {
            'Change' {
                $Data[$Last.RowIndex] = $Last.Original
            }

            'Remove' {
                # Readd row
                if ($Data) {
                    $Data.Insert($Last.RowIndex, $Last.Original)
                } else {
                    [Collections.ArrayList] $Data = @($Last.Original)   
                }
            }

            'Insert(Last|Above|Below)' {
                if ($Last.Action -eq 'InsertBelow') {$Offset = $Last.Conut}
                $Data.RemoveRange($Last.RowIndex+$Offset, $Last.Count)
            }
        }

        $UndoStack.RemoveAt($UndoStack.Count-1)
    }
    return $UndoStack, $Data
}

function Add-Row ($Data, $Action, $At, $Count, $Header, $Format) {
    # $Format and $Header only for $Action == 'InsertLast'
    # Prepare blank template for inserting
    $RowTemplate = [PSCustomObject] @{}
    $Header.Foreach({$RowTemplate | Add-Member NoteProperty $_ ''})
    
    if ($Action -eq 'InsertLast') {
        $Now = Get-Date
        for ($i = 0; $i -lt $Count; $i++) {
            # Expand <x> noation
            $ThisRow = $RowTemplate.PSObject.Copy()
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
        $Data.InsertRange(
            [Math]::Max(0, [Math]::Min($At, $Data.Count)),
            @($RowTemplate)*$Count
        )
    }

    # Process undo
    $Parameters = @{
        UndoStack = $undo
        Data      = $csv
        Operation = $Action
        At        = $At
        OldRow    = ''
        Count     = $Count
    }
    [Collections.ArrayList] $script:undo = Add-Undo @Parameters

    return $Data
}
