function Get-PsSapMSSQLServices {
    [CmdletBinding()]
    param (
        # The SID
        [Parameter(Mandatory = $true)]
        [ValidateLength(3,3)]
        [string]
        $SID
    )
    $returnValue = $null
    $ErrorActionPreference = 'Stop'
    try {
        $allServices = Get-Service -Name '*SQL*'

        # Check named instance service names
        $theEnd = '${0}' -f $SID.ToUpper()
        $returnValue = $allServices | Where-Object {$_.Name.EndsWith($theEnd)}

        # Fall back to default instance names
        if ($null -eq $returnValue) {
            $returnValue = $allServices | Where-Object {'SQLSERVERAGENT', 'MSSQLSERVER' -contains $_.Name}
        }

        Write-Output $returnValue
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
