Write-Output "Setting environment to $login_environment"
az cloud set --name $login_environment
az login 
az account set -s $subscription_id 