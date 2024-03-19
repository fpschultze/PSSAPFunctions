<#
.SYNOPSIS
    Gets status information of SAP instances
.DESCRIPTION
    Wrapper for "saphostctrl.exe -function ListInstances [-running (list running instances only) | -stopped (list stopped instances only)]"
.EXAMPLE
    $SapInstances = Get-PsSapInstances
.OUTPUTS
    pscustomobject
#>
function Get-PsSapInstances {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('Running', 'Stopped')]
        [string]
        $Scope
    )

    $regEx = '.*:\s{1}(?<SID>\w{3})\s{1}-\s{1}(?<InstanceNumber>\d{2})\s{1}-\s{1}(?<HostName>\w+)'

    $ErrorActionPreference = 'Stop'
    try {
        $cmdLine = '"{0}\saphostctrl.exe" -function ListInstances' -f $PsSapExe
        switch ($Scope) {
            'Running' {
                $cmdLine = '{0} -running' -f $cmdLine
            }
            'Stopped' {
                $cmdLine = '{0} -stopped' -f $cmdLine
            }
        }

        $result = Invoke-CommandAsBatchFile -CommandLine $cmdLine

        $result.StdOut | Where-Object {$_ -match $regEx} | ForEach-Object {
            $Matches.Remove(0)
            [pscustomobject]$Matches
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
