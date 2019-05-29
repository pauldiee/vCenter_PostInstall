<#
Created by : "Paul van Dieën"
Created on : "28-5-2019"
Latest Change :"28-5-2019"

prerequisites :
POSH-SSH Module installed
Powershell Framework 5.1
PowerCLI 11.2

This script Adds 5 hosts per MER for a total of 10 hosts, change the number of hosts within this script.
#>

$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

#secure credentials
$secureStringPwd = $p.esxipass | ConvertTo-SecureString -AsPlainText -Force
$esxicredential = New-Object -TypeName System.Management.Automation.PSCredential($p.esxiuser,$secureStringPwd)

#Connect to vCenter
Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

#Create Datacenter and Cluster Objects
$location = Get-Folder -NoRecursion
if ((Get-Datacenter |Where-Object {$_.Name -eq $p.datacenter})){
    Write-Host Datacenter $p.datacenter already exists! -ForegroundColor Cyan
 } else {
    New-Datacenter $p.datacenter -Location $location | Out-Null
    Write-Host Datacenter $p.datacenter Created! -ForegroundColor Green
 }
 if ((Get-Cluster |Where-Object {$_.Name -eq $p.cluster})){
    Write-Host Cluster $p.cluster already exists! -ForegroundColor Cyan
} else {
    New-Cluster $p.cluster -Location $p.datacenter | Out-Null
    Write-Host Cluster $p.cluster Created! -ForegroundColor Green
}

# Switch and Portgroups
if ((Get-Datacenter |Where-Object {$_.Name -eq $p.datacenter})){
    #Create DVSwitch $p.dvs
    $cluster = "$p.cluster"
    if ((Get-VDSwitch |Where-Object {$_.Name -eq $p.dvs})) {
        Write-Host Portgroup $p.dvs already exists! -ForegroundColor Cyan
    } else {
        New-VDSwitch -Location $p.datacenter -Name $p.dvs -NumUplinkPorts 2 -Mtu 9000 | Out-Null
        Write-Host Distributed Switch $p.dvs Created! -ForegroundColor Green
    }

    #Create $p.resourcemgmtportgroup Portgroup
    if ((Get-VDSwitch $p.dvs | Get-VDPortgroup | Where-Object {$_.Name -eq $p.resourcemgmtportgroup})){
        Write-Host Portgroup $p.resourcemgmtportgroup already exists! -ForegroundColor Cyan
    } else {
        New-VDPortgroup -Name $p.resourcemgmtportgroup -VlanId $p.rscmgmtvlan -PortBinding static -NumPorts 8 -VDSwitch $p.dvs | Out-Null
        Write-Host Portgroup $p.resourcemgmtportgroup Created! -ForegroundColor Green
    }

    #Create $p.vmotionportgroup Portgroup
    if ((Get-VDSwitch $p.dvs | Get-VDPortgroup | Where-Object {$_.Name -eq $p.vmotionportgroup})){
        Write-Host Portgroup $p.vmotionportgroup already exists! -ForegroundColor Cyan
    } else {
        New-VDPortgroup -Name $p.vmotionportgroup -VlanId $p.vmotionvlan -PortBinding static -NumPorts 8 -VDSwitch $p.dvs | Out-Null
        Write-Host Portgroup $p.vmotionportgroup Created! -ForegroundColor Green    
    }

    #Create $p.provisioningportgroup Portgroup
    if ((Get-VDSwitch $p.dvs | Get-VDPortgroup | Where-Object {$_.Name -eq $p.provisioningportgroup})){
        Write-Host Portgroup $p.provisioningportgroup already exists! -ForegroundColor Cyan
    } else {
        New-VDPortgroup -Name $p.provisioningportgroup -VlanId $p.provisioningvlan -PortBinding static -NumPorts 8 -VDSwitch $p.dvs | Out-Null
        Write-Host Portgroup $p.provisioningportgroup Created! -ForegroundColor Green    
    }

    #Create $p.provisioningportgroup Portgroup
    if ((Get-VDSwitch $p.dvs | Get-VDPortgroup | Where-Object {$_.Name -eq $p.vsanportgroup})){
        Write-Host Portgroup $p.vsanportgroup already exists! -ForegroundColor Cyan
    } else {
        New-VDPortgroup -Name $p.vsanportgroup -VlanId $p.vsanvlan -PortBinding static -NumPorts 8 -VDSwitch $p.dvs | Out-Null
        Write-Host Portgroup $p.vsanportgroup Created! -ForegroundColor Green    
    }
 } else {
    Write-Host Datacenter $p.datacenter does not exist! -ForegroundColor Cyan
}

