function Repair-PsSapStartService {
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
        [System.ServiceProcess.ServiceControllerStatus] $DesiredServiceStatus = 'Running'
        [System.ServiceProcess.ServiceStartMode] $DesiredServiceStartType = 'Automatic'
        $UnwantedServiceProperty = 'DelayedAutostart'
        $ErrorActionPreference = 'Stop'
    }
    process {
        try {
            $service = Get-Service -Name $Name
            $regPath = 'Registry::HKLM\System\CurrentControlSet\Services\{0}' -f $Name
            $serviceNeedsRestart = $false


            #----------------------------------------------------------------------------------------------------------
            #region Fix start type

            if ($service.StartType -ne $DesiredServiceStartType) {
                switch ($service.StartType) {
                    'Boot' {
                        'The service start mode is "Boot" - {0}' -f $service.Name | Write-Host #Write-Verbose
                    }
                    'Disabled' {
                        'The service start mode is "Disabled" - {0}' -f $service.Name | Write-Host #Write-Verbose
                    }
                    'Manual' {
                        'The service start mode is "Manual" - {0}' -f $service.Name | Write-Host #Write-Verbose
                    }
                    'System' {
                        'The service start mode is "System" - {0}' -f $service.Name | Write-Host #Write-Verbose
                    }
                }
                'Setting the service start mode to "{0}"' -f $DesiredServiceStartType | Write-Host #Write-Verbose
                $service | Set-Service -StartupType $DesiredServiceStartType
                $serviceNeedsRestart = $true
            }

            if ((Get-Item -Path $regPath | Select-Object -ExpandProperty Property) -contains $UnwantedServiceProperty) {
                'Removing the "{0}" option for the service' -f $UnwantedServiceProperty | Write-Host #Write-Verbose
                Remove-ItemProperty -Path $regPath -Name $UnwantedServiceProperty
                $serviceNeedsRestart = $true
            }

            if ($serviceNeedsRestart -eq $true) {
                $service = $service | Stop-Service -PassThru
            }

            #endregion
            #----------------------------------------------------------------------------------------------------------


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
