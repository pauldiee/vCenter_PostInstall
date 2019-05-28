$WorkingDir = Split-Path -Parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter -Force  | Out-Null

if ((Get-Datacenter |Where-Object {$_.Name -eq $p.datacenter})){
    #Create DVSwitch $p.dvs
    $cluster = "$p.cluster"
    if ((Get-VDSwitch |Where-Object {$_.Name -eq $p.dvs})) {
        Write-Host Portgroup $p.dvs already exists! -ForegroundColor Yellow
    } else {
        New-VDSwitch -Location $p.datacenter -Name $p.dvs -NumUplinkPorts 2 -Mtu 9000 | Out-Null
        Write-Host Distributed Switch $p.dvs Created! -ForegroundColor Yellow
    }

    #Create $p.resourcemgmtportgroup Portgroup
    if ((Get-VDSwitch $p.dvs | Get-VDPortgroup | Where-Object {$_.Name -eq $p.resourcemgmtportgroup})){
        Write-Host Portgroup $p.resourcemgmtportgroup already exists! -ForegroundColor Yellow
    } else {
        New-VDPortgroup -Name $p.resourcemgmtportgroup -VlanId $p.rscmgmtvlan -PortBinding static -NumPorts 8 -VDSwitch $p.dvs | Out-Null
        Write-Host Portgroup $p.resourcemgmtportgroup Created! -ForegroundColor Yellow    
    }

    #Create $p.vmotionportgroup Portgroup
    if ((Get-VDSwitch $p.dvs | Get-VDPortgroup | Where-Object {$_.Name -eq $p.vmotionportgroup})){
        Write-Host Portgroup $p.vmotionportgroup already exists! -ForegroundColor Yellow
    } else {
        New-VDPortgroup -Name $p.vmotionportgroup -VlanId $p.vmotionvlan -PortBinding static -NumPorts 8 -VDSwitch $p.dvs | Out-Null
        Write-Host Portgroup $p.vmotionportgroup Created! -ForegroundColor Yellow    
    }

    #Create $p.provisioningportgroup Portgroup
    if ((Get-VDSwitch $p.dvs | Get-VDPortgroup | Where-Object {$_.Name -eq $p.provisioningportgroup})){
        Write-Host Portgroup $p.provisioningportgroup already exists! -ForegroundColor Yellow
    } else {
        New-VDPortgroup -Name $p.provisioningportgroup -VlanId $p.provisioningvlan -PortBinding static -NumPorts 8 -VDSwitch $p.dvs | Out-Null
        Write-Host Portgroup $p.provisioningportgroup Created! -ForegroundColor Yellow    
    }

    #Create $p.provisioningportgroup Portgroup
    if ((Get-VDSwitch $p.dvs | Get-VDPortgroup | Where-Object {$_.Name -eq $p.vsanportgroup})){
        Write-Host Portgroup $p.vsanportgroup already exists! -ForegroundColor Yellow
    } else {
        New-VDPortgroup -Name $p.vsanportgroup -VlanId $p.vsanvlan -PortBinding static -NumPorts 8 -VDSwitch $p.dvs | Out-Null
        Write-Host Portgroup $p.vsanportgroup Created! -ForegroundColor Yellow    
    }
 } else {
    Write-Host Datacenter $p.datacenter does not exist! Nothing created. -ForegroundColor Yellow
}

Disconnect-VIServer -Force