#Add 10 Hosts to vCenter 5 per MER (Cluster and Datacenter)
if ((Get-Cluster |Where-Object {$_.Name -eq $p.cluster})){
    1..5 | Foreach-Object {
        if (($check = Get-VMHost dc1-esxi-2-0$_.infra.local -ErrorAction SilentlyContinue)){            
            Write-Host Host dc1-esxi-2-0$_.infra.local already exists. -ForegroundColor Cyan
        } else{
            Add-VMHost dc1-esxi-2-0$_.infra.local -Location  (Get-Cluster $p.cluster) -User $p.esxiuser -Password $p.esxipass -force:$true | Out-Null
            Write-Host Host dc1-esxi-2-0$_.infra.local added to $p.cluster -ForegroundColor Green
        }
    }
    1..5 | Foreach-Object { 
        if (($check = Get-VMHost dc2-esxi-2-0$_.infra.local -ErrorAction SilentlyContinue)){            
            Write-Host Host dc1-esxi-2-0$_.infra.local already exists. -ForegroundColor Cyan
        } else{
            Add-VMHost dc2-esxi-2-0$_.infra.local -Location (Get-Cluster $p.cluster) -User $p.esxiuser -Password $p.esxipass -force:$true | Out-Null
            Write-Host Host dc2-esxi-2-0$_.infra.local added to $p.cluster -ForegroundColor Green
        }
    }
} else {
    Write-Host Cluster $p.cluster does not exist! -ForegroundColor Cyan
}

#Configure NTP server
$esxihosts = get-cluster $p.cluster |get-vmhost
foreach ($esx in $esxihosts){
    if ((Get-VMHostNtpServer -VMHost $esx | Where-Object {$_.Name -ne $p.ntpserver})){
        Write-Host NTP Server already set on $esx. -ForegroundColor Cyan
    } else {
        Add-VmHostNtpServer -VMHost $esx -NtpServer $p.ntpserver | Out-Null
        #Allow NTP queries outbound through the firewall
        Get-VMHostFirewallException -VMHost $esx | Where-Object {$_.Name -eq "NTP client"} | Set-VMHostFirewallException -Enabled:$true  | Out-Null
        #Start NTP client service and set to automatic
        Get-VmHostService -VMHost $esx | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService  | Out-Null
        Get-VmHostService -VMHost $esx | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -policy "automatic"  | Out-Null
        Write-Host Done setting up NTP on $esx! -ForegroundColor Green
    }
}

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

#Create vSAN VMkernel
$Esxi_Hosts_vsan = Import-CSV ".\vsan_vmkernels.csv"
Foreach ($esxi in $Esxi_Hosts_vsan){
    if ((Get-VMHostNetworkAdapter -VMHost $esxi.ESXI_Host | Where-Object {($_.VsanTrafficEnabled -eq $true)})){
        Write-Host vSAN vmkernel already exists! -ForegroundColor Cyan
    } else{
        New-VMHostNetworkAdapter -VMHost $esxi.ESXI_Host -PortGroup $p.vsanportgroup -VirtualSwitch $p.dvs -IP $esxi.IP -SubnetMask $p.subnetmask -MTU 1500 -VsanTrafficEnabled $true | Out-Null
        Write-Host vSAN vmkernel created! -ForegroundColor Green
    }
}

#Create vMotion VMkernel
$Esxi_Hosts_vmotion = Import-CSV ".\vmotion_vmkernels.csv"
Foreach ($esxi in $Esxi_Hosts_vmotion){
    if ((Get-VMHostNetworkAdapter -VMHost $esxi.ESXI_Host | Where-Object {($_.VMotionEnabled -eq $true)})){
        Write-Host vMotion vmkernel already exists! -ForegroundColor Cyan
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
        Write-Host vMotion vmkernel created! -ForegroundColor Green
    }
}

#Create Provisioning VMkernel
$Esxi_Hosts_prov = Import-CSV ".\provisioning_vmkernels.csv"
Foreach ($esxi in $Esxi_Hosts_prov){
    if ((Get-VMHostNetworkAdapter -VMHost $esxi.ESXI_Host | Where-Object {$_.IP -eq $esxi.IP})){
        Write-Host Provisioning vmkernel already exists! -ForegroundColor Cyan
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
        Write-Host Provisioning vmkernel created! -ForegroundColor Green
    }
}

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

