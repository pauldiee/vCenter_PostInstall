<#
=============================================================================================================
Script:    		    create-affinityrules.ps1
Created Date:       November, 2018
Created by:        	Paul van Dieën
Last Edited by:	    Paul van Dieën
Last Edited Date:   04-06-2019
Requirements:		Minimaal versie 3.10 van RVtools
                    POSH-SSH Module installed
                    Powershell Framework 5.1
                    PowerCLI 11.2
                    Following scripts must be successfully run before this one:

                    create-datacenter-cluster.ps1
                    create-switch-portgroups.ps1
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

$ErrorActionPreference = "SilentlyContinue" #solution needs work!
$checkruleexistsMERA = $false
$checkruleexistsMERA = (Get-DrsVMHostRule -Cluster $p.cluster).Name.Contains("Should run in MER-A")
$ErrorActionPreference = "Continue" #solution needs work!

if ($checkruleexistsMERA -eq $true){
	Write-Host DRS Affinity Rule for MER A already exists -ForegroundColor Cyan
}

while ($checkruleexistsMERA -eq $false){
    #Create Affinity Rules for MER-A
    if ((Get-DrsClusterGroup -Cluster $p.cluster | Where-Object {$_.Name -contains "Should Run MER-A"})){    
        if ((Get-DrsClusterGroup -Cluster $p.cluster | Where-Object {$_.Name -contains "MER-A"})){        
            if ((Get-DrsVMHostRule -Cluster $p.cluster | Where-Object {$_.Name -contains "Should run in MER-A"})){
                Write-Host DRS Affinity Rule for MER A already exists -ForegroundColor Cyan
            } else{
                New-DrsVMHostRule -Cluster $p.cluster -Name "Should run in MER-A" -VMGroup "Should Run MER-A" -VMHostGroup "MER-A" -Type ShouldRunOn -Enabled $true | Out-Null
                $checkruleexistsMERA = (Get-DrsVMHostRule -Cluster $p.cluster).Name.Contains("Should run in MER-A")
                Write-Host Created DRS Affinity Rule for MER A -ForegroundColor Green
            }
        } else{
            #Create DRS Host Group MER-A
            $MERAHosts = (Get-Cluster $p.cluster) | Get-VMHost -Name dc1*
            New-DrsClusterGroup -Name "MER-A" -Cluster $p.cluster -VMHost $MERAHosts | Out-Null
            Write-Host DRS Host Group MER-A created -ForegroundColor Green        
        }
    } else{    
        if ((Get-VM | Where-Object {$_.Name -eq "MERA-1"})){
            Write-Host VM MERA-1 already exists -ForegroundColor Cyan
        } else{
            #Create VM MERA-1
            $cluster = Get-Cluster $p.cluster
            New-VM -Name MERA-1 -ResourcePool $cluster | Out-Null
            Write-Host VM MERA-1 created -ForegroundColor Green
        }
        #Create DRS VM Group Should Run MER-A
        New-DrsClusterGroup -Name "Should Run MER-A" -VM MERA-1 -Cluster $p.cluster | Out-Null
        Write-Host VM Group Should Run MER-A created -ForegroundColor Green
        if ((Get-VM | Where-Object {$_.Name -eq "MERA-1"})){
            #Remove VM MERA-1
            get-vm MERA-1 | Remove-VM -DeletePermanently -Confirm:$false -RunAsync | Out-Null
            Write-Host VM MERA-1 Removed -ForegroundColor Green
        } else {
            Write-Host VM MERA-1 already Removed -ForegroundColor Cyan
        }
    }
}

$ErrorActionPreference = "SilentlyContinue" #solution needs work!
$checkruleexistsMERB = $false
$checkruleexistsMERB = (Get-DrsVMHostRule -Cluster $p.cluster -ErrorAction SilentlyContinue).Name.Contains("Should run in MER-B")
$ErrorActionPreference = "Continue" #solution needs work!

if ($checkruleexistsMERB -eq $true){
	Write-Host DRS Affinity Rule for MER B already exists -ForegroundColor Cyan
}

while ($checkruleexistsMERB -eq $false){
    #Create Affinity Rules for MER-B
    if ((Get-DrsClusterGroup -Cluster $p.cluster | Where-Object {$_.Name -contains "Should Run MER-B"})){    
        if ((Get-DrsClusterGroup -Cluster $p.cluster | Where-Object {$_.Name -contains "MER-B"})){        
            if ((Get-DrsVMHostRule -Cluster $p.cluster | Where-Object {$_.Name -eq "Should run in MER-B"})){
                Write-Host DRS Affinity Rule for MER B already exists -ForegroundColor Cyan
            } else{
                New-DrsVMHostRule -Cluster $p.cluster -Name "Should run in MER-B" -VMGroup "Should Run MER-B" -VMHostGroup "MER-B" -Type ShouldRunOn -Enabled $true | Out-Null
                $checkruleexistsMERB = (Get-DrsVMHostRule -Cluster $p.cluster).Name.Contains("Should run in MER-B")
                Write-Host Created DRS Affinity Rule for MER B -ForegroundColor Green
            }
        } else{
            #Create DRS Host Group MER-B
            $MERBHosts = (Get-Cluster $p.cluster) | Get-VMHost -Name dc2*
            New-DrsClusterGroup -Name "MER-B" -Cluster $p.cluster -VMHost $MERBHosts | Out-Null
            Write-Host DRS Host Group MER-B created -ForegroundColor Green        
        }
    } else{    
        if ((Get-VM | Where-Object {$_.Name -eq "MERB-1"})){
            Write-Host VM MERB-1 already exists -ForegroundColor Cyan
        } else{
            #Create VM MERB-1
            $cluster = Get-Cluster $p.cluster
            New-VM -Name MERB-1 -ResourcePool $cluster | Out-Null
            Write-Host VM MERB-1 created -ForegroundColor Green
        }
        #Create DRS VM Group Should Run MER-A
        New-DrsClusterGroup -Name "Should Run MER-B" -VM MERB-1 -Cluster $p.cluster | Out-Null
        Write-Host VM Group Should Run MER-B created -ForegroundColor Green
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