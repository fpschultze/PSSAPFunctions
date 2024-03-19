function Invoke-CommandAsBatchFile {
    [CmdletBinding(DefaultParameterSetName = 'NoCredential')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $CommandLine,

        [Parameter()]
        [int]
        $TimeoutSec = 60,

        # Alternate credentials
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
        $Pass
    )
    $returnValue = [PSCustomObject]@{
        ExitCode = $null
        StdOut   = $null
        StdErr   = $null
    }
    $WaitForExitTimeout = $TimeoutSec * 1000
    $ErrorActionPreference = 'Stop'
    try {
        'EXECUTE (via temp Batch file): {0}' -f $CommandLine | Write-Host #Write-Verbose
        $tmpFileName1 = Get-TempFileName
        $tmpFileName2 = Get-TempFileName
        $batScriptBlock = '@{0} >{1} 2>{2}' -f $CommandLine, $tmpFileName1, $tmpFileName2
        $batFileName = $tmpFileName1 -replace '.tmp', '.cmd'
        Set-Content -Path $batFileName -Value $batScriptBlock -Encoding Ascii
        $parameters = @{
            FilePath     = $env:ComSpec
            ArgumentList = @('/C', $batFileName)
            WindowStyle  = 'Hidden'
        }
        switch ($PSCmdlet.ParameterSetName) {
            'PlainTextCredential' {
                $parameters.Add('Credential', (New-Object System.Management.Automation.PSCredential($User, ($Pass | ConvertTo-SecureString -AsPlainText -Force))))
            }
            'PSCredential' {
                $parameters.Add('Credential', $Credential)
            }
        }
        $process = Start-Process @parameters -PassThru
        if ($process.WaitForExit($WaitForExitTimeout) -eq $false) {
            throw 'The timeout limit is exceeded!'
        }
        $stdOut = Get-Content -Path $tmpFileName1 -Encoding Ascii #-Raw
        $stdErr = Get-Content -Path $tmpFileName2 -Encoding Ascii #-Raw
        $returnValue.ExitCode = $process.ExitCode
        "Exit Code:`n{0}" -f $returnValue.ExitCode | Write-Host #Write-Verbose
        if (-not ([string]::IsNullOrEmpty($stdOut))) {
            $returnValue.StdOut = $stdOut
            "Standard Output:`n{0}" -f ($returnValue.StdOut -join "`n") | Write-Host #Write-Verbose
        }
        if (-not ([string]::IsNullOrEmpty($stdErr))) {
            $returnValue.StdErr = $stdErr
            "Standard Error:`n{0}" -f ($returnValue.StdErr -join "`n") | Write-Host #Write-Verbose
        }
        Write-Output $returnValue
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        Remove-Item -Path $tmpFileName1, $tmpFileName2, $batFileName -Force -ErrorAction Ignore
    }
}
