function Import-CustomCSV ($ImportFrom) {
    # Returns the following variables:
    #   - Csv        [AList] Content
    #   - CsvHeader  [Array] Header of the CSV
    #   - CsvAlias   [Array] Aliases for CSV
    Write-Log 'Get  CSV'
    $ImportFrom = Expand-Path $ImportFrom

    # @() because https://github.com/PowerShell/PowerShell/issues/2208
    [Collections.ArrayList] $Csv = @(Import-CSV $ImportFrom)

    $Reader = [IO.StreamReader]::New($ImportFrom)
    $CsvHeader = $Reader.Readline() -replace '"' -split ','

    $CsvAlias = '.\Configurations\CSVAlias.csv'
    if (Test-Path $CsvAlias) {$CsvAlias = Import-CSV $CsvAlias}

    if (!$CsvHeader) {
        throw (
            'The input CSV file is empty' + "`n" +
            'Please set a valid path within the configuration file.'
        )
    }

    return $Csv, $CsvHeader, $CsvAlias
}

function Export-CustomCSV ($Data, $ExportTo) {
    try {
        $Data | Export-CSV (Expand-Path $ExportTo) -NoTypeInformation
    } catch {
        throw ('CSV cannot be saved: '+$_)
    }
}
