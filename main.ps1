######################################
Write-Output "Start"
Write-Output "Logging in to Azure"
$login = Get-AutomationPSCredential -Name 'Admin'
Login-AzureRmAccount -Credential $login
#Getting subscription ID
Write-Output "Getting subscription ID"
$tenantid = Get-AutomationVariable -Name 'TenantId'
$subscriptionsId = Get-AzureRmSubscription -TenantId $tenantid | Select-Object -ExpandProperty Id
#Getting all principals names
Write-Output "Getting all principals names"
$principals = Get-AzureRmADServicePrincipal | Select-Object -ExpandProperty DisplayName
#Adds a Microsoft .NET Framework type for password generator
Add-Type -Assembly System.Web
#searching through all subscriptions
foreach ($subscriptionId in $subscriptionsId) {
    #comparing SPN to subscriptions
    Write-Output "Searching in $subscriptionId"
    if ($principals -match $subscriptionId) {
        Write-Output "Found SPN for $subscriptionId"
    }
    else {
        Write-Output "SPN not found for $subscriptionId"
        Write-Output "Creating SPN"
        $password = [System.Web.Security.Membership]::GeneratePassword(16,3)
        New-AzureRmADServicePrincipal -DisplayName $subscriptionId -Password $password
        Write-Output "SPN Created"
        Write-Output "Sleep for 60s"
        Start-Sleep 60
        #getting ID for SPN
        $getId = Get-AzureRmADServicePrincipal | Where-Object {$_.DisplayName -eq $subscriptionId} | Select-Object -ExpandProperty ID
        Write-Output "Assigning role to ID: $getId in scope /subscriptions/$subscriptionId"
        New-AzureRmRoleAssignment -ObjectId $getId -RoleDefinitionName Contributor -scope ("/subscriptions/" + $subscriptionId)
        Write-Output "Assigned"
    }

}
Write-Output "Done"