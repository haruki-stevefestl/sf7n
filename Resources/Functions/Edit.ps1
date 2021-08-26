# Wrapper to reinitialize grid
function Update-Grid {
    $rows.Rows.Title = 'Rows  -  Unsaved changes'
    $rows.Undo.IsEnabled   = $true
    $rows.Commit.IsEnabled = $true
    $rows.Grid.ItemsSource = $csv
    $rows.Grid.Items.Refresh()
}

# Do not allow Undo and Commit buttons if
# there are no undo steps or ReadWrite is off 
function Get-CanEdit ($UndoStack, $ReadWrite) {
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
    # detect if the row was changed or read only,
    # so for now all non-duplicate actions are written into $UndoStack
    # See https://stackoverflow.com/q/30640700/
    if ($UndoStack) {
        if ($UndoStack[-1] -ne $ToAdd) {
            $UndoStack.Add($ToAdd)
        }
        
    } else {
        # @($null, ) since PSv5 (only) cannot handle single element
        # https://github.com/PowerShell/PowerShell/issues/2208
        [Collections.ArrayList] $UndoStack = @($null, $ToAdd)
    }
    return $UndoStack
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
            $ThisAt++

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
