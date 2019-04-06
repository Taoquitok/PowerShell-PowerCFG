# Start-PowercfgRequestsLog.ps1 must be RunAsAdministrator, so this test should be too
#Requires -RunAsAdministrator
$ProjectRoot = Resolve-Path $PSScriptRoot\..
$FileSearch = @{
    Path    = $ProjectRoot
    Include = $MyInvocation.MyCommand.Name -replace '\.Tests',''
    Recurse = $true
}

$ScriptFile = Get-ChildItem @FileSearch
$ValidationDescription = '{0} should pass testing' -f $ScriptFile.Name

$Splat = @{
    Delay = 1
    Runtime = 5
}

# Method to generate powercfg entries taken from https://github.com/stefanstranger/PowerShell/blob/master/Examples/SuspendPowerPlan.ps1
$MemberDefinition=@'
[DllImport("kernel32.dll", CharSet = CharSet.Auto,SetLastError = true)]
  public static extern void SetThreadExecutionState(uint esFlags);
'@
$ste = Add-Type -memberDefinition $MemberDefinition -name System -namespace Win32 -passThru

# Execution states: https://docs.microsoft.com/en-us/windows/desktop/api/winbase/nf-winbase-setthreadexecutionstate
$ES_CONTINUOUS = [uint32]"0x80000000" #Requests that the other EXECUTION_STATE flags set remain in effect until SetThreadExecutionState is called
$ES_AWAYMODE_REQUIRED = [uint32]"0x00000040" #Requests Away Mode to be enabled.
$ES_DISPLAY_REQUIRED = [uint32]"0x00000002" #Requests display availability (display idle timeout is prevented).
$ES_SYSTEM_REQUIRED = [uint32]"0x00000001" #Requests system availability (sleep idle timeout is prevented).

Describe  $ValidationDescription {

    $ContextDescription = '{0} should return results appropriately' -f $ScriptFile.Name

    Context $ContextDescription {
        It 'should return an AWAYMODE result' {

            $ste::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_AWAYMODE_REQUIRED)
            $Displayresults = . $ScriptFile.FullName @Splat
            $ste::SetThreadExecutionState($ES_CONTINUOUS)

            # Test results
            $Displayresults | should -not -BeNullOrEmpty
            $Displayresults.awaymode  -match "powershell" | Should -BeTrue

        }
        It 'should return a DISPLAY result' {

            $ste::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_DISPLAY_REQUIRED)
            $Displayresults = . $ScriptFile.FullName @Splat
            $ste::SetThreadExecutionState($ES_CONTINUOUS)

            # Test results
            $Displayresults | should -not -BeNullOrEmpty
            $Displayresults.display  -match "powershell" | Should -BeTrue

        }
        It 'should return a SYSTEM result' {

            $ste::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED)
            $Displayresults = . $ScriptFile.FullName @Splat
            $ste::SetThreadExecutionState($ES_CONTINUOUS)

            # Test results
            $Displayresults | should -not -BeNullOrEmpty
            $Displayresults.system  -match "powershell" | Should -BeTrue

        }
    }
}
<#
Test notes:
# Covered 83.67% of 49 analyzed Commands in 1 File.
# Missed commands:

# File                          Function Line Command
# ----                          -------- ---- -------
# Start-PowercfgRequestsLog.ps1            57 $Stopwatch.stop()
# Start-PowercfgRequestsLog.ps1            58 $Stopwatch.reset()
# Start-PowercfgRequestsLog.ps1           101 [int] $a = $Index.EXECUTION + 1
# Start-PowercfgRequestsLog.ps1           102 [int] $b = $Index.PERFBOOST - 1
# Start-PowercfgRequestsLog.ps1           103 $ToReturn.EXECUTION= $PowerCFG[$a..$b]
# Start-PowercfgRequestsLog.ps1           106 [int] $a = $Index.PERFBOOST + 1
# Start-PowercfgRequestsLog.ps1           107 [int] $b = $Index.ACTIVELOCKSCREEN - 1
# Start-PowercfgRequestsLog.ps1           108 $ToReturn.PERFBOOST = $PowerCFG[$a..$b]
# Start-PowercfgRequestsLog.ps1           111 [int] $a = $Index.ACTIVELOCKSCREEN + 1
# Start-PowercfgRequestsLog.ps1           112 [int] $b = $PowerCFG.count - 1
# Start-PowercfgRequestsLog.ps1           113 $ToReturn.ACTIVELOCKSCREEN = $PowerCFG[$a..$b]

Missing tests for:
$Runtime = 0 infinite loop (would be difficult to test...)
EXECUTION, PERFBOOST, and ACTIVELOCKSCREEN, results. No idea how to emulate these. Happy with 3/4 code coverage
#>
