$ProjectRoot = Resolve-Path $PSScriptRoot\..
$FileSearch = @{
    Path    = $ProjectRoot
    Include = '*.ps1', '*.psm1', '*.psd1'
    Recurse = $true
}
$Scripts = Get-ChildItem @FileSearch

$ValidationDescription = 'generic project validation '

Describe  $ValidationDescription {

    # TestCases are splatted to the script so we need them in a hashtable format
    # Due to how Get-ChildItem defaults to displaying text depending on if the results are multi-folder or not, FileName is declared to clean up the "IT" statement
    $FileTestCases = $Scripts | ForEach-Object {
        @{
            FileName = $_.Name
            File = $_
        }
    }

    Context 'All PowerShell files should be valid' {
        It '<FileName> should be valid powershell' -TestCases $FileTestCases {
            param($File)

            $File.FullName | Should -Exist

            $FileContents = Get-Content -Path $File.FullName -ErrorAction Stop
            $Errors = $null
            [System.Management.Automation.PSParser]::Tokenize($FileContents, [ref]$Errors) > $null
            $Errors.Count | Should -Be 0
        }
    }
