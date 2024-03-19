<#
.SYNOPSIS
    Provides some meta information about the instance.
.DESCRIPTION
    Get-PsSapInstanceProperty provides some meta information about the instance, which allows a client to display only information relevant for the actual instance type and version.
.EXAMPLE
    $SapInstanceProp = Get-PsSapInstanceProperty -InstanceNumber 79
.OUTPUTS
    Object[]
#>
function Get-PsSapInstanceProperty {
    [CmdletBinding(DefaultParameterSetName = 'NoCredential')]
    param (
        # Instance number (00-97)
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^([0-8]\d{1}|9[0-7])$')]
#        [ValidateScript( {(Get-PsSapInstances | Select-Object -ExpandProperty InstanceNumber) -contains $_} )]
        [string]
        $InstanceNumber
    )

    $ErrorActionPreference = 'Stop'
    $returnValue = $null
    try {
        $result = '"{0}\sapcontrol.exe" -nr {1} -function GetInstanceProperties' -f $PsSapExe, $InstanceNumber | Invoke-CommandAsBatchFile

        switch ($result.ExitCode) {
            0 {
                $returnValue = $result.StdOut | Select-Object -Skip 4 | ConvertFrom-Csv -Delimiter ','
            }
            default {
                if ($null -ne $result.StdOut) {
                    $FailMessage = $result.StdOut | Select-Object -Last 1 | Select-String -Pattern '^FAIL:\s{1}.*'
                    if ($null -ne $FailMessage) {
                        throw $FailMessage
                    }
                }
                throw 'Unknown error'
            }
        }
        Write-Output $returnValue
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
