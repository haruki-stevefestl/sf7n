function Search-CSV ($SearchText, $SearchFrom) {
    # Initialize
    if ($SearchFrom.Count -eq 0) {
        $wpf.Status.Text = 'Editing'
        return
    }

    $wpf.CSVGrid.ItemsSource = $null
    $wpf.Preview.Source      = $null
    $wpf.Status.Text         = 'Searching'

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
    if ($context.InputAlias) {
        $Criteria.PSObject.Properties.ForEach({
            $Header = $_.Name
            # Take into account of empty alias strings
            $Count  = ($csvAlias.$Header | Where-Object {$_}).Count
            for ($i = 0; $i -lt $Count; $i += 2) {
                $_.Value = $_.Value.Replace($csvAlias[$i+1].$Header, $csvAlias[$i].$Header)
            }
        })
    }

    # Search with new Powershell instance
    $Ps = [PowerShell]::Create().AddScript{
        function Update-GUI ([Action] $Action) {
            $wpf.Rows.Dispatcher.Invoke($Action, 'ApplicationIdle')
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
            if ($context.OutputAlias) {
                $Row = $Entry.PSObject.Copy()
                $Row.PSObject.Properties.ForEach({
                    $Header = $_.Name
                    # Take into account of empty alias strings
                    $Count  = ($csvAlias.$Header | Where-Object {$_}).Count
                    for ($i = 0; $i -lt $Count; $i += 2) {
                        $_.Value = $_.Value.Replace($csvAlias[$i].$Header, $csvAlias[$i+1].$Header)
                    }
                })
                $Search.Add($Row)
            } else {
                $Search.Add($Entry)
            }

            # Show preliminary results
            if ($Search.Count -eq 25) {
                Update-GUI {$wpf.CSVGrid.ItemsSource = $Search.PSObject.Copy()}
            }
        }
        # Show full results
        Update-GUI {$wpf.CSVGrid.ItemsSource = $Search}
        Update-GUI {$wpf.Status.Text = 'Ready'}
    }
    
    # Assign runspace to instance
    $Ps.Runspace = [RunspaceFactory]::CreateRunspace()
    $Ps.Runspace.ApartmentState = 'STA'
    $Ps.Runspace.ThreadOptions = 'ReuseThread'
    $Ps.Runspace.Open()
    (Get-Variable wpf,SearchFrom,Criteria,csvAlias,context).ForEach({
        $Ps.Runspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
    })
    $Ps.BeginInvoke()
    $wpf.TabControl.SelectedIndex = 1
}
