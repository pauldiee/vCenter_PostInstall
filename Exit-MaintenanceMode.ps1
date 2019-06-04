<#
=============================================================================================================
Script:    		    Exit-MaintenanceMode.ps1
Date:      		    June, 2019
Create By:          Paul van Dieën
Last Edited by:	    Paul van Dieën
Last Edited Date:   04-06-2019
Requirements:		Powershell Framework 5.1
                    PowerCLI 11.2
=============================================================================================================
.DESCRIPTION
This script will exit all Hosts from maintenance mode currently in maintenance mode.
#>
$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

#Exit Maintenance Mode all Hosts
$esxihosts = get-cluster $p.cluster |get-vmhost
foreach ($esx in $esxihosts){
    if ((Get-VMHost $esx | Where-Object {$_.ConnectionState -eq "Maintenance"})){
        Set-VMHost $esx -State Connected | Out-Null
        Write-Host Exited Maintenance Mode on $esx -ForegroundColor Green
    } else {
        Write-Host $esx not in Maintenance Mode. -ForegroundColor Cyan
    }
}
Disconnect-VIServer -Force -Confirm:$false