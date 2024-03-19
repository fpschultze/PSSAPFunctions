function Test-PsSapStartService {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidatePattern('SAP\w{3}_\d{2}')]
        [string[]]
        $Name
    )
    begin {
        $RequiredStatus = [System.ServiceProcess.ServiceControllerStatus]::Running
        $RequiredStartType = [System.ServiceProcess.ServiceStartMode]::Automatic
        $UnwantedServiceProperty = 'DelayedAutostart'
        $ErrorActionPreference = 'Stop'
    }
    process {
        $regPath = 'Registry::HKLM\System\CurrentControlSet\Services\{0}' -f $Name
        $returnValue = $false
        try {
            Get-Service -Name $Name |
                Where-Object {($_.Status -eq $RequiredStatus) -and ($_.StartType -eq $RequiredStartType)} |
                ForEach-Object {
                    $returnValue = (Get-Item -Path $regPath | Select-Object -ExpandProperty Property) -notcontains $UnwantedServiceProperty
                }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        finally {
            $returnValue
        }
    }
}
