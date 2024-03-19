function Stop-PsSapStartService {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidatePattern('SAP\w{3}_\d{2}')]
        [string[]]
        $Name,

        [Parameter()]
        [int]
        $TimeoutSec = 60,

        [Parameter()]
        [switch]
        $PassThru
    )
    begin {
        [System.ServiceProcess.ServiceControllerStatus] $DesiredServiceStatus = 'Stopped'
        $ErrorActionPreference = 'Stop'
    }
    process {
        try {
            $service = Get-Service -Name $Name


            #----------------------------------------------------------------------------------------------------------
            #region Ensure service status

            if ($service.Status -ne $DesiredServiceStatus) {
                $service | Wait-Service -Status $DesiredServiceStatus -TimeoutSec $TimeoutSec
            }

            if ($PSBoundParameters.ContainsKey('PassThru')) {
                Write-Output $service
            }
            else {
                $service | Format-Table -AutoSize -Property Name, Status, StartType
            }

            #endregion
            #----------------------------------------------------------------------------------------------------------
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
