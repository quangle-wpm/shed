#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Description: what this script does
# Usage: .\script-name.ps1 [-Param value]

function Main {
    Write-Output "Hello from $($MyInvocation.MyCommand.Name)"
}

Main
