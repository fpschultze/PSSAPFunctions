function Write-InvocationInfoBegin {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'MyInvocation object')]
        [object]
        $Invocation,

        [Parameter()]
        [object]
        $BoundParameters
    )

    'Entered function - {0}' -f $Invocation.InvocationName | Write-Verbose

    switch ($PSBoundParameters.Keys) {
        'BoundParameters' {
            $Invocation.MyCommand.Parameters.GetEnumerator() |
                Where-Object {'Debug', 'Verbose', 'WhatIf', 'Confirm' -notcontains $_.Key} |
                ForEach-Object {
                try {
                    $key = $_.Key
                    if ($key -notlike '*pass*') {
                        $val = Get-Variable -Name $key -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop
                        if (([String]::IsNullOrEmpty($val) -and (!$BoundParameters.ContainsKey($key)))) {
                            throw 'A blank value that was not supplied by the user.'
                        }
                    }
                    else {
                        $val = '********'
                    }
                    'Param {0} => "{1}"' -f $key, $val | Write-Verbose
                }
                catch {}
            }
        }
    }
}

function Write-InvocationInfoEnd {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = 'MyInvocation object')]
        [object]
        $Invocation,

        [Parameter()]
        [object]
        $Result,

        [Parameter()]
        [object]
        $BoundParameters
    )

    'Leaving function - {0}' -f $Invocation.InvocationName | Write-Verbose

    switch ($PSBoundParameters.Keys) {
        'BoundParameters' {
            $Invocation.MyCommand.Parameters.GetEnumerator() |
                Where-Object {'Debug', 'Verbose', 'WhatIf', 'Confirm' -notcontains $_.Key} |
                ForEach-Object {
                try {
                    $key = $_.Key
                    if ($key -notlike '*pass*') {
                        $val = Get-Variable -Name $key -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop
                        if (([String]::IsNullOrEmpty($val) -and (!$BoundParameters.ContainsKey($key)))) {
                            throw 'A blank value that was not supplied by the user.'
                        }
                    }
                    else {
                        $val = '********'
                    }
                    'Param {0} => "{1}"' -f $key, $val | Write-Verbose
                }
                catch {}
            }
        }
        'Result' {
            if ($null -eq $Result) {
                'Result: NULL-Value' | Write-Verbose
            }
            else {
                'Result:' | Write-Verbose
                try {
                    $Result.ToString() | Write-Verbose -ErrorAction Stop
                }
                catch {
                    $Result.GetType().ToString() | Write-Verbose -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

function ConvertTo-Base64String {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $String
    )
    $Bytes = [System.Text.Encoding]::ASCII.GetBytes($String)
    [System.Convert]::ToBase64String($Bytes)
}

function Get-TempFileName {
    [CmdletBinding()]
    param ()
    [System.IO.Path]::GetTempFileName()
}

function Open-LockedFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $Path,

        [Parameter()]
        [ValidateSet('Read', 'ReadWrite', 'Write')]
        [System.IO.FileAccess]
        $FileAccess = 'Read'
    )
    $ErrorActionPreference = 'Stop'
    $mode = 'Open'
    $share = 'None'
    try {
        [System.IO.File]::Open($Path, $mode, $FileAccess, $share)
    }
    catch {
        $_.Exception.Message
    }
}

function Test-LockedFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $Path
    )
    $ErrorActionPreference = 'Stop'
    try {
        $null = Get-Content @PSBoundParameters
        $returnValue = $false
    }
    catch [System.IO.IOException] {
        $returnValue = $true
    }
    finally {
        $returnValue
    }
}

function Close-LockedFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.IO.FileStream]
        $File
    )
    $ErrorActionPreference = 'Stop'
    try {
        $File.Close()
    }
    catch {
        $_.Exception.Message
    }
}

function Join-UrlPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( {
                [Uri]::IsWellFormedUriString($_, [UriKind]::Absolute)
            })]
        [String]
        $BasePath,

        [Parameter(Mandatory = $true)]
        [String]
        $ChildPath
    )
    $Uri = ($BasePath, $ChildPath | ForEach-Object {$_.Trim('/')}) -join '/'
    Write-Output $Uri
}

function Start-RandomSleep {
    [CmdletBinding()]
    param (
        $MaximumSeconds = 10
    )
    $Seconds = (Get-Random) % $MaximumSeconds + 1
    'Waiting less than {0} seconds...' -f $Seconds | Write-Verbose
    Start-Sleep -Seconds $Seconds
}

function Send-JsonOverTcp {
    [CmdletBinding()]
    param (
        $LogstashServer,
        $Port,
        $JsonString
    )

    begin {
        $HostAddresses = [System.Net.Dns]::GetHostAddresses($LogstashServer)
        $IPAddress = [System.Net.IPAddress]::Parse($HostAddresses)
        $TCPClient = New-Object System.Net.Sockets.TCPClient($IPAddress, $Port)
        $Stream = $TCPClient.GetStream()
        $StreamWriter = New-Object System.IO.StreamWriter($Stream)
    }

    process {
        $JsonOneLiner = $JsonString -replace "`n", ' ' -replace "`r", ' ' -replace ' ', ''
        $StreamWriter.WriteLine($JsonOneLiner)
    }
    end {
        $StreamWriter.Flush()
        $StreamWriter.Close()
        $TCPClient.Close()
    }
}

function ConvertFrom-Ini {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $InputObject
    )

    begin {
        $ErrorActionPreference = 'Stop'
        $OutputObject = [pscustomobject]@{}
        $Converted = [ordered]@{}
    }

    process {
        try {
            switch -Regex ($InputObject) {
                '^(\s+)?;|^\s*$' {
                    #Skipt Comment or blank line
                }
                '^(\s+)?\[(?<Section>.*)\](\s+)?$' {
                    if ($Converted.Count -gt 0) {
                        $OutputObject | Add-Member -MemberType Noteproperty -Name $Section -Value $([pscustomobject]$Converted) -Force
                        $Converted = [ordered]@{}
                    }
                    $Section = $Matches.Section.Trim()
                }
                '^(?<Name>.*)\=(?<Value>.*)$' {
                    $Converted.Add($Matches.Name.Trim(), $Matches.Value.Trim())
                }
                default {
                    'Unexpected line: {0}' -f $_ | Write-Warning
                }
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    end {
        If ($Converted.Count -gt 0) {
            $OutputObject | Add-Member -MemberType Noteproperty -Name $Section -Value $([pscustomobject]$Converted) -Force
        }
        Write-Output $OutputObject
    }
}
