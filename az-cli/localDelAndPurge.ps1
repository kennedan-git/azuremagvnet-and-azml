$rg = 'ngcml-dev3'
$subscription_id = 'd14a716b-f7ce-49d9-ae03-bbf94fdda533'
$keyvault_name = 'ngcml-kv3'

$delStartTime = $(get-date)
write-output "Deletion and purge of $rg and $keyvault_name started at $StartTime"

az group delete -n $rg --subscription $subscription_id -y
az keyvault update -n $keyvault_name -g $rg --default-action allow
az keyvault purge --name $keyvault_name --subscription $subscription_id

$delElapsedTime = $(get-date) - $delStartTime
$delTotalTime = "{0:HH:mm:ss}" -f ([datetime]$delElapsedTime.Ticks)
Write-Output "Deletion of $rg and $keyvault_name took $delTotalTime to run."