#HARDE STOP!
[void](Read-Host 'Press Enter to continue')

#Configure vSAN
if((Get-Cluster $p.cluster | Where-Object {$_.VsanEnabled -eq $false})){
    Set-Cluster $p.cluster -VsanEnabled $true -Confirm:$false
    Set-VsanClusterConfiguration -Configuration (Get-VsanClusterConfiguration $p.cluster) -SpaceEfficiencyEnabled $true
}

#HARDE STOP!
[void](Read-Host 'Press Enter to continue')

#Create 1 diskgroup of 8 disks on each host
$cluster = "$p.cluster"
$esxihosts = get-cluster $p.cluster |get-vmhost
ForEach ($esxi in $esxihosts){
    # Get Start Time
    $startDTM = (Get-Date)
    
    #diskgroep definities voor 8 disken in 1 diskgroep
    $diskgroup1="s1,2,3,4,5,6,7,8"
    $Diskgroups =$diskgroup1

    #enable SSH
    Get-VMHost $esxi | ForEach-Object {Start-VMHostService -HostService ($_ | Get-VMHostService | Where-Object { $_.Key -eq "TSM-SSH"} )}

    #Opbouwen SSH Sessie
    New-SSHSession -ComputerName "$esxi" -Credential $esxicredential -Acceptkey

    ForEach ($i in $Diskgroups){

        #Stap1: Opvragen WWN obv SLOTID
        $getdiskgroup= $(Invoke-SSHCommand -SessionID 0 -command "/opt/lsi/storcli/storcli /c0/e8/$i show all|grep 'WWN'")

        #Loop door de output om de WWNs te strippen en vervolgens in een aray te stoppen
        $disk3 = @()
            foreach ($disk in $getdiskgroup.Output) {
                $disk2 = $disk.split("=")[-1]
                $disk3 += "naa.$($disk2.TrimStart())"
            }

        #Creeer de diskgroup met de hierboven verkegen WWNs - pas deze aan als het aantal disks anders is dan 8 per diskgroep
        New-VsanDiskGroup -VMHost $esxi -SsdCanonicalName $disk3[0] -DataDiskCanonicalName $disk3[1],$disk3[2],$disk3[3],$disk3[4],$disk3[5],$disk3[6],$disk3[7]
}
    #Maak een csv aan met de diskgroup info voor de host
    get-vsandisk -vmhost $esxi |Select-Object VsanDiskGroup, CanonicalName |Export-Csv $WorkingDir\${esxi}.diskgroups.csv
    #DisableSSH
    Get-VMHostService -VMHost $esxi | Where-Object {$_.Key -eq "TSM-SSH" } | Stop-VMHostService -Confirm:$false

    #Opruimen SSH Sessie
    remove-sshsession -SessionId 0
    
    # Get End Time
    $endDTM = (Get-Date)

    $duration=$($endDTM-$startDTM)
    # Echo Time elapsed
    Write-Host "Verstreken Tijd: $($duration.Minutes) Minuten"

}

#HARDE STOP!
[void](Read-Host 'Press Enter to continue')

#Configure DRS Settings and Enable
Set-Cluster $p.cluster -DrsEnabled $true -DrsAutomationLevel FullyAutomated -Confirm:$false
$Cluster = Get-Cluster $p.cluster
$Cluster | New-AdvancedSetting -Name das.isolationaddress0 -Value $p.dasisolation1 -Type ClusterDRS -Confirm:$false
$Cluster | New-AdvancedSetting -Name das.isolationaddress1 -Value $p.dasisolation2 -Type ClusterDRS -Confirm:$false
$Cluster | New-AdvancedSetting -Name das.usedefaultisolationaddress -Value false -Type ClusterDRS -Confirm:$false

#HARDE STOP!
[void](Read-Host 'Press Enter to continue')

