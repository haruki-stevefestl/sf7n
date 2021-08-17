function Update-Grid {
    $rows.Undo.IsEnabled   = $true
    $rows.Commit.IsEnabled = $true
    $rows.Grid.ItemsSource = @($csv)
    $rows.Grid.Items.Refresh()
}

function Add-Undo ($UndoStack, $Data, $Operation, $At, $OldRow, $Count) {
    $ToAdd = [PSCustomObject] @{
        Action   = $Operation
        RowIndex = $At
        Original = $OldRow
        Count    = $Count
    }
    
    # Thanks to Microsoft, it is almost impossible to
    # detect if the row was changed or just accessed,
    # so for now all actions are written into $UndoStack
    # See https://stackoverflow.com/q/30640700/
    if ($UndoStack) {
        $UndoStack.Add($ToAdd)
        
    } else {
        # @($null, ) since PSv5 (only) cannot handle single element
        # https://github.com/PowerShell/PowerShell/issues/2208
        [Collections.ArrayList] $UndoStack = @($null, $ToAdd)
    }
    return $UndoStack
}

function Invoke-Undo ($UndoStack, $Data) {
    if ($UndoStack) {
        $Last = $UndoStack[-1]

        switch -regex ($Last.Action) {
            'Change' {
                $Data[$Last.RowIndex] = $Last.Original
            }

            'Remove' {
                if ($Data) {
                    $Data.Insert($Last.RowIndex, $Last.Original)
                } else {
                    [Collections.ArrayList] $Data = @($Last.Original)
                }
            }

            'Insert(Above|Below|Last)' {
                if ($Last.Action -eq 'InsertBelow') {$Offset = $Last.Conut}
                $Data.RemoveRange($Last.RowIndex+$Offset, $Last.Count)
            }
        }

        $UndoStack.RemoveAt($UndoStack.Count-1)
    }
    return $UndoStack, $Data
}

function Add-Row ($Action, $At, $Count, $Header, $Format) {
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
            if ($csv) {
                $script:csv.Insert($csv.Count, $ThisRow)
            } else {
                [Collections.ArrayList] $script:csv = @($ThisRow)
            }
        }
        
    } else {
        # InsertAbove/InsertBelow
        # Max & Min to prevent under/overflowing
        $script:csv.InsertRange(
            [Math]::Max(0, [Math]::Min($At, $csv.Count)),
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
}
