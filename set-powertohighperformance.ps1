<#
=============================================================================================================
Script:    		    set-powertohighperformance.ps1
Date:      		    June, 2019
Create By:          Paul van Dieën
Last Edited by:	    Paul van Dieën
Last Edited Date:   04-06-2019
Requirements:		Powershell Framework 5.1
                    PowerCLI 11.2
=============================================================================================================
.DESCRIPTION
This script will set PowerPolicy to High Performance on all Hosts in the Cluster.
#>
$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

#Set Powerconfig to High Performance
$esxihosts = get-cluster $p.cluster |get-vmhost
foreach ($esx in $esxihosts){
    $view = (Get-VMHost $esx | Get-View)
    if ((Get-View $view.ConfigManager.PowerSystem).info.currentpolicy.key -ne 1){
        (Get-View $view.ConfigManager.PowerSystem).ConfigurePowerPolicy(1)
        Write-Host $esx Power Management set to High Performance -ForegroundColor Green
    } else{
        Write-Host $esx already set to High Performance -ForegroundColor Cyan
    }
}
Disconnect-VIServer -Force -Confirm:$false