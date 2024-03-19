<#
.SYNOPSIS
    Waits for a SAP system to be started or stopped
.DESCRIPTION
    Wrapper for "sapcontrol.exe -host .. -nr .. -user .. .. -function WaitforStarted 360 0"

    Function waits for completion of the start or stop process.
.EXAMPLE
    Wait-PsSapSystem -Started
.EXAMPLE
    Wait-PsSapSystem -Stopped
.OUTPUTS
    bool
#>
function Wait-PsSapSystem {
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
        $Password,

        [Parameter()]
        [string]
        $TimeoutSec = '360',

        [switch]
        $Stopped
    )

    $SUCCESS = '0'  # Call successful
    $FAILURE = '1'  # Call failed, invalid parameter
    $TIMEOUT = '2' #  WaitforStarted, WaitforStopped timed out

    $returnValue = $false

    if ($PSBoundParameters.ContainsKey('Stopped')) {
        $SapControlFunction = 'WaitforStopped'
    }
    else {
        $SapControlFunction = 'WaitforStarted'
    }

    $ErrorActionPreference = 'Stop'

    try {
        if ($PSCmdlet.ParameterSetName -eq 'NoCredential') {
            $cmdLine = '"{0}\sapcontrol.exe" -host {1} -nr {2} -function {3} {4} 0' -f $PsSapExe, $Hostname, $InstanceNumber, $SapControlFunction, $TimeoutSec
        }
        else {
            if ($PSCmdlet.ParameterSetName -eq 'PSCredential') {
                $User = $Credential.UserName
                $Password = $Credential.GetNetworkCredential().Password
            }
            $cmdLine = '"{0}\sapcontrol.exe" -host {1} -nr {2} -user {3} {4} -function {5} {6} 0' -f $PsSapExe, $Hostname, $InstanceNumber, $User, $Password, $SapControlFunction, $TimeoutSec
        }

        $result = Invoke-CommandAsBatchFile -CommandLine $cmdLine

        switch ($result.ExitCode) {
            $SUCCESS {
                $returnValue = $true
                'The {0} return code indicates success.' -f $SapControlFunction | Write-Host #Write-Verbose
            }
            $FAILURE {
                throw ('The {0} return code indicates failure.' -f $SapControlFunction)
            }
            $TIMEOUT {
                throw ('The {0} call timed out.' -f $SapControlFunction)
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
