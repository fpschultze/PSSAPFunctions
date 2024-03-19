function Get-PsSapSybaseServices {
    [CmdletBinding()]
    param (
        # The SID
        [Parameter(Mandatory = $true)]
        [ValidateLength(3,3)]
        [string]
        $SID
    )
    $ErrorActionPreference = 'Stop'
    try {
        Get-Service | Where-Object {$_.Name -match "SYB\w{3}_$($SID.ToUpper())(_BS)?"}
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
