<#
.SYNOPSIS
    Provides a list of all instances of the system with its assigned priority level.
.DESCRIPTION
    Wrapper for "sapcontrol.exe -nr ... -function GetSystemInstanceList"
    Returns a list of all instances of the SAP system. features identifies the instance type (ABAP, J2EE, GATEWAY, MESSAGESERVER, ENQUE, ICMAN, TREX, IGS, ENQREP), e.g.:
    Dual-stack dialog instance: "ABAP|J2EE|GATEWAY|ICMAN"
    SCS instance: "MESSAGESERVER|ENQUE"
.EXAMPLE
    $SapSystemInstanceList = Get-PsSapSystemInstanceList
.OUTPUTS
    Object[]
#>
function Get-PsSapSystemInstanceList {
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
        $result = '"{0}\sapcontrol.exe" -nr {1} -function GetSystemInstanceList' -f $PsSapExe, $InstanceNumber | Invoke-CommandAsBatchFile

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
