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