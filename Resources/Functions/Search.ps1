function Search-CSV ($SearchText, $SearchFrom, $InputAlias, $OutputAlias, $Alias) {
    # Initialize
    if ($SearchFrom.Count -eq 0) {
        $rows.Status.Text = 'Editing'
        return
    }
    $rows.CSVGrid.ItemsSource = $null
    $rows.Preview.Source      = $null
    $rows.Status.Text         = 'Searching'

    # Parse SearchRules Text into [PSCustomObject] $Criteria
    $Criteria = [PSCustomObject] @{}
    $Regex    = '(["'']?)(.+?)\1[:=](["'']?)(.+?)\3(\s|$)'
    $Match    = ($SearchText | Select-String $Regex -AllMatches).Matches

    $Match.ForEach({
        $Header = $_.Groups[2].Value
        $Value  = $_.Groups[4].Value
        $Criteria | Add-Member -NotePropertyName $Header $Value
    })

    # Apply input alias
    if ($InputAlias) {
        $Criteria.PSObject.Properties.ForEach({
            $Header = $_.Name
            # Take into account of empty alias strings
            $Count  = ($Alias.$Header | Where-Object {$_}).Count
            for ($i = 0; $i -lt $Count; $i += 2) {
                $_.Value = $_.Value.Replace($Alias[$i+1].$Header, $Alias[$i].$Header)
            }
        })
    }

    # Search with new Powershell instance
    $Ps = [PowerShell]::Create().AddScript{
        function Update-GUI ([Action] $Action) {
            $rows.Rows.Dispatcher.Invoke($Action, 'ApplicationIdle')
        }

        [Collections.ArrayList] $Search = @()
        foreach ($Entry in $SearchFrom) {
            if ('' -ne $Criteria) {
                # If notMatch, goto next iteration
                $Criteria.PSObject.Properties.ForEach({
                    if ($Entry.($_.Name) -notmatch $_.Value) {continue}
                })
            }
        
            # Add entry; apply alias if OutputAlias is on 
            if ($OutputAlias) {
                $Row = $Entry.PSObject.Copy()
                $Row.PSObject.Properties.ForEach({
                    $Header = $_.Name
                    # Take into account of empty alias strings
                    $Count  = ($Alias.$Header | Where-Object {$_}).Count
                    for ($i = 0; $i -lt $Count; $i += 2) {
                        $_.Value = $_.Value.Replace($Alias[$i].$Header, $Alias[$i+1].$Header)
                    }
                })
                $Search.Add($Row)
            } else {
                $Search.Add($Entry)
            }

            # Show preliminary results
            if ($Search.Count -eq 25) {
                Update-GUI {$rows.CSVGrid.ItemsSource = $Search.PSObject.Copy()}
            }
        }
        # Show full results
        Update-GUI {$rows.CSVGrid.ItemsSource = $Search}
        Update-GUI {$rows.Status.Text = 'Ready'}
    }
    
    # Assign runspace to instance
    $Ps.Runspace = [RunspaceFactory]::CreateRunspace()
    $Ps.Runspace.ApartmentState = 'STA'
    $Ps.Runspace.ThreadOptions = 'ReuseThread'
    $Ps.Runspace.Open()
    (Get-Variable rows,SearchFrom,Criteria,Alias,OutputAlias).ForEach({
        $Ps.Runspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
    })
    $Ps.BeginInvoke()
}
