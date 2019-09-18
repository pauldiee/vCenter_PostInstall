<#
=============================================================================================================
Script:    		    create-affinityrules.ps1
Created Date:       June, 2019
Created by:        	Paul van Dieën
Last Edited by:	    Paul van Dieën
Last Edited Date:   04-06-2019
Requirements:		Minimaal versie 3.10 van RVtools
                    POSH-SSH Module installed
                    Powershell Framework 5.1
                    PowerCLI 11.2
                    Following scripts must be successfully run before this one:

                    create-datacenter-cluster.ps1
                    create-switch-NetworkNames.ps1
                    add-hoststocluster.ps1
                    connect-dvs-config-vswitch0.ps1
                    create-vmkernels.ps1
=============================================================================================================
.DESCRIPTION
This script configures 2 affinity rules with 2 DRS VM groups and 2 DRS Host Groups.
Datacenter and Cluster created + dvswitch + portgroups + hosts connected.
#>
$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

#Connect to vCenter
Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

$ErrorActionPreference = "SilentlyContinue" #dirty solution needs work!
$checkruleexistsMERA = $false
$checkruleexistsMERA = (Get-DrsVMHostRule -Cluster $p.cluster).Name.Contains("Should run in MER-1")
$ErrorActionPreference = "Continue" #dirty solution needs work!

if ($checkruleexistsMERA -eq $true){
	Write-Host DRS Affinity Rule for MER 1 already exists -ForegroundColor Cyan
}

while ($checkruleexistsMERA -eq $false){
    #Create Affinity Rules for MER-1
    if ((Get-DrsClusterGroup -Cluster $p.cluster | Where-Object {$_.Name -contains "Should Run MER-1"})){    
        if ((Get-DrsClusterGroup -Cluster $p.cluster | Where-Object {$_.Name -contains "MER-1"})){        
            if ((Get-DrsVMHostRule -Cluster $p.cluster | Where-Object {$_.Name -contains "Should run in MER-1"})){
                Write-Host DRS Affinity Rule for MER 1 already exists -ForegroundColor Cyan
            } else{
                New-DrsVMHostRule -Cluster $p.cluster -Name "Should run in MER-1" -VMGroup "Should Run MER-1" -VMHostGroup "MER-1" -Type ShouldRunOn -Enabled $true | Out-Null
                $checkruleexistsMERA = (Get-DrsVMHostRule -Cluster $p.cluster).Name.Contains("Should run in MER-1")
                Write-Host Created DRS Affinity Rule for MER 1 -ForegroundColor Green
            }
        } else{
            #Create DRS Host Group MER-1
            $MERAHosts = (Get-Cluster $p.cluster) | Get-VMHost -Name dc1*
            New-DrsClusterGroup -Name "MER-1" -Cluster $p.cluster -VMHost $MERAHosts | Out-Null
            Write-Host DRS Host Group MER-1 created -ForegroundColor Green        
        }
    } else{    
        if ((Get-VM | Where-Object {$_.Name -eq "MERA-1"})){
            Write-Host VM MERA-1 already exists -ForegroundColor Cyan
        } else{
            #Create VM MERA-1
            $cluster = Get-Cluster $p.cluster
            New-VM -Name MERA-1 -ResourcePool $cluster -NetworkName $p.resourcemgmtportgroup | Out-Null
            Write-Host VM MERA-1 created -ForegroundColor Green
        }
        #Create DRS VM Group Should Run MER-1
        New-DrsClusterGroup -Name "Should Run MER-1" -VM MERA-1 -Cluster $p.cluster | Out-Null
        Write-Host VM Group Should Run MER-1 created -ForegroundColor Green
        if ((Get-VM | Where-Object {$_.Name -eq "MERA-1"})){
            #Remove VM MERA-1
            get-vm MERA-1 | Remove-VM -DeletePermanently -Confirm:$false -RunAsync | Out-Null
            Write-Host VM MERA-1 Removed -ForegroundColor Green
        } else {
            Write-Host VM MERA-1 already Removed -ForegroundColor Cyan
        }
    }
}

$ErrorActionPreference = "SilentlyContinue" #dirty solution needs work!
$checkruleexistsMERB = $false
$checkruleexistsMERB = (Get-DrsVMHostRule -Cluster $p.cluster -ErrorAction SilentlyContinue).Name.Contains("Should run in MER-2")
$ErrorActionPreference = "Continue" #dirty solution needs work!

if ($checkruleexistsMERB -eq $true){
	Write-Host DRS Affinity Rule for MER 2 already exists -ForegroundColor Cyan
}

while ($checkruleexistsMERB -eq $false){
    #Create Affinity Rules for MER-2
    if ((Get-DrsClusterGroup -Cluster $p.cluster | Where-Object {$_.Name -contains "Should Run MER-2"})){    
        if ((Get-DrsClusterGroup -Cluster $p.cluster | Where-Object {$_.Name -contains "MER-2"})){        
            if ((Get-DrsVMHostRule -Cluster $p.cluster | Where-Object {$_.Name -eq "Should run in MER-2"})){
                Write-Host DRS Affinity Rule for MER 2 already exists -ForegroundColor Cyan
            } else{
                New-DrsVMHostRule -Cluster $p.cluster -Name "Should run in MER-2" -VMGroup "Should Run MER-2" -VMHostGroup "MER-2" -Type ShouldRunOn -Enabled $true | Out-Null
                $checkruleexistsMERB = (Get-DrsVMHostRule -Cluster $p.cluster).Name.Contains("Should run in MER-2")
                Write-Host Created DRS Affinity Rule for MER 2 -ForegroundColor Green
            }
        } else{
            #Create DRS Host Group MER-2
            $MERBHosts = (Get-Cluster $p.cluster) | Get-VMHost -Name dc2*
            New-DrsClusterGroup -Name "MER-2" -Cluster $p.cluster -VMHost $MERBHosts | Out-Null
            Write-Host DRS Host Group MER-2 created -ForegroundColor Green        
        }
    } else{    
        if ((Get-VM | Where-Object {$_.Name -eq "MERB-1"})){
            Write-Host VM MERB-1 already exists -ForegroundColor Cyan
        } else{
            #Create VM MERB-1
            $cluster = Get-Cluster $p.cluster
            New-VM -Name MERB-1 -ResourcePool $cluster -NetworkName $p.resourcemgmtportgroup | Out-Null
            Write-Host VM MERB-1 created -ForegroundColor Green
        }
        #Create DRS VM Group Should Run MER-1
        New-DrsClusterGroup -Name "Should Run MER-2" -VM MERB-1 -Cluster $p.cluster | Out-Null
        Write-Host VM Group Should Run MER-2 created -ForegroundColor Green
        if ((Get-VM | Where-Object {$_.Name -eq "MERB-1"})){
            #Remove VM MERB-1
            get-vm MERB-1 | Remove-VM -DeletePermanently -Confirm:$false -RunAsync | Out-Null
            Write-Host VM MERB-1 Removed -ForegroundColor Green
        } else {
            Write-Host VM MERB-1 already Removed -ForegroundColor Cyan
        }
    }
}
Disconnect-VIServer -Force -Confirm:$false | Out-Null