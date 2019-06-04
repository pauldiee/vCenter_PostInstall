<#
=============================================================================================================
Script:    		    create-datacenter-cluster.ps1
Date:      		    June, 2019
Create By:          Paul van Dieën
Last Edited by:	    Paul van Dieën
Last Edited Date:   04-06-2019
Requirements:		Powershell Framework 5.1
                    PowerCLI 11.2
=============================================================================================================
.DESCRIPTION
This script will create a Datacenter and Cluster object.
#>
$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

#Create Datacenter and Cluster Objects
$location = Get-Folder -NoRecursion
if ((Get-Datacenter |Where-Object {$_.Name -eq $p.datacenter})){
    Write-Host $p.datacenter already exists! -ForegroundColor Cyan
 } else {
    New-Datacenter $p.datacenter -Location $location | Out-Null
    Write-Host $p.datacenter Created! -ForegroundColor Green
 }
 if ((Get-Cluster |Where-Object {$_.Name -eq $p.cluster})){
    Write-Host $p.cluster already exists! -ForegroundColor Cyan
} else {
    New-Cluster $p.cluster -Location $p.datacenter | Out-Null
    Write-Host $p.cluster Created! -ForegroundColor Green
}
Disconnect-VIServer -Force -Confirm:$false