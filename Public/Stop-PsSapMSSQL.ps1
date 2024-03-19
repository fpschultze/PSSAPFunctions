<#
.SYNOPSIS
    Stop MSSQL
.DESCRIPTION
    Stop MSSQL services, that is
    1. MSSQL$<SID> or MSSQLSERVER service
    2. SQLAgent$<SID> or SQLSERVERAGENT service
    Both steps use the same timeout limit (TimeoutSec parameter)
.EXAMPLE
    Stop-PsSapMSSQL -SID ABC
.EXAMPLE
    Stop-PsSapMSSQL -SID ABC -TimeoutSec 90
#>
function Stop-PsSapMSSQL {
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
        $MSSQLServices = Get-PsSapMSSQLServices -SID $SID |
            Select-Object -ExpandProperty Name |
            Sort-Object -Descending # 1. SQLAgent$*|SQLSERVERAGENT, 2. MSSQL$*|MSSQLSERVER
        foreach ($Name in $MSSQLServices) {

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
