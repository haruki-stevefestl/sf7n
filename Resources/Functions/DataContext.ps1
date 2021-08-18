function Expand-Path ($Path) {
    return ($ExecutionContext.InvokeCommand.ExpandString($Path))
}

function New-DataContext ($ImportFrom) {
    Write-Log 'Load configurations'
    $Key = Get-Content $ImportFrom | ConvertFrom-StringData

    Write-Log 'New  DataContext'
    return ([PSCustomObject] @{
        # Dynamic properties that support INPC
        InputAlias   = $Key.InputAlias  -ieq 'true'
        OutputAlias  = $Key.OutputAlias -ieq 'true'
        ReadWrite    = $Key.ReadWrite   -ieq 'true'

        # Static properties
        csvLocation  = $Key.csvLocation
        PreviewPath  = $Key.PreviewPath
        AppendFormat = $Key.AppendFormat
        AppendCount  = $Key.AppendCount
        HasAlias     = ''
    })
}
