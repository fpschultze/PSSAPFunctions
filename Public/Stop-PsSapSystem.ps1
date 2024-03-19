<#
.SYNOPSIS
    Stops a SAP system
.DESCRIPTION
    Wrapper for "sapcontrol.exe -host ... -nr ... -user ... -function StopSystem ALL"

    Function does not wait for completion of the stop process.
.EXAMPLE
    Stop-PsSapSystem
.OUTPUTS
    bool
#>
function Stop-PsSapSystem {
    [CmdletBinding(DefaultParameterSetName = 'NoCredential')]
    param (
        # Host to connect to (default: localhost)
        [Parameter()]
        [string]
        $Hostname = 'localhost',

        # Instance number
        [Parameter(Mandatory = $true)]
        [string]
        $InstanceNumber,

        # Instance type
        [Parameter()]
        [ValidateSet('ALL', 'SCS', 'DIALOG', 'ABAP', 'J2EE', 'TREX', 'ENQREP', 'HDB', 'ALLNOHDB')]
        [string]
        $InstanceType = 'ALL',

        # Credentials for Webservice authentication
        [Parameter(ParameterSetName = 'PSCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        # Alternate credentials (plain-text user)
        [Parameter(ParameterSetName = 'PlainTextCredential')]
        [String]
        $User,

        # Alternate credentials (plain-text password)
        [Parameter(ParameterSetName = 'PlainTextCredential')]
        [String]
        $Password
    )

    $SUCCESS = '0'  # Call successful
    $FAILURE = '1'  # Call failed
    $returnValue = $false

    $ErrorActionPreference = 'Stop'
    try {
        if ($PSCmdlet.ParameterSetName -eq 'NoCredential') {
            $cmdLine = '"{0}\sapcontrol.exe" -host {1} -nr {2} -function StopSystem {3}' -f $PsSapExe, $Hostname, $InstanceNumber, $InstanceType
        }
        else {
            if ($PSCmdlet.ParameterSetName -eq 'PSCredential') {
                $User = $Credential.UserName
                $Password = $Credential.GetNetworkCredential().Password
            }
            $cmdLine = '"{0}\sapcontrol.exe" -host {1} -nr {2} -user {3} {4} -function StopSystem {5}' -f $PsSapExe, $Hostname, $InstanceNumber, $User, $Password, $InstanceType
        }

        $result = Invoke-CommandAsBatchFile -CommandLine $cmdLine

        switch ($result.ExitCode) {
            $SUCCESS {
                $returnValue = $true
                'The stop of the SAP system is in progress.' | Write-Host #Write-Verbose
            }
            $FAILURE {
                throw 'Failed to stop the SAP system.'
            }
            default {
                throw 'Unexpected return code.'
            }
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        Write-Output $returnValue
    }
}
