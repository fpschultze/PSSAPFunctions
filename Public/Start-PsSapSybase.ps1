<#
.SYNOPSIS
    Start Sybase
.DESCRIPTION
    Start Sybase services, that is
    1. SYBSQL_<UPPERSID>
    2. SYBBCK_<UPPERSID>_BS
    Both steps use the same timeout limit (TimeoutSec parameter)
.EXAMPLE
    Start-PsSapSybase -SID ABC
.EXAMPLE
    Start-PsSapSybase -SID ABC -TimeoutSec 90
#>
function Start-PsSapSybase {
    [CmdletBinding()]
    param (
        # The SID
        [Parameter(Mandatory = $true)]
        [ValidateLength(3,3)]
        [string]
        $SID,

        # Timeout limit for reaching the desired service status
        [Parameter()]
        [int]
        $TimeoutSec = 60
    )
    $returnValue = $false

    [System.ServiceProcess.ServiceControllerStatus] $DesiredServiceStatus = 'Running'

    $ErrorActionPreference = 'Stop'
    try {
        $SybaseServices = @(Get-PsSapSybaseServices -SID $SID | Select-Object -ExpandProperty Name)
        if ($SybaseServices.Count -eq 0) {
            throw 'No Sybase services found'
        }

        foreach ($Name in $SybaseServices) {

            'About to start {0}' -f $Name | Write-Host

            $Service = Get-Service -Name $Name
            if ($Service.Status -ne $DesiredServiceStatus) {
                $Service | Wait-Service -Status $DesiredServiceStatus -TimeoutSec $TimeoutSec
            }
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
echo Starting Sybase Services  ...
net start SYBSQL_UPPERSID
net start SYBBCK_UPPERSID_BS
#>