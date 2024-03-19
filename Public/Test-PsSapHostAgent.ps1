<#
.SYNOPSIS
    Gets status information of SAP instances, databases, and components
.DESCRIPTION
    Wrapper for "saphostexec.exe -status"
.EXAMPLE
    $SAPServiceStatus = Test-PsSapHostAgent
.OUTPUTS
    bool
#>
function Test-PsSapHostAgent {
    [CmdletBinding()]
    param (
        [switch]
        $Stopped
    )
    $regEx = '.*\(pid\s{1}\=\s{1}(?<PID>\d+)\)'
    $ErrorActionPreference = 'Stop'
    try {
        $result = '"{0}\saphostexec.exe" -status' -f $PsSapExe | Invoke-CommandAsBatchFile

        $totalProcesses = $result.StdErr.Count
        $runningProcesses = @($result.StdErr | Where-Object {$_ -match $regEx} | Where-Object {$Matches.PID -gt 0}).Count
        if ($PSBoundParameters.ContainsKey('Stopped')) {
            0 -eq $runningProcesses
        }
        else {
            $totalProcesses -eq $runningProcesses
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
