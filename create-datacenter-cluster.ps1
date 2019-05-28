$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter -Force  | Out-Null

#Create Datacenter and Cluster Objects
$location = Get-Folder -NoRecursion
if ((Get-Datacenter |Where-Object {$_.Name -eq $p.datacenter})){
    Write-Host Datacenter $p.datacenter already exists! -ForegroundColor Yellow
 } else {
    New-Datacenter $p.datacenter -Location $location | Out-Null
    Write-Host Datacenter $p.datacenter Created! -ForegroundColor Yellow
 }
 if ((Get-Cluster |Where-Object {$_.Name -eq $p.cluster})){
    Write-Host Cluster $p.cluster already exists! -ForegroundColor Yellow
} else {
    New-Cluster $p.cluster -Location $p.datacenter | Out-Null
    Write-Host Cluster $p.cluster Created! -ForegroundColor Yellow
}