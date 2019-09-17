<#
=============================================================================================================
Script:    		    set-staticroute_vsan.ps1
Date:      		    September, 2019
Create By:          Paul van Dieën
Last Edited by:	    Paul van Dieën
Last Edited Date:   17-09-2019
Requirements:		Powershell Framework 5.1
                    PowerCLI 11.4
=============================================================================================================
.DESCRIPTION
This will set static routes on vsan nodes and the witness node that make up the stretched cluster.
#>
#Define variables
$witnessnetwork = "172.31.66.0"
$witnessgateway = "172.31.66.250"
$vsannetwork    = "172.31.46.0"
$vsangateway    = "172.31.46.250"

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
    New-VMHostRoute -VMHost $esx -Destination $witnessnetwork -PrefixLength 24 -Gateway $vsangateway
}

#Set static route to vsan nodes
$witness = Get-Datacenter "*Witness" | Get-VMHost
New-VMHostRoute -VMHost $witness -Destination $vsannetwork -PrefixLength 24 -Gateway $witnessgateway

if ($global:DefaultVIServers.Count -gt 0) {Disconnect-VIServer * -Confirm:$false}