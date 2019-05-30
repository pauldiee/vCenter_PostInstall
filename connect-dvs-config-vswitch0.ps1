<#
Script Assumes the use of 4 physical nics. The First 2 are connected to vSwitch0 and the last 2 are connected to the Distributed vSwitch.



#>
$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

#Connect DVSwitch to all Hosts
$esxihosts = get-cluster $p.cluster |get-vmhost
ForEach ($esx in $esxihosts){
    if ((Get-VDSwitch -VMHost $esx | Where-Object {$_.Name -eq $p.dvs})){
        Write-Host $p.dvs Already Connected to $esx! -ForegroundColor Cyan  
    } else{
        Get-VDSwitch -Name $p.dvs | Add-VDSwitchVMHost -VMHost $esx
        $vmhostNetworkAdapter1 = Get-VMHost $esx | Get-VMHostNetworkAdapter -Physical -Name "vmnic2"
        $vmhostNetworkAdapter2 = Get-VMHost $esx | Get-VMHostNetworkAdapter -Physical -Name "vmnic3"
        Get-VDSwitch -Name $p.dvs | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter1 -Confirm:$false | Out-Null
        Get-VDSwitch -Name $p.dvs | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter2 -Confirm:$false | Out-Null
        Write-Host $p.dvs Connected to $esx! -ForegroundColor Green
        Write-Host $vmhostNetworkAdapter1 and $vmhostNetworkAdapter2 Connected on $esx to $p.dvs -ForegroundColor Green
    }
}

#Add Uplinks to all Hosts for vSwitch0 and set Security to reject all
$esxihosts = get-cluster $p.cluster |get-vmhost
ForEach ($esx in $esxihosts){
    if ((Get-VirtualSwitch -VMHost $esx -Name vSwitch0 | Where-Object {$_.nic -eq "vmnic1" -and "vmnic0"})){
        Write-Host vSwitch0 already properly configured on $esx -ForegroundColor Cyan   
    } else{
        $vmhostLocalNetworkAdapter = Get-VMHost $esx | Get-VMHostNetworkAdapter -Physical -Name "vmnic1"
        Get-VirtualSwitch -VMHost $esx -Name vSwitch0 | Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $vmhostLocalNetworkAdapter -Confirm:$false
        Get-VirtualSwitch -VMHost $esx -Name vSwitch0 | Get-SecurityPolicy| Set-SecurityPolicy -AllowPromiscuous $false -ForgedTransmits $false -MacChanges $false | Out-Null
        Write-Host Connected $vmhostLocalNetworkAdapter to vSwitch0 on $esx! -ForegroundColor Green
    }
}

#Remove default portgroup on vSwitch0
$esxihosts = get-cluster $p.cluster |get-vmhost
ForEach ($esx in $esxihosts){
    if ((Get-VirtualSwitch -VMHost $esx -Name vSwitch0 | Get-VirtualPortGroup | Where-Object {$_.Name -eq "VM Network"})){
        Get-VirtualSwitch -VMHost $esx -Name vSwitch0 | Get-VirtualPortGroup -Name "VM Network"| Remove-VirtualPortGroup -Confirm:$false
        Write-Host Removed Portgroup VM Network from vSwitch0 on $esx! -ForegroundColor Green
    } else{
        Write-Host Portgroup VM Network already removed! -ForegroundColor Cyan
    }
}
Disconnect-VIServer -Force -Confirm:$false