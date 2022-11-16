. ".\Build\01_commercialConfig.ps1"
. ".\Build\00_commonConfig.ps1"

$StartTime = $(get-date)
write-output "Script started at $StartTime"

$scriptlist = @(
#'.\Build\00_commonConfig.ps1',
#'.\Build\01_commercialConfig.ps1',
'.\Build\05_login.ps1',
#'.\Build\deleteAllAndPurgeKV.ps1',
'.\Build\10_createRgVnetDnsPrivateKV.ps1'
#'.\Build\20_createBastionSubnetAndHost.ps1',
#'.\Build\30_createVM.ps1',
'.\Build\40_armPSdeployWorkspace.ps1'
)

foreach ($script in $scriptList) {
    Write-Output "Running $script"
    & $script 
}

$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Output "Build script took $totalTime to run."