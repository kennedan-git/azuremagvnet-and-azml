$delStartTime = $(get-date)
write-output "Deletion and purge of $rg and $keyvault_name started at $delStartTime"

az group delete -n $rg --subscription $subscription_id -y
az keyvault update -n $env:keyvault_name -g $rg --default-action allow
az keyvault purge --name $keyvault_name --subscription $subscription_id

$delElapsedTime = $(get-date) - $delStartTime
$delTotalTime = "{0:HH:mm:ss}" -f ([datetime]$delElapsedTime.Ticks)
Write-Output "Deletion of $rg and $keyvault_name took $delTotalTime to run."
