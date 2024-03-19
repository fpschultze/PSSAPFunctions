<#
.SYNOPSIS
    Gets status information of SAP instances, databases, and components
.DESCRIPTION
    Wrapper for "saphostctrl.exe -function ListDatabases"
.EXAMPLE
    $dbStatus = Get-PsSapDatabases
.OUTPUTS
    PSCustomObject
#>
function Get-PsSapDatabases {
    [CmdletBinding()]
    param ()

    function ConvertTo-CustomObject {
        [CmdletBinding()]
        Param (
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            $InputObject
        )
        Begin {
            $instanceClass = [PSCustomObject]@{
                InstanceName = $null
                Hostname     = $null
                Vendor       = $null
                Type         = $null
                Release      = $null
                Database     = @()
            }
            $databaseClass = [PSCustomObject]@{
                DatabaseName = $null
                Status       = $null
                Component    = @()
            }
            $componentClass = [PSCustomObject]@{
                ComponentName        = $null
                ComponentDescription = $null
                Status               = $null
                StatusDescription    = $null
            }
        }
        Process {
            switch -regex ($InputObject) {
                #For MS-SQL w/ Default Instance: match empty InstanceName
                '^Instance name:\s{1}(?<InstanceName>\w+|),\s{1}Hostname:\s{1}(?<Hostname>\w+),\s{1}Vendor:\s{1}(?<Vendor>\w+),\s{1}Type:\s{1}(?<Type>\w+),\s{1}Release:\s{1}(?<Release>.*)$' {
                    if ($null -ne $myInstance) {
                        $myInstance.Database += $myDatabase
                        Write-Output $myInstance
                    }
                    else {
                        $myInstance = $instanceClass.PSObject.Copy()
                    }
                    $Matches.Keys | Where-Object {$_ -ne '0'} | ForEach-Object {
                        $myInstance.$_ = $Matches.$_
                    }
                }
                #For stopped MS-SQL: match empty DatabaseName
                '^\s{2}Database name:\s{1}(?<DatabaseName>\w+|),\s{1}Status:\s{1}(?<Status>\w+)$' {
                    #Workaround for MS-SQL w/ Default Instance: replace empty InstanceName with DatabaseName
                    if ($myInstance.Type -eq 'mss') {
                        if ([string]::IsNullOrEmpty($myInstance.InstanceName)) {
                            $myInstance.InstanceName = $Matches.DatabaseName
                        }
                    }
                    $myDatabase = $databaseClass.PSObject.Copy()
                    $Matches.Keys | Where-Object {$_ -ne '0'} | ForEach-Object {
                        $myDatabase.$_ = $Matches.$_
                    }
                }
                '^\s{4}Component name:\s{1}(?<ComponentName>\w+)\s{1}\((?<ComponentDescription>.*)\),\s{1}Status:\s{1}(?<Status>\w+)\s{1}\((?<StatusDescription>.*)\)$' {
                    $myComponent = $componentClass.PSObject.Copy()
                    $Matches.Keys | Where-Object {$_ -ne '0'} | ForEach-Object {
                        $myComponent.$_ = $Matches.$_
                    }
                    $myDatabase.Component += $myComponent
                }
            }
        }
        End {
            if ($null -ne $myInstance) {
                $myInstance.Database += $myDatabase
                Write-Output $myInstance
            }
        }
    }

    $ErrorActionPreference = 'Stop'
    try {
        $result = '"{0}\saphostctrl.exe" -function ListDatabases' -f $PsSapExe | Invoke-CommandAsBatchFile

        if ($null -ne $result.StdOut) {
            $result.StdOut | ConvertTo-CustomObject
        }
        if ($null -ne $result.StdErr) {
#            $result.StdErr | Write-Warning
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
