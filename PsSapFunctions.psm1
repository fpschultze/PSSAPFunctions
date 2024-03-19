$PsSapExe = "${env:ProgramFiles}\SAP\hostctrl\exe"

$PsSapExe | Where-Object {-not (Test-Path -Path $_)} | ForEach-Object {
    'Folder not found - {0}' -f $_ | Write-Warning
}

Join-Path -Path $PSScriptRoot -ChildPath 'Private' |
    Get-ChildItem -Filter '*.ps1' -Exclude '*.Tests.*' -Recurse |
    ForEach-Object {
        . $_.FullName
    }

Join-Path -Path $PSScriptRoot -ChildPath 'Public' |
    Get-ChildItem -Filter '*.ps1' -Exclude '*.Tests.*' -Recurse |
    ForEach-Object {
        . $_.FullName
    }

Write-Verbose 'The module is loaded.'
