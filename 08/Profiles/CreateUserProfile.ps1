﻿$ver = $host | select version 
if ($ver.Version.Major -gt 1) {$Host.Runspace.ThreadOptions = "ReuseThread"} 
Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
 
#Load Functions 
 
function PollService 
{ 
	sleep 5 
} 
 
#Set Script Variables 
 
Write-Progress -Activity "Provisioning User Profile Service Application" -Status "Creating Script Variables" 
 
$ProfileSyncServer = "SP2013c" 
 
$UserProfileDB = "Contoso_Profile_DB" 
 
$UserProfileSyncDB = "Contoso_Profile_Sync_DB" 
 
$UserProfileSocialDB = "Contoso_Profile_Social_DB" 
 
$UserProfileApplicationPoolManagedAccount = "spdom\spservice" 
 
$UserProfileApplicationPoolPassword = "Pa$$w0rd" 
 
$SPFarmAccount = "spdom\spservice" 
 
$FarmAccountPassword = "Pa$$w0rd" 
 
$UserProfileServiceName = "User Profile Service" 
 
 
#Begin Script 
 
$UserProfileAppPoolCredential = New-Object System.Management.Automation.PSCredential $UserProfileApplicationPoolManagedAccount, (ConvertTo-SecureString $UserProfileApplicationPoolPassword -AsPlainText -Force) 
 
 
Write-Progress -Activity "Provisioning User Profile Service Application" -Status "Creating Managed Account if Required" 
if (get-spmanagedaccount $UserProfileApplicationPoolManagedAccount -EA 0) 
  { 
  Write-Host "Managed Account Exists, No Need to Create a Managed Account" -foregroundcolor "Yellow" 
  $UserProfileServiceAccount = Get-SPManagedAccount $UserProfileApplicationPoolManagedAccount 
  } 
else 
  { 
  $UserProfileServiceAccount = New-SPManagedAccount -Credential $UserProfileAppPoolCredential 
  } 
   
$UserProfileSyncAccount = Get-SPManagedAccount $SPFarmAccount 
 
Write-Progress -Activity "Provisioning User Profile Service Application" -Status "Creating Application Pool" 
 
$UserProfileServiceApplicationAppPool = New-SPServiceApplicationPool -Name $UserProfileServiceName -Account $UserProfileServiceAccount 
 
Write-Progress -Activity "Provisioning User Profile Service Application" -Status "Starting User Profile Service" 
 
$UPSI = get-spserviceinstance | where {$_.server -like "*" + $ProfileSyncServer -and $_.Typename -eq "User Profile Service"} | Start-SPServiceInstance 
$UserProfileSyncServiceInstance = get-spserviceinstance | where {$_.server -like "*" + $ProfileSyncServer -and $_.Typename -eq "User Profile Synchronization Service"} 
 
Write-Progress -Activity "Provisioning User Profile Service Application" -Status "Creating User Profile Service Application 
" 
$UserProfileSA = New-SPProfileServiceApplication -Name $UserProfileServiceName -ApplicationPool $UserProfileServiceApplicationAppPool -ProfileDBName $UserProfileDB -ProfileSyncDBName $UserProfileSyncDB -SocialDBName $UserProfileSocialDB 
 
Write-Progress -Activity "Provisioning User Profile Service Application" -Status "Setting User Profile Service Application Properties" 
$SPUserprofileMachine = get-spserver $ProfileSyncServer 
$UserProfileSA.SetSynchronizationMachine($ProfileSyncServer, $UserProfileSyncServiceInstance.id, $UserProfileSyncAccount.username, $FarmAccountPassword) 
 
Write-Progress -Activity "Provisioning User Profile Service Application" -Status "Creating User Profile Service Application Proxy" 
 
New-SPProfileServiceApplicationProxy -Name ($UserProfileServiceName + " Proxy") -ServiceApplication $UserProfileSA 
 
Write-Progress -Activity "Provisioning User Profile Service Application" -Status "Starting User Profile Synchronization Service" 
 
Start-SPServiceInstance $UserProfileSyncServiceInstance 
 
while ($UserProfileSyncServiceInstance.status -ne "online") 
{ 
pollservice 
Write-Progress -Activity "Provisioning User Profile Service Application" -Status "Waiting for User Profile Synchronization Service to Start" 
$UserProfileSyncServiceInstance = get-spserviceinstance | where {$_.server -like "*" + $ProfileSyncServer -and $_.Typename -eq "User Profile Synchronization Service"} 
} 
 
Write-Host "Resetting IIS" 
cmd.exe /c "iisreset $ProfileSyncServer /noforce" New-SPProfileServiceApplication -Name User_Profiles  -ApplicationPool $appPool