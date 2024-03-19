<#
.SYNOPSIS
    Restarts SAP services
.DESCRIPTION
    Wrapper for "saphostexec.exe -restart"
.EXAMPLE
    Restart-PsSapHostAgent
.OUTPUTS
    boolean
#>
function Restart-PsSapHostAgent {
    [CmdletBinding()]
    param ()
    $ErrorActionPreference = 'Stop'
    try {
        $result = '"{0}\saphostexec.exe" -restart' -f $PsSapExe | Invoke-CommandAsBatchFile

        switch ($result.ExitCode) {
            0 {
                $returnValue = Test-PsSapHostAgent
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
