<#
.SYNOPSIS
    Wrapper for powercfg to monitor requests for a set period of time and at a set interval
    Must be RunAsAdministrator
.DESCRIPTION
    Wrapper for powercfg to monitor requests for a set period of time and at a set interval
    Converts the results of "powercfg /requests" into an object to return to the output stream
.EXAMPLE
    PS C:\> .\Start-PowercfgRequestsLog.ps1 -Delay 500 -Runtime 600
    DATETIME         : 17/10/2018 00:11:15
    DISPLAY          : {[PROCESS] \Device\HarddiskVolume7\Users\username\AppData\Local\Google\Chrome\Application\Chrome.exe,
                        Requested By SomeApp, }
    SYSTEM           : {[DRIVER] Legacy Kernel Caller, }
    AWAYMODE         :
    EXECUTION        :
    PERFBOOST        :
    ACTIVELOCKSCREEN :


    Description
    -----------
    Runs for 600 seconds (10 minutes)  at an interval of every 500 milliseconds directly to console
.EXAMPLE
    PS C:\> $Results = .\Start-PowercfgRequestsLog.ps1 -Delay 1 -Runtime 10


    Description
    -----------
    Runs for 10 seconds at an interval of every 1 millisecond
    Once completed, you can get a quick idea of the processes recorded with the below:

    # Foreach property that is not DateTime, print title and sort results, filtered to exclude blank entries
    $Results[0].psobject.Properties.name.where{$_ -ne 'DateTime'} | % {Write-Host $_ -f Cyan; $Results.$_ | where {$_ -ne ''} | Sort-Object -Unique}
.NOTES
    https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options
#>
[CmdletBinding()]
#Requires -RunAsAdministrator
param (
    # Millisecond delay to wait between running powercfg
    # Defaults to 100 milliseconds
    # Parameter help description
    [Parameter(
        Position=0)]
    [int] $Delay = 100,
    # Runtime until function will finish. Set to 0 to never end, instead requiring you to manually cancel it
    # Defaults to 300 seconds (5 minutes)
    [Parameter(
        Position=1)]
    [int] $Runtime = 300
)
begin {
    $Stopwatch = [system.diagnostics.stopwatch]::StartNew()

    if ($Runtime -eq 0) {
        # Reset $Stopwatch to ensure While check always returns true. "0 -le 0"
        $Stopwatch.stop()
        $Stopwatch.reset()
    } else {
        # Due to using "$Stopwatch.Elapsed.Seconds -le $Runtime" for the While check, a 5min timer will technically run up to the 6min mark
        # Remove 1 minute from $runtime to bring the end run to last up the expected completion time
        $Runtime--
    }
}
process {
    while ($Stopwatch.Elapsed.Seconds -le $Runtime) {
        $ToReturn = '' | Select-Object -Property DATETIME, DISPLAY, SYSTEM, AWAYMODE, EXECUTION, PERFBOOST, ACTIVELOCKSCREEN
        $Index = ''| Select-Object -Property DISPLAY, SYSTEM, AWAYMODE, EXECUTION, PERFBOOST, ACTIVELOCKSCREEN

        Start-Sleep -Milliseconds $Delay

        $PowerCFG = powercfg /requests

        # Due to how powercfg outputs the results, there's no consistent index position for each section
        # Re-indexing the index IDs for each section is necessary to allow accurate selection of the results for each section
        $Index.DISPLAY = $PowerCFG.IndexOf('DISPLAY:')
        $Index.SYSTEM = $PowerCFG.IndexOf('SYSTEM:')
        $Index.AWAYMODE = $PowerCFG.IndexOf('AWAYMODE:')
        $Index.EXECUTION = $PowerCFG.IndexOf('EXECUTION:')
        $Index.PERFBOOST = $PowerCFG.IndexOf('PERFBOOST:')
        $Index.ACTIVELOCKSCREEN = $PowerCFG.IndexOf('ACTIVELOCKSCREEN:')


        switch ($true) {
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
        if (
            # No need to output results for every loop, only those with any result
            $null -ne $ToReturn.DISPLAY -or
            $null -ne $ToReturn.SYSTEM -or
            $null -ne $ToReturn.AWAYMODE -or
            $null -ne $ToReturn.EXECUTION -or
            $null -ne $ToReturn.PERFBOOST -or
            $null -ne $ToReturn.ACTIVELOCKSCREEN
        ) {
            $ToReturn.DATETIME = $(Get-Date)

            Write-Output -InputObject $ToReturn
        }
    }
}
end {
    if ($Stopwatch.IsRunning) {
        $Stopwatch.Stop()
    }
}
