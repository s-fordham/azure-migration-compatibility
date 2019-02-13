<#
.DESCRIPTION 
This script will load a menu and check which resources can be moved by Resource Group of Subscription

.NOTES
Stuart Fordham
Change Log
V1.0, 20/11/2018 Initial Version
V1.1, 04/12/2018 Updated Menu Layout
V1.2, 13/02/2019 Upload to Github
#>

$logpath = "C:\Temp\AzureMigrationCompatibility"

# Sign in to your Azure account 
Write-Host "
----------------------------------------------
Please enter the Azure Portal Details to check
----------------------------------------------" -ForegroundColor Yellow

Login-AzureRMAccount
Get-AzureRmSubscription | fl

[BOOLEAN]$global:xExitSession=$false

function PullCSV(){
Write-Host "Creating Output folder and downloading raw data CSV.." -ForegroundColor Green
#Create Folder
If (Test-Path -Path $logpath -PathType Container){ 
	Write-Host "$logpath already exists" -ForegroundColor Yellow
	}else{
	New-Item -Path $logpath -ItemType directory
	}

#Download CSV Raw Data
$url = "https://github.com/s-fordham/azure-migration-compatibility/blob/master/resourcerawdata.csv"
$output = "$logpath\resourcerawdata.csv"
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
Invoke-WebRequest -Uri $url -OutFile $output
}

function LoadMenuSystem(){
	[INT]$xMenu1 = 0
	while ( $xMenu1 -lt 1 -or $xMenu1 -gt 4 ){
		Clear-Host
		#… Present the Menu Options
		Write-Host "`n`tAzure Migration Compatibility Check - Version 1.0`n" -ForegroundColor Yellow
		Write-Host "`t`tPlease select the task you wish to run`n" -Fore Green
		Write-Host "`t`t1. Check migration by Resource Group" -Fore Green
		Write-Host "`t`t2. Check migration by Subscription" -Fore Green
		Write-Host "`t`t3. Quit`n" -Fore Red
		#… Retrieve the response from the user
		[int]$xMenu1 = Read-Host "`t`tEnter Menu Option Number"}
	Switch ($xMenu1){    #… User has selected a valid entry.. load next menu
        1 {Write-Host "`n`t`tYou selected 'Check migration by Resource Group'" -ForegroundColor Yellow
        Start-Sleep -s 3
        ResourceGroupCheck}
		2 {Write-Host "`n`t`tYou selected 'Check migration by Subscription'" -ForegroundColor Yellow
        Start-Sleep -s 3
        SubscriptionCheck}
		3 {Write-Host "`n`t`tYou selected Quit, closing script." -ForegroundColor Red
        Start-Sleep -s 3
        Exit}
	}
}

function ResourceGroupCheck(){
Write-Host "Starting Transcript" -ForegroundColor Yellow
Start-Transcript -Path "C:\Temp\AzureMigrationCompatibility\transcript.txt" -Append

PullCSV

$logfile = "ResourceGroup-Compatibility-log.csv"
Write-Output "Name,ResourceType,Supported" | Out-File "$($logpath)\$($logfile)" -Encoding UTF8
$csvrawdata = Import-Csv "$($logpath)\resourcerawdata.csv"
$resources = Get-AzureRmResource | Select-Object Name, ResourceType
foreach ($resource in $resources){
$resourceitem = $csvrawdata | Where-Object {$_.Resourcetype -eq $resource.ResourceType}
if ($resourceitem.Resourcegroup -eq "Yes") {
Write-Host "The resource '$($resource.Name)' is supported for migration by ResourceGroup" -ForegroundColor Green
Write-Output "$($resource.Name),$($resource.ResourceType),Yes" | Out-File "$($logpath)\$($logfile)" -append -Encoding UTF8
}elseif ($resourceitem.Resourcegroup -eq "No") {
Write-Host "The resource '$($resource.Name)' is NOT supported for migration by ResourceGroup" -ForegroundColor Red
Write-Output "$($resource.Name),$($resource.ResourceType),Yes" | Out-File "$($logpath)\$($logfile)" -append -Encoding UTF8
}
}
Write-Host "
Log created. Please review the log in '$($logpath)\$($logfile)'

For any items that are not supported, please check 'https://docs.microsoft.com/en-us/azure/azure-resource-manager/move-support-resources'" -ForegroundColor Yellow
}
function SubscriptionCheck(){
Write-Host "Starting Transcript" -ForegroundColor Yellow
Start-Transcript -Path "C:\Temp\AzureMigrationCompatibility\transcript.txt" -Append

PullCSV

$logfile = "Subscription-Compatibility-log.csv"
Write-Output "Name,ResourceType,Supported" | Out-File "$($logpath)\$($logfile)" -Encoding UTF8
$csvrawdata = Import-Csv "$($logpath)\resourcerawdata.csv"
$resources = Get-AzureRmResource | Select-Object Name, ResourceType
foreach ($resource in $resources){
$resourceitem = $csvrawdata | Where-Object {$_.Resourcetype -eq $resource.ResourceType}
if ($resourceitem.Subscription -eq "Yes") {
Write-Host "The resource '$($resource.Name)' is supported for migration by Subscription" -ForegroundColor Green
Write-Output "$($resource.Name),$($resource.ResourceType),Yes" | Out-File "$($logpath)\$($logfile)" -append -Encoding UTF8
}elseif ($resourceitem.Subscription -eq "No") {
Write-Host "The resource '$($resource.Name)' is NOT supported for migration by Subscription" -ForegroundColor Red
Write-Output "$($resource.Name),$($resource.ResourceType),No" | Out-File "$($logpath)\$($logfile)" -append -Encoding UTF8
}
}
Write-Host "
Log created. Please review the log in '$($logpath)\$($logfile)'

For any items that are not supported, please check 'https://docs.microsoft.com/en-us/azure/azure-resource-manager/move-support-resources'" -ForegroundColor Yellow
}

LoadMenuSystem