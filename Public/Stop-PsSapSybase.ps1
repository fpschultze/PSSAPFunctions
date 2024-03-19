<#
.SYNOPSIS
    Stop Sybase
.DESCRIPTION
    Stop Sybase services, that is
    1. SYBSQL_<UPPERSID>
    2. SYBBCK_<UPPERSID>_BS
    Both steps use the same timeout limit (TimeoutSec parameter)
.EXAMPLE
    Stop-PsSapSybase -SID ABC
.EXAMPLE
    Stop-PsSapSybase -SID ABC -TimeoutSec 90
.OUTPUTS
    bool
#>
function Stop-PsSapSybase {
    [CmdletBinding()]
    param (
        # The SID
        [Parameter(Mandatory = $true)]
        [ValidateLength(3, 3)]
        [string]
        $SID,

        # Timeout limit for reaching the desired service status
        [Parameter()]
        [int]
        $TimeoutSec = 60
    )
    $returnValue = $false

    [System.ServiceProcess.ServiceControllerStatus] $DesiredServiceStatus = 'Stopped'

    $ErrorActionPreference = 'Stop'
    try {
        $SybaseServices = @(Get-PsSapSybaseServices -SID $SID | Select-Object -ExpandProperty Name)
        if ($SybaseServices.Count -eq 0) {
            throw 'No Sybase services found'
        }

        foreach ($Name in $SybaseServices) {

            'About to stop {0}' -f $Name | Write-Host

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
echo Stopping Sybase Services  ...
net stop SYBSQL_UPPERSID
net stop SYBBCK_UPPERSID_BS
#>