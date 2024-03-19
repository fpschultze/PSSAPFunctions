function Get-PsSapStartServices {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidatePattern('SAP\w{3}_\d{2}')]
        [string[]]
        $Name = 'SAP???_??'
    )
    $ErrorActionPreference = 'Stop'
    try {
        Get-Service -Name $Name
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
