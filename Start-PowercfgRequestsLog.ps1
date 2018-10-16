<#
.SYNOPSIS
    Wrapper for powercfg to monitor requests for a set period of time and at a set interval
    Must be run in an elevated console
.DESCRIPTION
    Wrapper for powercfg to monitor requests for a set period of time and at a set interval
    Converts the results of "powercfg -requests" into an object and adds them to the $Global:Output variable
.EXAMPLE
    PS C:\> Start-PowercfgRequestsLog.ps1 -Delay 500 -Runtime 10

    Description
    -----------
    Runs for 10 minutes at an interval of every 500 milliseconds
    Once completed, you can get a quick idea of the processes recorded with the below:

    # Foreach property that is not DateTime, print title and sort results, filtered to exclude blank entries
    $Global:Output[0].psobject.Properties.name.where{$_ -ne 'DateTime'} | % {Write-Host $_ -f Cyan; $Output.$_ | where {$_ -ne ''} | Sort-Object -Unique}
.NOTES
    https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options
#>
[CmdletBinding()]
#Requires -RunAsAdministrator
param (
    # Millisecond delay to wait between running powercfg
    # Defaults to 100 ms
    # Parameter help description
    [Parameter(
        Position=0)]
    [int] $Delay = 100,
    # Runtime until function will finish. Set to 0 to never end, instead requiring you to manually cancel it
    # Defaults to 5 minutes
    [Parameter(
        Position=1)]
    [int] $Runtime = 5
)
begin {
    $Global:Output = New-Object -TypeName 'System.Collections.Generic.List[object]'

    $stopwatch =  [system.diagnostics.stopwatch]::StartNew()

    If ($Runtime -eq 0) {
        # Reset $stopwatch to ensure While check always returns true. "0 -le 0"
        $stopwatch.stop()
        $stopwatch.reset()
    } else {
        # Due to using "$stopwatch.Elapsed.Minutes -le $Runtime" for the While check, a 5min timer will technically run up to the 6min mark
        # Remove 1 minute from $runtime to bring the end run to last up the expected completion time
        $Runtime--
    }
}
process {
    While ($stopwatch.Elapsed.Minutes -le $Runtime) {
        $ToReturn = '' | Select-Object DATETIME, DISPLAY, SYSTEM, AWAYMODE, EXECUTION, PERFBOOST, ACTIVELOCKSCREEN
        $Index = ''| Select-Object DISPLAY, SYSTEM, AWAYMODE, EXECUTION, PERFBOOST, ACTIVELOCKSCREEN

        Start-Sleep -Milliseconds $Delay

        $PowerCFG = powercfg -requests

        # Due to how powercfg outputs the results, there's no consistent index position for each section
        # Re-indexing the index IDs for each section is necessary to allow accurate selection of the results for each section
        $Index.DISPLAY = $PowerCFG.IndexOf('DISPLAY:')
        $Index.SYSTEM = $PowerCFG.IndexOf('SYSTEM:')
        $Index.AWAYMODE = $PowerCFG.IndexOf('AWAYMODE:')
        $Index.EXECUTION = $PowerCFG.IndexOf('EXECUTION:')
        $Index.PERFBOOST = $PowerCFG.IndexOf('PERFBOOST:')
        $Index.ACTIVELOCKSCREEN = $PowerCFG.IndexOf('ACTIVELOCKSCREEN:')


        Switch ($true) {
            ($PowerCFG[$Index.DISPLAY + 1] -ne 'None.') {
                [int] $a = $Index.DISPLAY + 1
                [int] $b = $Index.SYSTEM - 1
                $ToReturn.DISPLAY = $PowerCFG[$a..$b]
            }
            ($PowerCFG[$Index.SYSTEM + 1] -ne 'None.') {
                [int] $a = $Index.SYSTEM + 1
                [int] $b = $Index.AWAYMODE - 1
                $ToReturn.SYSTEM = $PowerCFG[$a..$b]
            }
            ($PowerCFG[$Index.AWAYMODE + 1] -ne 'None.') {
                [int] $a = $Index.AWAYMODE + 1
                [int] $b = $Index.EXECUTION - 1
                $ToReturn.AWAYMODE = $PowerCFG[$a..$b]
            }
            ($PowerCFG[$Index.EXECUTION + 1] -ne 'None.') {
                [int] $a = $Index.EXECUTION + 1
                [int] $b = $Index.PERFBOOST - 1
                $ToReturn.EXECUTION= $PowerCFG[$a..$b]
            }
            ($PowerCFG[$Index.PERFBOOST + 1] -ne 'None.') {
                [int] $a = $Index.PERFBOOST + 1
                [int] $b = $Index.ACTIVELOCKSCREEN - 1
                $ToReturn.PERFBOOST = $PowerCFG[$a..$b]
            }
            ($PowerCFG[$Index.ACTIVELOCKSCREEN + 1] -ne 'None.') {
                [int] $a = $Index.ACTIVELOCKSCREEN + 1
                [int] $b = $PowerCFG.count - 1
                $ToReturn.ACTIVELOCKSCREEN = $PowerCFG[$a..$b]
            }
        }
        If (
            # No need to output results for every loop, only those with any result
            $null -ne $ToReturn.DISPLAY -or
            $null -ne $ToReturn.SYSTEM -or
            $null -ne $ToReturn.AWAYMODE -or
            $null -ne $ToReturn.EXECUTION -or
            $null -ne $ToReturn.PERFBOOST -or
            $null -ne $ToReturn.ACTIVELOCKSCREEN
        ) {
            $ToReturn.DATETIME = $(get-date)
            $Output.Add($ToReturn)
        }
    }
}
end {
    If ($stopwatch.IsRunning) {
        $stopwatch.Stop()
    }
    write-host ('$Global:Output count: {0}' -f $Global:Output.count)
}
