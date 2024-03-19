<#
.SYNOPSIS
    Start MSSQL
.DESCRIPTION
    Start MSSQL services, that is
    1. SQLAgent$<SID> service
    2. MSSQL$<SID> service
    Both steps use the same timeout limit (TimeoutSec parameter)
.EXAMPLE
    Start-PsSapMSSQL -SID ABC
.EXAMPLE
    Start-PsSapMSSQL -SID ABC -TimeoutSec 90
#>
function Start-PsSapMSSQL {
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
        $MSSQLServices = Get-PsSapMSSQLServices -SID $SID |
            Select-Object -ExpandProperty Name |
            Sort-Object # 1. MSSQL$*|MSSQLSERVER, 2. SQLAgent$*|SQLSERVERAGENT
        foreach ($Name in $MSSQLServices) {

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
