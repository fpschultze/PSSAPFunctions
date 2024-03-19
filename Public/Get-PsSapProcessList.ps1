<#
.SYNOPSIS
    Gets status information of SAP processes
.DESCRIPTION
    Wrapper for "sapcontrol.exe -host ... -nr ... -function GetProcessList"
.EXAMPLE
    $SapProcesses = Get-PsSapProcessList
.OUTPUTS
    System.String[]
#>
function Get-PsSapProcessList {
    [CmdletBinding(DefaultParameterSetName = 'NoCredential')]
    param (
        # Host to connect to (default: localhost)
        [Parameter()]
        [string]
        $Hostname = 'localhost',

        # Instance number (00-97)
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^([0-8]\d{1}|9[0-7])$')]
#        [ValidateScript( {(Get-PsSapInstances | Select-Object -ExpandProperty InstanceNumber) -contains $_} )]
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
        $Password
    )

    $DefaultStatus = 'Mixed'
    $Fail = @{
        CommandExitCode = 1
        Status          = 'Failed'
    }
    $AllProcessesRunning = @{
        CommandExitCode = 3
        Status          = 'AllRunning'
    }
    $AllProcessesStopped = @{
        CommandExitCode = 4
        Status          = 'AllStopped'
    }
    $ErrorActionPreference = 'Stop'
    try {
        if ($PSCmdlet.ParameterSetName -eq 'NoCredential') {
            $cmdLine = '"{0}\sapcontrol.exe" -host {1} -nr {2} -function GetProcessList' -f $PsSapExe, $Hostname, $InstanceNumber
        }
        else {
            if ($PSCmdlet.ParameterSetName -eq 'PSCredential') {
                $User = $Credential.UserName
                $Password = $Credential.GetNetworkCredential().Password
            }
            $cmdLine = '"{0}\sapcontrol.exe" -host {1} -nr {2} -user {3} {4} -function GetProcessList' -f $PsSapExe, $Hostname, $InstanceNumber, $User, $Password
        }

        $result = Invoke-CommandAsBatchFile -CommandLine $cmdLine

        $returnValue = [PSCustomObject]@{
            InstanceNumber = $InstanceNumber
            Process        = $(
                if ($null -ne $result.StdOut) {
                    $FailMessage = $result.StdOut | Select-Object -Last 1 | Select-String -Pattern '^FAIL:\s{1}.*'
                    if ($null -eq $FailMessage) {
                        @($result.StdOut | Select-Object -Skip 4 | ConvertFrom-Csv -Delimiter ',')
                    }
                    else {
                        $FailMessage | Write-Warning
                    }
                }
                else {
                    @()
                }
            )
        }
        switch ($result.ExitCode) {
            $Fail.CommandExitCode {
                $sapstartsvc = Get-PsSapStartServices | Where-Object {$_.Name -like ('*_{0}' -f $InstanceNumber)} | Test-PsSapStartService
                if ($sapstartsvc -eq $false) {
                    $returnValue | Add-Member -MemberType NoteProperty -Name Status -Value 'SapStartServiceStopped'
                }
                else {
                    $returnValue | Add-Member -MemberType NoteProperty -Name Status -Value $Fail.Status
                }
            }
            $AllProcessesRunning.CommandExitCode {
                'All processes running correctly' | Write-Host #Write-Verbose
                $returnValue | Add-Member -MemberType NoteProperty -Name Status -Value $AllProcessesRunning.Status
            }
            $AllProcessesStopped.CommandExitCode {
                'All processes stopped' | Write-Host #Write-Verbose
                $returnValue | Add-Member -MemberType NoteProperty -Name Status -Value $AllProcessesStopped.Status
            }
            default {
                $returnValue | Add-Member -MemberType NoteProperty -Name Status -Value $DefaultStatus
            }
        }
        Write-Output $returnValue
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
