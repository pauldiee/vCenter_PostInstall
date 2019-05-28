$WorkingDir = split-path -parent $PSCommandPath
Set-Location -Path $WorkingDir
$p = Import-PowerShellDataFile -Path ".\parameters.psd1"

Connect-VIServer $p.vcenter -User $p.vcenteruser -Password $p.vcenterpass -Force | Out-Null

#Add 10 Hosts to vCenter 5 per MER (Cluster and Datacenter)
if ((Get-Cluster |Where-Object {$_.Name -eq $p.cluster})){
    1..5 | Foreach-Object { 
        Add-VMHost dc1-esxi-2-0$_.infra.local -Location  (Get-Cluster $p.cluster) -User $p.esxiuser -Password $p.esxipass -force:$true
        Write-Host Hosts dc1-esxi-2-0$_.infra.local added to $p.cluster -ForegroundColor Yellow
    }
    1..5 | Foreach-Object { 
        Add-VMHost dc2-esxi-2-0$_.infra.local -Location (Get-Cluster $p.cluster) -User $p.esxiuser -Password $p.esxipass -force:$true
        Write-Host Hosts dc2-esxi-2-0$_.infra.local added to $p.cluster -ForegroundColor Yellow
    }
} else {
    Write-Host Cluster $p.cluster does not exist! Nothing Done. -ForegroundColor Yellow
}

Disconnect-VIServer -Force