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
$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

#Create vSAN VMkernel
$Esxi_Hosts_vsan = Import-CSV ".\vsan_vmkernels.csv"
Foreach ($esxi in $Esxi_Hosts_vsan){
    if ((Get-VMHostNetworkAdapter -VMHost $esxi.ESXI_Host | Where-Object {($_.VsanTrafficEnabled -eq $true)})){
        Write-Host vSAN vmkernel already exists on $esxi.ESXI_Host -ForegroundColor Cyan
    } else{
        New-VMHostNetworkAdapter -VMHost $esxi.ESXI_Host -PortGroup $p.vsanportgroup -VirtualSwitch $p.dvs -IP $esxi.IP -SubnetMask $p.subnetmask -MTU 1500 -VsanTrafficEnabled $true | Out-Null
        Write-Host vSAN vmkernel created on $esxi.ESXI_Host -ForegroundColor Green
    }
}

#Create vMotion VMkernel
$Esxi_Hosts_vmotion = Import-CSV ".\vmotion_vmkernels.csv"
Foreach ($esxi in $Esxi_Hosts_vmotion){
    if ((Get-VMHostNetworkAdapter -VMHost $esxi.ESXI_Host | Where-Object {($_.VMotionEnabled -eq $true)})){
        Write-Host vMotion vmkernel already exists on $esxi.ESXI_Host -ForegroundColor Cyan
    } else{
        $esxcli = Get-EsxCli -VMHost $esxi.ESXI_Host -V2
           
        #Create vmotion netstack
        $esxcli.network.ip.netstack.add.invoke(@{netstack = "vmotion"}) | Out-Null
    
        #Create Temp Portgroup for Kernel
        $vswitch = Get-VirtualSwitch -Standard -VMHost $esxi.ESXI_Host
        New-VirtualPortGroup -VirtualSwitch $vswitch -Name "VMOTIONTEMP" | Out-Null

        #Create VMKERNEL ON LOCAL vswitch
        $arguments = $esxcli.network.ip.interface.add.CreateArgs()
        $arguments.mtu = "1500"
        $arguments.portgroupname = "VMOTIONTEMP"
        $arguments.netstack = "vmotion"
        $arguments.interfacename = "vmk2"
        $esxcli.network.ip.interface.add.Invoke($arguments) | Out-Null

        Start-Sleep -Seconds 10

        #Set IP Configuration
        $vmk = Get-VMHostNetworkAdapter -Name "vmk2" -VMHost $esxi.ESXI_Host
        Set-VMHostNetworkAdapter -VirtualNic $vmk -IP $esxi.IP -SubnetMask $p.subnetmask -IPv6Enabled $false -Confirm:$false | Out-Null

        #Migrate vmotion vmk to Distibuted Portgroup
        $vmk = Get-VMHostNetworkAdapter -Name "vmk2" -VMHost $esxi.ESXI_Host
        Set-VMHostNetworkAdapter -PortGroup $p.vmotionportgroup -VirtualNic $vmk -Confirm:$false | Out-Null

        #Remove Temp Portgroup for Kernel
        $pg = Get-VirtualPortGroup -VirtualSwitch $vswitch -VMHost $esxi.ESXI_Host -Standard -Name "VMOTIONTEMP"
        Remove-VirtualPortGroup -VirtualPortGroup $pg -Confirm:$false | Out-Null
        Write-Host vMotion vmkernel created on $esxi.ESXI_Host -ForegroundColor Green
    }
}

#Create Provisioning VMkernel
$Esxi_Hosts_prov = Import-CSV ".\provisioning_vmkernels.csv"
Foreach ($esxi in $Esxi_Hosts_prov){
    if ((Get-VMHostNetworkAdapter -VMHost $esxi.ESXI_Host | Where-Object {$_.IP -eq $esxi.IP})){
        Write-Host Provisioning vmkernel already exists on $esxi.ESXI_Host -ForegroundColor Cyan
    } else{
        $esxcli = Get-EsxCli -VMHost $esxi.ESXI_Host -V2
           
        #Create Provisioning netstack
        $esxcli.network.ip.netstack.add.invoke(@{netstack = "vSphereProvisioning"}) | Out-Null
    
        #Create Temp Portgroup for Kernel
        $vswitch = Get-VirtualSwitch -Standard -VMHost $esxi.ESXI_Host
        New-VirtualPortGroup -VirtualSwitch $vswitch -Name "PROVISIONINGTEMP" | Out-Null

        #Create VMKERNEL ON LOCAL vswitch
        $arguments = $esxcli.network.ip.interface.add.CreateArgs()
        $arguments.mtu = "1500"
        $arguments.portgroupname = "PROVISIONINGTEMP"
        $arguments.netstack = "vSphereProvisioning"
        $arguments.interfacename = "vmk3"
        $esxcli.network.ip.interface.add.Invoke($arguments) | Out-Null

        Start-Sleep -Seconds 10

        #Set IP Configuration
        $vmk = Get-VMHostNetworkAdapter -Name "vmk3" -VMHost $esxi.ESXI_Host
        Set-VMHostNetworkAdapter -VirtualNic $vmk -IP $esxi.IP -SubnetMask $p.subnetmask -IPv6Enabled $false -Confirm:$false | Out-Null

        #Migrate Kernel to Distibuted Portgroup
        $vmk = Get-VMHostNetworkAdapter -Name "vmk3" -VMHost $esxi.ESXI_Host
        Set-VMHostNetworkAdapter -PortGroup $p.provisioningportgroup -VirtualNic $vmk -Confirm:$false | Out-Null

        #Remove Temp Portgroup for Kernel
        $pg = Get-VirtualPortGroup -VirtualSwitch $vswitch -VMHost $esxi.ESXI_Host -Standard -Name "PROVISIONINGTEMP"
        Remove-VirtualPortGroup -VirtualPortGroup $pg -Confirm:$false | Out-Null
        Write-Host Provisioning vmkernel created on $esxi.ESXI_Host -ForegroundColor Green
    }
}
Disconnect-VIServer -Force -Confirm:$false