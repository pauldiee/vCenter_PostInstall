$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

#Connect DVSwitch to all Hosts
$esxihosts = get-cluster $p.cluster |get-vmhost
ForEach ($esx in $esxihosts){
    if ((Get-VDSwitch -VMHost $esx | Where-Object {$_.Name -eq $p.dvs})){
    Write-Host $p.dvs Already Connected to $esx! -ForegroundColor Yellow    
    } else{
    Get-VDSwitch -Name $p.dvs | Add-VDSwitchVMHost -VMHost $esx
    $vmhostNetworkAdapter1 = Get-VMHost $esx | Get-VMHostNetworkAdapter -Physical -Name "vmnic2"
    $vmhostNetworkAdapter2 = Get-VMHost $esx | Get-VMHostNetworkAdapter -Physical -Name "vmnic3"
    Get-VDSwitch -Name $p.dvs | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter1 -Confirm:$false | Out-Null
    Get-VDSwitch -Name $p.dvs | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter2 -Confirm:$false | Out-Null
    Write-Host $p.dvs Connected to $esx! -ForegroundColor Yellow
    Write-Host $vmhostNetworkAdapter1 and $vmhostNetworkAdapter2 Connected on $esx to $p.dvs -ForegroundColor Yellow
    }
}

#Add Uplinks to all Hosts for vSwitch0 and set Security to reject all
$esxihosts = get-cluster $p.cluster |get-vmhost
ForEach ($esx in $esxihosts){
    $vmhostLocalNetworkAdapter = Get-VMHost $esx | Get-VMHostNetworkAdapter -Physical -Name "vmnic1"
    Get-VirtualSwitch -VMHost $esx -Name vSwitch0 | Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $vmhostLocalNetworkAdapter -Confirm:$false
    Get-VirtualSwitch -VMHost $esx -Name vSwitch0 | Get-SecurityPolicy| Set-SecurityPolicy -AllowPromiscuous $false -ForgedTransmits $false -MacChanges $false | Out-Null
    Write-Host Connected $vmhostLocalNetworkAdapter to vSwitch0 on $esx! -ForegroundColor Yellow
}
Disconnect-VIServer -Force -Confirm:$false