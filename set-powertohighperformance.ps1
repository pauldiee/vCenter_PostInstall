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