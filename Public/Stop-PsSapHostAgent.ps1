<#
.SYNOPSIS
    Stops SAP services
.DESCRIPTION
    Wrapper for "saphostexec.exe -stop"
.EXAMPLE
    Stop-PsSapHostAgent
.OUTPUTS
    boolean
#>
function Stop-PsSapHostAgent {
    [CmdletBinding()]
    param ()
    $ErrorActionPreference = 'Stop'
    try {
        $result = '"{0}\saphostexec.exe" -stop' -f $PsSapExe | Invoke-CommandAsBatchFile

        switch ($result.ExitCode) {
            0 {
                $returnValue = Test-PsSapHostAgent -Stopped
            }
            default {
                $returnValue = $false
            }
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        $returnValue
    }
}
