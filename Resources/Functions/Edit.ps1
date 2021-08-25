# Wrapper to reinitialize grid
function Update-Grid {
    $rows.Rows.Title = 'Rows  -  Unsaved changes'
    $rows.Undo.IsEnabled   = $true
    $rows.Commit.IsEnabled = $true
    $rows.Grid.ItemsSource = @($csv)
    $rows.Grid.Items.Refresh()
}

# Do not allow Undo and Commit buttons if
# there are no undo steps or ReadWrite is off 
function Get-CanEnableEditing ($UndoStack, $ReadWrite) {
    return [Bool] ($UndoStack) -and $ReadWrite
}

function Add-Undo ($UndoStack, $Operation, $At, $OldRow, $Count) {
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

            'Insert' {
                $Data.RemoveRange($Last.RowIndex, $Last.Count)
            }
        }

        $UndoStack.RemoveAt($UndoStack.Count-1)
    }
    return $UndoStack, $Data
}

function Add-Row ($At, $Count, $Header, $IsTemplate, $LeftCellFormat) {
    # $LeftCellFormat only used when $IsTemplate is TRUE
    # Prepare blank row template
    $RowTemplate = [PSCustomObject] @{}
    $Header.ForEach({$RowTemplate | Add-Member NoteProperty $_ ''})

    # Insert rows
    $Now = Get-Date
    $ThisAt = $At
    for ($i = 0; $i -lt $Count; $i++) {
        # Expand <x> notation if $IsTemplate
        $ThisRow = $RowTemplate.PSObject.Copy()
        if ($IsTemplate) {
            $ThisRow.($Header[0]) = $LeftCellFormat -replace
                '<D>', $Now.ToString('yyyyMMdd') -replace
                '<T>', $Now.ToString('HHmmss')   -replace
                '<#>', $i
        }
        
        if ($csv) {
            # Make IDs arranged in ascending order
            $script:csv.Insert($ThisAt, $ThisRow)
            $ThisAt += 1

        } else {
            [Collections.ArrayList] $script:csv = @($ThisRow)
        }
    }

    # Process undo
    $Parameters = @{
        UndoStack = $undo
        Operation = 'Insert'
        At        = $At
        OldRow    = ''
        Count     = $Count
    }
    [Collections.ArrayList] $script:undo = Add-Undo @Parameters
}