#Configure vSphere Availability
Set-Cluster $p.cluster -HAEnabled $true -HARestartPriority Medium -HAIsolationResponse PowerOff -HAAdmissionControlEnabled $true -Confirm:$false
$cluster = Get-Cluster -Name $p.cluster
$spec = New-Object VMware.Vim.ClusterConfigSpec
$spec.DasConfig = New-Object VMware.Vim.ClusterDasConfigInfo
$spec.DasConfig.AdmissionControlPolicy = New-Object VMware.Vim.ClusterFailoverResourcesAdmissionControlPolicy
$spec.DasConfig.AdmissionControlPolicy.AutoComputePercentages = $false
$spec.DasConfig.AdmissionControlPolicy.CpuFailoverResourcesPercent = 50
$spec.DasConfig.AdmissionControlPolicy.MemoryFailoverResourcesPercent = 50
$cluster.ExtensionData.ReconfigureCluster($spec,$true)

#HARDE STOP!
[void](Read-Host 'Press Enter to continue')

#Configure EVC on Cluster
Set-Cluster $p.cluster -EVCMode "intel-broadwell" -Confirm:$false

#Create Host DRS Groups MER-A and MER-B
$cluster = Get-Cluster $p.cluster
$MERAHosts = $cluster | Get-VMHost -Name dc1*
$MERBHosts = $cluster | Get-VMHost -Name dc2*
New-DrsClusterGroup -Name "MER-A" -Cluster $cluster -VMHost $MERAHosts
New-DrsClusterGroup -Name "MER-B" -Cluster $cluster -VMHost $MERBHosts

#Create VM DRS Groups Should Run MER-A and Should Run MER-B
$cluster = Get-Cluster $p.cluster
New-VM -Name MERA-1 -ResourcePool $cluster -Portgroup $p.resourcemgmtportgroup
New-VM -Name MERB-1 -ResourcePool $cluster -Portgroup $p.resourcemgmtportgroup

New-DrsClusterGroup -Name "Should Run MER-A" -VM MERA-1 -Cluster $cluster
New-DrsClusterGroup -Name "Should Run MER-B" -VM MERB-1 -Cluster $cluster

get-vm MERA-1 | Remove-VM -DeletePermanently -Confirm:$false -RunAsync
get-vm MERB-1 | Remove-VM -DeletePermanently -Confirm:$false -RunAsync


#Create Affinity Rules for MER-A and MER-B
New-DrsVMHostRule -Cluster $cluster -Name "Should run in MER-A" -VMGroup "Should Run MER-A" -VMHostGroup "MER-A" -Type ShouldRunOn -Enabled $true
New-DrsVMHostRule -Cluster $cluster -Name "Should run in MER-B" -VMGroup "Should Run MER-B" -VMHostGroup "MER-B" -Type ShouldRunOn -Enabled $true

#Supress L1TF warning
$esxihosts = get-cluster $p.cluster |get-vmhost
foreach ($esxi in $esxihosts){
    Get-AdvancedSetting -Entity $esxi -Name UserVars.SuppressHyperthreadWarning | Set-AdvancedSetting -Value 1 -Confirm:$false
}

#Create CAMCUBE Folders
New-Folder "Applicaties" -Location VM
New-Folder "CAMCUBE-PRODUCTIE" -Location VM
New-Folder "DO_NOT_BACKUP" -Location VM

#Rename vsanDatastore
Get-Datastore vsanDatastore | Set-Datastore -Name "Resource-vsanDatastore"

#Set Coredump on all hosts
$esxihosts = get-cluster $p.cluster |get-vmhost
foreach ($esxi in $esxihosts){
    $esxcli = Get-EsxCli -VMHost $esxi
    $esxcli.system.coredump.network.set($null,"vmk0",$null,$p.vcenteripadress,6500)
    $esxcli.system.coredump.network.set($true)
    $esxcli.system.coredump.network.get()
}

#Create ProductLocker Location on vsanDatastore (nog uitwerken)
#$datastore = (Get-Datastore)
#New-PSDrive -Location $datastore -Name DS -PSProvider VimDatastore -Root "\"
#New-Item -Path DS: -ItemType Directory -Name SharedProductLocker
#New-Item -ItemType Directory -Name vmtools -Path \SharedProductLocker\
#New-Item -ItemType Directory -Name floppies -Path \SharedProductLocker\

#Create vSAN Storage Policies (nog uitwerken)
Get-SpbmStoragePolicy

#Add Permission for AD group after AD Join and Adding Identity Source
New-VIPermission -Entity (Get-Folder -NoRecursion) -Principal $p.adminadgroup -Role (Get-VIRole -Name Admin)

