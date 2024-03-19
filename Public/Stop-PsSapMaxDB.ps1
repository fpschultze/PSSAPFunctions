<#
.SYNOPSIS
    Stop MaxDB
.DESCRIPTION
    Stop MaxDB services, that is
    1. dbmcli -U c -d <SID> db_offline
    2. XServer service
    Both steps use the same timeout limit (TimeoutSec parameter)
.EXAMPLE
    Stop-PsSapMaxDB -SID ABC
.EXAMPLE
    Stop-PsSapMaxDB -SID ABC -TimeoutSec 90
#>
function Stop-PsSapMaxDB {
    [CmdletBinding()]
    param (
        # The SID
        [Parameter(Mandatory = $true)]
        [ValidateLength(3, 3)]
        [string]
        $SID,

        # Timeout limit for reaching the desired DB and service status
        [Parameter()]
        [int]
        $TimeoutSec = 60
    )
    $returnValue = $false

    $DesiredDBStatus = 'OK'

    [System.ServiceProcess.ServiceControllerStatus] $DesiredServiceStatus = 'Stopped'

    $ErrorActionPreference = 'Stop'
    try {
        Write-Host 'About to stop MaxDB'

        $result = 'dbmcli -U c -d {0} db_offline' -f $SID.ToUpper() | Invoke-CommandAsBatchFile -TimeoutSec $TimeoutSec

        if ($result.StdOut -ne $DesiredDBStatus) {
            throw 'The DB status is not ok.'
        }

        Write-Host 'About to stop XServer'

        $Service = Get-Service -Name XServer
        if ($Service.Status -ne $DesiredServiceStatus) {
            $Service | Wait-Service -Status $DesiredServiceStatus -TimeoutSec $TimeoutSec
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
