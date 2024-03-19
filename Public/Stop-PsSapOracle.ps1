<#
.SYNOPSIS
    Stop Oracle
.DESCRIPTION
    Stop Oracle services, that is
    1. Stop database
    2. listener
    Both steps use the same timeout limit (TimeoutSec parameter)
.EXAMPLE
    Stop-PsSapOracle
.EXAMPLE
    Stop-PsSapOracle -TimeoutSec 90
#>
function Stop-PsSapOracle {
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
        Write-Host 'About to stop Database'

        $tmpSqlScript = Get-TempFileName
        @'
whenever sqlerror exit sql.sqlcode
connect / as sysdba
shutdown immediate;
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

        Write-Host 'About to stop Listener'

        $parameters = @{
            CommandLine = 'lsnrctl STOP'
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

        $ListenerOK = [bool]($result.StdOut | Select-String -SimpleMatch 'The command completed successfully') -or
                      [bool]($result.StdOut | Select-String -SimpleMatch 'no listener')

        if ($ListenerOK -eq $false) {
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
echo Stopping Database wirh sqlplus  ...
echo connect / as sysdba> f:\usr\sap\scripts\work\stopdb.sql
echo shutdown immediate;>> f:\usr\sap\scripts\work\stopdb.sql
echo exit>> f:\usr\sap\scripts\work\stopdb.sql
sqlplus /nolog @f:\usr\sap\scripts\work\stopdb.sql

echo ==========================================================================
echo Stopping Listener  ...
lsnrctl stop
#>
