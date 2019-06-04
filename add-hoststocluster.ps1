<#
=============================================================================================================
Script:    		    add-hoststocluster.ps1
Date:      		    June, 2019
Create By:          Paul van Dieen
Last Edited by:	    Paul van Dieen
Last Edited Date:   04-06-2019
Requirements:		Powershell Framework 5.1
                    PowerCLI 11.2
=============================================================================================================
.DESCRIPTION
This script will connect 10 hosts to the cluster.
#>
$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

#Add 10 Hosts to vCenter 5 per MER (Cluster and Datacenter)
if ((Get-Cluster |Where-Object {$_.Name -eq $p.cluster})){
    1..5 | Foreach-Object { #Change Number of hosts here for MER1 (does not work from 10 up needs work)
        if ((Get-VMHost dc1-esxi-2-0$_.infra.local -ErrorAction SilentlyContinue)){            
            Write-Host Host dc1-esxi-2-0$_.infra.local already exists. -ForegroundColor Cyan
        } else{
            if ((Test-NetConnection dc1-esxi-2-0$_.infra.local).PingSucceeded.Equals($false)){
                Write-Host Host dc1-esxi-2-0$_.infra.local does not respond to PING done nothing -ForegroundColor Red
            } else{
                Add-VMHost dc1-esxi-2-0$_.infra.local -Location  (Get-Cluster $p.cluster) -User $p.esxiuser -Password $p.esxipass -force:$true | Out-Null
                Write-Host Host dc1-esxi-2-0$_.infra.local added to $p.cluster -ForegroundColor Green
            }
        }
    }
    1..5 | Foreach-Object { #Change Number of hosts here for MER2 (does not work from 10 up needs work)
        if ((Get-VMHost dc2-esxi-2-0$_.infra.local -ErrorAction SilentlyContinue)){            
            Write-Host Host dc1-esxi-2-0$_.infra.local already exists. -ForegroundColor Cyan
        } else{
            if ((Test-NetConnection dc2-esxi-2-0$_.infra.local).PingSucceeded.Equals($false)){
                Write-Host Host dc2-esxi-2-0$_.infra.local does not respond to PING done nothing -ForegroundColor Red
            } else{
                Add-VMHost dc2-esxi-2-0$_.infra.local -Location (Get-Cluster $p.cluster) -User $p.esxiuser -Password $p.esxipass -force:$true | Out-Null
                Write-Host Host dc2-esxi-2-0$_.infra.local added to $p.cluster -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host Cluster $p.cluster does not exist! -ForegroundColor Cyan
}
Disconnect-VIServer -Force -Confirm:$false