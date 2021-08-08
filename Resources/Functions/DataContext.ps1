function Expand-Path ($Path) {
    return ($ExecutionContext.InvokeCommand.ExpandString($Path))
}

function New-DataContext ($ImportFrom) {
    Write-Log 'Load configurations'
    $Key = Get-Content $ImportFrom | ConvertFrom-StringData

    Write-Log 'New  DataContext'
    return ([PSCustomObject] @{
        csvLocation  = $Key.csvLocation
        PreviewPath  = $Key.PreviewPath
        Theme        = $Key.Theme
        AppendFormat = $Key.AppendFormat
        AppendCount  = $Key.AppendCount
        InputAlias   = $Key.InputAlias  -ieq 'true'
        OutputAlias  = $Key.OutputAlias -ieq 'true'
        ReadWrite    = $Key.ReadWrite   -ieq 'true'
    })
}
