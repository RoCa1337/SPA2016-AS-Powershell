if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
{
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

#TemplateIDs: https://absolute-sharepoint.com/2013/06/sharepoint-2013-site-template-id-list-for-powershell.html

#Export
Export-SPWeb -Identity http://sp2013c/ -Path "d:\SP2013_export.cmp" -IncludeVersions ALL
Write-Host "Export done"

#Import
New-SPSite http://sp2013c/sites/Import -OwnerAlias "spdom\Administrator" -Language 1033 -Template "ENTERWIKI#0"
Write-Host "Site created"
Import-SPWeb -Identity http://sp2013c/sites/Import -Path "d:\SP2013_export.cmp"
Write-Host "Import done"