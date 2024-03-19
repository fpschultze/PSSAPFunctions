function Wait-Service {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $Name,

        [int]
        $TimeoutSec = 60,

        [switch]
        $PassThru,

        [Parameter()]
        [System.ServiceProcess.ServiceControllerStatus]
        $Status = 'Running'
    )
    begin {
        $WaitForStatusTimeout = New-TimeSpan -Seconds ($TimeoutSec - 1)
        $ErrorActionPreference = 'Stop'
    }
    process {
        try {
            $service = Get-Service -Name $Name

            if ($service.Status -eq $Status) {
                'Nothing to do - service "{0}" has desired status' -f $service.Name | Write-Host #Write-Verbose
                break
            }

            switch ($Status) {
                'Running' {
                    switch ($service.Status) {
                        'StartPending' {
                            'Start service is pending - {0}' -f $service.Name | Write-Host #Write-Verbose
                        }
                        'Stopped' {
                            'Starting the service because it has been stopped - {0}' -f $service.Name | Write-Host #Write-Verbose
                            $service = $service | Start-Service -PassThru
                        }
                        'StopPending' {
                            'Stop is pending - {0}' -f $service.Name | Write-Host #Write-Verbose
                            $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped, $WaitForStatusTimeout)
                            'Starting the service - {0}' -f $service.Name | Write-Host #Write-Verbose
                            $service = $service | Start-Service -PassThru
                        }
                    }
                }
                'Stopped' {
                    switch ($service.Status) {
                        'StopPending' {
                            'Stop service is pending - {0}' -f $service.Name | Write-Host #Write-Verbose
                        }
                        'Running' {
                            'Stopping the service because it is running - {0}' -f $service.Name | Write-Host #Write-Verbose
                            $service = $service | Stop-Service -PassThru
                        }
                        'StartPending' {
                            'Start is pending - {0}' -f $service.Name | Write-Host #Write-Verbose
                            $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running, $WaitForStatusTimeout)
                            'Stopping the service - {0}' -f $service.Name | Write-Host #Write-Verbose
                            $service = $service | Stop-Service -PassThru
                        }
                    }
                }
            }

            'Waiting max {0} seconds until the service has entered the "{1}" status' -f $TimeoutSec, $Status | Write-Host #Write-Verbose
            Start-Sleep -Seconds 1
            $service.WaitForStatus($Status, $WaitForStatusTimeout)

            $service.Refresh()
            if ($PSBoundParameters.ContainsKey('PassThru')) {
                Write-Output $service
            }
            else {
                $service | Format-Table -AutoSize -Property Name, Status, StartType
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
