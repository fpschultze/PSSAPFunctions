function Get-PsSapDBType {
    [CmdletBinding()]
    param ()

    $ErrorActionPreference = 'Stop'
    try {
        [PsDBType]$DBType = 'None'
        switch (Get-Service | Select-Object -ExpandProperty Name) {
            {$_ -eq 'XServer'} {
                $DBType = 'ADA'
                break
            }
            {$_ -like 'MSSQL*'} {
                $DBType = 'MSS'
                break
            }
            {$_ -like 'OracleService???'} {
                $DBType = 'ORA'
                break
            }
            {$_ -like "SYB???_*"} {
                $DBType = 'SYB'
                break
            }
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        Write-Output $DBType
    }
}
