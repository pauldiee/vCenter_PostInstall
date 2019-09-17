<#
=============================================================================================================
Script:    		    create-vmkernels.ps1
Date:      		    June, 2019
Create By:          Paul van Dieën
Last Edited by:	    Paul van Dieën
Last Edited Date:   04-06-2019
Requirements:		Powershell Framework 5.1
                    PowerCLI 11.2
=============================================================================================================
.DESCRIPTION
This script heavily relies on the information from 3 csv files. Fill out the correct host and ip information in all 3 first.
It will create vSAN, vMotion and Provisioning vmkernels.
#>

#Connect to vCenter
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $true -Confirm:$false | Out-Null
if ($global:DefaultVIServers.Count -gt 0) {Disconnect-VIServer * -Confirm:$false}
Write-Host -BackgroundColor Yellow -ForegroundColor Black "Please fill in all information for vCenter Connection!"
$vcenter = Read-Host "Enter vCenter name"
$vCenterCredential = Get-Credential

Connect-VIServer $vcenter -Credential $vCenterCredential -Force -ErrorAction Stop | Out-Null
Write-host -ForegroundColor Green "Connected to vCenter server: $($global:DefaultVIServer.Name)"

#Set static route to witness node
$esxihosts = Get-Cluster Resource-Cluster |Get-VMHost
ForEach ($esx in $esxihosts){
    New-VMHostRoute -VMHost $esx -Destination 172.31.66.0 -PrefixLength 24 -Gateway 172.31.46.250
}

#Set static route to vsan nodes
$witness = Get-Datacenter "*Witness" | Get-VMHost
New-VMHostRoute -VMHost $witness -Destination 172.31.46.0 -PrefixLength 24 -Gateway 172.31.66.250