<#
.SYNOPSIS
    Start Oracle
.DESCRIPTION
    Start Oracle services, that is
    1. listener
    2. Start database
    Both steps use the same timeout limit (TimeoutSec parameter)
.EXAMPLE
    Start-PsSapOracle
.EXAMPLE
    Start-PsSapOracle -TimeoutSec 90
#>
function Start-PsSapOracle {
    [CmdletBinding(DefaultParameterSetName = 'NoCredential')]
    param (
        # Timeout limit for reaching the desired DB and service status
        [Parameter()]
        [int]
        $TimeoutSec = 60,

        # Alternate credentials
        [Parameter(ParameterSetName = 'PSCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        # Alternate credentials (plain-text user)
        [Parameter(ParameterSetName = 'PlainTextCredential')]
        [String]
        $User,

        # Alternate credentials (plain-text password)
        [Parameter(ParameterSetName = 'PlainTextCredential')]
        [String]
        $Pass
    )
    $returnValue = $false

    $ErrorActionPreference = 'Stop'
    try {
        Write-Host 'About to start Listener'

        $parameters = @{
            CommandLine = 'lsnrctl start'
            TimeoutSec  = $TimeoutSec
        }
        switch ($PSCmdlet.ParameterSetName) {
            'PlainTextCredential' {
                $parameters.Add('Credential', (New-Object System.Management.Automation.PSCredential($User, ($Pass | ConvertTo-SecureString -AsPlainText -Force))))
            }
            'PSCredential' {
                $parameters.Add('Credential', $Credential)
            }
        }

        $result = Invoke-CommandAsBatchFile @parameters

        $ListenerOK = [bool]($result.StdOut | Select-String -Pattern '^Uptime\s+(?<Days>\d)\s\w+\s(?<Hr>\d)\s\w+\.\s(?<Min>\d)\s\w+\.\s(?<Sec>\d)\s\w+') -or
                      [bool]($result.StdOut | Select-String -SimpleMatch 'has already been started') -or
                      [bool]($result.StdOut | Select-String -SimpleMatch 'The command completed successfully')

        if ($ListenerOK -eq $false) {
            throw 'Something went wrong'
        }

        Write-Host 'About to start Database'

        $tmpSqlScript = Get-TempFileName
        @'
whenever sqlerror exit sql.sqlcode
connect / as sysdba
startup;
exit
'@ | Set-Content -Path $tmpSqlScript -Encoding Ascii

        $parameters = @{
            CommandLine = 'sqlplus /nolog @{0}' -f $tmpSqlScript
            TimeoutSec  = $TimeoutSec
        }
        switch ($PSCmdlet.ParameterSetName) {
            'PlainTextCredential' {
                $parameters.Add('Credential', (New-Object System.Management.Automation.PSCredential($User, ($Pass | ConvertTo-SecureString -AsPlainText -Force))))
            }
            'PSCredential' {
                $parameters.Add('Credential', $Credential)
            }
        }

        $result = Invoke-CommandAsBatchFile @parameters

        if ($null, 0 -notcontains $result.ExitCode) {
            throw 'Something went wrong'
        }

        $returnValue = $true
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        $returnValue
    }
}

<#
echo ==========================================================================
echo Starting Listener  ...
lsnrctl start

echo ==========================================================================
echo Starting Database  ...
echo connect / as sysdba>f:\usr\sap\scripts\work\startdb.sql
echo startup; >>f:\usr\sap\scripts\work\startdb.sql
echo exit>>f:\usr\sap\scripts\work\startdb.sql
sqlplus /nolog @f:\usr\sap\scripts\work\startdb.sql
#>