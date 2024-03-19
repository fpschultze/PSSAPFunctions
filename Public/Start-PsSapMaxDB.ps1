<#
.SYNOPSIS
    Start MaxDB
.DESCRIPTION
    Start MaxDB services, that is
    1. dbmcli -U c -d <SID> db_online
    2. XServer service
    Both steps use the same timeout limit (TimeoutSec parameter)
.EXAMPLE
    Start-PsSapMaxDB -SID ABC
.EXAMPLE
    Start-PsSapMaxDB -SID ABC -TimeoutSec 90
#>
function Start-PsSapMaxDB {
    [CmdletBinding()]
    param (
        # The SID
        [Parameter(Mandatory = $true)]
        [ValidateLength(3,3)]
        [string]
        $SID,

        # Timeout limit for reaching the desired DB and service status
        [Parameter()]
        [int]
        $TimeoutSec = 60
    )
    $returnValue = $false

    $DesiredDBStatus = 'OK'

    [System.ServiceProcess.ServiceControllerStatus] $DesiredServiceStatus = 'Running'

    $ErrorActionPreference = 'Stop'
    try {
        Write-Host 'About to start MaxDB'

        $result = 'dbmcli -U c -d {0} db_online' -f $SID.ToUpper() | Invoke-CommandAsBatchFile -TimeoutSec $TimeoutSec

        if ($result.StdOut -ne $DesiredDBStatus) {
            throw 'The DB status is not ok.'
        }

        Write-Host 'About to start XServer'

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
